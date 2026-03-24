import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jewelry_app/core/utils/luxury_toast.dart';
import '../../cart/providers/cart_provider.dart';
import '../../offer/screens/coupon_screen.dart';
import '../models/order_model.dart';
import '../../../router/app_router.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;

  // Address
  final Map<String, dynamic> _address = {
    'name': 'Home',
    'detail': '123 Le Loi Street, District 1',
    'city': 'Ho Chi Minh City, Vietnam',
    'phone': '+84 912 345 678',
  };

  // Shipping
  String _selectedShipping = 'premium';
  final Map<String, Map<String, dynamic>> _shippingOptions = {
    'premium': {'label': 'Insured Premium Delivery', 'desc': '2-3 business days', 'fee': 20.0, 'icon': Icons.local_shipping_outlined},
    'express': {'label': 'Express Delivery', 'desc': 'Next day delivery', 'fee': 35.0, 'icon': Icons.flight_outlined},
    'standard': {'label': 'Standard Delivery', 'desc': '5-7 business days', 'fee': 0.0, 'icon': Icons.inventory_2_outlined},
  };

  // Payment
  String _selectedPayment = 'cod';
  final List<Map<String, dynamic>> _paymentOptions = [
    {'id': 'card', 'label': 'Credit Card', 'icon': Icons.credit_card},
    {'id': 'apple', 'label': 'Apple Pay', 'icon': Icons.apple},
    {'id': 'cod', 'label': 'Cash on Delivery', 'icon': Icons.money},
  ];

  // Voucher
  Map<String, dynamic>? _orderVoucher;
  double _voucherDiscount = 0;

  double get _shippingFee => _shippingOptions[_selectedShipping]!['fee'] as double;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF333333))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF333333)),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          final items = cart.selectedItems;
          if (items.isEmpty) {
            return const Center(child: Text('No items selected', style: TextStyle(fontSize: 16, color: Color(0xFF999999))));
          }

          final subTotal = cart.totalSelectedPrice;
          final itemDiscount = cart.totalDiscount;
          final totalDiscount = itemDiscount + _voucherDiscount;
          final total = subTotal + _shippingFee - _voucherDiscount;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAddressSection(),
                      const SizedBox(height: 16),
                      _buildShippingSection(),
                      const SizedBox(height: 16),
                      _buildPaymentSection(),
                      const SizedBox(height: 16),
                      _buildProductSummary(items),
                      const SizedBox(height: 16),
                      _buildVoucherSection(),
                      const SizedBox(height: 16),
                      _buildOrderSummary(subTotal, totalDiscount, _shippingFee, total),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _buildPlaceOrderButton(context, cart, items, subTotal, totalDiscount, total),
            ],
          );
        },
      ),
    );
  }

  // ===== ADDRESS SECTION =====
  Widget _buildAddressSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 18, color: Color(0xFFD4AF37)),
                  SizedBox(width: 8),
                  Text('Shipping Address', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                ],
              ),
              GestureDetector(
                onTap: () => LuxuryToast.show(context, message: 'Address selection coming soon'),
                child: const Text('Change', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_address['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
          const SizedBox(height: 4),
          Text(_address['detail'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF777777))),
          Text(_address['city'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF777777))),
          const SizedBox(height: 4),
          Text(_address['phone'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF777777))),
        ],
      ),
    );
  }

  // ===== SHIPPING METHOD =====
  Widget _buildShippingSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_shipping_outlined, size: 18, color: Color(0xFFD4AF37)),
              SizedBox(width: 8),
              Text('Shipping Method', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            ],
          ),
          const SizedBox(height: 12),
          ..._shippingOptions.entries.map((e) {
            final key = e.key;
            final opt = e.value;
            final isSelected = _selectedShipping == key;
            return GestureDetector(
              onTap: () => setState(() => _selectedShipping = key),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFBF7EE) : Colors.white,
                  border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFFEEEEEE)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(opt['icon'] as IconData, size: 20, color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF999999)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(opt['label'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF333333) : const Color(0xFF777777))),
                          Text(opt['desc'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
                        ],
                      ),
                    ),
                    Text(
                      (opt['fee'] as double) == 0 ? 'FREE' : '\$${(opt['fee'] as double).toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF777777)),
                    ),
                    const SizedBox(width: 8),
                    Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, size: 18, color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFFCCCCCC)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===== PAYMENT METHOD =====
  Widget _buildPaymentSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment_outlined, size: 18, color: Color(0xFFD4AF37)),
              SizedBox(width: 8),
              Text('Payment Method', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _paymentOptions.map((opt) {
              final isSelected = _selectedPayment == opt['id'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPayment = opt['id']),
                  child: Container(
                    margin: EdgeInsets.only(right: opt != _paymentOptions.last ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFBF7EE) : Colors.white,
                      border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFFEEEEEE)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(opt['icon'] as IconData, size: 22, color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF999999)),
                        const SizedBox(height: 6),
                        Text(opt['label'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF333333) : const Color(0xFF999999))),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===== PRODUCT SUMMARY =====
  Widget _buildProductSummary(List<Map<String, dynamic>> items) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 18, color: Color(0xFFD4AF37)),
              const SizedBox(width: 8),
              Text('Order Items (${items.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            final name = item['name'] ?? '';
            final image = item['image'] ?? '';
            final price = (item['price'] ?? 0.0) is num ? (item['price'] as num).toDouble() : 0.0;
            final qty = item['qty'] as int? ?? 1;
            final opts = item['selectedOptions'] as Map<String, dynamic>? ?? {};

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
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
                        Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text(
                          [
                            if (opts['size'] != null && opts['size'] != 'N/A') opts['size'],
                            if (opts['material'] != null && opts['material'] != 'N/A') opts['material'],
                            if (opts['purity'] != null && opts['purity'] != 'N/A') opts['purity'],
                          ].join(' · '),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                            Text('x$qty', style: const TextStyle(fontSize: 13, color: Color(0xFF777777))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===== VOUCHER SECTION =====
  Widget _buildVoucherSection() {
    return _sectionCard(
      child: GestureDetector(
        onTap: () async {
          final voucher = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(
              builder: (_) => CouponScreen(
                cartItemId: 'checkout',
                selectedVoucher: _orderVoucher,
              ),
            ),
          );
          if (voucher != null && mounted) {
            _applyOrderVoucher(voucher);
          }
        },
        child: Row(
          children: [
            const Icon(Icons.confirmation_num_outlined, size: 18, color: Color(0xFFD4AF37)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _orderVoucher != null ? _orderVoucher!['code'] ?? 'Voucher Applied' : 'Apply Voucher',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFD4AF37)),
              ),
            ),
            if (_orderVoucher != null)
              Text(_orderVoucher!['discount'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  void _applyOrderVoucher(Map<String, dynamic> voucher) {
    final cart = context.read<CartProvider>();
    final subTotal = cart.totalSelectedPrice;
    String discountStr = voucher['discount'] ?? '';
    double discount = 0;

    if (discountStr.contains('%')) {
      RegExp regExp = RegExp(r'(\d+)%');
      Match? match = regExp.firstMatch(discountStr);
      if (match != null) {
        double percent = double.tryParse(match.group(1) ?? '0') ?? 0;
        discount = subTotal * (percent / 100);
      }
    } else if (discountStr.contains('\$')) {
      RegExp regExp = RegExp(r'\$(\d+)');
      Match? match = regExp.firstMatch(discountStr);
      if (match != null) {
        discount = double.tryParse(match.group(1) ?? '0') ?? 0;
      }
    }

    setState(() {
      _orderVoucher = voucher;
      _voucherDiscount = discount;
    });
    LuxuryToast.show(context, message: 'Voucher applied: ${voucher['code']}');
  }

  // ===== ORDER SUMMARY =====
  Widget _buildOrderSummary(double subTotal, double totalDiscount, double shippingFee, double total) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 12),
          _summaryRow('Subtotal', '\$${subTotal.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          if (totalDiscount > 0) ...[
            _summaryRow('Discount', '-\$${totalDiscount.toStringAsFixed(2)}', valueColor: Colors.green),
            const SizedBox(height: 6),
          ],
          _summaryRow('Shipping Fee', shippingFee == 0 ? 'FREE' : '\$${shippingFee.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 4),
          _summaryRow('Total', '\$${total.toStringAsFixed(2)}', isBold: true, fontSize: 17),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, double fontSize = 14, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: const Color(0xFF777777))),
        Text(value, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: valueColor ?? const Color(0xFF333333))),
      ],
    );
  }

  // ===== PLACE ORDER BUTTON =====
  Widget _buildPlaceOrderButton(BuildContext context, CartProvider cart, List<Map<String, dynamic>> items, double subTotal, double totalDiscount, double total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, offset: Offset(0, -2), blurRadius: 10)],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _placeOrder(context, cart, items, subTotal, totalDiscount, total),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF333333),
              disabledBackgroundColor: Colors.grey.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
            child: _isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text('Place Order · \$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  // ===== PLACE ORDER LOGIC =====
  Future<void> _placeOrder(BuildContext context, CartProvider cart, List<Map<String, dynamic>> items, double subTotal, double totalDiscount, double total) async {
    // Validation
    if (items.isEmpty) {
      LuxuryToast.show(context, message: 'Please select items to checkout');
      return;
    }
    if (_address.isEmpty) {
      LuxuryToast.show(context, message: 'Please add a shipping address');
      return;
    }

    // Auth check
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        LuxuryToast.show(context, message: 'Please log in to place order');
        Navigator.pushNamed(context, AppRouter.signin);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final orderId = FirebaseFirestore.instance.collection('orders').doc().id;

      final order = OrderModel(
        orderId: orderId,
        userId: user.uid,
        items: items,
        subTotal: subTotal,
        discount: totalDiscount,
        shippingFee: _shippingFee,
        totalAmount: total,
        paymentMethod: _selectedPayment,
        shippingMethod: _selectedShipping,
        address: _address,
        voucher: _orderVoucher,
      );

      // Save to main orders collection
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .set(order.toMap());

      // Save to user's orders sub-collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .doc(orderId)
          .set(order.toMap());

      // Remove ONLY purchased items
      cart.removeSelectedItems();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.orderSuccess,
          (route) => route.settings.name == AppRouter.home,
          arguments: {'orderId': orderId},
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        LuxuryToast.show(context, message: e.message ?? 'Failed to place order');
      }
    } catch (e) {
      if (mounted) {
        LuxuryToast.show(context, message: 'An unexpected error occurred');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== REUSABLE SECTION CARD =====
  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, 1), blurRadius: 6)],
      ),
      child: child,
    );
  }
}