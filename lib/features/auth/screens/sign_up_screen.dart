import 'package:jewelry_app/core/utils/luxury_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../router/app_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController =
      TextEditingController(); // MỚI

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

  Future<void> _saveLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
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
    LuxuryToast.show(context, message: message);

  }

  void _showSuccess(String message) {
    LuxuryToast.show(context, message: message);

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
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Fill your information below to get started.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 40),

              _buildTextField(
                controller: _nameController,
                label: "Name",
                hint: "John Doe",
                focusNode: _nameFocus,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _emailController,
                label: "Email",
                hint: "example@gmail.com",
                focusNode: _emailFocus,
              ),
              const SizedBox(height: 20),

              // Ô Mật khẩu
              _buildTextField(
                controller: _passController,
                label: "Password",
                hint: "••••••••",
                isPassword: true,
                obscureText: _obscurePassword, // Truyền biến riêng
                focusNode: _passFocus,
                onToggle: () => setState(
                  () => _obscurePassword = !_obscurePassword,
                ), // Callback riêng
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
                onToggle: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ), // Callback riêng
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
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      // Check if platform supports authentication
      if (!googleSignIn.supportsAuthenticate()) {
        _showError("Google Sign-In is not supported on this platform.");
        return;
      }

      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // In version 7.0+, accessToken is obtained via authorizationClient
      final GoogleSignInClientAuthorization? clientAuth = await googleUser
          .authorizationClient
          .authorizationForScopes([]);

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: clientAuth?.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await _saveLoginStatus();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.home,
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Lỗi đăng nhập Google!");
    } catch (e) {
      _showError("Đã xảy ra lỗi không xác định.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: focusNode.hasFocus ? Colors.black87 : Colors.transparent,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText, // Dùng biến truyền vào
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: onToggle, // Dùng callback truyền vào
                    )
                  : null,
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
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              16,
                            ), // Bo góc cho Dialog đẹp hơn
                          ),
                          title: const Text(
                            "Terms & Conditions",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          // Bọc nội dung bằng Scrollbar và SingleChildScrollView để có thể kéo xuống
                          content: SizedBox(
                            width: double.maxFinite,
                            child: Scrollbar(
                              thumbVisibility: true, // Hiện thanh cuộn bên phải
                              child: SingleChildScrollView(
                                physics:
                                    const BouncingScrollPhysics(), // Hiệu ứng cuộn mượt
                                child: const Text(
                                  "Nội dung Điều khoản & Điều kiện của ứng dụng bắt đầu ở đây.\n\n"
                                  "1. Chấp nhận điều khoản\n"
                                  "Bằng việc sử dụng ứng dụng này, bạn đồng ý với tất cả các điều khoản và điều kiện được nêu ra dưới đây. Bạn có thể viết nội dung dài bao nhiêu tùy thích.\n\n"
                                  "2. Quyền riêng tư\n"
                                  "Chúng tôi cam kết bảo vệ dữ liệu cá nhân của bạn. Mọi thông tin thu thập sẽ chỉ được sử dụng cho mục đích cải thiện trải nghiệm người dùng.\n\n"
                                  "3. Trách nhiệm người dùng\n"
                                  "Người dùng cam kết không sử dụng ứng dụng cho các mục đích bất hợp pháp hoặc gây hại đến hệ thống.\n\n"
                                  "4. Thay đổi điều khoản\n"
                                  "Chúng tôi có quyền thay đổi các điều khoản này bất kỳ lúc nào mà không cần thông báo trước. Việc tiếp tục sử dụng ứng dụng đồng nghĩa với việc bạn chấp nhận các thay đổi đó.\n\n"
                                  "5. ... (Bạn có thể thêm hàng trăm dòng chữ nữa vào đây, hộp thoại sẽ tự động có thanh cuộn để kéo xuống).",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context), // Đóng Dialog
                              child: const Text(
                                "Đóng",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _socialButton(
    IconData icon, {
    Color? color,
    double iconSize = 24,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap, // Thêm hành động khi nhấn
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, color: color ?? Colors.black87, size: iconSize),
      ),
    );
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("Or sign in with"),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialButton(Icons.apple),
            const SizedBox(width: 20),
            // Gắn sự kiện onTap vào đây
            _socialButton(
              Icons.g_mobiledata,
              iconSize: 32,
              onTap: _signInWithGoogle,
            ),
            const SizedBox(width: 20),
            _socialButton(Icons.facebook, color: Colors.blue),
          ],
        ),
      ],
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
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () =>
                    Navigator.pushReplacementNamed(context, AppRouter.signin),
            ),
          ],
        ),
      ),
    );
  }
}
