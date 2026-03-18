import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../router/app_router.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
    _passFocus.addListener(() => setState(() {}));
  }

  Future<void> _saveLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Email và mật khẩu không được để trống!");
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError("Định dạng email không hợp lệ!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _saveLoginStatus();

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.home);
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Sai email hoặc mật khẩu!";
      if (e.code == 'network-request-failed') msg = "Lỗi kết nối mạng!";
      _showError(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
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
              const SizedBox(height: 60),
              const Text(
                "Sign In",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                "Hi! Welcome back, you've been missed",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 50),

              _buildTextField(
                controller: _emailController,
                label: "Email",
                hint: "example@gmail.com",
                focusNode: _emailFocus,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _passController,
                label: "Password",
                hint: "••••••••",
                isPassword: true,
                focusNode: _passFocus,
              ),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRouter.forgotPassword),
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, decoration: TextDecoration.underline),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    shape: const StadiumBorder(),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Sign In", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 40),
              _buildSocialSection(),
              const SizedBox(height: 40),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, bool isPassword = false, required FocusNode focusNode}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: focusNode.hasFocus ? Colors.black87 : Colors.transparent),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isPassword && _obscurePassword,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: isPassword ? IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ) : null,
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
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Or sign in with")),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ]),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialButton(Icons.apple),
            const SizedBox(width: 20),
            _socialButton(Icons.g_mobiledata, iconSize: 32),
            const SizedBox(width: 20),
            _socialButton(Icons.facebook, color: Colors.blue),
          ],
        ),
      ],
    );
  }

  Widget _socialButton(IconData icon, {Color? color, double iconSize = 24}) {
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
      child: Icon(icon, color: color ?? Colors.black87, size: iconSize),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.grey),
          children: [
            const TextSpan(text: "Don't have an account? "),
            TextSpan(
              text: "Sign Up",
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
              recognizer: TapGestureRecognizer()..onTap = () => Navigator.pushReplacementNamed(context, AppRouter.signup),
            ),
          ],
        ),
      ),
    );
  }
}