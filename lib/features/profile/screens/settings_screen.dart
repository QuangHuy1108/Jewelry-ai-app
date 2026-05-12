import 'package:flutter/material.dart';
import 'package:jewelry_app/router/app_router.dart';

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
}
