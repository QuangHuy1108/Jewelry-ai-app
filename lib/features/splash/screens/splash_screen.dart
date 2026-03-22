import 'package:flutter/material.dart';
// Giả sử bạn dùng SharedPreferences để lưu token, hãy thêm: import 'package:shared_preferences/shared_preferences.dart';
import '../../../router/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Hiệu ứng Fade In -> Hold -> Fade Out
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 37.5),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 50.0),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 12.5),
    ]).animate(_controller);

    // Hiệu ứng Scale nhẹ lúc kết thúc
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 87.5),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 12.5),
    ]).animate(_controller);

    // Kích hoạt chạy hiệu ứng và xử lý logic điều hướng khi kết thúc
    _controller.forward().then((_) => _handleNavigation());
  }

  // --- TÍNH NĂNG MỚI: KIỂM TRA TRẠNG THÁI NGƯỜI DÙNG ---
  Future<void> _handleNavigation() async {
    if (!mounted) return;

    // GIẢ LẬP KIỂM TRA AUTH (Bạn thay đoạn này bằng logic thực tế của app)
    // Ví dụ: final prefs = await SharedPreferences.getInstance();
    // String? token = prefs.getString('user_token');
    bool isLoggedIn = false; // Mặc định là chưa đăng nhập

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppRouter.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.welcome);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Decor (Giữ nguyên)
          _buildBackgroundIcon(top: -30, right: -30),
          _buildBackgroundIcon(bottom: -30, left: -30),

          // Logo & Text Animation
          Center(
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.diamond_outlined,
                        size: 45,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "JEWELRY SHOP",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 4.0, // Tăng khoảng cách chữ cho sang trọng
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget để code gọn hơn
  Widget _buildBackgroundIcon({double? top, double? right, double? bottom, double? left}) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Opacity(
        opacity: 0.05,
        child: Icon(
          Icons.energy_savings_leaf,
          size: 250,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }
}