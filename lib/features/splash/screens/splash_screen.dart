import 'package:flutter/material.dart';
import '../../../router/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Bổ sung SingleTickerProviderStateMixin để màn hình có thể đồng bộ nhịp thời gian (Tick) với hiệu ứng
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Tạo bộ điều khiển với tổng thời gian = 4.0 giây
    // (1.5s hiện + 2.0s chờ + 0.5s chuyển cảnh)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // 2. Thiết lập chuỗi hiệu ứng cho Độ mờ (Opacity)
    // Thuộc tính 'weight' đại diện cho phần trăm (%) thời gian của tổng 4 giây
    _opacityAnimation = TweenSequence<double>([
      // 1.5s / 4.0s = 37.5%: Từ 0 lên 1 (Fade In)
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 37.5),
      // 2.0s / 4.0s = 50.0%: Giữ nguyên ở mức 1 (Hold)
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 50.0),
      // 0.5s / 4.0s = 12.5%: Từ 1 về 0 (Fade Out)
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 12.5),
    ]).animate(_controller);

    // 3. Thiết lập chuỗi hiệu ứng cho Kích thước (Scale)
    _scaleAnimation = TweenSequence<double>([
      // 3.5s đầu / 4.0s = 87.5%: Giữ nguyên tỷ lệ 1.0
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 87.5),
      // 0.5s cuối / 4.0s = 12.5%: Phóng to từ 1.0 lên 1.1
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 12.5),
    ]).animate(_controller);

    // 4. Kích hoạt chạy hiệu ứng. Hàm .then() sẽ được gọi khi hiệu ứng chạy xong 4 giây
    _controller.forward().then((_) {
      if (mounted) {
        // Tự động chuyển sang màn hình Onboarding mượt mà
        Navigator.pushReplacementNamed(context, AppRouter.onboarding);
      }
    });
  }

  @override
  void dispose() {
    // Rất quan trọng: Phải hủy bỏ _controller khi màn hình này đóng lại để giải phóng bộ nhớ
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Họa tiết lá mờ ở góc trên bên phải (không đổi)
          Positioned(
            top: -30,
            right: -30,
            child: Opacity(
              opacity: 0.05,
              child: Icon(
                Icons.energy_savings_leaf,
                size: 200,
                color: Colors.grey.shade800,
              ),
            ),
          ),

          // 2. Họa tiết lá mờ ở góc dưới bên trái (không đổi)
          Positioned(
            bottom: -30,
            left: -30,
            child: Opacity(
              opacity: 0.05,
              child: Icon(
                Icons.energy_savings_leaf,
                size: 200,
                color: Colors.grey.shade800,
              ),
            ),
          ),

          // 3. Khối Logo và Tên Text bọc trong hiệu ứng
          Center(
            child: FadeTransition(
              opacity: _opacityAnimation, // Gắn hiệu ứng mờ
              child: ScaleTransition(
                scale: _scaleAnimation, // Gắn hiệu ứng phóng to
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.diamond_outlined,
                          size: 45,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Jewelry Shop",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 1.2,
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
}