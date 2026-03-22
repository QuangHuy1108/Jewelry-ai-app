import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

import '../../home/widgets/bottom_nav.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final items = cart.items;
    
    // Calculate super simple total
    double total = 0;
    for (var item in items) {
      double price = (item['price'] ?? 0.0) is num ? (item['price'] as num).toDouble() : 0.0;
      int qty = item['qty'] as int? ?? 1;
      total += price * qty;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text("My Cart", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF333333))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF333333)),
      ),
      body: items.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildCartItem(context, item, index, cart);
                    },
                  ),
                ),
                _buildCheckoutBar(context, total),
              ],
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

  Widget _buildCartItem(BuildContext context, Map item, int index, CartProvider cart) {
    String name = item['name'] ?? 'Unknown Item';
    String image = item['image'] ?? '';
    String size = item['size'] ?? 'N/A';
    String purity = item['purity'] ?? 'N/A';
    double price = (item['price'] ?? 0.0) is num ? (item['price'] as num).toDouble() : 0.0;
    int qty = item['qty'] as int? ?? 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, 2), blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Size: $size | Purity: $purity', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('\$${price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333))),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFEEEEEE)), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (qty > 1) {
                                cart.items[index]['qty'] = qty - 1;
                                // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                                cart.notifyListeners();
                              } else {
                                cart.items.removeAt(index);
                                // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                                cart.notifyListeners();
                              }
                            },
                            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Icon(Icons.remove, size: 16, color: Color(0xFF333333))),
                          ),
                          Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          GestureDetector(
                            onTap: () {
                              cart.items[index]['qty'] = qty + 1;
                              // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                              cart.notifyListeners();
                            },
                            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Icon(Icons.add, size: 16, color: Color(0xFF333333))),
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
    );
  }

  Widget _buildCheckoutBar(BuildContext context, double total) {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, offset: Offset(0, -2), blurRadius: 10)],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF999999))),
                Text('\$${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proceeding to Checkout...')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}