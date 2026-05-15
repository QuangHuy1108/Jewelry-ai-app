import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:jewelry_app/services/product_service.dart';
import '../widgets/product_card.dart';
import '../../../router/app_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/product_grid_constants.dart';

class PopularProductsScreen extends StatefulWidget {
  const PopularProductsScreen({super.key});

  @override
  State<PopularProductsScreen> createState() => _PopularProductsScreenState();
}

class _PopularProductsScreenState extends State<PopularProductsScreen> {

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
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: ProductService().getPopularProductsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingList();
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) return _buildEmptyState();
                  return _buildPopularList(docs);
                },
              ),
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
            onTap: () => Navigator.pop(context),
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
          const Expanded(
            child: Center(
              child: Text(
                'Popular Products',
                style: TextStyle(
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

  Widget _buildLoadingList() {
    return GridView.builder(
      padding: ProductGridConstants.gridPadding,
      gridDelegate: ProductGridConstants.gridDelegate,
      itemCount: 6,
      itemBuilder: (context, index) => const ShimmerPopularProductItem(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.layers_clear_outlined, size: 80, color: AppColors.hairline),
            const SizedBox(height: 16),
            const Text(
              'Empty List',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                letterSpacing: -0.374,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Try browsing our categories to find products.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.inkMuted48, letterSpacing: -0.224),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.bodyOnDark,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                elevation: 0,
              ),
              child: const Text('Browse Categories'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
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
          'category': data['category'] ?? '',
          'price': data['discountPrice'] ?? data['price'] ?? 0,
          'originalPrice': data['price'] ?? 0,
          'rating': data['rating'] ?? 0.0,
          'image': data['image'] ?? '',
        };
        return ProductCard(
          product: product,
          onTap: () {
            AppNavigation.toProductDetail(context, product: product);
          },
        );
      },
    );
  }
}

class ShimmerPopularProductItem extends StatelessWidget {
  const ShimmerPopularProductItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            ),
            // Content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: double.infinity, height: 12, color: Colors.white),
                    Container(width: 60, height: 14, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
