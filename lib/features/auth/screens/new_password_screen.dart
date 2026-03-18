import 'package:flutter/material.dart';
import '../../../router/app_router.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({Key? key}) : super(key: key);

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // BIẾN MỚI: Quản lý lỗi hiển thị trực tiếp dưới ô nhập
  String? _confirmPasswordError;

  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  @override
  void dispose() {
    _newPassController.dispose();
    _confirmPassController.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    String newPass = _newPassController.text.trim();
    String confirmPass = _confirmPassController.text.trim();

    // Reset trạng thái lỗi trước khi kiểm tra
    setState(() => _confirmPasswordError = null);

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showSnackBar("Vui lòng điền đầy đủ thông tin!", Colors.orange);
      return;
    }

    if (newPass.length < 6) {
      _showSnackBar("Mật khẩu phải tối thiểu 6 ký tự!", Colors.redAccent);
      return;
    }

    // TÍNH NĂNG CỐT LÕI: Kiểm tra trùng khớp và hiện lỗi đỏ
    if (newPass != confirmPass) {
      setState(() {
        _confirmPasswordError = "Passwords do not match"; // Chữ báo lỗi màu đỏ
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      _showSuccessBottomSheet();
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccessBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 70),
            const SizedBox(height: 20),
            const Text("Mật khẩu đã đổi!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text("Bạn đã có thể đăng nhập bằng mật khẩu mới này.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, AppRouter.signin);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: const StadiumBorder()),
                child: const Text("Về Đăng Nhập", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 20),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBackButton(),
                      const SizedBox(height: 24),
                      _buildHeader(),
                      const SizedBox(height: 40),

                      _buildLabel("Mật khẩu mới"),
                      _buildTextField(
                        controller: _newPassController,
                        hintText: "••••••••",
                        obscureText: _obscurePassword,
                        focusNode: _passwordFocus,
                        onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),

                      const SizedBox(height: 24),

                      _buildLabel("Xác nhận mật khẩu"),
                      _buildTextField(
                        controller: _confirmPassController,
                        hintText: "••••••••",
                        obscureText: _obscureConfirmPassword,
                        focusNode: _confirmPasswordFocus,
                        errorText: _confirmPasswordError, // Truyền biến lỗi vào đây
                        onChanged: (val) {
                          // TỰ ĐỘNG XÓA LỖI KHI NGƯỜI DÙNG GÕ LẠI
                          if (_confirmPasswordError != null) setState(() => _confirmPasswordError = null);
                        },
                        onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),

                      const Spacer(),
                      _buildSubmitButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- WIDGETS TỐI ƯU ---

  Widget _buildBackButton() {
    return IconButton(
      onPressed: () => Navigator.pop(context),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
        child: const Icon(Icons.arrow_back_ios_new, size: 16),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tạo mật khẩu mới", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text("Hãy đặt mật khẩu mạnh để bảo vệ tài khoản của bạn.", style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleResetPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: const StadiumBorder(),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Xác nhận thay đổi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required FocusNode focusNode,
    required VoidCallback onToggleVisibility,
    String? errorText, // Thêm tham số errorText
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      focusNode: focusNode,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText, // Hiển thị chữ đỏ tự động nhờ Flutter SDK
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.black87)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 1)),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }
}