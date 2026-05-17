import 'package:flutter/material.dart';
import 'package:jewelry_app/router/app_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../notification/providers/notification_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildMenuItem(
                      context,
                      icon: Icons.notifications_none,
                      title: 'Notification Settings',
                      onTap: () => Navigator.pushNamed(context, AppRouter.notificationSettings),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                    _buildMenuItem(
                      context,
                      icon: Icons.key_outlined,
                      title: 'Password Manager',
                      onTap: () => Navigator.pushNamed(context, AppRouter.passwordManager),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                    _buildMenuItem(
                      context,
                      icon: Icons.shield_outlined,
                      title: 'Privacy Policy',
                      onTap: () => Navigator.pushNamed(context, AppRouter.privacyPolicy),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                    _buildMenuItem(
                      context,
                      icon: Icons.delete_outline,
                      title: 'Delete Account',
                      onTap: () => Navigator.pushNamed(context, AppRouter.deleteAccount),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                    
                    // Phase 3: AI Predictive Engine Debug Trigger
                    const SizedBox(height: 24),
                    _buildMenuItem(
                      context,
                      icon: Icons.science_outlined,
                      title: 'Debug: Run AI Golden Hour Analysis',
                      onTap: () => _runAIGoldenHourAnalysis(context),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEEEEEE)),
                color: Colors.white,
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF333333), size: 20),
            ),
          ),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF777777), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  Future<void> _runAIGoldenHourAnalysis(BuildContext context) async {
    // Show a loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Seeding mock data and running AI Pipeline...'),
        duration: Duration(seconds: 3),
      ),
    );

    try {
      // 1. Seed mock data
      await context.read<NotificationProvider>().seedNotificationEvents();

      // 2. Trigger Cloud Function
      final result = await FirebaseFunctions.instance.httpsCallable('calculateOptimalEngagementHours').call();
      debugPrint('Cloud Function result: ${result.data}');

      // 3. Fetch latest result from Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final optimalHourUtc = doc.data()?['analytics']?['optimalEngagementHour'] as int?;
if (optimalHourUtc != null && context.mounted) {
  // Lấy giờ UTC convert sang giờ Local của thiết bị
  final now = DateTime.now();
  final utcTime = DateTime.utc(now.year, now.month, now.day, optimalHourUtc);
  final localHour = utcTime.toLocal().hour;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('✅ AI Analysis complete! Your golden hour is: $localHour:00 (Local Time)'),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 5),
    ),
  );
}
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error running AI Analysis: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
