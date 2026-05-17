import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'package:provider/provider.dart';
import 'features/cart/providers/cart_provider.dart';
import 'features/wishlist/providers/wishlist_provider.dart';
import 'features/chat/providers/chat_provider.dart';
import 'features/notification/providers/notification_provider.dart';
import 'features/product/providers/product_provider.dart';
import 'features/ai_scan/providers/ai_scan_provider.dart';
import 'features/checkout/providers/payment_provider.dart';
import 'services/push_notification_service.dart';
import 'services/connectivity_service.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize GoogleSignIn (required in version 7.0+)
  await GoogleSignIn.instance.initialize();

  try {
    await PushNotificationService().initialize();
  } catch (e) {
    debugPrint("Failed to initialize push notifications: $e");
  }

  // Start network monitoring
  ConnectivityService().startMonitoring();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Set online when app starts
    if (FirebaseAuth.instance.currentUser != null) {
      _userService.setOnlineStatus(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (FirebaseAuth.instance.currentUser != null) {
      switch (state) {
        case AppLifecycleState.resumed:
          _userService.setOnlineStatus(true);
          break;
        case AppLifecycleState.paused:
        case AppLifecycleState.detached:
        case AppLifecycleState.inactive:
          _userService.setOnlineStatus(false);
          break;
        default:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => AiScanProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: ConnectivityWrapper(
        child: MaterialApp(
          navigatorKey: AppRouter.navigatorKey,
          scaffoldMessengerKey: AppRouter.scaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          initialRoute: AppRouter.splash,
          routes: AppRouter.routes,
        ),
      ),
    );
  }
}
