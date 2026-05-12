/**
 * One-time script to set up the first admin user.
 * 
 * Usage:
 *   node functions/setupAdmin.js your-email@gmail.com
 * 
 * This script:
 *   1. Finds the user by email in Firebase Auth
 *   2. Sets the { admin: true } custom claim
 *   3. Creates the admins/{uid} document in Firestore
 */

const admin = require('firebase-admin');

// Initialize with default credentials (uses GOOGLE_APPLICATION_CREDENTIALS or gcloud auth)
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function setupAdmin(email) {
  if (!email) {
    console.error('❌ Usage: node setupAdmin.js <email>');
    process.exit(1);
  }

  try {
    // 1. Find user by email
    const user = await admin.auth().getUserByEmail(email);
    console.log(`✅ Found user: ${user.displayName || user.email} (${user.uid})`);

    // 2. Set custom claim
    await admin.auth().setCustomUserClaims(user.uid, { admin: true });
    console.log('✅ Admin custom claim set');

    // 3. Create admin document
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
      grantedBy: 'system_bootstrap',
    });
    console.log('✅ Admin document created in Firestore');

    console.log(`\n🎉 ${email} is now an admin!`);
    console.log('   The user must sign out and sign back in for the claim to take effect.');
    
    process.exit(0);
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      console.error(`❌ No user found with email: ${email}`);
      console.error('   Make sure the user has signed in to the app at least once.');
    } else {
      console.error('❌ Error:', error.message);
    }
    process.exit(1);
  }
}

const email = process.argv[2];
setupAdmin(email);
