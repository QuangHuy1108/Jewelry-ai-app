/**
 * ═══════════════════════════════════════════════════════════════
 * AI PREDICTIVE ENGAGEMENT & CALIBRATION ENGINE (PHASE 3)
 * ═══════════════════════════════════════════════════════════════
 * 
 * Enforces state-of-the-art predictive messaging patterns. Analyzes telemetry 
 * event clusters to deduce personalized optimal engagement hours, automating 
 * high-conversion follow-ups to maximize lifetime user value (LTV) while 
 * avoiding notification fatigue.
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { resolveTemplate } = require('./templateEngine');

/**
 * 1. PREDICTIVE TIMING CALIBRATION CLUSTER
 * Analyzes historical OPENED events from the decoupled telemetry collection
 * to calculate each user's primary engagement timing vector.
 * 
 * Scaled to run selectively or via explicit CRON sweeps to safeguard against
 * uncontrolled cloud costs.
 */
exports.calibrateUserTimingClusters = functions.https.onCall(async (data, context) => {
  // Ensure elevated or authenticated execution contexts
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Execution context denied.');
  }

  const targetUserId = data.userId || context.auth.uid;
  const db = admin.firestore();

  try {
    // Query historical interactions mapping directly to Phase 2 event collectors
    const eventsSnap = await db.collection('notification_events')
      .where('userId', '==', targetUserId)
      .where('eventType', '==', 'OPENED')
      .orderBy('timestamp', 'desc')
      .limit(50)
      .get();

    if (eventsSnap.empty) {
      return { calibrated: false, message: 'Insufficient telemetry events for statistical calibration.' };
    }

    // Compute hour distribution histogram
    const hourHistogram = {};
    eventsSnap.docs.forEach(doc => {
      const evt = doc.data();
      if (evt.timestamp) {
        const dateObj = evt.timestamp.toDate ? evt.timestamp.toDate() : new Date(evt.timestamp);
        const hour = dateObj.getHours();
        hourHistogram[hour] = (hourHistogram[hour] || 0) + 1;
      }
    });

    // Resolve optimal hour vector via maximum frequency density
    let optimalHour = 12; // Base default 12 PM
    let maxHits = -1;

    for (const [hourStr, hits] of Object.entries(hourHistogram)) {
      if (hits > maxHits) {
        maxHits = hits;
        optimalHour = parseInt(hourStr, 10);
      }
    }

    // Write persistent calibration properties back to root profile nodes
    await db.collection('users').doc(targetUserId).set({
      engagementIntelligence: {
        optimalHour: optimalHour,
        sampleSize: eventsSnap.size,
        lastCalibratedAt: admin.firestore.FieldValue.serverTimestamp(),
        confidenceScore: Math.min(1.0, eventsSnap.size / 30)
      }
    }, { merge: true });

    return { 
      calibrated: true, 
      optimalEngagementHour: optimalHour,
      dataPointsAnalyzed: eventsSnap.size
    };

  } catch (err) {
    console.error('Calibration failure:', err);
    throw new functions.https.HttpsError('internal', 'Calibration calculation aborted.');
  }
});


/**
 * 2. AUTOMATED ABANDONMENT CONVERSION ENGINE
 * Dispatches hyper-tailored predictive acquisition reminders automatically
 * when checking idle shopping session structures.
 */
exports.triggerIntelligentCartRecovery = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Unauthorized triggering.');
  }

  const userId = context.auth.uid;
  const db = admin.firestore();

  try {
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) return { success: false, reason: 'Profile missing' };

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;
    const cartItems = userData.cart || [];

    if (cartItems.length === 0) {
      return { success: false, reason: 'Cart empty' };
    }

    // Fetch primary item details to build personalized luxury imagery parameters
    const primaryItem = cartItems[0];
    let productName = 'Curated Handcrafted Piece';
    let productImg = 'https://zink.cdn/assets/placeholder.jpg';

    if (primaryItem.productId) {
      const prdSnap = await db.collection('products').doc(primaryItem.productId).get();
      if (prdSnap.exists) {
        productName = prdSnap.data().name || productName;
        const images = prdSnap.data().images || [];
        if (images.length > 0) productImg = images[0];
      }
    }

    // Check user intelligence boundaries to compute custom ML priority boosts
    const aiPrefs = userData.engagementIntelligence || {};
    const optimalHour = aiPrefs.optimalHour ?? 19; // Default evening browsing hour
    const currentHour = new Date().getHours();
    
    // Boost relevance priority dynamically if current server window aligns with predicted profile behavior
    const isOptimalWindow = Math.abs(currentHour - optimalHour) <= 2;
    const computedBoostScore = isOptimalWindow ? 150 : 50;

    // Resolve persistent document strings via dynamic template subsystem
    const templateKey = 'CART_RECOVERY';
    const resolved = await resolveTemplate(templateKey, { productName: productName });

    const finalTitle = resolved.title || '✨ Timeless beauty awaits.';
    const finalBody = resolved.body || `Your reserved piece "${productName}" remains protected in our digital vault. Complete secure acquisition before inventory releases.`;

    const expiresDate = new Date();
    expiresDate.setDate(expiresDate.getDate() + 2); // 48-hour short TTL for idle conversion drives

    // Write persistence document ensuring cross-device UI rendering
    const notifRef = await db.collection('users').doc(userId).collection('notifications').add({
      title: finalTitle,
      body: finalBody,
      type: 'promotion',
      deepLink: '/cart',
      image: productImg,
      priority: 'medium',
      level: 'marketing',
      role: 'buyer',
      status: 'DELIVERED',
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: expiresDate,
      metadata: {
        aiOptimalPriority: computedBoostScore,
        productId: primaryItem.productId || null,
        scheduledDeliveryHour: optimalHour
      }
    });

    // Execute standard transport push targeting target devices
    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: finalTitle,
          body: finalBody,
          imageUrl: productImg
        },
        data: {
          type: 'promotion',
          deepLink: '/cart',
          notificationId: notifRef.id,
          priority: 'medium',
          level: 'marketing',
          role: 'buyer',
          aiOptimalPriority: String(computedBoostScore)
        }
      }).catch(e => console.warn('FCM broadcast failure during cart push:', e.message));
    }

    return { 
      success: true, 
      dispatched: true,
      boostScoreApplied: computedBoostScore,
      targetProduct: productName
    };

  } catch (err) {
    console.error('Cart conversion error:', err);
    throw new functions.https.HttpsError('internal', 'Cart automation routing skipped.');
  }
});
