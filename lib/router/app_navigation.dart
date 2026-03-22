import 'package:flutter/material.dart';
import '../../features/product/screens/product_detail_screen.dart';

/// Centralized navigation helpers for consistent behavior across the app.
class AppNavigation {
  /// Navigate to Product Detail screen from any screen.
  /// Always uses [Navigator.push] to preserve the back stack.
  static void toProductDetail(BuildContext context, {Map<String, dynamic>? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProductDetailScreen(),
        settings: const RouteSettings(name: '/product'),
      ),
    );
  }

  /// Navigate to Home and clear the entire auth/splash stack.
  /// Use this ONLY after login or onboarding completion.
  static void toHomeAndClearStack(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }
}
