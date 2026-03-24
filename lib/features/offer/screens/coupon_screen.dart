import 'package:flutter/material.dart';
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
  bool _isLoading = true;
  List<Map<String, dynamic>> _coupons = [];

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() => _isLoading = true);
    // Simulate API fetch delay
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _coupons = [
          {
            "code": "WELCOME200",
            "condition": "Min. spend \$500. Valid for first order.",
            "discount": "Get \$200 OFF",
          },
          {
            "code": "GOLDENSET",
            "condition": "Valid for Gold jewelry sets only.",
            "discount": "Get 15% OFF",
          },
          {
            "code": "FREESHIP",
            "condition": "Free shipping on all orders over \$100.",
            "discount": "Free Shipping",
          },
          {
            "code": "EXPIRED10",
            "condition": "Halloween special offer.",
            "discount": "Get 10% OFF",
            "isExpired": true,
          },
        ];
      });
    }
  }

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
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 24, bottom: 16),
              child: const Text(
                'Vouchers for you',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? _buildLoadingList()
                  : _coupons.isEmpty
                      ? _buildEmptyState()
                      : _buildCouponList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 70, // Height: 60px - 80px
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
      ),
      child: Row(
        children: [
          // Circular Back Button
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
          const SizedBox(width: 40), // Balance
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadCoupons,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333333),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponList() {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    
    return ListView.separated(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 20 + bottomPadding,
      ),
      itemCount: _coupons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final coupon = _coupons[index];
        
        // Entrance: Slide-up or Fade-in for the list (Duration: 400ms).
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
              if (widget.cartItemId != null && !(coupon['isExpired'] ?? false)) {
                Navigator.pop(context, coupon);
              }
            },
            child: CouponCard(
              code: coupon['code'],
              condition: coupon['condition'],
              discount: coupon['discount'],
              isExpired: coupon['isExpired'] ?? false,
            ),
          ),
        );
      },
    );
  }
}
