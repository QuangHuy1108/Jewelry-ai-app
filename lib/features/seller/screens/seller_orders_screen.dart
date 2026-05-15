import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/seller_order_tile.dart';

class SellerOrdersScreen extends StatelessWidget {
  final String sellerId;
  const SellerOrdersScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.canvasParchment,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back, color: AppColors.ink, size: 22),
            ),
          ),
          title: const Text('Orders', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: -0.3,
          )),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.inkMuted48,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Shipped'),
              Tab(text: 'Delivered'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OrderListView(sellerId: sellerId),
            _OrderListView(sellerId: sellerId, statusFilter: 'pending'),
            _OrderListView(sellerId: sellerId, statusFilter: 'shipped'),
            _OrderListView(sellerId: sellerId, statusFilter: 'delivered'),
          ],
        ),
      ),
    );
  }
}

class _OrderListView extends StatelessWidget {
  final String sellerId;
  final String? statusFilter;

  const _OrderListView({required this.sellerId, this.statusFilter});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.ink));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox_outlined, size: 64, color: AppColors.inkMuted48),
                const SizedBox(height: 16),
                Text(
                  statusFilter != null ? 'No ${statusFilter} orders' : 'No orders yet',
                  style: const TextStyle(fontSize: 17, color: AppColors.inkMuted48),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return SellerOrderTile(
              orderId: doc.id,
              customerName: data['customerName'] ?? 'Customer',
              total: (data['totalAmount'] as num?)?.toDouble() ?? (data['total'] as num?)?.toDouble() ?? 0,
              status: data['status'] ?? 'pending',
              createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
              itemCount: (data['items'] as List?)?.length ?? 0,
              address: data['address'] is Map ? Map<String, dynamic>.from(data['address']) : null,
              onStatusUpdate: (newStatus) async {
                await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(doc.id)
                    .update({'status': newStatus});
              },
            );
          },
        );
      },
    );
  }
}
