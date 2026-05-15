import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jewelry_app/services/product_service.dart';
import '../../product/widgets/product_card.dart';
import '../../../router/app_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/product_grid_constants.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryName;
  const CategoryScreen({super.key, required this.categoryName});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
          Expanded(
              child: _buildProductGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(
          bottom: BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.hairline),
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.ink, size: 20),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                widget.categoryName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  letterSpacing: -0.374,
                ),
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ProductService().getProductsByCategoryStream(widget.categoryName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.ink));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No products in this category', style: TextStyle(color: AppColors.inkMuted48, letterSpacing: -0.224)));
        }

        return GridView.builder(
          padding: ProductGridConstants.gridPaddingWithBottom(context),
          gridDelegate: ProductGridConstants.gridDelegate,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final product = {
              'id': doc.id,
              'name': data['name'] ?? '',
              'category': data['category'] ?? widget.categoryName,
              'price': data['discountPrice'] ?? data['price'] ?? 0,
              'originalPrice': data['price'] ?? 0,
              'rating': data['rating'] ?? 0.0,
              'image': data['image'] ?? '',
            };
            
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: ProductCard(
                product: product,
                onTap: () {
                  AppNavigation.toProductDetail(context, product: product);
                },
              ),
            );
          },
        );
      },
    );
  }
}
