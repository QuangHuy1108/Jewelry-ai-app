import 'package:flutter/material.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/auth/screens/sign_up_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/auth/screens/verify_code_screen.dart'; // THÊM DÒNG NÀY
import '../features/home/screens/home_screen.dart';
import 'package:jewelry_app/features/product/screens/product_detail_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/checkout/screens/checkout_screen.dart';
import '../features/chat_ai/screens/chat_screen.dart';
import '../features/auth/screens/new_password_screen.dart';


class AppRouter {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const signup = '/signup';
  static const signin = '/signin';
  static const verifyCode = '/verify-code'; // THÊM DÒNG NÀY
  static const home = '/';
  static const product = '/product';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const chat = '/chat';
  static const String newPassword = '/new-password';

  static Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    onboarding: (_) => const OnboardingScreen(),
    signup: (_) => const SignUpScreen(),
    signin: (_) => const SignInScreen(),
    verifyCode: (_) => const VerifyCodeScreen(), // THÊM DÒNG NÀY
    home: (_) => const HomeScreen(),
    product: (_) => const ProductDetailScreen(),
    cart: (_) => const CartScreen(),
    checkout: (_) => const CheckoutScreen(),
    chat: (_) => const ChatScreen(),
    newPassword: (_) => const NewPasswordScreen(),
  };
}