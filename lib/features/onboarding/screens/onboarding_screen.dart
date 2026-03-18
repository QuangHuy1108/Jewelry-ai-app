import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Thêm thư viện này
import '../../../router/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;

  late AnimationController _entranceController;
  late Animation<Offset> _phoneSlide;
  late Animation<double> _phoneFade;
  late Animation<double> _textFade;

  late AnimationController _nextButtonController;
  late Animation<double> _nextButtonScale;

  late AnimationController _backButtonController;
  late Animation<double> _backButtonScale;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "titleSpans": [
        TextSpan(text: "Effortless\n", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal)),
        const TextSpan(text: "Jewelry Shopping\nExperience", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ],
      "desc": "Explore high-end jewelry with just a few taps on your screen.",
    },
    {
      "titleSpans": [
        const TextSpan(text: "Build Your Perfect\n", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        TextSpan(text: "Jewelry Box", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
      ],
      "desc": "Discover our unique collections and customize your own sparkling jewelry box.",
    },
    {
      "titleSpans": [
        const TextSpan(text: "Shine Delivered:\n", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        TextSpan(text: "Quick & Secure\n", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal)),
        const TextSpan(text: "Jewelry Shopping", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ],
      "desc": "Your precious items are handled with care and delivered with maximum security.",
    }
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initAnimations();
  }

  void _initAnimations() {
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _phoneSlide = Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.75, curve: Curves.easeOut)),
    );
    _phoneFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.75)),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.25, 1.0)),
    );

    _entranceController.forward();

    _nextButtonController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), lowerBound: 0.9, upperBound: 1.0, value: 1.0);
    _nextButtonScale = Tween<double>(begin: 0.9, end: 1.0).animate(_nextButtonController);

    _backButtonController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), lowerBound: 0.9, upperBound: 1.0, value: 1.0);
    _backButtonScale = Tween<double>(begin: 0.9, end: 1.0).animate(_backButtonController);
  }

  // --- TÍNH NĂNG MỚI: LƯU TRẠNG THÁI ---
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true); // Lưu lại để lần sau không hiện Onboarding nữa

    if (mounted) {
      // Chuyển sang màn hình Đăng nhập
      Navigator.pushReplacementNamed(context, AppRouter.signin);
    }
  }

  void _onNextPressed() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _completeOnboarding(); // Lưu trạng thái và thoát
    }
  }

  void _onBackPressed() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    _nextButtonController.dispose();
    _backButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isLastPage = _currentPage == _onboardingData.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Decor
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: ClipPath(
              clipper: ConcaveCurveClipper(),
              child: Container(color: Colors.grey.shade100),
            ),
          ),

          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) => _buildPageContent(index),
          ),

          // Nút Skip
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 24.0, top: 8.0),
                child: AnimatedOpacity(
                  opacity: isLastPage ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: isLastPage,
                    child: TextButton(
                      onPressed: _completeOnboarding, // Bấm Skip cũng tính là đã xem Onboarding
                      child: Text(
                        "Skip",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Footer: Nút Back, Dot, Next
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                child: FadeTransition(
                  opacity: _textFade,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      _buildIconButton(
                        visible: _currentPage != 0,
                        icon: Icons.arrow_back,
                        onTap: _onBackPressed,
                        controller: _backButtonController,
                        scale: _backButtonScale,
                        isDark: false,
                      ),

                      // Dots
                      Row(
                        children: List.generate(_onboardingData.length, (index) => _buildPaginationDot(index)),
                      ),

                      // Next Button
                      _buildIconButton(
                        visible: true,
                        icon: isLastPage ? Icons.check : Icons.arrow_forward,
                        onTap: _onNextPressed,
                        controller: _nextButtonController,
                        scale: _nextButtonScale,
                        isDark: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tối ưu hóa lại Widget Nút bấm để tránh lặp code
  Widget _buildIconButton({
    required bool visible,
    required IconData icon,
    required VoidCallback onTap,
    required AnimationController controller,
    required Animation<double> scale,
    required bool isDark,
  }) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !visible,
        child: GestureDetector(
          onTapDown: (_) => controller.animateTo(0.9),
          onTapUp: (_) {
            controller.animateTo(1.0);
            onTap();
          },
          onTapCancel: () => controller.animateTo(1.0),
          child: ScaleTransition(
            scale: scale,
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                shape: BoxShape.circle,
                border: isDark ? null : Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
              child: Icon(icon, color: isDark ? Colors.white : Colors.grey.shade700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(int index) {
    final data = _onboardingData[index];
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + 50),
        Expanded(
          flex: 11,
          child: SlideTransition(
            position: _phoneSlide,
            child: FadeTransition(
              opacity: _phoneFade,
              child: Center(
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(color: Colors.black87, width: 8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 15)),
                    ],
                  ),
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 60, height: 16,
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 8,
          child: FadeTransition(
            opacity: _textFade,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(fontSize: 28, height: 1.3, fontFamily: 'Georgia'), // Ví dụ thêm font cho sang
                      children: data['titleSpans'],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data['desc'],
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationDot(int index) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.grey.shade800 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class ConcaveCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(size.width / 2, size.height - 60, size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}