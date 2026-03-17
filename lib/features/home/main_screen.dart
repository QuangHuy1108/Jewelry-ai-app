import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jewelry_app/core/theme/app_colors.dart';
import 'package:jewelry_app/shared/providers/cart_provider.dart';

// Import các màn hình con của bạn
import '../shopping/home_screen.dart';
import '../shopping/cart_screen.dart';
import '../chat/chat_screen.dart'; // Màn hình AI Chat của bạn
// import '../camera/camera_screen.dart'; // Nếu bạn có màn hình Camera AI

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Danh sách các màn hình sẽ hiển thị khi bấm vào từng Tab
  final List<Widget> _screens = [
    const HomeScreen(),
    const ChatScreen(), // Trợ lý AI
    const CartScreen(),
    const Center(child: Text("TRANG CÁ NHÂN", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))), // Tạm thời để trống
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex], // Hiển thị màn hình tương ứng với Tab được chọn
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, child) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed, // Giữ cố định các Tab
            backgroundColor: AppColors.luxuryBlack,
            selectedItemColor: AppColors.primaryGold,
            unselectedItemColor: Colors.grey,
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Trang chủ"),
              const BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: "AI Tư vấn"),

              // Tab Giỏ hàng có tích hợp chấm đỏ (Badge) báo số lượng
              BottomNavigationBarItem(
                icon: Badge(
                  label: Text(cart.itemCount.toString()),
                  isLabelVisible: cart.itemCount > 0,
                  child: const Icon(Icons.shopping_bag),
                ),
                label: "Giỏ hàng",
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.person), label: "Hồ sơ"),
            ],
          );
        },
      ),
    );
  }
}