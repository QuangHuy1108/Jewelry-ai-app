import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../router/app_router.dart';

class EnableNotificationScreen extends StatefulWidget {
  const EnableNotificationScreen({Key? key}) : super(key: key);

  @override
  State<EnableNotificationScreen> createState() => _EnableNotificationScreenState();
}

class _EnableNotificationScreenState extends State<EnableNotificationScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _shakeController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _entranceController.forward().then((_) {
      _shakeController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // LOGIC: Handle Allow (Request system permission)
  Future<void> _handleAllowNotification() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Request permission
      // This triggers the system dialog on Android 13+.
      // We await the result. If the dialog shows, this will wait for the user to interact.
      final status = await Permission.notification.request();

      // 2. Save state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notificationsEnabled', status.isGranted);
    } catch (e) {
      debugPrint("Error requesting notification permission: $e");
    } finally {
      // 3. Navigate to Location Permission screen after the request interaction is complete.
      // We use a small delay to ensure the app has resumed focus from the system dialog.
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context, 
              AppRouter.locationPermission, 
            );
          }
        });
      }
    }
  }

  // LOGIC: Handle Maybe Later
  Future<void> _handleMaybeLater() async {
    if (_isProcessing) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', false);

    if (mounted) {
      Navigator.pushReplacementNamed(
        context, 
        AppRouter.locationPermission,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      final sineValue = math.sin(_shakeController.value * math.pi * 6);
                      final dampening = 1.0 - _shakeController.value;
                      final angle = sineValue * dampening * 0.3;

                      return Transform.rotate(
                        angle: angle,
                        alignment: Alignment.topCenter,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 50,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  const Text(
                    "Enable Notification Access",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "Enable notifications to receive\nreal-time updates.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),

                  const Spacer(flex: 2),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _handleAllowNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              "Allow Notification",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: TextButton(
                      onPressed: _isProcessing ? null : _handleMaybeLater,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        "Maybe Later",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
