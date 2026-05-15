import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jewelry_app/core/utils/luxury_toast.dart';
import 'package:jewelry_app/router/app_router.dart';
import 'package:jewelry_app/features/offer/screens/coupon_screen.dart';
import 'package:jewelry_app/services/user_service.dart';
import '../../home/widgets/bottom_nav.dart';
import '../../seller/screens/become_seller_screen.dart';
import '../../seller/screens/seller_application_status_screen.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Elowen Sutter';
    final photoUrl = user?.photoURL;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      bottomNavigationBar: const BottomNav(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: user != null ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots() : const Stream.empty(),
                  builder: (context, snapshot) {
                    String display = userName;
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data();
                      if (data != null && data['name'] != null && data['name'].toString().isNotEmpty) {
                        display = data['name'];
                      }
                    }
                    // Use Firestore avatar if available, fallback to Auth photoURL
                    String? avatarToShow = photoUrl;
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final avatarData = snapshot.data!.data();
                      if (avatarData != null && avatarData['avatar'] != null && avatarData['avatar'].toString().isNotEmpty) {
                        avatarToShow = avatarData['avatar'];
                      }
                    }
                    return Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildProfileAvatar(avatarToShow),
                        const SizedBox(height: 16),
                        Text(
                          display,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildMenuItems(context),
                        const SizedBox(height: 24),
                        _buildLogoutButton(context),
                        const SizedBox(height: 40),
                      ],
                    );
                  }
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
            'Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 44), // To balance the back button
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String? photoUrl) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE0E0E0),
              image: (photoUrl != null && photoUrl.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF777777),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Your profile',
            onTap: () => Navigator.pushNamed(context, AppRouter.editProfile),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.location_on_outlined,
            title: 'Manage Address',
            onTap: () => Navigator.pushNamed(context, AppRouter.manageAddress),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.credit_card_outlined,
            title: 'Payment Methods',
            onTap: () => Navigator.pushNamed(context, AppRouter.paymentMethods),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.assignment_outlined,
            title: 'My Orders',
            onTap: () => Navigator.pushNamed(context, AppRouter.myOrders),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.confirmation_num_outlined,
            title: 'My Vouchers',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CouponScreen())),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.account_balance_wallet_outlined,
            title: 'My Wallet',
            onTap: () => Navigator.pushNamed(context, AppRouter.wallet),
          ),
          _buildDivider(),
          _buildSellerMenuItem(context),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () => Navigator.pushNamed(context, AppRouter.settings),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'Help Center',
            onTap: () => Navigator.pushNamed(context, AppRouter.helpCenter),
            hideDivider: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool hideDivider = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF777777)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerMenuItem(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildMenuItem(
        icon: Icons.storefront_outlined,
        title: 'Become a Seller',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BecomeSellerScreen())),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('seller_applications').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildMenuItem(
            icon: Icons.storefront_outlined,
            title: 'Become a Seller',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BecomeSellerScreen())),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'pending';

        switch (status) {
          case 'approved':
            return _buildMenuItem(
              icon: Icons.storefront,
              title: 'Seller Dashboard',
              onTap: () => Navigator.pushNamed(context, AppRouter.sellerDashboard),
            );
          case 'pending':
            return _buildMenuItem(
              icon: Icons.hourglass_top,
              title: 'Application Pending',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerApplicationStatusScreen())),
            );
          case 'rejected':
            return _buildMenuItem(
              icon: Icons.storefront_outlined,
              title: 'Reapply as Seller',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerApplicationStatusScreen())),
            );
          default:
            return _buildMenuItem(
              icon: Icons.storefront_outlined,
              title: 'Become a Seller',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BecomeSellerScreen())),
            );
        }
      },
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: const Color(0xFFEEEEEE).withAlpha(128),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: () async {
            // Set offline before signing out
            await UserService().setOnlineStatus(false);
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(context, AppRouter.splash, (route) => false);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFEEEEEE)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(27),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Log Out',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDD3333),
            ),
          ),
        ),
      ),
    );
  }
}
