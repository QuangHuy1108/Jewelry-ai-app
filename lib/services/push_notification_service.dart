import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../router/app_router.dart';
import 'package:provider/provider.dart';
import '../features/chat/providers/chat_provider.dart';
import '../features/notification/providers/notification_provider.dart';
import '../features/notification/models/notification_model.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Try not to rely on context or initialized plugins here as much as possible
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // 1. Request permissions
    await _requestPermission();

    // 2. Setup token
    await _setupToken();

    // 3. Setup background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Listen to foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Listen to background message opened (app in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNavigationData);

    // 6. Check if app was opened from terminated state
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      // Small delay just to make sure navigator context is mounted
      Future.delayed(const Duration(milliseconds: 1000), () {
        _handleNavigationData(initialMessage);
      });
    }
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _setupToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
      _fcm.onTokenRefresh.listen(_saveTokenToFirestore);
    } catch (e) {
      debugPrint("Failed to get FCM token: $e");
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Failed to save token to Firestore: $e");
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      // Trigger Provider synchronization manually if needed based on payload
      _syncProviderState(message);

      AppRouter.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('${message.notification?.title}: ${message.notification?.body}'),
          action: SnackBarAction(
            label: 'VIEW',
            onPressed: () => _handleNavigationData(message),
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _syncProviderState(RemoteMessage message) {
    final payload = message.data;
    final type = payload['type'] ?? 'unknown';
    final context = AppRouter.navigatorKey.currentContext;
    if (context == null) return;

    // Convert FCM to NotificationItem
    final priority = type == 'order' ? 'high' : (type == 'chat' ? 'medium' : 'low');
    final notifItem = NotificationItem(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      targetId: payload['targetId'] ?? payload['sellerId'] ?? '',
      isRead: false,
      createdAt: DateTime.now(),
      productId: payload['productId'],
      sellerId: payload['sellerId'],
      priority: priority,
      isPinned: priority == 'high',
    );

    // Save to global NotificationProvider / Firestore
    context.read<NotificationProvider>().addNotification(notifItem);

    if (type == 'chat') {
      context.read<ChatProvider>().refreshChats();
    } else if (type == 'order') {
      // Order Provider logic
    }
  }

  void _handleNavigationData(RemoteMessage message) {
    final payload = message.data;
    if (payload.isEmpty) return;

    final type = payload['type'];
    final currentState = AppRouter.navigatorKey.currentState;
    if (currentState == null) return;

    switch (type) {
      case 'chat':
        final sellerId = payload['targetId'] ?? payload['sellerId'];
        if (sellerId != null) {
          currentState.pushNamed(
            AppRouter.chatDetail,
            arguments: {
              'seller': {
                'id': sellerId, 
                'name': message.notification?.title ?? 'Seller', 
                'avatar': ''
              },
            },
          );
        }
        break;
      case 'order':
        // Navigate to Order detail or success
        currentState.pushNamed(AppRouter.myOrders);
        break;
      case 'promotion':
        // Not specifically mapped in routes to "vouchers", navigate to Home or profile
        currentState.pushNamed(AppRouter.home);
        break;
      default:
        break;
    }
  }
}
