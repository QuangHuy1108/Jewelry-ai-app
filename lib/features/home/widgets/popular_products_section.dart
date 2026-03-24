import 'package:flutter/material.dart';
import '../../product/screens/popular_products_screen.dart';
import '../../product/widgets/product_card.dart';

class PopularProductsSection extends StatelessWidget {
  const PopularProductsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final products = [
      {
        "name": "Classic Gold Hoops",
        "category": "Earrings",
        "price": "\$250",
        "image": "https://i.postimg.cc/cHWq3842/h8.jpg",
      },
      {
        "name": "Silver Chain Bracelet",
        "category": "Bracelets",
        "price": "\$120",
        "image": "https://i.postimg.cc/zv06gtVy/h9.jpg",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Popular Product",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
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
                  "See All",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 250,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final Map<String, dynamic> p = {
                "id": "pop_${index}",
                "name": products[index]["name"],
                "price": products[index]["price"]?.replaceAll('\$', ''),
                "image": products[index]["image"],
              };
              
              return SizedBox(
                width: 160,
                child: ProductCard(product: p),
              );
            },
          ),
        ),
      ],
    );
  }
}
