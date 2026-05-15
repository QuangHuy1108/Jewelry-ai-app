import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jewelry_app/services/product_service.dart';
import '../../product/screens/popular_products_screen.dart';
import '../../product/widgets/product_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/product_grid_constants.dart';

class PopularProductsSection extends StatelessWidget {
  const PopularProductsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Trending Items",
                style: TextStyle(
                  fontSize: 21, // SF Pro tagline size
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  letterSpacing: 0.231,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PopularProductsScreen()),
                  );
                },
                child: const Text(
                  "Browse All",
                  style: TextStyle(
                    fontSize: 14, 
                    color: AppColors.primary, 
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.224,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: ProductGridConstants.horizontalListHeight,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ProductService().getPopularProductsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.ink));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text("No trending items currently", style: TextStyle(color: AppColors.inkMuted48)));
              }
              return ListView.separated(
                padding: ProductGridConstants.horizontalListPadding,
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(width: ProductGridConstants.horizontalCardSpacing),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final Map<String, dynamic> p = {
                    "id": doc.id,
                    "name": data['name'] ?? '',
                    "price": "${data['price']}",
                    "image": data['image'] ?? '',
                  };
                  
                  return SizedBox(
                    width: ProductGridConstants.horizontalCardWidth,
                    child: ProductCard(product: p),
                  );
                },
              );
            }
          ),
        ),
      ],
    );
  }
}
