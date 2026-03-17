import 'package:flutter/material.dart';
import '../../shared/mock/mock_products.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/cart_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product; // Nhận dữ liệu sản phẩm

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar trong suốt để lộ ảnh nền
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ảnh lớn phía trên
            Hero(
              tag: product.id, // Hiệu ứng chuyển cảnh mượt mà
              child: Image.network(
                product.imageUrl,
                height: 400,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Tên sản phẩm
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // 3. Giá tiền
                  Text(
                    '\$${product.price}',
                    style: const TextStyle(
                        fontSize: 22,
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.w600
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 4. Mô tả
                  const Text(
                    "MÔ TẢ SẢN PHẨM",
                    style: TextStyle(fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    product.description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 5. Nút Mua ngay ở dưới cùng
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: () {
            // Gọi lệnh thêm vào giỏ từ Provider
            context.read<CartProvider>().addToCart(product);

            // Hiện thông báo nhỏ dưới màn hình cho khách hàng yên tâm
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Đã thêm ${product.name} vào giỏ!"),
                duration: const Duration(seconds: 2),
                backgroundColor: const Color(0xFFD4AF37), // Màu vàng Gold
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A1A),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text("THÊM VÀO GIỎ HÀNG", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}