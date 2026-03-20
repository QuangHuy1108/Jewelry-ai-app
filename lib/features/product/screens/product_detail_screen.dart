import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Product Detail")),
      body: Column(
        children: [
          Image.network("https://i.postimg.cc/4yh339Lk/h7.jpg"),
          const SizedBox(height: 10),
          const Text("Diamond Ring", style: TextStyle(fontSize: 20)),
          const Text("\$299", style: TextStyle(color: Colors.orange)),
          ElevatedButton(onPressed: () {}, child: const Text("Add to Cart")),
        ],
      ),
    );
  }
}
