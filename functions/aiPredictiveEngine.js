const functions = require('firebase-functions');
const admin = require('firebase-admin');

/**
 * ═══════════════════════════════════════════════════════════════
 * AI PREDICTIVE ENGAGEMENT & CALIBRATION ENGINE (PHASE 3)
 * ═══════════════════════════════════════════════════════════════
 */

// Logic cốt lõi để tính toán Khung Giờ Vàng (Optimal Engagement Hour)
async function runPredictiveEngine() {
    const db = admin.firestore();
    console.log("Bắt đầu quét dữ liệu sự kiện thông báo (eventType === 'OPENED')...");
    
    // Bước 1: Truy vấn toàn bộ dữ liệu OPENED
    const eventsSnap = await db.collection('notification_events')
        .where('eventType', '==', 'OPENED')
        .get();

    if (eventsSnap.empty) {
        console.log("Không có dữ liệu sự kiện OPENED nào.");
        return { success: true, message: 'No OPENED events found.', updatedUsers: 0 };
    }

    // Gom nhóm danh sách sự kiện theo từng userId
    const userHistograms = {};
    
    eventsSnap.forEach(doc => {
        const evt = doc.data();
        const uid = evt.userId;
        const timestamp = evt.timestamp;
        
        if (!uid || !timestamp) return;

        // Trích xuất thành phần Giờ
        let dateObj;
        if (timestamp.toDate) {
            dateObj = timestamp.toDate();
        } else {
            dateObj = new Date(timestamp);
        }

        const hour = dateObj.getHours();

        if (!userHistograms[uid]) {
            userHistograms[uid] = {};
        }
        userHistograms[uid][hour] = (userHistograms[uid][hour] || 0) + 1;
    });

    const batch = db.batch();
    let updatedCount = 0;

    // Tính toán tìm ra giá trị "Yếu vị" (Mode) cho mỗi user
    for (const [uid, hourHistogram] of Object.entries(userHistograms)) {
        let bestHour = 12; // Giờ mặc định
        let maxHits = -1;

        for (const [hourStr, hits] of Object.entries(hourHistogram)) {
            if (hits > maxHits) {
                maxHits = hits;
                bestHour = parseInt(hourStr, 10);
            }
        }

        // Bước 2: Đồng bộ hóa ngược về Firestore (sử dụng merge: true)
        const userRef = db.collection('users').doc(uid);
        batch.set(userRef, {
            analytics: {
                optimalEngagementHour: bestHour,
                lastAIPrediction: admin.firestore.FieldValue.serverTimestamp()
            }
        }, { merge: true });

        updatedCount++;
        console.log(`User ${uid}: Khung giờ vàng là ${bestHour}h (với ${maxHits} lần mở)`);
        
        // Push batch mỗi 500 records
        if (updatedCount % 500 === 0) {
            await batch.commit();
        }
    }

    if (updatedCount % 500 !== 0) {
        await batch.commit();
    }

    console.log(`Đã tính toán và cập nhật thành công cho ${updatedCount} users.`);
    return { success: true, updatedUsers: updatedCount };
}

/**
 * Hàm HTTP Callable: Kích hoạt thủ công luồng AI để kiểm thử
 */
exports.calculateOptimalEngagementHours = functions.https.onCall(async (data, context) => {
    try {
        return await runPredictiveEngine();
    } catch (err) {
        console.error('Lỗi khi chạy Predictive Engine:', err);
        throw new functions.https.HttpsError('internal', 'Lỗi hệ thống: ' + err.message);
    }
});

/**
 * Hàm Pub/Sub: Chạy định kỳ hàng tuần (Chủ nhật lúc 00:00)
 */
exports.scheduledPredictiveEngine = functions.pubsub.schedule('every sunday 00:00').onRun(async (context) => {
    try {
        await runPredictiveEngine();
    } catch (err) {
        console.error('Lỗi khi chạy CronJob Predictive Engine:', err);
    }
    return null;
});

/**
 * Bước 3: Bộ khung chặn gửi (Delay Push Helper)
 * Hàm kiểm tra và quyết định gửi ngay hay hoãn thông báo dựa trên Khung Giờ Vàng
 */
exports.smartPushHelper = async (userId, notificationPayload) => {
    const db = admin.firestore();
    try {
        const userDoc = await db.collection('users').doc(userId).get();
        if (!userDoc.exists) {
            console.log(`[SmartPush] User ${userId} không tồn tại.`);
            return false;
        }

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        
        if (!fcmToken) {
            console.log(`[SmartPush] User ${userId} chưa có FCM Token.`);
            return false;
        }

        const optimalHour = userData.analytics?.optimalEngagementHour;
        const currentHour = new Date().getHours();

        // Kiểm tra xem giờ hiện tại có khớp với optimalHour hay không
        if (optimalHour !== undefined && currentHour !== optimalHour) {
            console.log(`[SmartPush] Chưa đến khung giờ vàng của user ${userId} (Hiện tại: ${currentHour}h, Vàng: ${optimalHour}h).`);
            console.log(`[SmartPush] Hoãn tiến trình gửi Push và đưa vào hàng đợi scheduled_notifications.`);
            
            // TODO (Tương lai): Lưu notificationPayload vào collection scheduled_notifications
            return false; 
        }

        console.log(`[SmartPush] Thời điểm lý tưởng! Đang gửi Push ngay lập tức cho user ${userId} vào lúc ${currentHour}h.`);
        
        // Nếu trùng hoặc chưa phân tích, gọi FCM gửi ngay lập tức
        await admin.messaging().send({
            token: fcmToken,
            notification: notificationPayload.notification,
            data: notificationPayload.data
        });

        return true;
    } catch (error) {
        console.error(`[SmartPush] Lỗi khi xử lý cho user ${userId}:`, error);
        return false;
    }
};
