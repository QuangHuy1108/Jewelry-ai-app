const functions = require('firebase-functions');
const admin = require('firebase-admin');

const db = admin.firestore();

// ═══════════════════════════════════════════════════════════════
// 1. ON ORDER CREATED
//    - Deduct stock from products
//    - Send push notification to the buyer
//    - Log the order event
// ═══════════════════════════════════════════════════════════════
exports.onOrderCreated = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const order = snap.data();
    const orderId = context.params.orderId;
    const userId = order.userId;

    // ── Deduct stock ──
    const items = order.items || [];
    const batch = db.batch();

    for (const item of items) {
      if (item.id) {
        const productRef = db.collection('products').doc(item.id);
        const productSnap = await productRef.get();
        if (productSnap.exists) {
          const currentStock = productSnap.data().stock || 0;
          const currentSold = productSnap.data().soldCount || 0;
          const qty = item.qty || 1;
          batch.update(productRef, {
            stock: Math.max(0, currentStock - qty),
            soldCount: currentSold + qty,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }
    }

    await batch.commit();

    // ── Send push notification ──
    try {
      const userDoc = await db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        const fcmToken = userDoc.data().fcmToken;
        if (fcmToken) {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: 'Order Confirmed! 🎉',
              body: `Your order #${orderId.substring(0, 8).toUpperCase()} has been placed successfully.`,
            },
            data: {
              type: 'order_created',
              orderId: orderId,
            },
          });
        }

        // Save in-app notification
        await db.collection('users').doc(userId).collection('notifications').add({
          title: 'Order Confirmed',
          body: `Your order #${orderId.substring(0, 8).toUpperCase()} has been placed successfully.`,
          type: 'order_created',
          orderId: orderId,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    } catch (err) {
      console.error('FCM send error:', err);
    }

    console.log(`Order ${orderId} processed: stock deducted, notification sent.`);
    return null;
  });


// ═══════════════════════════════════════════════════════════════
// 2. ON ORDER STATUS CHANGED
//    - Notify user when order status is updated (shipped, delivered, etc.)
// ═══════════════════════════════════════════════════════════════
exports.onOrderUpdated = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const orderId = context.params.orderId;

    // Only trigger on status change
    if (before.status === after.status) return null;

    const userId = after.userId;
    const newStatus = after.status;
    const shortId = orderId.substring(0, 8).toUpperCase();

    const statusMessages = {
      'processing': `Your order #${shortId} is being processed.`,
      'shipped': `Your order #${shortId} has been shipped! 🚚`,
      'delivered': `Your order #${shortId} has been delivered! ✅`,
      'cancelled': `Your order #${shortId} has been cancelled.`,
      'refunded': `Your order #${shortId} has been refunded. 💰`,
    };

    const message = statusMessages[newStatus] || `Order #${shortId} status updated to: ${newStatus}`;

    try {
      const userDoc = await db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        const fcmToken = userDoc.data().fcmToken;
        if (fcmToken) {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: 'Order Update',
              body: message,
            },
            data: {
              type: 'order_status',
              orderId: orderId,
              status: newStatus,
            },
          });
        }

        // Save in-app notification
        await db.collection('users').doc(userId).collection('notifications').add({
          title: 'Order Update',
          body: message,
          type: 'order_status',
          orderId: orderId,
          status: newStatus,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    } catch (err) {
      console.error('FCM send error on status update:', err);
    }

    // ── If cancelled, restore stock ──
    if (newStatus === 'cancelled' || newStatus === 'refunded') {
      const items = after.items || [];
      const batch = db.batch();
      for (const item of items) {
        if (item.id) {
          const productRef = db.collection('products').doc(item.id);
          const productSnap = await productRef.get();
          if (productSnap.exists) {
            const currentStock = productSnap.data().stock || 0;
            const currentSold = productSnap.data().soldCount || 0;
            const qty = item.qty || 1;
            batch.update(productRef, {
              stock: currentStock + qty,
              soldCount: Math.max(0, currentSold - qty),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        }
      }
      await batch.commit();
      console.log(`Order ${orderId} ${newStatus}: stock restored.`);
    }

    return null;
  });


// ═══════════════════════════════════════════════════════════════
// 3. ON WALLET TOP-UP
//    - Send notification confirming wallet credit
// ═══════════════════════════════════════════════════════════════
exports.onWalletTopUp = functions.firestore
  .document('users/{userId}/transactions/{txId}')
  .onCreate(async (snap, context) => {
    const tx = snap.data();
    const userId = context.params.userId;

    if (!tx.isPositive) return null; // Only notify on credits

    const amount = (tx.amount || 0).toFixed(2);

    try {
      const userDoc = await db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        const fcmToken = userDoc.data().fcmToken;
        if (fcmToken) {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: 'Wallet Credited 💳',
              body: `$${amount} has been added to your wallet.`,
            },
            data: { type: 'wallet_topup' },
          });
        }

        await db.collection('users').doc(userId).collection('notifications').add({
          title: 'Wallet Credited',
          body: `$${amount} has been added to your wallet via ${tx.paymentMethod || 'unknown'}.`,
          type: 'wallet_topup',
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    } catch (err) {
      console.error('Wallet notification error:', err);
    }

    return null;
  });


// ═══════════════════════════════════════════════════════════════
// 4. SCHEDULED: DAILY ANALYTICS AGGREGATION
//    - Runs every day at midnight UTC
//    - Counts total orders, revenue, top products, etc.
// ═══════════════════════════════════════════════════════════════
exports.dailyAnalytics = functions.pubsub
  .schedule('every day 00:00')
  .timeZone('UTC')
  .onRun(async () => {
    const now = new Date();
    const todayStr = now.toISOString().split('T')[0]; // "2026-05-12"

    // Get today's start
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const endOfDay = new Date(startOfDay.getTime() + 24 * 60 * 60 * 1000);

    const ordersSnap = await db.collection('orders')
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(startOfDay))
      .where('createdAt', '<', admin.firestore.Timestamp.fromDate(endOfDay))
      .get();

    let totalRevenue = 0;
    let totalOrders = ordersSnap.size;
    const categoryRevenue = {};

    ordersSnap.forEach((doc) => {
      const data = doc.data();
      totalRevenue += data.totalAmount || 0;

      const items = data.items || [];
      for (const item of items) {
        const cat = item.category || 'Unknown';
        categoryRevenue[cat] = (categoryRevenue[cat] || 0) + ((item.price || 0) * (item.qty || 1));
      }
    });

    // Count total users
    const usersSnap = await db.collection('users').get();

    // Count total products
    const productsSnap = await db.collection('products').get();

    await db.collection('analytics').doc(todayStr).set({
      date: todayStr,
      totalOrders,
      totalRevenue,
      totalUsers: usersSnap.size,
      totalProducts: productsSnap.size,
      categoryRevenue,
      calculatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    console.log(`Daily analytics for ${todayStr}: ${totalOrders} orders, $${totalRevenue} revenue.`);
    return null;
  });


// ═══════════════════════════════════════════════════════════════
// 5. SCHEDULED: AUTO-CANCEL STALE ORDERS
//    - Runs every hour
//    - Cancels pending orders older than 24 hours
// ═══════════════════════════════════════════════════════════════
exports.autoCancelStaleOrders = functions.pubsub
  .schedule('every 1 hours')
  .timeZone('UTC')
  .onRun(async () => {
    const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000); // 24 hours ago

    const staleOrders = await db.collection('orders')
      .where('status', '==', 'pending')
      .where('createdAt', '<', admin.firestore.Timestamp.fromDate(cutoff))
      .get();

    if (staleOrders.empty) {
      console.log('No stale orders to cancel.');
      return null;
    }

    const batch = db.batch();
    staleOrders.forEach((doc) => {
      batch.update(doc.ref, {
        status: 'cancelled',
        cancelReason: 'Auto-cancelled: no payment within 24 hours',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();
    console.log(`Auto-cancelled ${staleOrders.size} stale orders.`);
    return null;
  });
