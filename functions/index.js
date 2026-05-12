const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// ── AI Scan ──
const { aiScan } = require('./aiScan');
exports.aiScan = aiScan;

// ── Order & Business Logic ──
const orderFunctions = require('./orderFunctions');
exports.onOrderCreated = orderFunctions.onOrderCreated;
exports.onOrderUpdated = orderFunctions.onOrderUpdated;
exports.onWalletTopUp = orderFunctions.onWalletTopUp;
exports.dailyAnalytics = orderFunctions.dailyAnalytics;
exports.autoCancelStaleOrders = orderFunctions.autoCancelStaleOrders;

// ── Admin & Analytics ──
const adminFunctions = require('./adminFunctions');
exports.setAdminRole = adminFunctions.setAdminRole;
exports.removeAdminRole = adminFunctions.removeAdminRole;
exports.getDashboardStats = adminFunctions.getDashboardStats;
