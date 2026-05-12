import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../../product/widgets/product_card.dart';

class SimilarProductList extends StatelessWidget {
  const SimilarProductList({super.key});

  @override
  Widget build(BuildContext context) {
    // In a real app, you would fetch similar products based on the current product
    final currentProduct = context.watch<ProductProvider>().product;
    if (currentProduct.isEmpty) return const SizedBox.shrink();

    // Mock similar products
    final List<Map<String, dynamic>> similarProducts = [
      {
        "id": "sim_1",
        "name": "Luxury Gold Bracelet",
        "price": 1200.0,
        "image": "https://i.postimg.cc/4yh339Lk/h7.jpg",
      },
      {
        "id": "sim_2",
        "name": "Silver Choker",
        "price": 450.0,
        "image": "https://i.postimg.cc/cHWq3842/h8.jpg",
      },
      {
        "id": "sim_3",
        "name": "Diamond Ring",
        "price": 2500.0,
        "image": "https://i.postimg.cc/zv06gtVy/h9.jpg",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Similar Products',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: similarProducts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 160,
                child: ProductCard(product: similarProducts[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
