import 'package:flutter/material.dart';
import '../widgets/home_header.dart';
import '../widgets/offer_banner.dart';
import '../widgets/category_list.dart';
import '../widgets/product_grid.dart';
import 'package:jewelry_app/features/home/widgets/bottom_nav.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: const SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              HomeHeader(),
              OfferBanner(),
              CategoryList(),
              ProductGrid(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(),
    );
  }
}