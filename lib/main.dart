import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'package:provider/provider.dart';
import 'features/cart/providers/cart_provider.dart';
import 'features/wishlist/providers/wishlist_provider.dart';
import 'features/chat/providers/chat_provider.dart';
import 'features/product/providers/product_provider.dart';
import 'features/ai_scan/providers/ai_scan_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize GoogleSignIn (required in version 7.0+)
  await GoogleSignIn.instance.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => AiScanProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: AppRouter.splash,
        routes: AppRouter.routes,
      ),
    );
  }
}
