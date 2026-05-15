import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jewelry_app/services/product_service.dart';
import '../widgets/product_card.dart';
import '../../../router/app_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/product_grid_constants.dart';

class BestSellerScreen extends StatefulWidget {
  const BestSellerScreen({super.key});

  @override
  State<BestSellerScreen> createState() => _BestSellerScreenState();
}

class _BestSellerScreenState extends State<BestSellerScreen> {

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
                stream: ProductService().getBestSellersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingGrid();
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) return _buildEmptyState();
                  return _buildProductGrid(docs);
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
                'Best Sellers',
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

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: ProductGridConstants.gridPadding,
      gridDelegate: ProductGridConstants.gridDelegate,
      itemCount: 6,
      itemBuilder: (context, index) => const ShimmerProductCard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 80, color: AppColors.hairline),
            const SizedBox(height: 16),
            const Text(
              'No best sellers found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                letterSpacing: -0.374,
              ),
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
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
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
        
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            final staggerDelay = index * 50; 
            return FutureBuilder(
              future: Future.delayed(Duration(milliseconds: staggerDelay)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
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
  }
}

class ShimmerProductCard extends StatelessWidget {
  const ShimmerProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasParchment,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
    );
  }
}
