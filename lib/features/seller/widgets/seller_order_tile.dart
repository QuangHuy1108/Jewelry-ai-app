import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SellerOrderTile extends StatelessWidget {
  final String orderId;
  final String customerName;
  final double total;
  final String status;
  final DateTime? createdAt;
  final int itemCount;
  final Map<String, dynamic>? address;
  final void Function(String newStatus)? onStatusUpdate;

  const SellerOrderTile({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.total,
    required this.status,
    this.createdAt,
    this.itemCount = 0,
    this.address,
    this.onStatusUpdate,
  });

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  Color get _statusColor {
    switch (status) {
      case 'pending': return const Color(0xFFFF9800);
      case 'shipped': return const Color(0xFF2196F3);
      case 'delivered': return const Color(0xFF4CAF50);
      case 'cancelled': return const Color(0xFFF44336);
      default: return AppColors.inkMuted48;
    }
  }

  Color get _statusBgColor {
    switch (status) {
      case 'pending': return const Color(0xFFFFF3E0);
      case 'shipped': return const Color(0xFFE3F2FD);
      case 'delivered': return const Color(0xFFE8F5E9);
      case 'cancelled': return const Color(0xFFFFEBEE);
      default: return AppColors.canvasParchment;
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case 'pending': return Icons.schedule;
      case 'shipped': return Icons.local_shipping_outlined;
      case 'delivered': return Icons.check_circle_outline;
      case 'cancelled': return Icons.cancel_outlined;
      default: return Icons.info_outline;
    }
  }

  bool get _hasAddress {
    if (address == null || address!.isEmpty) return false;
    return (address!['detail'] ?? address!['address'] ?? '').toString().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = createdAt != null
        ? '${_months[createdAt!.month - 1]} ${createdAt!.day.toString().padLeft(2, '0')}, ${createdAt!.year}'
        : '—';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${orderId.substring(0, orderId.length.clamp(0, 8)).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: AppColors.inkMuted48),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(customerName, style: const TextStyle(
                              fontSize: 13, color: AppColors.inkMuted48,
                            ), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon, size: 14, color: _statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ─── Shipping Address ───────────────────
            if (_hasAddress) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD0E4F7)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Color(0xFF2196F3)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address!['name'] ?? address!['type'] ?? 'Shipping',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            address!['detail'] ?? address!['address'] ?? '',
                            style: const TextStyle(fontSize: 12, color: AppColors.inkMuted48, height: 1.3),
                          ),
                          if ((address!['city'] ?? address!['landmark'] ?? '').toString().isNotEmpty)
                            Text(
                              address!['city'] ?? address!['landmark'] ?? '',
                              style: const TextStyle(fontSize: 12, color: AppColors.inkMuted48),
                            ),
                          if ((address!['phone'] ?? address!['floor'] ?? '').toString().isNotEmpty)
                            Text(
                              address!['phone'] ?? address!['floor'] ?? '',
                              style: const TextStyle(fontSize: 12, color: AppColors.inkMuted48),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            // Footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.canvasParchment,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formattedDate, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted48)),
                      const SizedBox(height: 2),
                      Text('$itemCount ${itemCount == 1 ? 'item' : 'items'}', style: const TextStyle(
                        fontSize: 12, color: AppColors.inkMuted48,
                      )),
                    ],
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            // Status update button
            if (onStatusUpdate != null && status != 'delivered' && status != 'cancelled') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    final nextStatus = status == 'pending' ? 'shipped' : 'delivered';
                    onStatusUpdate?.call(nextStatus);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.bodyOnDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(
                    status == 'pending' ? 'Mark as Shipped' : 'Mark as Delivered',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
