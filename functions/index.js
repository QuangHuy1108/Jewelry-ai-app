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

// ── Payment Webhooks ──
const paymentFunctions = require('./paymentFunctions');
exports.paymentWebhook = paymentFunctions.paymentWebhook;

// ── Commission & Seller Financial Engine ──
const commissionFunctions = require('./commissionFunctions');
exports.onAffiliateOrderCreated = commissionFunctions.onAffiliateOrderCreated;
exports.onOrderStatusForCommission = commissionFunctions.onOrderStatusForCommission;
exports.processWithdrawalRequest = commissionFunctions.processWithdrawalRequest;
exports.validatePromoCode = commissionFunctions.validatePromoCode;
exports.applyPromoCode = commissionFunctions.applyPromoCode;
exports.recordReferralClick = commissionFunctions.recordReferralClick;

// ── AI Predictive Engagement Engine (Phase 3) ──
const aiPredictiveEngine = require('./aiPredictiveEngine');
exports.calculateOptimalEngagementHours = aiPredictiveEngine.calculateOptimalEngagementHours;
exports.scheduledPredictiveEngine = aiPredictiveEngine.scheduledPredictiveEngine;
exports.smartPushHelper = aiPredictiveEngine.smartPushHelper;

// ── Chat Notifications ──
const chatNotifications = require('./chatNotifications');
exports.onChatMessageCreated = chatNotifications.onChatMessageCreated;

// ── Reviews & Ratings ──
const reviewFunctions = require('./reviewFunctions');
exports.onReviewUpdated = reviewFunctions.onReviewUpdated;
exports.submitReview = reviewFunctions.submitReview;
exports.onSellerReviewWritten = reviewFunctions.onSellerReviewWritten;
