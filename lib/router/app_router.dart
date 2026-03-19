import 'package:flutter/material.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/auth/screens/sign_up_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/auth/screens/verify_code_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/new_password_screen.dart';
import '../features/home/screens/home_screen.dart';
import 'package:jewelry_app/features/product/screens/product_detail_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/checkout/screens/checkout_screen.dart';
import '../features/chat_ai/screens/chat_screen.dart';
import '../features/auth/screens/complete_profile_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/onboarding/screens/enable_notification.dart';
import '../features/onboarding/screens/location_permission_screen.dart';
import '../features/onboarding/screens/enter_location_screen.dart';




class AppRouter {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const signup = '/signup';
  static const signin = '/signin';
  static const forgotPassword = '/forgot-password';
  static const verifyCode = '/verify-code';
  static const home = '/';
  static const product = '/product';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const chat = '/chat';
  static const profile = '/profile';
  static const welcome = '/welcome';
  static const newPassword = '/new-password';
  static const enableNotification = '/enable-notification';
  static const locationPermission = '/location-permission';
  static const enterLocation = '/new-password';



  static Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    onboarding: (_) => const OnboardingScreen(),
    signup: (_) => const SignUpScreen(),
    signin: (_) => const SignInScreen(),
    forgotPassword: (_) => const ForgotPasswordScreen(),
    verifyCode: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return VerifyCodeScreen(
        email: args?['email'] ?? "your email",
        isFromForgotPassword: args?['isFromForgotPassword'] ?? false,
      );
    },
    home: (_) => const HomeScreen(),
    product: (_) => const ProductDetailScreen(),
    cart: (_) => const CartScreen(),
    checkout: (_) => const CheckoutScreen(),
    chat: (_) => const ChatScreen(),
    profile: (_) => const CompleteProfileScreen(),
    welcome: (_) => const WelcomeScreen(),
    newPassword: (_) => const NewPasswordScreen(),
    enableNotification: (_) => const EnableNotificationScreen(),
    locationPermission: (_) => const LocationPermissionScreen(),
    enterLocation: (_) => const EnterLocationScreen(),
  };
}
