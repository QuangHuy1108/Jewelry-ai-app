import 'package:flutter/material.dart';
import '../widgets/home_header.dart';
import '../widgets/offer_banner.dart';
import '../widgets/category_list.dart';
import '../widgets/product_grid.dart';
import 'package:jewelry_app/features/home/widgets/bottom_nav.dart';
import '../widgets/popular_products_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: const SingleChildScrollView(
            child: Column(
              children: [
                HomeHeader(),
                OfferBanner(),
                CategoryList(),
                ProductGrid(),
                PopularProductsSection(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(),
    );
  }
}