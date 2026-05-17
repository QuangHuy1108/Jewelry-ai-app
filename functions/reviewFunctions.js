const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Task 1: Safe Average Rating (Transactions)
exports.onReviewUpdated = functions.firestore
  .document('products/{productId}/reviews/{reviewId}')
  .onWrite(async (change, context) => {
    const { productId } = context.params;
    const db = admin.firestore();
    const productRef = db.collection('products').doc(productId);

    await db.runTransaction(async (transaction) => {
      const productDoc = await transaction.get(productRef);
      if (!productDoc.exists) return;

      const reviewsSnapshot = await transaction.get(db.collection('products').doc(productId).collection('reviews'));

      let totalRating = 0;
      let reviewCount = 0;

      reviewsSnapshot.forEach((doc) => {
        const data = doc.data();
        if (data.rating) {
          totalRating += data.rating;
          reviewCount++;
        }
      });

      const averageRating = reviewCount === 0 ? 0 : totalRating / reviewCount;

      transaction.update(productRef, {
        reviewCount,
        averageRating
      });
    });
  });

// Task 2: Submit Review (Verified Purchase)
exports.submitReview = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
  }

  const { orderId, productId, sellerId, isSellerReview, rating, comment, hasMedia } = data;
  const uid = context.auth.uid;

  if (!orderId) {
    throw new functions.https.HttpsError('invalid-argument', 'orderId is required to submit a review.');
  }

  if (uid === sellerId) {
    throw new functions.https.HttpsError('permission-denied', 'You cannot review your own store.');
  }

  const db = admin.firestore();

  let newReviewId = '';

  await db.runTransaction(async (transaction) => {
    const orderRef = db.collection('orders').doc(orderId);
    const orderDoc = await transaction.get(orderRef);

    if (!orderDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Order not found.');
    }

    const orderData = orderDoc.data();

    // Verify order belongs to user
    if (orderData.userId !== uid) {
      throw new functions.https.HttpsError('permission-denied', 'Order does not belong to the current user.');
    }

    // Verify DELIVERED status
    if (orderData.status !== 'delivered' && orderData.status !== 'DELIVERED') {
      throw new functions.https.HttpsError('failed-precondition', 'Order must be delivered before you can review.');
    }

    // Duplicate Prevention
    if (isSellerReview && orderData.isSellerReviewed) {
      throw new functions.https.HttpsError('already-exists', 'You have already reviewed the seller for this order.');
    } else if (!isSellerReview && orderData.isProductReviewed) {
      throw new functions.https.HttpsError('already-exists', 'You have already reviewed the product for this order.');
    }

    // Verify sellerId or productId
    if (isSellerReview) {
      if (orderData.sellerId !== sellerId && orderData.affiliateId !== sellerId) {
        throw new functions.https.HttpsError('invalid-argument', 'This order is not associated with the specified seller or consultant.');
      }
    } else {
      const items = orderData.items || [];
      if (!items.some(item => item.id === productId || item.productId === productId)) {
        throw new functions.https.HttpsError('invalid-argument', 'This order does not contain the specified product.');
      }
    }

    // Fetch User details for review display
    const userRef = db.collection('users').doc(uid);
    const userDoc = await transaction.get(userRef);
    const userData = userDoc.exists ? userDoc.data() : {};

    let finalRating = rating;
    if (isSellerReview) {
      const { honesty, attitude, consultingSkill, afterSalesService, productKnowledge } = data;
      if (honesty == null || attitude == null || consultingSkill == null || afterSalesService == null || productKnowledge == null) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing multi-criteria ratings for seller review.');
      }
      finalRating = (honesty + attitude + consultingSkill + afterSalesService + productKnowledge) / 5;
    }

    // Create review
    const reviewRef = db.collection(isSellerReview ? `sellers/${sellerId}/reviews` : `products/${productId}/reviews`).doc();
    newReviewId = reviewRef.id;

    transaction.set(reviewRef, {
      userId: uid,
      name: userData.name || 'Anonymous User',
      avatar: userData.avatar || '',
      isVerified: true,
      rating: finalRating,
      comment,
      hasMedia: hasMedia || false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      ...(isSellerReview && {
        ratings: {
          'Honesty': data.honesty,
          'Attitude': data.attitude,
          'Consulting Skill': data.consultingSkill,
          'After-sales Service': data.afterSalesService,
          'Product Knowledge': data.productKnowledge
        }
      })
    });

    transaction.update(orderRef, {
      ...(isSellerReview ? { isSellerReviewed: true } : { isProductReviewed: true })
    });

    const userOrderRef = db.collection('users').doc(uid).collection('orders').doc(orderId);
    transaction.update(userOrderRef, {
      ...(isSellerReview ? { isSellerReviewed: true } : { isProductReviewed: true })
    });
  });

  return { success: true, reviewId: newReviewId };
});

// Task 1b: Seller Rating Aggregation Trigger
exports.onSellerReviewWritten = functions.firestore
  .document('sellers/{sellerId}/reviews/{reviewId}')
  .onWrite(async (change, context) => {
    const { sellerId } = context.params;
    const db = admin.firestore();
    const sellerRef = db.collection('sellers').doc(sellerId);

    await db.runTransaction(async (transaction) => {
      const sellerDoc = await transaction.get(sellerRef);
      if (!sellerDoc.exists) return;

      const reviewsSnapshot = await transaction.get(db.collection('sellers').doc(sellerId).collection('reviews'));

      let totalRating = 0;
      let reviewCount = 0;

      const sumRatings = {
        'Honesty': 0,
        'Attitude': 0,
        'Consulting Skill': 0,
        'After-sales Service': 0,
        'Product Knowledge': 0
      };
      let criteriaCount = 0;

      reviewsSnapshot.forEach((doc) => {
        const data = doc.data();
        if (data.rating) {
          totalRating += data.rating;
          reviewCount++;
        }
        if (data.ratings) {
          sumRatings['Honesty'] += data.ratings['Honesty'] || 0;
          sumRatings['Attitude'] += data.ratings['Attitude'] || 0;
          sumRatings['Consulting Skill'] += data.ratings['Consulting Skill'] || 0;
          sumRatings['After-sales Service'] += data.ratings['After-sales Service'] || 0;
          sumRatings['Product Knowledge'] += data.ratings['Product Knowledge'] || 0;
          criteriaCount++;
        }
      });

      const averageRating = reviewCount === 0 ? 0 : totalRating / reviewCount;

      const finalRatings = {};
      if (criteriaCount > 0) {
        for (const key in sumRatings) {
          finalRatings[key] = sumRatings[key] / criteriaCount;
        }
      }

      const updateData = {
        reviewCount,
        averageRating,
        rating: averageRating
      };

      if (criteriaCount > 0) {
        updateData.ratings = finalRatings;
      }

      transaction.update(sellerRef, updateData);
    });
  });
