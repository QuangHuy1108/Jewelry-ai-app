import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../router/app_router.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _obscurePassword = true;

  // Quản lý trạng thái Focus của các ô nhập liệu
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
    _passFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // Cấu trúc cuộn linh hoạt để tránh bàn phím ảo
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 60),

                        // --- PHẦN 1: TIÊU ĐỀ & MÔ TẢ ---
                        const Text(
                          "Sign In",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Hi! Welcome back, you've been missed",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 50),

                        // --- PHẦN 2: FORM NHẬP LIỆU ---
                        _buildTextField(
                          label: "Email",
                          hint: "example@gmail.com",
                          focusNode: _emailFocus,
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          label: "Password",
                          hint: "••••••••",
                          isPassword: true,
                          focusNode: _passFocus,
                        ),
                        const SizedBox(height: 12),

                        // --- PHẦN 3: QUÊN MẬT KHẨU (Căn phải) ---
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              // CHUYỂN HƯỚNG SANG MÀN HÌNH OTP KHI BẤM
                              Navigator.pushNamed(context, AppRouter.verifyCode);
                            },
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // --- PHẦN 4: NÚT SIGN IN ---
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              // Chuyển tới màn hình Home khi đăng nhập thành công
                              Navigator.pushReplacementNamed(context, AppRouter.home);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade900,
                              shape: const StadiumBorder(), // Bo tròn 2 đầu (viên thuốc)
                              elevation: 0,
                            ),
                            child: const Text(
                              "Sign In",
                              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // --- PHẦN 5: ĐƯỜNG PHÂN CÁCH & MẠNG XÃ HỘI ---
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "Or sign in with",
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Cụm 3 nút mạng xã hội có hiệu ứng Scale & Opacity
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _AnimatedSocialButton(icon: Icons.apple),
                            const SizedBox(width: 20),
                            _AnimatedSocialButton(icon: Icons.g_mobiledata, iconSize: 32),
                            const SizedBox(width: 20),
                            _AnimatedSocialButton(icon: Icons.facebook, color: Colors.blue.shade700),
                          ],
                        ),

                        // Spacer đẩy Footer xuống đáy
                        const Spacer(),

                        // --- PHẦN 6: FOOTER (Chuyển sang Đăng ký) ---
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16, top: 24),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(fontSize: 14),
                              children: [
                                TextSpan(text: "Don't have an account? ", style: TextStyle(color: Colors.grey.shade600)),
                                TextSpan(
                                  text: "Sign Up",
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()..onTap = () {
                                    // Quay lại hoặc chuyển hướng sang màn hình Đăng ký
                                    Navigator.pushReplacementNamed(context, AppRouter.signup);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Widget con: Ô nhập liệu tùy chỉnh
  Widget _buildTextField({
    required String label,
    required String hint,
    bool isPassword = false,
    required FocusNode focusNode,
  }) {
    bool isFocused = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isFocused ? Colors.grey.shade500 : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: TextField(
            focusNode: focusNode,
            obscureText: isPassword && _obscurePassword,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: isPassword
                  ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

// Widget con: Nút mạng xã hội có Animation tương tác (Scale & Opacity)
class _AnimatedSocialButton extends StatefulWidget {
  final IconData icon;
  final Color? color;
  final double iconSize;

  const _AnimatedSocialButton({required this.icon, this.color, this.iconSize = 24});

  @override
  State<_AnimatedSocialButton> createState() => _AnimatedSocialButtonState();
}

class _AnimatedSocialButtonState extends State<_AnimatedSocialButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    // Khi bấm vào sẽ thu nhỏ về 90% (0.9)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        // Gọi hàm xử lý đăng nhập mạng xã hội tại đây
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        // Dùng AnimatedBuilder hoặc cách đơn giản là thay đổi độ mờ của toàn bộ khối khi đang bấm
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Khi _controller.value = 1 (đang giữ), opacity = 0.7. Mặc định là 1.0
            return Opacity(
              opacity: 1.0 - (_controller.value * 0.3),
              child: child,
            );
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
            ),
            child: Icon(widget.icon, color: widget.color ?? Colors.black87, size: widget.iconSize),
          ),
        ),
      ),
    );
  }
}