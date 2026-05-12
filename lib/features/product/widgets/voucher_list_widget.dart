import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jewelry_app/services/coupon_service.dart';

class VoucherListWidget extends StatefulWidget {
  final double currentPrice;
  final Function(Map<String, dynamic>?) onVoucherSelected;

  const VoucherListWidget({
    super.key, 
    required this.currentPrice,
    required this.onVoucherSelected
  });

  @override
  State<VoucherListWidget> createState() => _VoucherListWidgetState();
}

class _VoucherListWidgetState extends State<VoucherListWidget> {
  String? _selectedVoucherId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: CouponService().getActiveCouponsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        // Filter to only usable vouchers (not expired, not maxed out)
        final vouchers = <Map<String, dynamic>>[];
        for (var doc in docs) {
          final data = doc.data();
          data['id'] = doc.id;
          
          bool isExpired = data['isExpired'] == true;
          if (!isExpired && data['expiresAt'] != null) {
            final expiryDate = (data['expiresAt'] as Timestamp).toDate();
            isExpired = expiryDate.isBefore(DateTime.now());
          }
          if (!isExpired && data['maxUses'] != null && data['usedCount'] != null) {
            isExpired = data['usedCount'] >= data['maxUses'];
          }
          if (!isExpired) {
            vouchers.add(data);
          }
        }

        if (vouchers.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Vouchers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: vouchers.length,
                itemBuilder: (context, index) {
                  final voucher = vouchers[index];
                  final double minSpend = (voucher['minSpend'] ?? 0).toDouble();
                  final bool isEligible = widget.currentPrice >= minSpend;
                  final bool isSelected = _selectedVoucherId == voucher['id'];

                  return GestureDetector(
                    onTap: isEligible
                        ? () {
                            setState(() {
                              if (isSelected) {
                                _selectedVoucherId = null;
                                widget.onVoucherSelected(null);
                              } else {
                                _selectedVoucherId = voucher['id'];
                                widget.onVoucherSelected(voucher);
                              }
                            });
                          }
                        : null,
                    child: Opacity(
                      opacity: isEligible ? 1.0 : 0.5,
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF333333) : Colors.white,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF333333) : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              voucher['discount'] ?? voucher['title'] ?? '',
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF333333),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              voucher['condition'] ?? '',
                              style: TextStyle(
                                color: isSelected ? Colors.white70 : Colors.grey.shade600,
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
