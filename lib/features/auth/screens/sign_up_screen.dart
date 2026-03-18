import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../router/app_router.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController(); // MỚI

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true; // MỚI
  bool _agreeToTerms = false;
  bool _isLoading = false;

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();
  final FocusNode _confirmPassFocus = FocusNode(); // MỚI

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _passFocus.addListener(() => setState(() {}));
    _confirmPassFocus.addListener(() => setState(() {})); // MỚI
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // --- LOGIC XỬ LÝ ĐĂNG KÝ ---
  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passController.text.trim();
    final confirmPassword = _confirmPassController.text.trim(); // MỚI

    if (name.isEmpty) {
      _showError("Please enter your name");
      return;
    }
    if (!_isValidEmail(email)) {
      _showError("Please enter a valid email address");
      return;
    }
    if (password.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }
    // KIỂM TRA TRÙNG KHỚP
    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }
    if (!_agreeToTerms) {
      _showError("You must agree to the Terms & Conditions");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);

      if (mounted) {
        _showSuccess("Account created! Verifying your email...");
        // Lưu ý: Đảm bảo AppRouter.verifyCode đã nhận arguments nếu cần
        Navigator.pushReplacementNamed(
          context,
          AppRouter.verifyCode,
          arguments: {'email': email, 'isFromForgotPassword': false},
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Registration failed");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose(); // MỚI
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmPassFocus.dispose(); // MỚI
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Create Account",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                "Fill your information below to get started.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 40),

              _buildTextField(controller: _nameController, label: "Name", hint: "John Doe", focusNode: _nameFocus),
              const SizedBox(height: 20),
              _buildTextField(controller: _emailController, label: "Email", hint: "example@gmail.com", focusNode: _emailFocus),
              const SizedBox(height: 20),

              // Ô Mật khẩu
              _buildTextField(
                controller: _passController,
                label: "Password",
                hint: "••••••••",
                isPassword: true,
                obscureText: _obscurePassword, // Truyền biến riêng
                focusNode: _passFocus,
                onToggle: () => setState(() => _obscurePassword = !_obscurePassword), // Callback riêng
              ),
              const SizedBox(height: 20),

              // Ô Xác nhận mật khẩu (MỚI)
              _buildTextField(
                controller: _confirmPassController,
                label: "Confirm Password",
                hint: "••••••••",
                isPassword: true,
                obscureText: _obscureConfirmPassword, // Truyền biến riêng
                focusNode: _confirmPassFocus,
                onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword), // Callback riêng
              ),

              const SizedBox(height: 24),
              _buildTermsCheckbox(),
              const SizedBox(height: 32),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    shape: const StadiumBorder(),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Sign Up", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 32),
              _buildSocialSection(),
              const SizedBox(height: 40),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET CON ĐÃ TỐI ƯU (Sửa đổi để dùng cho cả 2 ô mật khẩu) ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isPassword = false,
    bool obscureText = false, // MỚI
    VoidCallback? onToggle, // MỚI
    required FocusNode focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: focusNode.hasFocus ? Colors.black87 : Colors.transparent),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText, // Dùng biến truyền vào
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: isPassword ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
                onPressed: onToggle, // Dùng callback truyền vào
              ) : null,
            ),
          ),
        ),
      ],
    );
  }

  // ... (Các hàm _buildTermsCheckbox, _buildSocialSection, _buildFooter giữ nguyên)
  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreeToTerms,
          activeColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          onChanged: (val) => setState(() => _agreeToTerms = val!),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              children: [
                const TextSpan(text: "Agree with "),
                TextSpan(
                  text: "Terms & Condition",
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        Row(children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Or sign up with")),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ]),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialIcon(Icons.g_mobiledata, color: Colors.red),
            const SizedBox(width: 20),
            _socialIcon(Icons.apple, color: Colors.black),
            const SizedBox(width: 20),
            _socialIcon(Icons.facebook, color: Colors.blue),
          ],
        ),
      ],
    );
  }

  Widget _socialIcon(IconData icon, {required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
      child: Icon(icon, color: color, size: 30),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.grey),
          children: [
            const TextSpan(text: "Already have an account? "),
            TextSpan(
              text: "Sign In",
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
              recognizer: TapGestureRecognizer()..onTap = () => Navigator.pushReplacementNamed(context, AppRouter.signin),
            ),
          ],
        ),
      ),
    );
  }
}