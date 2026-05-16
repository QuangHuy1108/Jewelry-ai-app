import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../router/app_router.dart';
import 'package:provider/provider.dart';
import '../features/chat/providers/chat_provider.dart';
import '../features/notification/providers/notification_provider.dart';
import '../features/notification/models/notification_model.dart';
import '../features/notification/widgets/liquid_notification_overlay.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled by the OS notification tray automatically.
  // Do NOT initialize FlutterLocalNotificationsPlugin here — it's unreliable
  // in isolate context. The OS will display the notification payload directly.
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Flutter Local Notifications (for foreground OS-level heads-up) ──
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Android notification channel matching AndroidManifest.xml meta-data
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Important Notifications',
    description: 'Notifications for orders, messages, and important updates',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  Future<void> initialize() async {
    // 1. Request permissions
    await _requestPermission();

    // 2. Initialize flutter_local_notifications
    await _initLocalNotifications();

    // 3. Setup token sync with auth state
    _setupTokenSync();

    // 4. Setup background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Disable default foreground notification presentation from FCM
    //    (we handle it ourselves via flutter_local_notifications + overlay)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );

    // 6. Listen to foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 7. Listen to background message opened (app in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNavigationData);

    // 8. Check if app was opened from terminated state
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

  Future<void> _initLocalNotifications() async {
    // Android initialization
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    // Create the Android notification channel at runtime
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_channel);
    }
  }

  /// Called when the user taps an OS-level notification (from local notifications plugin)
  void _onLocalNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    // Parse the payload to navigate
    // Payload format: "type|targetId|deepLink"
    final parts = payload.split('|');
    if (parts.length < 2) return;

    final type = parts[0];
    final targetId = parts[1];
    final deepLink = parts.length > 2 ? parts[2] : null;
    final senderName = parts.length > 3 ? parts[3] : 'Seller';
    final chatId = parts.length > 4 ? parts[4] : null;

    final currentState = AppRouter.navigatorKey.currentState;
    if (currentState == null) return;

    if (deepLink != null && deepLink.isNotEmpty) {
      if (deepLink.startsWith('/orders/')) {
        currentState.pushNamed(AppRouter.myOrders);
        return;
      } else if (deepLink.startsWith('/chat/')) {
        final sellerId = deepLink.split('/').last;
        currentState.pushNamed(
          AppRouter.chatDetail,
          arguments: {
            'sellerId': sellerId,
            'sellerName': senderName,
            'chatId': chatId,
          },
        );
        return;
      }
    }

    switch (type) {
      case 'chat':
        if (targetId.isNotEmpty) {
          currentState.pushNamed(
            AppRouter.chatDetail,
            arguments: {
              'sellerId': targetId,
              'sellerName': senderName,
              'chatId': chatId,
            },
          );
        }
        break;
      case 'order':
      case 'order_created':
      case 'order_status':
        currentState.pushNamed(AppRouter.myOrders);
        break;
      case 'promotion':
        currentState.pushNamed(AppRouter.home);
        break;
    }
  }

  void _setupTokenSync() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        try {
          String? token = await _fcm.getToken();
          debugPrint("═══ FCM TOKEN ═══\n$token\n═════════════════");
          if (token != null) {
            await _saveTokenToFirestore(token);
          }
        } catch (e) {
          debugPrint("Failed to get FCM token: $e");
        }
      }
    });

    _fcm.onTokenRefresh.listen((token) {
      if (_auth.currentUser != null) {
        _saveTokenToFirestore(token);
      }
    });
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
      final payload = message.data;
      final type = payload['type'] ?? 'unknown';
      final targetId = payload['targetId'] ?? payload['sellerId'] ?? '';

      final context = AppRouter.navigatorKey.currentContext;
      if (context != null && type == 'chat' && targetId.isNotEmpty) {
        final chatProvider = context.read<ChatProvider>();
        if (chatProvider.isChatActiveWith(targetId)) {
          // Suppress heads-up notification display since user is already chatting in this active thread
          _syncProviderState(message);
          return;
        }
      }

      // Trigger Provider synchronization manually if needed based on payload
      _syncProviderState(message);

      // Show OS-level heads-up notification via flutter_local_notifications
      _showLocalNotification(message);

      // Also show in-app Liquid Glass overlay
      if (context != null) {
        LiquidNotificationOverlay.show(
          context: context,
          title: message.notification?.title ?? 'Notification',
          body: message.notification?.body ?? '',
          imageUrl: payload['image'],
          onTap: () => _handleNavigationData(message),
        );
      }
    }
  }

  /// Display an OS-level heads-up notification using flutter_local_notifications.
  /// This ensures the notification appears in the system tray and produces sound/vibration
  /// even when the app is in the foreground.
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final payload = message.data;
    final type = payload['type'] ?? 'unknown';
    final targetId = payload['targetId'] ?? payload['sellerId'] ?? '';
    final deepLink = payload['deepLink'] ?? '';
    final senderName = payload['senderName'] ?? notification.title ?? 'Seller';
    final chatId = payload['chatId'] ?? '';
    // Payload string for navigation on tap: "type|targetId|deepLink|senderName|chatId"
    final payloadString = '$type|$targetId|$deepLink|$senderName|$chatId';

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Important Notifications',
      channelDescription:
          'Notifications for orders, messages, and important updates',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // Use hashCode of messageId for unique int ID
    final id =
        message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

    await _localNotifications.show(
      id: id,
      title: notification.title ?? 'Notification',
      body: notification.body ?? '',
      notificationDetails: notificationDetails,
      payload: payloadString,
    );
  }

  void _syncProviderState(RemoteMessage message) {
    final payload = message.data;
    final type = payload['type'] ?? 'unknown';
    final context = AppRouter.navigatorKey.currentContext;
    if (context == null) return;

    // Convert FCM to NotificationItem
    final priority =
        payload['priority'] ??
        (type == 'order' ? 'high' : (type == 'chat' ? 'medium' : 'low'));
    final deepLink = payload['deepLink'];
    final image =
        payload['image'] ??
        (message.notification?.android?.imageUrl ??
            message.notification?.apple?.imageUrl);
    final status = payload['status'] ?? 'DELIVERED';
    final role = payload['role'];
    final level = payload['level'];

    DateTime? expiresAt;
    if (payload['expiresAt'] != null) {
      expiresAt = DateTime.tryParse(payload['expiresAt'].toString());
    } else if (type == 'promotion') {
      // Automatic default TTL for promotions MVP
      expiresAt = DateTime.now().add(const Duration(hours: 48));
    }

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
      deepLink: deepLink,
      image: image,
      status: status,
      expiresAt: expiresAt,
      role: role,
      level: level,
      metadata: Map<String, dynamic>.from(payload),
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
    final context = AppRouter.navigatorKey.currentContext;

    // Log telemetry: OPENED
    if (context != null && message.messageId != null) {
      context.read<NotificationProvider>().logNotificationEvent(
        message.messageId!,
        'OPENED',
      );
    }

    if (payload.isEmpty) return;

    final currentState = AppRouter.navigatorKey.currentState;
    if (currentState == null) return;

    // Enterprise Deep Linking parsing MVP
    final deepLink = payload['deepLink'] as String?;
    if (deepLink != null && deepLink.isNotEmpty) {
      // Log telemetry: ACTION_CLICKED
      if (context != null && message.messageId != null) {
        context.read<NotificationProvider>().logNotificationEvent(
          message.messageId!,
          'ACTION_CLICKED',
        );
      }

      // If a specific deep link path is provided, route directly to it if mapped
      if (deepLink.startsWith('/orders/')) {
        currentState.pushNamed(AppRouter.myOrders);
        return;
      } else if (deepLink.startsWith('/chat/')) {
        final parts = deepLink.split('/');
        final sellerId = parts.last;
        currentState.pushNamed(
          AppRouter.chatDetail,
          arguments: {
            'seller': {
              'id': sellerId,
              'name': message.notification?.title ?? 'Seller',
              'avatar': '',
            },
          },
        );
        return;
      }
    }

    final type = payload['type'];
    final senderName =
        payload['senderName'] ?? message.notification?.title ?? 'Seller';
    final chatId = payload['chatId'] as String?;

    switch (type) {
      case 'chat':
        final sellerId = payload['targetId'] ?? payload['sellerId'];
        if (sellerId != null) {
          currentState.pushNamed(
            AppRouter.chatDetail,
            arguments: {
              'chatId': chatId,
              'seller': {'id': sellerId, 'name': senderName, 'avatar': ''},
            },
          );
        }
        break;
      case 'order':
      case 'order_created':
      case 'order_status':
        currentState.pushNamed(AppRouter.myOrders);
        break;
      case 'promotion':
        currentState.pushNamed(AppRouter.home);
        break;
      default:
        break;
    }
  }
}
