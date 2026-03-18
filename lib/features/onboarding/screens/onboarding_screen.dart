import 'package:flutter/material.dart';
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

  // CẬP NHẬT: Cấu trúc lại dữ liệu để hỗ trợ nhiều đoạn văn bản đan xen kiểu dáng
  final List<Map<String, dynamic>> _onboardingData = [
    {
      "titleSpans": [
        TextSpan(text: "Effortless\n", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal)),
        const TextSpan(text: "Jewelry Shopping\nExperience", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ],
      "desc": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore.",
    },
    {
      "titleSpans": [
        const TextSpan(text: "Build Your Perfect\n", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        TextSpan(text: "Jewelry Box", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
      ],
      "desc": "Discover our unique collections and customize your own sparkling jewelry box seamlessly.",
    },
    {
      // Dữ liệu cho Màn hình 3 với 3 mảng màu xen kẽ
      "titleSpans": [
        const TextSpan(text: "Shine Delivered:\n", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        TextSpan(text: "Quick & Secure\n", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal)),
        const TextSpan(text: "Jewelry Shopping", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ],
      "desc": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore.",
    }
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Hiệu ứng xuất hiện
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

    // Hiệu ứng nút
    _nextButtonController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 100), lowerBound: 0.9, upperBound: 1.0, value: 1.0,
    );
    _nextButtonScale = Tween<double>(begin: 0.9, end: 1.0).animate(_nextButtonController);

    _backButtonController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 100), lowerBound: 0.9, upperBound: 1.0, value: 1.0,
    );
    _backButtonScale = Tween<double>(begin: 0.9, end: 1.0).animate(_backButtonController);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    _nextButtonController.dispose();
    _backButtonController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentPage < _onboardingData.length - 1) {
      // Nếu chưa phải trang cuối, chuyển sang trang tiếp theo
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      // Đã ở trang cuối (Màn 3), kết thúc Onboarding và chuyển vào ứng dụng
      // (Bạn có thể đổi AppRouter.home thành AppRouter.login sau này)
      Navigator.pushReplacementNamed(context, AppRouter.signup);
    }
  }

  void _onBackPressed() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Biến kiểm tra xem có phải trang cuối không
    bool isLastPage = _currentPage == _onboardingData.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Nền xám và đường cong lõm
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: ClipPath(
              clipper: ConcaveCurveClipper(),
              child: Container(color: Colors.grey.shade100),
            ),
          ),

          // 2. PageView cho phép vuốt qua lại
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) => _buildPageContent(index),
          ),

          // 3. Header: Nút Skip (Sẽ mờ dần và biến mất ở trang cuối)
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 24.0, top: 8.0),
                child: AnimatedOpacity(
                  opacity: isLastPage ? 0.0 : 1.0, // Mờ đi khi là trang cuối
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: isLastPage, // Vô hiệu hóa tính năng bấm khi đã mờ
                    child: TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, AppRouter.home),
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

          // 4. Footer: Nút Back, Pagination Dots, Nút Next
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
                      // NÚT BACK
                      AnimatedOpacity(
                        opacity: _currentPage == 0 ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: GestureDetector(
                          onTapDown: (_) => _currentPage > 0 ? _backButtonController.animateTo(0.9) : null,
                          onTapUp: (_) {
                            _backButtonController.animateTo(1.0);
                            _onBackPressed();
                          },
                          onTapCancel: () => _backButtonController.animateTo(1.0),
                          child: ScaleTransition(
                            scale: _backButtonScale,
                            child: Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300, width: 1.5),
                              ),
                              child: Icon(Icons.arrow_back, color: Colors.grey.shade700),
                            ),
                          ),
                        ),
                      ),

                      // DẢI DẤU CHẤM
                      Row(
                        children: List.generate(_onboardingData.length, (index) => _buildPaginationDot(index)),
                      ),

                      // NÚT NEXT (Hoạt động như nút Done ở trang cuối)
                      GestureDetector(
                        onTapDown: (_) => _nextButtonController.animateTo(0.9),
                        onTapUp: (_) {
                          _nextButtonController.animateTo(1.0);
                          _onNextPressed(); // Đã bao gồm logic chuyển hướng nếu ở trang cuối
                        },
                        onTapCancel: () => _nextButtonController.animateTo(1.0),
                        child: ScaleTransition(
                          scale: _nextButtonScale,
                          child: Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(color: Colors.grey.shade900, shape: BoxShape.circle),
                            // Nếu muốn, bạn có thể đổi icon ở trang cuối thành dấu tích (Icons.check) thay vì mũi tên:
                            // child: Icon(isLastPage ? Icons.check : Icons.arrow_forward, color: Colors.white),
                            child: const Icon(Icons.arrow_forward, color: Colors.white),
                          ),
                        ),
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

  Widget _buildPageContent(int index) {
    final data = _onboardingData[index];

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + 50),

        // Mockup điện thoại
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

        // Cụm văn bản
        Expanded(
          flex: 8,
          child: FadeTransition(
            opacity: _textFade,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Tiêu đề động hỗ trợ nhiều TextSpan
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(fontSize: 28, height: 1.3),
                      children: data['titleSpans'], // Gắn mảng cấu hình chữ vào đây
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Mô tả
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