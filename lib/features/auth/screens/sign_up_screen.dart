import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../router/app_router.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Trạng thái ẩn/hiện mật khẩu và Checkbox
  bool _obscurePassword = true;
  bool _agreeToTerms = false;

  // FocusNodes để lắng nghe sự kiện người dùng nhấp vào ô nhập liệu
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Lắng nghe sự thay đổi Focus để cập nhật giao diện (hiển thị viền)
    _nameFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _passFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // SafeArea giúp tránh phần tai thỏ (notch) và thanh trạng thái
      body: SafeArea(
        // LayoutBuilder + SingleChildScrollView + IntrinsicHeight giúp cuộn màn hình khi có bàn phím
        // nhưng vẫn ép phần Footer dính xuống đáy khi không có bàn phím.
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
                        const SizedBox(height: 40),

                        // --- PHẦN 1: TIÊU ĐỀ ---
                        const Text(
                          "Create Account",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Fill your information below or register\nwith your social account.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // --- PHẦN 2: FORM NHẬP LIỆU ---
                        _buildTextField(
                          label: "Name",
                          hint: "Ex. John Doe",
                          focusNode: _nameFocus,
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          label: "Email",
                          hint: "Ex. john.doe@example.com",
                          focusNode: _emailFocus,
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          label: "Password",
                          hint: "••••••••",
                          isPassword: true,
                          focusNode: _passFocus,
                        ),
                        const SizedBox(height: 24),

                        // --- PHẦN 3: CHECKBOX ---
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _agreeToTerms = !_agreeToTerms;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _agreeToTerms ? Colors.black87 : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _agreeToTerms ? Colors.black87 : Colors.transparent,
                                  ),
                                ),
                                // Hiệu ứng phóng to/thu nhỏ icon dấu tích
                                child: AnimatedScale(
                                  scale: _agreeToTerms ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                  children: [
                                    const TextSpan(text: "Agree with "),
                                    TextSpan(
                                      text: "Terms & Condition",
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()..onTap = () {},
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // --- PHẦN 4: NÚT SIGN UP ---
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              // Chuyển tới màn hình Home khi đăng ký thành công
                              Navigator.pushReplacementNamed(context, AppRouter.home);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade900,
                              shape: const StadiumBorder(), // Nút hình viên thuốc
                              elevation: 0,
                            ),
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // --- PHẦN 5: ĐƯỜNG PHÂN CÁCH & MẠNG XÃ HỘI ---
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "Or sign up with",
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButton(Icons.apple),
                            const SizedBox(width: 20),
                            _buildSocialButton(Icons.g_mobiledata, iconSize: 32), // Google mô phỏng
                            const SizedBox(width: 20),
                            _buildSocialButton(Icons.facebook, color: Colors.blue.shade700),
                          ],
                        ),

                        // Spacer sẽ đẩy Footer xuống tận cùng đáy màn hình
                        const Spacer(),

                        // --- PHẦN 6: FOOTER ---
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16, top: 24),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(fontSize: 14),
                              children: [
                                TextSpan(text: "Already have an account? ", style: TextStyle(color: Colors.grey.shade600)),
                                TextSpan(
                                  text: "Sign In",
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()..onTap = () {
                                    Navigator.pushReplacementNamed(context, AppRouter.signin);
                                    // Sẽ gọi sang màn hình Login sau
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
    bool isFocused = focusNode.hasFocus; // Kiểm tra xem ô này có đang được chọn không

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        // Input Field với hiệu ứng đổi màu viền
        AnimatedContainer(
          duration: const Duration(milliseconds: 200), // Thời gian mượt mà khi đổi viền
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isFocused ? Colors.grey.shade500 : Colors.transparent, // Hiện viền xám khi Focus
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
              // Icon bật tắt mật khẩu
              suffixIcon: isPassword
                  ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  // Widget con: Nút mạng xã hội
  Widget _buildSocialButton(IconData icon, {Color? color, double iconSize = 24}) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Icon(icon, color: color ?? Colors.black87, size: iconSize),
    );
  }
}