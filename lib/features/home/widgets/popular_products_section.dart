import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jewelry_app/services/product_service.dart';
import '../../product/screens/popular_products_screen.dart';
import '../../product/widgets/product_card.dart';

class PopularProductsSection extends StatelessWidget {
  const PopularProductsSection({super.key});

  @override
  Widget build(BuildContext context) {

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
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ProductService().getPopularProductsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF333333)));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text("No popular products found", style: TextStyle(color: Color(0xFF999999))));
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final Map<String, dynamic> p = {
                    "id": doc.id,
                    "name": data['name'] ?? '',
                    "price": "${data['price']}", // ProductCard typically prefixes $ for popular
                    "image": data['image'] ?? '',
                  };
                  
                  return SizedBox(
                    width: 160,
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
