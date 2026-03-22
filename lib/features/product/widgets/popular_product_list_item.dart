import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'product_card.dart';

class PopularProductListItem extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const PopularProductListItem({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ProductCard(
      product: product,
      onTap: onTap,
    );
  }
}

class ShimmerPopularProductItem extends StatelessWidget {
  const ShimmerPopularProductItem({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.75,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
