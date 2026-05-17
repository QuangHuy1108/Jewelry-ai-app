/**
 * ═══════════════════════════════════════════════════════════════
 * COMMISSION & SELLER FINANCIAL ENGINE
 * ═══════════════════════════════════════════════════════════════
 * 
 * SECURITY: ALL money calculations happen HERE on the server.
 * Flutter app is strictly READ-ONLY for financial fields.
 * 
 * Functions:
 *   1. onAffiliateOrderCreated  — Set pending commission when order placed via referral
 *   2. onOrderStatusForCommission — Process commission when order delivered / cancelled
 *   3. processWithdrawalRequest — Validate and process seller withdrawal
 *   4. validatePromoCode        — Server-side promo code validation at checkout
 *   5. recordReferralClick      — Track referral link clicks
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { resolveTemplate } = require('./templateEngine');
const db = admin.firestore();

// ═══════════════════════════════════════════════════════════════
// 1. ON ORDER CREATED — Calculate Pending Commission
//    Triggered when a new order is created.
//    If the order has a referralSellerId, calculate and set
//    pending commission on the seller's record.
// ═══════════════════════════════════════════════════════════════
exports.onAffiliateOrderCreated = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const order = snap.data();
    const orderId = context.params.orderId;
    const referralSellerId = order.referralSellerId || order.affiliateId || order.sellerId;

    // Only process orders that came through a referral
    if (!referralSellerId) return null;

    try {
      // Get seller's commission rate
      const sellerDoc = await db.collection('sellers').doc(referralSellerId).get();
      if (!sellerDoc.exists) {
        console.error(`Seller ${referralSellerId} not found for order ${orderId}`);
        return null;
      }

      const sellerData = sellerDoc.data();
      const commissionRate = sellerData.commissionRate || 0.10; // Default 10%
      const orderTotal = order.totalAmount || order.total || 0;
      const commissionAmount = Math.round(orderTotal * commissionRate * 100) / 100;

      // Create a commission transaction record
      await db.collection('seller_transactions').add({
        sellerId: referralSellerId,
        orderId: orderId,
        type: 'commission',
        amount: commissionAmount,
        orderTotal: orderTotal,
        commissionRate: commissionRate,
        status: 'processing', // Customer just placed order
        description: `Commission from order #${orderId.substring(0, 8).toUpperCase()}`,
        customerUserId: order.userId || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        completedAt: null,
      });

      // Increment pending commission on seller (server-side atomic)
      await db.collection('sellers').doc(referralSellerId).update({
        pendingCommission: admin.firestore.FieldValue.increment(commissionAmount),
        totalConversions: admin.firestore.FieldValue.increment(1),
      });

      console.log(`Commission ${commissionAmount} set as pending for seller ${referralSellerId} on order ${orderId}`);

      // ── SMART GROUPING / DEBOUNCING NOTIFICATION ENGINE (PHASE 2) ──
      const sellerUserId = sellerData.userId;
      if (sellerUserId) {
        const userDoc = await db.collection('users').doc(sellerUserId).get();
        if (userDoc.exists) {
          const userData = userDoc.data();
          const fcmToken = userData.fcmToken;

          // Check user notification preferences mapping directly to telemetry
          const prefs = userData.notificationPreferences || {};
          const financeAllowed = prefs.categories?.finance?.push ?? prefs.channels?.push ?? true;

          if (financeAllowed) {
            const debouncingWindowMs = 5 * 60 * 1000; // 5 minutes window
            const now = Date.now();
            const expiresDate = new Date();
            expiresDate.setDate(expiresDate.getDate() + 30);

            // Find recent notification block to group with
            const recentNotifsSnap = await db.collection('users')
              .doc(sellerUserId)
              .collection('notifications')
              .where('type', '==', 'affiliate_conversion')
              .where('status', '==', 'DELIVERED')
              .orderBy('createdAt', 'desc')
              .limit(1)
              .get();

            let grouped = false;
            if (!recentNotifsSnap.empty) {
              const recentDoc = recentNotifsSnap.docs[0];
              const recentData = recentDoc.data();
              const createdTime = recentData.createdAt ? recentData.createdAt.toMillis() : 0;

              if (now - createdTime < debouncingWindowMs) {
                // Execute rolling update grouping transaction
                grouped = true;
                const meta = recentData.metadata || {};
                const prevCount = meta.conversionCount || 1;
                const newCount = prevCount + 1;
                const prevTotal = meta.totalCommission || (recentData.metadata?.commissionAmount || 0);
                const newTotal = Math.round((prevTotal + commissionAmount) * 100) / 100;

                // Resolve updated dynamic template string reflecting count parameters
                const resolved = await resolveTemplate('COMMISSION_UNLOCKED', {
                  amount: newTotal,
                  count: newCount
                });

                const rolledUpTitle = `💰 Active Campaign Conversions (${newCount})`;
                const rolledUpBody = `🔥 Impressive Reach: Your showcase successfully captured ${newCount} client acquisitions within the last few minutes, accumulating $${newTotal} in pending rewards.`;

                await recentDoc.ref.update({
                  title: rolledUpTitle,
                  body: rolledUpBody,
                  'metadata.conversionCount': newCount,
                  'metadata.totalCommission': newTotal,
                  updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });

                // Dispatch silent real-time FCM payload update to mobile clients
                if (fcmToken) {
                  await admin.messaging().send({
                    token: fcmToken,
                    data: {
                      type: 'affiliate_conversion',
                      action: 'update_digest',
                      notificationId: recentDoc.id,
                      count: String(newCount),
                      total: String(newTotal),
                      priority: 'medium'
                    }
                  }).catch(e => console.warn('Silent payload skip:', e.message));
                }

                console.log(`Smart Grouping triggered: Rolled up conversion count to ${newCount} for seller ${referralSellerId}`);
              }
            }

            if (!grouped) {
              // Standard individual notification document creation via Template Engine
              const resolved = await resolveTemplate('COMMISSION_UNLOCKED', { amount: commissionAmount });
              
              const newNotifRef = await db.collection('users').doc(sellerUserId).collection('notifications').add({
                title: resolved.title,
                body: resolved.body,
                type: 'affiliate_conversion',
                deepLink: '/seller/finance',
                priority: 'medium',
                level: resolved.level,
                role: 'seller',
                status: 'DELIVERED',
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                expiresAt: expiresDate,
                metadata: {
                  orderId: orderId,
                  commissionAmount: commissionAmount,
                  conversionCount: 1,
                  totalCommission: commissionAmount
                }
              });

              if (fcmToken) {
                await admin.messaging().send({
                  token: fcmToken,
                  notification: {
                    title: resolved.title,
                    body: resolved.body
                  },
                  data: {
                    type: 'affiliate_conversion',
                    deepLink: '/seller/finance',
                    notificationId: newNotifRef.id,
                    priority: 'medium',
                    level: resolved.level,
                    role: 'seller'
                  }
                }).catch(e => console.warn('FCM dispatch recovery:', e.message));
              }
            }
          }
        }
      }
    } catch (err) {
      console.error('Error processing affiliate commission:', err);
    }

    return null;
  });


// ═══════════════════════════════════════════════════════════════
// 2. ON ORDER STATUS CHANGE — Process Commission Lifecycle
//    When order status changes:
//    - "shipped"    → Commission moves to "reconciling"
//    - "delivered"  → Commission moves to "completed", balance updated
//    - "cancelled"  → Commission is cancelled, pending reduced
//    - "refunded"   → Same as cancelled
// ═══════════════════════════════════════════════════════════════
exports.onOrderStatusForCommission = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const orderId = context.params.orderId;

    // Only trigger on status change
    if (before.status === after.status) return null;

    const referralSellerId = after.referralSellerId;
    if (!referralSellerId) return null; // Not an affiliate order

    const newStatus = after.status;

    try {
      // Find the commission transaction for this order
      const txQuery = await db.collection('seller_transactions')
        .where('orderId', '==', orderId)
        .where('sellerId', '==', referralSellerId)
        .where('type', '==', 'commission')
        .limit(1)
        .get();

      if (txQuery.empty) {
        console.log(`No commission transaction found for order ${orderId}`);
        return null;
      }

      const txDoc = txQuery.docs[0];
      const txData = txDoc.data();
      const commissionAmount = txData.amount;

      if (newStatus === 'shipped') {
        // ── Order shipped → Awaiting reconciliation ──
        await txDoc.ref.update({
          status: 'reconciling',
        });
        console.log(`Commission for order ${orderId} moved to reconciling`);

      } else if (newStatus === 'delivered') {
        // ── Order delivered → Commission completed ──
        // Move money from pending to available (atomic server-side)
        const sellerRef = db.collection('sellers').doc(referralSellerId);

        await db.runTransaction(async (transaction) => {
          const sellerSnap = await transaction.get(sellerRef);
          if (!sellerSnap.exists) throw new Error('Seller not found');

          const sellerData = sellerSnap.data();
          const currentPending = sellerData.pendingCommission || 0;
          const currentAvailable = sellerData.availableBalance || 0;
          const currentTotal = sellerData.totalEarnings || 0;

          transaction.update(sellerRef, {
            pendingCommission: Math.max(0, currentPending - commissionAmount),
            availableBalance: currentAvailable + commissionAmount,
            totalEarnings: currentTotal + commissionAmount,
          });

          transaction.update(txDoc.ref, {
            status: 'completed',
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        console.log(`Commission ${commissionAmount} completed for seller ${referralSellerId}`);

      } else if (newStatus === 'cancelled' || newStatus === 'refunded') {
        // ── Order cancelled/refunded → Cancel commission ──
        if (txData.status !== 'completed') {
          // Only reverse if not already paid out
          await db.collection('sellers').doc(referralSellerId).update({
            pendingCommission: admin.firestore.FieldValue.increment(-commissionAmount),
          });
        }

        await txDoc.ref.update({
          status: 'cancelled',
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`Commission cancelled for order ${orderId}`);
      }
    } catch (err) {
      console.error('Error processing commission status change:', err);
    }

    return null;
  });


// ═══════════════════════════════════════════════════════════════
// 3. PROCESS WITHDRAWAL REQUEST
//    Callable function — seller requests withdrawal.
//    Server validates balance, creates withdrawal record,
//    deducts from available balance.
// ═══════════════════════════════════════════════════════════════
exports.processWithdrawalRequest = functions.https.onCall(async (data, context) => {
  // Auth check
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const userId = context.auth.uid;
  const requestedAmount = data.amount;
  const MINIMUM_WITHDRAWAL = 500000; // 500,000 VND

  if (!requestedAmount || requestedAmount < MINIMUM_WITHDRAWAL) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Minimum withdrawal is ${MINIMUM_WITHDRAWAL.toLocaleString()} VND`
    );
  }

  // Find the seller record for this user
  const sellerQuery = await db.collection('sellers')
    .where('userId', '==', userId)
    .limit(1)
    .get();

  if (sellerQuery.empty) {
    throw new functions.https.HttpsError('not-found', 'Seller profile not found');
  }

  const sellerDoc = sellerQuery.docs[0];
  const sellerData = sellerDoc.data();
  const availableBalance = sellerData.availableBalance || 0;

  if (requestedAmount > availableBalance) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      `Insufficient balance. Available: ${availableBalance.toLocaleString()} VND`
    );
  }

  // Validate bank info exists
  if (!sellerData.bankAccount || !sellerData.bankName) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Please update your bank information before withdrawing'
    );
  }

  // Atomic: deduct balance and create withdrawal record
  await db.runTransaction(async (transaction) => {
    const freshSellerSnap = await transaction.get(sellerDoc.ref);
    const freshBalance = freshSellerSnap.data().availableBalance || 0;

    if (requestedAmount > freshBalance) {
      throw new functions.https.HttpsError('failed-precondition', 'Balance changed, please retry');
    }

    // Deduct from available balance
    transaction.update(sellerDoc.ref, {
      availableBalance: freshBalance - requestedAmount,
    });

    // Create withdrawal record
    const withdrawalRef = db.collection('withdrawals').doc();
    transaction.set(withdrawalRef, {
      sellerId: sellerDoc.id,
      userId: userId,
      amount: requestedAmount,
      status: 'pending', // Admin will process
      bankName: sellerData.bankName,
      bankAccount: sellerData.bankAccount,
      bankHolder: sellerData.bankHolder || '',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      processedAt: null,
    });

    // Create transaction record
    const txRef = db.collection('seller_transactions').doc();
    transaction.set(txRef, {
      sellerId: sellerDoc.id,
      type: 'withdrawal',
      amount: -requestedAmount, // Negative = outflow
      status: 'pending',
      description: `Withdrawal to ${sellerData.bankName} ****${(sellerData.bankAccount || '').slice(-4)}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      completedAt: null,
    });
  });

  return { success: true, message: 'Withdrawal request submitted successfully' };
});


// ═══════════════════════════════════════════════════════════════
// 4. VALIDATE PROMO CODE — Server-side validation at checkout
//    Callable function — checks code validity, usage limits,
//    expiration, and per-user limits.
// ═══════════════════════════════════════════════════════════════
exports.validatePromoCode = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const userId = context.auth.uid;
  const code = (data.code || '').toUpperCase().trim();

  if (!code) {
    throw new functions.https.HttpsError('invalid-argument', 'Promo code is required');
  }

  // Find the promo code
  const codeQuery = await db.collection('promo_codes')
    .where('code', '==', code)
    .limit(1)
    .get();

  if (codeQuery.empty) {
    throw new functions.https.HttpsError('not-found', 'Invalid promo code');
  }

  const codeDoc = codeQuery.docs[0];
  const codeData = codeDoc.data();

  // Check if active
  if (!codeData.isActive) {
    throw new functions.https.HttpsError('failed-precondition', 'This promo code has been deactivated');
  }

  // Check expiration
  if (codeData.expirationDate) {
    const expDate = codeData.expirationDate.toDate();
    if (new Date() > expDate) {
      throw new functions.https.HttpsError('failed-precondition', 'This promo code has expired');
    }
  }

  // Check total usage limit
  const currentUsage = codeData.currentUsageCount || 0;
  const maxTotal = codeData.maxTotalUsage || Infinity;
  if (currentUsage >= maxTotal) {
    throw new functions.https.HttpsError('failed-precondition', 'This promo code has reached its usage limit');
  }

  // Check per-user limit
  const usedBy = codeData.usedBy || {};
  const maxPerUser = codeData.maxUsagePerUser || 1;
  const userUsageCount = usedBy[userId] ? 1 : 0;
  if (userUsageCount >= maxPerUser) {
    throw new functions.https.HttpsError('failed-precondition', 'You have already used this promo code');
  }

  return {
    valid: true,
    discountPercent: codeData.discountPercent || 0,
    sellerId: codeData.sellerId || null,
    codeId: codeDoc.id,
  };
});


// ═══════════════════════════════════════════════════════════════
// 5. APPLY PROMO CODE — Called after successful order placement
//    Increments usage count and records the user
// ═══════════════════════════════════════════════════════════════
exports.applyPromoCode = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const userId = context.auth.uid;
  const codeId = data.codeId;

  if (!codeId) {
    throw new functions.https.HttpsError('invalid-argument', 'Code ID is required');
  }

  const codeRef = db.collection('promo_codes').doc(codeId);

  await codeRef.update({
    currentUsageCount: admin.firestore.FieldValue.increment(1),
    [`usedBy.${userId}`]: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});


// ═══════════════════════════════════════════════════════════════
// 6. RECORD REFERRAL CLICK — Track when someone clicks a referral link
//    HTTP function for lightweight tracking
// ═══════════════════════════════════════════════════════════════
exports.recordReferralClick = functions.https.onRequest(async (req, res) => {
  const sellerId = req.query.ref || req.body.ref;
  const productId = req.query.product || req.body.product;

  if (!sellerId) {
    res.status(400).json({ error: 'Missing ref parameter' });
    return;
  }

  try {
    // Log the click
    await db.collection('referral_clicks').add({
      sellerId: sellerId,
      productId: productId || null,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      converted: false,
      orderId: null,
      userAgent: req.headers['user-agent'] || '',
    });

    // Increment seller's click count (server-side)
    const sellerQuery = await db.collection('sellers')
      .where('referralCode', '==', sellerId)
      .limit(1)
      .get();

    if (!sellerQuery.empty) {
      await sellerQuery.docs[0].ref.update({
        totalClicks: admin.firestore.FieldValue.increment(1),
      });
    }

    res.status(200).json({ success: true });
  } catch (err) {
    console.error('Referral click error:', err);
    res.status(500).json({ error: 'Internal error' });
  }
});
