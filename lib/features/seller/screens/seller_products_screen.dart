import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import 'seller_add_product_screen.dart';

class SellerProductsScreen extends StatelessWidget {
  final String sellerId;
  const SellerProductsScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: const Text('My Products', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: -0.3,
        )),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => SellerAddProductScreen(sellerId: sellerId),
              ));
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('sellerId', isEqualTo: sellerId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
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
                  Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.inkMuted48),
                  const SizedBox(height: 16),
                  const Text('No products yet', style: TextStyle(
                    fontSize: 17, color: AppColors.inkMuted48, letterSpacing: -0.374,
                  )),
                  const SizedBox(height: 8),
                  const Text('Tap + to add your first product', style: TextStyle(
                    fontSize: 14, color: AppColors.bodyMuted,
                  )),
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
              return _ProductListItem(
                productId: doc.id,
                data: data,
                sellerId: sellerId,
              );
            },
          );
        },
      ),
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> data;
  final String sellerId;

  const _ProductListItem({
    required this.productId,
    required this.data,
    required this.sellerId,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['image'] ?? '';
    final name = data['name'] ?? '';
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final isActive = data['isActive'] ?? true;
    final category = data['category'] ?? '';
    final stock = (data['stock'] as num?)?.toInt() ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.canvasParchment,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : const Icon(Icons.diamond_outlined, color: AppColors.inkMuted48),
              ),
            ),
            const SizedBox(width: 14),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: -0.224,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(category, style: const TextStyle(
                    fontSize: 13, color: AppColors.inkMuted48,
                  )),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('\$${price.toStringAsFixed(0)}', style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink,
                      )),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Stock: $stock', style: const TextStyle(fontSize: 12, color: AppColors.inkMuted48)),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.inkMuted48, size: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: AppColors.canvas,
              onSelected: (value) async {
                if (value == 'toggle') {
                  await FirebaseFirestore.instance
                      .collection('products')
                      .doc(productId)
                      .update({'isActive': !isActive});
                } else if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Product'),
                      content: Text('Are you sure you want to delete "$name"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await FirebaseFirestore.instance.collection('products').doc(productId).delete();
                  }
                } else if (value == 'edit') {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SellerAddProductScreen(sellerId: sellerId, editProduct: {'id': productId, ...data}),
                  ));
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
                PopupMenuItem(value: 'toggle', child: Row(children: [Icon(isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18), const SizedBox(width: 8), Text(isActive ? 'Deactivate' : 'Activate')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
