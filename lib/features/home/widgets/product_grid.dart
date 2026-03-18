import 'package:flutter/material.dart';
import '../../product/widgets/product_card.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final products = [
      {
        "name": "Gold Ring",
        "price": "\$1200",
        "image": "https://i.imgur.com/1.jpg"
      },
      {
        "name": "Diamond Ring",
        "price": "\$2500",
        "image": "https://i.imgur.com/2.jpg"
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          final p = products[index];
          return ProductCard(
            name: p["name"]!,
            price: p["price"]!,
            image: p["image"]!,
          );
        },
      ),
    );
  }
}