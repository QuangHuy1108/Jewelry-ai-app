import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/cart_provider.dart';
import 'package:jewelry_app/core/theme/app_colors.dart'; // Lấy màu chuẩn của bạn

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  void _placeOrder(BuildContext context, double total) {
    if (_formKey.currentState!.validate()) {
      // 1. Dọn sạch giỏ hàng
      context.read<CartProvider>().clearCart();

      // 2. Hiện thông báo chúc mừng lấp lánh
      showDialog(
        context: context,
        barrierDismissible: false, // Bắt buộc bấm nút mới tắt
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.backgroundCream,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(Icons.check_circle, color: AppColors.primaryGold, size: 60),
          content: Text(
            "Đặt hàng thành công!\nTổng hóa đơn: \$${total.toStringAsFixed(1)}",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.luxuryBlack),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold),
                onPressed: () {
                  // Đóng Dialog và quay thẳng về Trang chủ
                  context.pop();
                  context.go('/');
                },
                child: const Text("TIẾP TỤC MUA SẮM", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>(); // Lấy tổng tiền

    return Scaffold(
      appBar: AppBar(title: const Text('THÔNG TIN GIAO HÀNG'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Địa chỉ nhận hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Ô nhập Tên
              TextFormField(
                decoration: const InputDecoration(labelText: 'Họ và Tên', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),

              // Ô nhập SĐT
              TextFormField(
                decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập SĐT' : null,
              ),
              const SizedBox(height: 16),

              // Ô nhập Địa chỉ
              TextFormField(
                decoration: const InputDecoration(labelText: 'Địa chỉ chi tiết', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
              ),

              const SizedBox(height: 40),

              // Nút Chốt đơn
              ElevatedButton(
                onPressed: () => _placeOrder(context, cart.totalAmount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.luxuryBlack,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  "XÁC NHẬN THANH TOÁN (\$${cart.totalAmount.toStringAsFixed(1)})",
                  style: const TextStyle(color: AppColors.primaryGold, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}