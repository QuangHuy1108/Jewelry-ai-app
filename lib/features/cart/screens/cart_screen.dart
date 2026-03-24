import 'package:jewelry_app/core/utils/luxury_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/edit_cart_item_sheet.dart';
import '../../offer/screens/coupon_screen.dart';
import '../../../router/app_navigation.dart';
import '../../../router/app_router.dart';
import '../../home/widgets/bottom_nav.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text("My Cart", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF333333))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF333333)),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              _buildSelectAllHeader(cart),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _buildCartItem(context, item, index, cart);
                  },
                ),
              ),
              _buildCheckoutBar(context, cart),
            ],
          );
        },
      ),
      bottomNavigationBar: const BottomNav(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 80, color: Color(0xFFDDDDDD)),
          const SizedBox(height: 16),
          const Text("Your cart is empty", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF333333),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text("Continue Shopping"),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectAllHeader(CartProvider cart) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: cart.isAllSelected,
            activeColor: const Color(0xFFD4AF37),
            onChanged: (val) {
              if (val != null) cart.toggleAllSelection(val);
            },
          ),
          const Text("Select All", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, Map<String, dynamic> item, int index, CartProvider cart) {
    String name = item['name'] ?? 'Unknown Item';
    String image = item['image'] ?? '';
    String category = item['category'] ?? '';
    double price = (item['price'] ?? 0.0) is num ? (item['price'] as num).toDouble() : 0.0;
    double originalPrice = (item['originalPrice'] ?? price) is num ? ((item['originalPrice'] ?? price) as num).toDouble() : price;
    int qty = item['qty'] as int? ?? 1;
    bool isSelected = item['isSelected'] ?? false;
    
    final options = item['selectedOptions'] as Map<String, dynamic>? ?? {};
    String size = options['size'] ?? 'N/A';
    String purity = options['purity'] ?? 'N/A';

    return Dismissible(
      key: Key("${item['id']}_$index"),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await _showRemoveConfirmation(context, item, index, cart);
      },
      background: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline, color: Color(0xFF555555), size: 24),
        ),
      ),
      child: GestureDetector(
        onTap: () {
          AppNavigation.toProductDetail(context, product: {'id': item['id'], 'name': name});
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, 2), blurRadius: 8)],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: isSelected,
                    activeColor: const Color(0xFFD4AF37),
                    onChanged: (_) => cart.toggleItemSelection(index),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                      image: image.isEmpty ? null : DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => EditCartItemSheet(itemIndex: index, currentItem: item),
                                );
                              },
                              child: const Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF999999))),
                            )
                          ],
                        ),
                        if (category.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(category, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                        ],
                        const SizedBox(height: 4),
                        Text('Size: $size | Purity: $purity', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333))),
                                if (originalPrice > price) ...[
                                  const SizedBox(width: 6),
                                  Text('\$${originalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF999999), decoration: TextDecoration.lineThrough)),
                                ],
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFEEEEEE)), borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => cart.updateQty(index, qty - 1),
                                    child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Icon(Icons.remove, size: 16, color: Color(0xFF333333))),
                                  ),
                                  Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  GestureDetector(
                                    onTap: () => cart.updateQty(index, qty + 1),
                                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Icon(Icons.add, size: 16, color: Colors.grey.shade800)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Voucher Inline UI 
              GestureDetector(
                onTap: () async {
                  final selectedVoucher = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CouponScreen(
                        cartItemId: item['id'],
                        selectedVoucher: item['voucher'],
                      ),
                    ),
                  );
                  if (selectedVoucher != null) {
                    cart.applyVoucher(index, selectedVoucher);
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_num_outlined, size: 16, color: Color(0xFFD4AF37)),
                    const SizedBox(width: 8),
                    Text(item['voucher']?['code'] ?? 'Best Voucher Available', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                    const Spacer(),
                    Text(item['voucher'] != null ? item['voucher']['discount'] : '10% OFF', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ========== DELETE CONFIRMATION BOTTOM SHEET ==========
  Future<bool> _showRemoveConfirmation(BuildContext context, Map<String, dynamic> item, int index, CartProvider cart) async {
    String name = item['name'] ?? 'Unknown Item';
    String image = item['image'] ?? '';
    String category = item['category'] ?? '';
    double price = (item['price'] ?? 0.0) is num ? (item['price'] as num).toDouble() : 0.0;
    double originalPrice = (item['originalPrice'] ?? price) is num ? ((item['originalPrice'] ?? price) as num).toDouble() : price;

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              const Text(
                'Remove from Cart?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 20),
              // Divider
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 16),
              // Product info row
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      image: image.isEmpty
                          ? null
                          : DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF333333)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (category.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(category, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF333333))),
                            if (originalPrice > price) ...[
                              const SizedBox(width: 8),
                              Text('\$${originalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Color(0xFF999999), decoration: TextDecoration.lineThrough)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 16),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF555555))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF333333),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('Yes, Remove', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (result == true) {
      cart.removeItem(index);
      if (context.mounted) {
        LuxuryToast.show(context, message: '$name removed from cart');
      }
    }
    return false; // Always return false — we already handled removal manually above
  }

  // ========== CHECKOUT COST BREAKDOWN ==========
  Widget _buildCheckoutBar(BuildContext context, CartProvider cart) {
    final subTotal = cart.totalSelectedPrice;
    final discount = cart.totalDiscount;
    final delivery = cart.deliveryCharge;
    final tax = cart.tax;
    final grandTotal = cart.grandTotal;

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, offset: Offset(0, -2), blurRadius: 10)],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Promo Code Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Promo Code',
                        hintStyle: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      LuxuryToast.show(context, message: 'Promo code applied!');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF333333),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text('Apply', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Cost breakdown
            _costRow('Sub-Total', '\$${subTotal.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _costRow('Delivery Charge', '\$${delivery.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _costRow('Tax', '\$${tax.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            if (discount > 0) ...[
              _costRow('Discount', '-\$${discount.toStringAsFixed(2)}', valueColor: Colors.green),
              const SizedBox(height: 8),
            ],
            const Divider(),
            const SizedBox(height: 4),
            _costRow('Total Cost', '\$${grandTotal.toStringAsFixed(2)}', isBold: true),
            const SizedBox(height: 16),
            // Checkout button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: grandTotal == 0 ? null : () {
                  final selectedCount = cart.selectedItems.length;
                  if (selectedCount == 0) {
                    LuxuryToast.show(context, message: 'Please select items to checkout');
                    return;
                  }
                  Navigator.pushNamed(context, AppRouter.checkout);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _costRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: const Color(0xFF666666))),
        Text(value, style: TextStyle(fontSize: isBold ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: valueColor ?? const Color(0xFF333333))),
      ],
    );
  }
}