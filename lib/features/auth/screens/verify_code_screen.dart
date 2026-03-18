import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../router/app_router.dart';

class VerifyCodeScreen extends StatefulWidget {
  final bool isFromForgotPassword;
  final String email;

  const VerifyCodeScreen({
    super.key,
    this.isFromForgotPassword = false,
    this.email = "your email"
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  late AnimationController _verifyButtonController;
  late Animation<double> _verifyButtonScale;

  Timer? _timer;
  int _start = 60;
  bool _canResend = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();

    for (var node in _focusNodes) {
      node.addListener(() => setState(() {}));
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

  void _startTimer() {
    _canResend = false;
    _start = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        if (mounted) {
          setState(() {
            _canResend = true;
            timer.cancel();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _start--;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) controller.dispose();
    for (var node in _focusNodes) node.dispose();
    _verifyButtonController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_isLoading) return;

    String otp = _controllers.map((e) => e.text).join();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the full 4-digit code")),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Simulating OTP verification delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      if (widget.isFromForgotPassword) {
        // Correctly navigate to New Password screen
        Navigator.pushReplacementNamed(context, AppRouter.newPassword);
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.signin);
      }
    }
  }

  void _onOTPChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _handleVerify(); // Auto-submit when last digit entered
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Verification", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text("Verify Code", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("Please enter the code sent to\n${widget.email}",
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, height: 1.5)),
            const SizedBox(height: 48),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _buildOTPBox(index),
              )),
            ),

            const SizedBox(height: 48),
            _buildResendSection(),
            const SizedBox(height: 40),
            _buildVerifyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        Text("Didn't receive OTP?", style: TextStyle(color: Colors.grey.shade500)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _canResend ? () {
            _startTimer();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("A new code has been sent!")));
          } : null,
          child: Text(
            _canResend ? "Resend code" : "Resend in ${_start}s",
            style: TextStyle(
              color: _canResend ? Colors.black87 : Colors.grey,
              fontWeight: FontWeight.bold,
              decoration: _canResend ? TextDecoration.underline : TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOTPBox(int index) {
    bool isFocused = _focusNodes[index].hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 60, height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isFocused ? Colors.black87 : Colors.transparent, width: 2),
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(border: InputBorder.none, hintText: "-"),
          onChanged: (value) => _onOTPChanged(value, index),
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return GestureDetector(
      onTapDown: (_) => _verifyButtonController.animateTo(0.95),
      onTapUp: (_) {
        _verifyButtonController.animateTo(1.0);
        _handleVerify();
      },
      onTapCancel: () => _verifyButtonController.animateTo(1.0),
      child: ScaleTransition(
        scale: _verifyButtonScale,
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(28)),
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Verify", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
