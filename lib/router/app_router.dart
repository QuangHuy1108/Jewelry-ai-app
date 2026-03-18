import 'package:flutter/material.dart';
import '../features/home/screens/home_screen.dart';
import 'package:jewelry_app/features/product/screens/product_detail_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/checkout/screens/checkout_screen.dart';
import '../features/chat_ai/screens/chat_screen.dart';

class AppRouter {
  static const home = '/';
  static const product = '/product';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const chat = '/chat';

  static Map<String, WidgetBuilder> routes = {
    home: (_) => const HomeScreen(),
    product: (_) => const ProductDetailScreen(),
    cart: (_) => const CartScreen(),
    checkout: (_) => const CheckoutScreen(),
    chat: (_) => const ChatScreen(),
  };
}