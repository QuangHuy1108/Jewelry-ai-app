import 'package:flutter/material.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  // Logic ẩn/hiện mật khẩu độc lập cho 2 ô nhập liệu
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Controller để quản lý text (nếu cần xử lý logic sau này)
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Màu nền trắng chủ đạo
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
            ),
          ),
        ),
      ),
      // Sử dụng SafeArea và SingleChildScrollView để hỗ trợ Keyboard Avoiding
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // 1. Tiêu đề chính
              const Text(
                "New Password",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              // 2. Đoạn mô tả
              const Text(
                "Your new password must be different from\npreviously used passwords.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // 3. Khối nhập liệu 1: Password
              _buildInputLabel("Password"),
              _buildPasswordField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              ),

              const SizedBox(height: 24),

              // 4. Khối nhập liệu 2: Confirm Password
              _buildInputLabel("Confirm Password"),
              _buildPasswordField(
                controller: _confirmController,
                obscureText: _obscureConfirmPassword,
                onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),

              const SizedBox(height: 60),

              // 5. Nút bấm xác nhận "Create New Password"
              _buildSubmitButton(context),

              const SizedBox(height: 20), // Khoảng cách an toàn phía dưới
            ],
          ),
        ),
      ),
    );
  }

  // Widget xây dựng Nhãn (Label)
  Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF424242), // Xám đậm
          ),
        ),
      ),
    );
  }

  // Widget xây dựng Ô nhập liệu mật khẩu
  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Nền xám rất nhạt
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: "******",
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey,
            ),
            onPressed: onToggle,
          ),
        ),
        // Hiệu ứng khi focus: có thể thêm Border nếu muốn đổi màu nhẹ
      ),
    );
  }

  // Widget xây dựng Nút bấm xác nhận với hiệu ứng OnPress
  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          // Xử lý logic thành công và hiển thị thông báo
          _showSuccessDialog(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF212121), // Nền xám đậm (gần đen)
          foregroundColor: Colors.white,
          shape: const StadiumBorder(), // Hình viên thuốc
          elevation: 0,
        ),
        child: const Text(
          "Create New Password",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        ),
      ),
    );
  }

  // Hiệu ứng Popup thông báo thành công
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          "Password Changed Successfully!",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Đóng modal
              // Điều hướng về màn hình Sign In
            },
            child: const Text("Go to Login"),
          )
        ],
      ),
    );
  }
}