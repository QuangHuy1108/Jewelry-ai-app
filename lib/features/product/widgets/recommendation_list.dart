import 'package:flutter/material.dart';
import 'product_card.dart';
import '../../product/screens/product_detail_screen.dart';

class RecommendationList extends StatelessWidget {
  final String currentCategory;

  const RecommendationList({super.key, required this.currentCategory});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> recommended = [];
    final categoryLow = currentCategory.toLowerCase();
    
    if (categoryLow.contains('ring')) {
      recommended = [
        {"id": "c1", "name": "Gold Necklace", "price": 1200.0, "image": "https://i.postimg.cc/pL94mBxp/h10.jpg", "category": "Necklaces", "rating": 4.9},
        {"id": "c2", "name": "Silver Bracelet", "price": 450.0, "image": "https://i.postimg.cc/cHWq3842/h8.jpg", "category": "Bracelets", "rating": 4.5},
        {"id": "c3", "name": "Diamond Studs", "price": 850.0, "image": "https://i.postimg.cc/zv06gtVy/h9.jpg", "category": "Earrings", "rating": 4.8},
      ];
    } else {
      recommended = [
        {"id": "c4", "name": "Diamond Ring", "price": 2500.0, "image": "https://i.postimg.cc/4yh339Lk/h7.jpg", "category": "Rings", "rating": 4.9},
        {"id": "c2", "name": "Silver Bracelet", "price": 450.0, "image": "https://i.postimg.cc/cHWq3842/h8.jpg", "category": "Bracelets", "rating": 4.5},
      ];
    }

    if (recommended.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Complete Your Set',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommended.length,
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16),
                child: ProductCard(
                  product: recommended[index],
                  onTap: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProductDetailScreen()));
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
