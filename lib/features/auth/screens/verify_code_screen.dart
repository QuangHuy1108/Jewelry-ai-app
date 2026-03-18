import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import '../../../router/app_router.dart';

class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({super.key});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> with SingleTickerProviderStateMixin {
  // Tạo danh sách 4 Controller và 4 FocusNode cho 4 ô OTP
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  // Bộ điều khiển hiệu ứng cho nút Verify
  late AnimationController _verifyButtonController;
  late Animation<double> _verifyButtonScale;

  @override
  void initState() {
    super.initState();
    // Lắng nghe sự thay đổi Focus để cập nhật viền cho ô OTP
    for (var node in _focusNodes) {
      node.addListener(() {
        setState(() {}); // Gọi build lại để vẽ lại viền
      });
    }

    _verifyButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _verifyButtonScale = Tween<double>(begin: 0.95, end: 1.0).animate(_verifyButtonController);
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _verifyButtonController.dispose();
    super.dispose();
  }

  // Logic chuyển ô tự động
  void _onOTPChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Nếu có nhập số và chưa phải ô cuối cùng -> Nhảy sang ô tiếp theo
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Nếu là ô cuối cùng, có thể tự động đóng bàn phím hoặc tự động Verify
        _focusNodes[index].unfocus();
      }
    } else {
      // Nếu người dùng xóa số (Backspace) và chưa phải ô đầu tiên -> Lùi về ô trước đó
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                        const SizedBox(height: 16),

                        // --- PHẦN 1: HEADER (Nút Back) ---
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () {
                              // Trượt về màn hình trước đó
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300, width: 1.5),
                              ),
                              child: Icon(Icons.arrow_back, color: Colors.grey.shade800),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // --- PHẦN 2: TIÊU ĐỀ & MÔ TẢ ---
                        const Text(
                          "Verify Code",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Please enter the code we just sent to email\nexample@email.com",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // --- PHẦN 3: KHỐI 4 Ô NHẬP MÃ OTP ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center, // Căn giữa toàn bộ 4 ô
                          children: List.generate(4, (index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0), // Khoảng cách (gap) giữa các ô
                              child: _buildOTPBox(index),
                            );
                          }),
                        ),
                        const SizedBox(height: 40),

                        // --- PHẦN 4: DÒNG HỖ TRỢ RESEND ---
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(fontSize: 14),
                            children: [
                              TextSpan(
                                text: "Didn't receive OTP? ",
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                              TextSpan(
                                text: "Resend code",
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()..onTap = () {
                                  // Xử lý gửi lại mã tại đây
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("A new code has been sent!")),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // --- PHẦN 5: NÚT VERIFY LỚN ---
                        GestureDetector(
                          onTapDown: (_) => _verifyButtonController.animateTo(0.95),
                          onTapUp: (_) {
                            _verifyButtonController.animateTo(1.0);
                            // Xử lý xác thực thành công -> Chuyển vào Home
                            Navigator.pushReplacementNamed(context, AppRouter.home);
                          },
                          onTapCancel: () => _verifyButtonController.animateTo(1.0),
                          child: ScaleTransition(
                            scale: _verifyButtonScale,
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade900,
                                borderRadius: BorderRadius.circular(28), // Bo góc viên thuốc
                              ),
                              child: const Center(
                                child: Text(
                                  "Verify",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Spacer đẩy mọi thứ lên trên, để trống phần đáy
                        const Spacer(),
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

  // Widget con: Ô nhập liệu OTP vuông
  Widget _buildOTPBox(int index) {
    bool isFocused = _focusNodes[index].hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6), // Nền xám nhạt
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // Đổi màu viền khi được chọn (Focus state)
          color: isFocused ? Colors.grey.shade600 : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number, // Bật bàn phím số
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          // Giới hạn chỉ nhập 1 ký tự, không hiển thị bộ đếm ở dưới
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly, // Chỉ cho phép nhập số
          ],
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "-", // Placeholder
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 24),
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) => _onOTPChanged(value, index),
        ),
      ),
    );
  }
}