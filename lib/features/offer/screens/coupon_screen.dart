import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jewelry_app/services/coupon_service.dart';
import '../widgets/coupon_card.dart';

class CouponScreen extends StatefulWidget {
  final String? cartItemId;
  final Map<String, dynamic>? selectedVoucher;

  const CouponScreen({
    super.key,
    this.cartItemId,
    this.selectedVoucher,
  });

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  final CouponService _couponService = CouponService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const Padding(
              padding: EdgeInsets.only(left: 20, top: 24, bottom: 16),
              child: Text(
                'Vouchers for you',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _couponService.getActiveCouponsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingList();
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) return _buildEmptyState();
                  return _buildCouponList(docs);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF333333), size: 20),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Voucher',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => const ShimmerCouponCard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sentiment_dissatisfied_outlined, size: 80, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 16),
            const Text(
              'You have no vouchers available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    
    return ListView.separated(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 20 + bottomPadding,
      ),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final doc = docs[index];
        final coupon = doc.data();
        coupon['docId'] = doc.id;

        // Check if expired
        bool isExpired = coupon['isExpired'] == true;
        if (!isExpired && coupon['expiresAt'] != null) {
          final expiryDate = (coupon['expiresAt'] as Timestamp).toDate();
          isExpired = expiryDate.isBefore(DateTime.now());
        }
        // Check usage
        if (!isExpired && coupon['maxUses'] != null && coupon['usedCount'] != null) {
          isExpired = coupon['usedCount'] >= coupon['maxUses'];
        }

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: child,
              ),
            );
          },
          child: GestureDetector(
            onTap: () {
              if (widget.cartItemId != null && !isExpired) {
                Navigator.pop(context, coupon);
              }
            },
            child: CouponCard(
              code: coupon['code'] ?? '',
              condition: coupon['condition'] ?? '',
              discount: coupon['discount'] ?? '',
              isExpired: isExpired,
            ),
          ),
        );
      },
    );
  }
}
