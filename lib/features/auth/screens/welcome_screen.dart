import 'package:flutter/material.dart';
import 'dart:math' as math;
// Import router của bạn để sử dụng các hằng số route
import '../../../router/app_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _floatingController;

  late Animation<double> _bgFadeAnimation;
  late Animation<Offset> _imageSlideAnimation;
  late Animation<double> _imageFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _buttonSlideAnimation;
  late Animation<double> _buttonFadeAnimation;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Chỉnh chậm lại cho mượt hơn
    )..repeat(reverse: true);

    // Định nghĩa Intervals cho hiệu ứng xuất hiện tuần tự
    _bgFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    _imageSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic)),
    );
    _imageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.2, 0.7, curve: Curves.easeOut)),
    );

    _textSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic)),
    );
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.4, 0.9, curve: Curves.easeOut)),
    );

    _buttonSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic)),
    );
    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background (Sửa lỗi Incorrect use of ParentDataWidget)
          _buildMasonryBackground(size),

          SafeArea(
            child: Column(
              children: [
                // 2. Hình ảnh chính (Sửa lại UI mượt hơn)
                Expanded(
                  flex: 5,
                  child: FadeTransition(
                    opacity: _imageFadeAnimation,
                    child: SlideTransition(
                      position: _imageSlideAnimation,
                      child: AnimatedBuilder(
                        animation: _floatingController,
                        builder: (context, child) {
                          final floatingOffset = math.sin(_floatingController.value * 2 * math.pi) * 8;
                          return Transform.translate(
                            offset: Offset(0, floatingOffset),
                            child: child,
                          );
                        },
                        child: Center(
                          child: Transform.rotate(
                            angle: -0.04,
                            child: Container(
                              width: size.width * 0.7,
                              height: size.height * 0.4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(48),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 40,
                                    offset: const Offset(0, 20),
                                  ),
                                ],
                                image: const DecorationImage(
                                    image: NetworkImage('https://i.postimg.cc/kX889qJT/h5.jpg'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Khối Text
                Expanded(
                  flex: 3,
                  child: FadeTransition(
                    opacity: _textFadeAnimation,
                    child: SlideTransition(
                      position: _textSlideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Column(
                          children: [
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: const TextStyle(fontSize: 32, height: 1.1, color: Color(0xFF1A1A1A)),
                                children: [
                                  const TextSpan(text: "Your Ultimate\nDestination for\n", style: TextStyle(fontWeight: FontWeight.w900)),
                                  TextSpan(text: "Sparkle & Shine", style: TextStyle(fontWeight: FontWeight.w300, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Discover exquisite collections and timeless elegance crafted just for you.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15, color: Colors.grey.shade500, height: 1.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Khối Buttons (Sửa logic chuyển hướng)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: FadeTransition(
                    opacity: _buttonFadeAnimation,
                    child: SlideTransition(
                      position: _buttonSlideAnimation,
                      child: Column(
                        children: [
                          // Nút Get Started -> Vào Onboarding
                          SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, AppRouter.onboarding),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A1A1A),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 0,
                              ),
                              child: const Text("Let's Get Started", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Link Sign In -> Vào Đăng nhập trực tiếp
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, AppRouter.signin), // Giả sử route là login
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(fontSize: 15, color: Colors.grey),
                                children: [
                                  TextSpan(text: "Already have an account? "),
                                  TextSpan(text: "Sign In", style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasonryBackground(Size size) {
    return Positioned(
      top: -20,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _bgFadeAnimation,
        child: Opacity(
          opacity: 0.3,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(8, (index) {
              return Container(
                width: (index % 2 == 0) ? size.width * 0.4 : size.width * 0.3,
                height: (index % 3 == 0) ? 160 : 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
