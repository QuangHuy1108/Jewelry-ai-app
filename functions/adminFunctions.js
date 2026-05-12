const functions = require('firebase-functions');
const admin = require('firebase-admin');

const db = admin.firestore();

// ═══════════════════════════════════════════════════════════════
// SET ADMIN ROLE — Callable function
// Call this to grant admin privileges to a user by email.
// Usage: firebase functions:shell > setAdminRole({email: "admin@example.com"})
// ═══════════════════════════════════════════════════════════════
exports.setAdminRole = functions.https.onCall(async (data, context) => {
  // Only existing admins can create new admins
  if (context.auth && context.auth.token.admin !== true) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can assign admin roles.'
    );
  }

  const email = data.email;
  if (!email) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Email is required.'
    );
  }

  try {
    const user = await admin.auth().getUserByEmail(email);

    // Set custom claim
    await admin.auth().setCustomUserClaims(user.uid, { admin: true });

    // Save to admins collection
    await db.collection('admins').doc(user.uid).set({
      email: user.email,
      displayName: user.displayName || '',
      role: 'admin',
      permissions: [
        'manage_products',
        'manage_orders',
        'manage_users',
        'manage_coupons',
        'view_analytics',
      ],
      grantedAt: admin.firestore.FieldValue.serverTimestamp(),
      grantedBy: context.auth ? context.auth.uid : 'system',
    });

    return { result: `Admin role granted to ${email}` };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});


// ═══════════════════════════════════════════════════════════════
// REMOVE ADMIN ROLE
// ═══════════════════════════════════════════════════════════════
exports.removeAdminRole = functions.https.onCall(async (data, context) => {
  if (context.auth && context.auth.token.admin !== true) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can remove admin roles.'
    );
  }

  const email = data.email;
  if (!email) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Email is required.'
    );
  }

  try {
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().setCustomUserClaims(user.uid, { admin: false });
    await db.collection('admins').doc(user.uid).delete();
    return { result: `Admin role removed from ${email}` };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});


// ═══════════════════════════════════════════════════════════════
// GET DASHBOARD STATS — Callable function for admin dashboard
// Returns real-time counts of users, products, orders, revenue
// ═══════════════════════════════════════════════════════════════
exports.getDashboardStats = functions.https.onCall(async (data, context) => {
  if (!context.auth || context.auth.token.admin !== true) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Admin access required.'
    );
  }

  const [usersSnap, productsSnap, ordersSnap] = await Promise.all([
    db.collection('users').get(),
    db.collection('products').get(),
    db.collection('orders').get(),
  ]);

  let totalRevenue = 0;
  let pendingOrders = 0;
  let completedOrders = 0;
  const statusCounts = {};

  ordersSnap.forEach((doc) => {
    const data = doc.data();
    totalRevenue += data.totalAmount || 0;
    const status = data.status || 'pending';
    statusCounts[status] = (statusCounts[status] || 0) + 1;
    if (status === 'pending') pendingOrders++;
    if (status === 'delivered') completedOrders++;
  });

  return {
    totalUsers: usersSnap.size,
    totalProducts: productsSnap.size,
    totalOrders: ordersSnap.size,
    totalRevenue,
    pendingOrders,
    completedOrders,
    ordersByStatus: statusCounts,
  };
});
