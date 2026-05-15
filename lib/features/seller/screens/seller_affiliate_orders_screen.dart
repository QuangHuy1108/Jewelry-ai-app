import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';

class SellerAffiliateOrdersScreen extends StatefulWidget {
  final String sellerId;
  const SellerAffiliateOrdersScreen({super.key, required this.sellerId});

  @override
  State<SellerAffiliateOrdersScreen> createState() => _SellerAffiliateOrdersScreenState();
}

class _SellerAffiliateOrdersScreenState extends State<SellerAffiliateOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _statuses = ['all', 'processing', 'reconciling', 'completed', 'cancelled'];
  final _statusLabels = ['All', 'Processing', 'Reconciling', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      appBar: AppBar(
        backgroundColor: AppColors.canvasParchment,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.ink), onPressed: () => Navigator.pop(context)),
        title: const Text('Affiliate Orders', style: TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.inkMuted48,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: _statusLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statuses.map((status) => _buildOrderList(status)).toList(),
      ),
    );
  }

  Widget _buildOrderList(String statusFilter) {
    Query query = FirebaseFirestore.instance
        .collection('seller_transactions')
        .where('sellerId', isEqualTo: widget.sellerId)
        .where('type', isEqualTo: 'commission')
        .orderBy('createdAt', descending: true);

    if (statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.limit(50).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: AppColors.inkMuted48)));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 56, color: AppColors.inkMuted48),
                const SizedBox(height: 12),
                Text('No $statusFilter orders', style: TextStyle(fontSize: 16, color: AppColors.inkMuted48)),
              ],
            ),
          );
        }

        // Summary header
        double totalCommission = 0;
        for (final doc in docs) {
          totalCommission += ((doc.data() as Map<String, dynamic>)['amount'] as num?)?.toDouble() ?? 0;
        }

        return Column(
          children: [
            // Summary bar
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.hairline.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${docs.length} Orders', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    Text(statusFilter == 'all' ? 'All statuses' : statusFilter.toUpperCase(), style: TextStyle(fontSize: 12, color: AppColors.inkMuted48)),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(_formatVND(totalCommission), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A8B4A))),
                    const Text('Total Commission', style: TextStyle(fontSize: 11, color: Color(0xFF1A8B4A))),
                  ]),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _buildOrderTile(data);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrderTile(Map<String, dynamic> data) {
    final status = data['status'] ?? 'processing';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final orderTotal = (data['orderTotal'] as num?)?.toDouble() ?? 0;
    final rate = (data['commissionRate'] as num?)?.toDouble() ?? 0.10;
    final desc = data['description'] ?? '';
    final date = (data['createdAt'] as Timestamp?)?.toDate();
    final orderId = data['orderId'] ?? '';

    final statusConfig = _getStatusConfig(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: statusConfig.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(statusConfig.icon, color: statusConfig.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(desc, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  if (orderId.isNotEmpty)
                    Text('#${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length).toUpperCase()}', style: TextStyle(fontSize: 11, color: AppColors.inkMuted48)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('+${_formatVND(amount)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: statusConfig.color)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusConfig.color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(statusConfig.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusConfig.color)),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.hairline.withOpacity(0.3)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order value: ${_formatVND(orderTotal)}', style: TextStyle(fontSize: 12, color: AppColors.inkMuted48)),
              Text('Rate: ${(rate * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, color: AppColors.inkMuted48)),
              if (date != null) Text('${date.day}/${date.month}/${date.year}', style: TextStyle(fontSize: 12, color: AppColors.inkMuted48)),
            ],
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'completed': return _StatusConfig('Successful', const Color(0xFF1A8B4A), Icons.check_circle);
      case 'reconciling': return _StatusConfig('Reconciling', const Color(0xFF0066CC), Icons.local_shipping);
      case 'cancelled': return _StatusConfig('Cancelled', Colors.red, Icons.cancel);
      default: return _StatusConfig('Processing', const Color(0xFFFF8C00), Icons.hourglass_bottom);
    }
  }

  String _formatVND(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M ₫';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K ₫';
    return '${amount.toStringAsFixed(0)} ₫';
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  final IconData icon;
  _StatusConfig(this.label, this.color, this.icon);
}
