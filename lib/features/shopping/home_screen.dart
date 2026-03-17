import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/product_provider.dart';
import 'package:provider/provider.dart' as prov;
import '../../shared/providers/cart_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:jewelry_app/core/theme/app_colors.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lắng nghe dữ liệu từ Provider
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('JEWELRY AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent), // Biểu tượng trợ lý
            onPressed: () => context.push('/chat'),
          ),
          prov.Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Badge(
                label: Text(cart.itemCount.toString()), // Hiển thị số lượng hàng
                isLabelVisible: cart.itemCount > 0,     // Chỉ hiện số khi có hàng trong giỏ
                child: IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined, size: 28),
                  onPressed: () => context.push('/cart'), // Chuyển sang trang giỏ hàng
                ),
              );
            },
          ),
          const SizedBox(width: 16), // Cách lề phải một chút cho cân đối
        ],
      ),
      body: productsAsync.when(
        // 1. TRẠNG THÁI ĐANG TẢI (SHIMMER)
          loading: () => GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75, // Tỷ lệ khung hình giống hệt thẻ sản phẩm thật
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: 6, // Hiện 6 ô tải giả
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: AppColors.shimmerBase,
                highlightColor: AppColors.shimmerHighlight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              );
            },
          ),

          // 2. TRẠNG THÁI LỖI (MẤT MẠNG/FIREBASE LỖI)
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 60, color: AppColors.textGrey),
                const SizedBox(height: 16),
                const Text(
                  "Không thể tải dữ liệu trang sức.",
                  style: TextStyle(color: AppColors.luxuryBlack, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text("Vui lòng kiểm tra lại kết nối mạng của bạn.", style: TextStyle(color: AppColors.textGrey)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    // Lệnh làm mới lại dữ liệu của Riverpod
                    // Giả sử provider của bạn tên là productsProvider
                    ref.invalidate(productsProvider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text("Thử lại", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        // Trường hợp dữ liệu về thành công
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('Chưa có sản phẩm nào.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return InkWell(
                onTap: () {
                  context.push('/detail', extra: product);
                },
                child: Card(
                margin: const EdgeInsets.only(bottom: 20),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hình ảnh sản phẩm
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Image.network(
                        product.imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        // Thêm đoạn này để xử lý khi ảnh đang tải
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        // Thêm đoạn này để xử lý khi ảnh bị lỗi (như lỗi 404 bạn gặp)
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                    // Thông tin sản phẩm
                    // Trong phần Padding của thông tin sản phẩm:
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Tăng khoảng cách cho thoáng
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name.toUpperCase(), // Chữ in hoa nhìn sẽ sang hơn
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1, // Khoảng cách chữ rộng ra chút
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${product.price}',
                            style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xFFD4AF37), // Màu vàng Gold
                                fontWeight: FontWeight.w800
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/camera'); // Lệnh để mở màn hình Camera
        },
        backgroundColor: const Color(0xFFD4AF37), // Màu vàng Gold Luxury
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        label: const Text("AI SCAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}