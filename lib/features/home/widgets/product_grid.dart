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
        "image": "https://i.postimg.cc/cHWq3842/h8.jpg",
      },
      {
        "name": "Diamond Ring",
        "price": "\$2500",
        "image": "https://i.postimg.cc/4yh339Lk/h7.jpg",
      },
      {
        "name": "Silver Bracelet",
        "price": "\$450",
        "image": "https://i.postimg.cc/zv06gtVy/h9.jpg",
      },
      {
        "name": "Pearl Necklace",
        "price": "\$890",
        "image": "https://i.postimg.cc/pL94mBxp/h10.jpg",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Best Seller Product",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  "See All",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
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
        ),
      ],
    );
  }
}
