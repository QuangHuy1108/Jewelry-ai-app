import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jewelry_app/services/product_service.dart';
import '../../product/widgets/product_card.dart';
import '../../product/screens/best_seller_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/product_grid_constants.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Best Sellers",
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
                    MaterialPageRoute(builder: (context) => const BestSellerScreen()),
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
        Padding(
          padding: ProductGridConstants.gridPadding,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ProductService().getBestSellersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.ink));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text("No items found", style: TextStyle(color: AppColors.inkMuted48))));
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                gridDelegate: ProductGridConstants.gridDelegate,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final p = {
                    "id": doc.id,
                    "name": data['name'] ?? '',
                    "price": "\$${data['price']}",
                    "image": data['image'] ?? '',
                  };
                  return ProductCard(product: p);
                },
              );
            }
          ),
        ),
      ],
    );
  }
}
