import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/seller_stats_card.dart';
import '../widgets/commission_card.dart';
import '../widgets/clicks_chart.dart';
import 'seller_marketing_screen.dart';
import 'seller_affiliate_orders_screen.dart';
import 'seller_finance_screen.dart';
import 'seller_media_hub_screen.dart';
import 'seller_add_product_screen.dart';
import 'seller_products_screen.dart';
import 'become_seller_screen.dart';
import 'seller_edit_profile_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String? _sellerId;
  Map<String, dynamic> _sellerData = {};

  @override
  void initState() {
    super.initState();
    _initSeller();
  }

  Future<void> _initSeller() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Verify application is approved
    final appDoc = await _firestore.collection('seller_applications').doc(user.uid).get();
    if (!appDoc.exists || appDoc.data()?['status'] != 'approved') {
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BecomeSellerScreen()));
      }
      return;
    }

    // Check if this user is already a seller
    final sellerQuery = await _firestore
        .collection('sellers')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (sellerQuery.docs.isNotEmpty) {
      if (mounted) {
        setState(() {
          _sellerId = sellerQuery.docs.first.id;
          _sellerData = sellerQuery.docs.first.data();
        });
      }
    } else {
      // Create seller profile from approved application data
      final appData = appDoc.data()!;
      final docRef = await _firestore.collection('sellers').add({
        'userId': user.uid,
        'name': appData['fullName'] ?? user.displayName ?? 'My Store',
        'avatar': user.photoURL ?? '',
        'coverImage': '',
        'description': '',
        'referralCode': appData['referralCode'] ?? '',
        'promoCode': '',
        'mainPlatform': appData['mainPlatform'] ?? '',
        'channelLink': appData['channelLink'] ?? '',
        'experienceYears': 0,
        'totalSold': 0,
        'returningCustomers': 0.0,
        'followersCount': 0,
        'favoritesCount': 0,
        'rating': 0.0,
        'ratings': {},
        'commissionRate': 0.10,
        'pendingCommission': 0,
        'availableBalance': 0,
        'totalEarnings': 0,
        'totalClicks': 0,
        'totalConversions': 0,
        'bankName': '',
        'bankAccount': '',
        'bankHolder': '',
        'taxId': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() {
          _sellerId = docRef.id;
          _sellerData = {
            'name': appData['fullName'] ?? user.displayName ?? 'My Store',
            'avatar': user.photoURL ?? '',
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sellerId == null) {
      return const Scaffold(
        backgroundColor: AppColors.canvasParchment,
        body: Center(child: CircularProgressIndicator(color: AppColors.ink)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            // ─── Commission Overview (READ-ONLY from Firestore) ───
            SliverToBoxAdapter(child: _buildCommissionOverview()),
            // ─── Clicks & Conversions Chart ───
            SliverToBoxAdapter(child: _buildClicksSection()),
            // ─── Quick Actions Grid ───
            SliverToBoxAdapter(child: _buildQuickActions()),
            // ─── Recent Affiliate Orders ───
            SliverToBoxAdapter(child: _buildSectionHeader('Recent Orders', onSeeAll: () {
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => SellerAffiliateOrdersScreen(sellerId: _sellerId!)));
            })),
            _buildRecentOrders(),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SellerAddProductScreen(sellerId: _sellerId!)),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.bodyOnDark,
        icon: const Icon(Icons.add),
        label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    );
  }

  Widget _buildHeader() {
    final sellerName = _sellerData['name'] ?? 'My Store';
    final avatarUrl = _sellerData['avatar'] ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => SellerEditProfileScreen(sellerId: _sellerId!),
            )),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.hairline,
              backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty ? const Icon(Icons.store, color: AppColors.ink) : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back,', style: TextStyle(fontSize: 14, color: AppColors.inkMuted48, letterSpacing: -0.224)),
                Text(sellerName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: -0.3)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.hairline)),
              child: const Icon(Icons.close, size: 20, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionOverview() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('sellers').doc(_sellerId).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final pending = (data['pendingCommission'] as num?)?.toDouble() ?? 0;
          final available = (data['availableBalance'] as num?)?.toDouble() ?? 0;
          final totalEarnings = (data['totalEarnings'] as num?)?.toDouble() ?? 0;

          return Column(
            children: [
              // Main balance card
              CommissionCard(
                pendingCommission: pending,
                availableBalance: available,
                totalEarnings: totalEarnings,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: SellerStatsCard(
                    icon: Icons.trending_up,
                    label: 'Pending',
                    value: _formatCurrency(pending),
                    gradient: const [Color(0xFFFF8C00), Color(0xFFFFAD33)],
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: SellerStatsCard(
                    icon: Icons.account_balance_wallet,
                    label: 'Available',
                    value: _formatCurrency(available),
                    gradient: const [Color(0xFF1A8B4A), Color(0xFF2ECC71)],
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: SellerStatsCard(
                    icon: Icons.bar_chart,
                    label: 'Total',
                    value: _formatCurrency(totalEarnings),
                    gradient: const [Color(0xFF0066CC), Color(0xFF00A3FF)],
                  )),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildClicksSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('sellers').doc(_sellerId).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final clicks = (data['totalClicks'] as num?)?.toInt() ?? 0;
          final conversions = (data['totalConversions'] as num?)?.toInt() ?? 0;
          return ClicksChart(totalClicks: clicks, totalConversions: conversions);
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(Icons.link, 'Marketing\nTools', const Color(0xFF6C3CB4), () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => SellerMarketingScreen(sellerId: _sellerId!),
        ));
      }),
      _QuickAction(Icons.receipt_long, 'Affiliate\nOrders', const Color(0xFF0066CC), () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => SellerAffiliateOrdersScreen(sellerId: _sellerId!),
        ));
      }),
      _QuickAction(Icons.account_balance, 'Finance\n& Withdraw', const Color(0xFF1A8B4A), () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => SellerFinanceScreen(sellerId: _sellerId!),
        ));
      }),
      _QuickAction(Icons.photo_library, 'Media\nHub', const Color(0xFFE65100), () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const SellerMediaHubScreen(),
        ));
      }),
      _QuickAction(Icons.inventory_2_outlined, 'My\nProducts', const Color(0xFF424242), () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => SellerProductsScreen(sellerId: _sellerId!),
        ));
      }),
      _QuickAction(Icons.person_outline, 'Edit\nProfile', const Color(0xFF795548), () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => SellerEditProfileScreen(sellerId: _sellerId!),
        ));
      }),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: AppColors.ink)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: actions.map((a) => _buildActionTile(a)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(_QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline.withValues(alpha: 0.5)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: action.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(action.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.ink, height: 1.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: AppColors.ink)),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text('See All', style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w400)),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
    return SliverToBoxAdapter(
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('seller_transactions')
            .where('sellerId', isEqualTo: _sellerId)
            .where('type', isEqualTo: 'commission')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(children: [
                  Icon(Icons.receipt_long, size: 40, color: AppColors.inkMuted48),
                  const SizedBox(height: 8),
                  Text('No affiliate orders yet', style: TextStyle(color: AppColors.inkMuted48, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Share your referral link to start earning!', style: TextStyle(color: AppColors.inkMuted48, fontSize: 12)),
                ]),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildOrderTile(data);
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderTile(Map<String, dynamic> data) {
    final status = data['status'] ?? 'processing';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final desc = data['description'] ?? '';
    final date = (data['createdAt'] as Timestamp?)?.toDate();

    Color statusColor;
    switch (status) {
      case 'completed': statusColor = const Color(0xFF1A8B4A); break;
      case 'reconciling': statusColor = const Color(0xFF0066CC); break;
      case 'cancelled': statusColor = Colors.red; break;
      default: statusColor = const Color(0xFFFF8C00);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.receipt, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(date != null ? '${date.day}/${date.month}/${date.year}' : '', style: TextStyle(fontSize: 11, color: AppColors.inkMuted48)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatCurrency(amount), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: statusColor)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _QuickAction(this.icon, this.label, this.color, this.onTap);
}
