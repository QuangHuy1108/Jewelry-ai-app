import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import 'become_seller_screen.dart';

class SellerApplicationStatusScreen extends StatelessWidget {
  const SellerApplicationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.ink), onPressed: () => Navigator.pop(context)),
        title: const Text('Application Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('seller_applications').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.ink));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildNoApplication(context);
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'pending';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildStatusCard(status, data),
                const SizedBox(height: 24),
                _buildApplicationDetails(data),
                if (status == 'rejected') ...[
                  const SizedBox(height: 24),
                  _buildReapplyButton(context),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoApplication(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront_outlined, size: 64, color: AppColors.inkMuted48),
            const SizedBox(height: 16),
            const Text('No Application Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 8),
            Text('Start your seller journey today!', style: TextStyle(fontSize: 14, color: AppColors.inkMuted48)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BecomeSellerScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text('Apply Now', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status, Map<String, dynamic> data) {
    IconData icon;
    Color color;
    Color bgColor;
    String title;
    String subtitle;

    switch (status) {
      case 'approved':
        icon = Icons.check_circle;
        color = const Color(0xFF4CAF50);
        bgColor = const Color(0xFFE8F5E9);
        title = 'Application Approved!';
        subtitle = 'Congratulations! You can now access your Seller Dashboard.';
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = const Color(0xFFF44336);
        bgColor = const Color(0xFFFFEBEE);
        title = 'Application Rejected';
        subtitle = data['rejectionReason']?.isNotEmpty == true
            ? 'Reason: ${data['rejectionReason']}'
            : 'Your application was not approved. You may reapply.';
        break;
      default:
        icon = Icons.hourglass_top;
        color = const Color(0xFFFF9800);
        bgColor = const Color(0xFFFFF3E0);
        title = 'Under Review';
        subtitle = 'Your application is being reviewed by our team. We\'ll notify you once a decision is made.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 56, color: color),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: color.withOpacity(0.8), height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildApplicationDetails(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
          const SizedBox(height: 16),
          _detailRow('Full Name', data['fullName'] ?? ''),
          _detailRow('Email', data['email'] ?? ''),
          _detailRow('Phone', data['phone'] ?? ''),
          const Divider(height: 24),
          _detailRow('Platform', data['mainPlatform'] ?? ''),
          _detailRow('Channel', data['channelLink'] ?? '', isLink: true),
          _detailRow('Referral Code', data['referralCode'] ?? '—'),
          const Divider(height: 24),
          _detailRow('Bank', data['bankName'] ?? ''),
          _detailRow('Account', _maskString(data['accountNumber'] ?? '')),
          _detailRow('Holder', data['accountHolderName'] ?? ''),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.inkMuted48)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isLink ? AppColors.primary : AppColors.ink,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _maskString(String s) {
    if (s.length <= 4) return s;
    return '${'*' * (s.length - 4)}${s.substring(s.length - 4)}';
  }

  Widget _buildReapplyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BecomeSellerScreen())),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        icon: const Icon(Icons.refresh, size: 20),
        label: const Text('Reapply', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
