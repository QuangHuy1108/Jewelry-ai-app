import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../router/app_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email address")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Note: fetchSignInMethodsForEmail has been removed in newer Firebase Auth versions
      // to prevent email enumeration. We now directly call sendPasswordResetEmail.
      // If 'Email enumeration protection' is ENABLED in Firebase Console, this will 
      // always succeed even if the email doesn't exist.
      // If it is DISABLED, it will throw a 'user-not-found' error.
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reset link sent to your email!")),
        );
        // After sending, we go to OTP/Verify screen as requested by flow
        Navigator.pushNamed(
          context, 
          AppRouter.verifyCode, 
          arguments: {'email': email, 'isFromForgotPassword': true}
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = "An error occurred. Please try again.";
        if (e.code == 'user-not-found') {
          message = "No account found with this email address.";
        } else if (e.code == 'invalid-email') {
          message = "The email address is badly formatted.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An unexpected error occurred."))
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Forgot Password", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text("Reset Password", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              "Enter your registered email below to receive password reset instructions.",
              style: TextStyle(color: Colors.grey.shade500, height: 1.5),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email Address",
                hintText: "example@gmail.com",
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleResetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Send Reset Instructions", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
