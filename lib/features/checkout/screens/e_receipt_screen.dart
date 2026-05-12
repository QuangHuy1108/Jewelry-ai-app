import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jewelry_app/core/utils/luxury_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EReceiptScreen extends StatefulWidget {
  const EReceiptScreen({super.key});

  @override
  State<EReceiptScreen> createState() => _EReceiptScreenState();
}

class _EReceiptScreenState extends State<EReceiptScreen> {
  bool _isLoading = true;
  bool _hasError = false;

  Map<String, dynamic>? _receiptData;

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

  Future<void> _loadReceipt() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final orderId = args?['orderId'];

      if (orderId == null) {
        setState(() { _isLoading = false; _hasError = true; });
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      
      if (!doc.exists) {
        setState(() { _isLoading = false; _hasError = true; });
        return;
      }

      final data = doc.data()!;
      final timestamp = data['createdAt'] as Timestamp?;
      final dateStr = timestamp != null 
          ? '${_monthName(timestamp.toDate().month)} ${timestamp.toDate().day}, ${timestamp.toDate().year}'
          : 'Unknown Date';

      if (mounted) {
        setState(() {
          _isLoading = false;
          _receiptData = {
            'orderId': orderId,
            'orderDate': dateStr,
            'promoCode': data['voucher']?['code'] ?? 'None',
            'deliveryType': _getShippingLabel(data['shippingMethod'] ?? 'standard'),
            'paymentMethod': _getPaymentLabel(data['paymentMethod'] ?? 'cod'),
            'address': data['address'] ?? {},
            'items': data['items'] ?? [],
            'totalAmount': (data['totalAmount'] ?? 0.0).toDouble(),
          };
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _hasError = true; });
      }
    }
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _getShippingLabel(String method) {
    switch (method) {
      case 'premium': return 'Insured Premium Delivery';
      case 'express': return 'Express Delivery';
      default: return 'Standard Delivery';
    }
  }

  String _getPaymentLabel(String method) {
    switch (method) {
      case 'card': return 'Credit Card';
      case 'apple': return 'Apple Pay';
      default: return 'Cash on Delivery';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildSkeleton()
                  : _hasError
                      ? _buildError()
                      : _buildBody(),
            ),
          ],
        ),
      ),
      bottomSheet: (!_isLoading && !_hasError) ? _buildFooter() : null,
    );
  }

  // ===== HEADER =====
  Widget _buildHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
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
              child: Text('E-Receipt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ===== BODY =====
  Widget _buildBody() {
    final data = _receiptData!;
    final items = data['items'] as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Barcode
          _FadeIn(delay: 0, child: _buildBarcode(data['orderId'])),
          const SizedBox(height: 28),
          // Itemized list
          ...List.generate(items.length, (i) {
            final item = items[i] as Map<String, dynamic>;
            return _FadeIn(
              delay: 100 + (i * 80),
              child: Padding(
                padding: EdgeInsets.only(bottom: i < items.length - 1 ? 20 : 0),
                child: _buildProductRow(item),
              ),
            );
          }),
          const SizedBox(height: 24),
          // Dashed divider
          _buildDashedDivider(),
          const SizedBox(height: 20),
          // Order summary
          _FadeIn(
            delay: 100 + items.length * 80,
            child: _buildOrderSummary(data),
          ),
          const SizedBox(height: 100), // space for bottom button
        ],
      ),
    );
  }

  // ===== BARCODE =====
  Widget _buildBarcode(String orderId) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Column(
          children: [
            // Barcode lines
            SizedBox(
              height: 80,
              width: MediaQuery.of(context).size.width * 0.75,
              child: CustomPaint(painter: _BarcodePainter(orderId)),
            ),
            const SizedBox(height: 10),
            Text(orderId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF555555), letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  // ===== PRODUCT ROW =====
  Widget _buildProductRow(Map<String, dynamic> item) {
    final name = item['name'] ?? '';
    final category = item['category'] ?? '';
    final image = item['image'] ?? '';
    final price = (item['price'] ?? 0.0) is num ? (item['price'] as num).toDouble() : 0.0;
    final originalPrice = (item['originalPrice'] ?? 0.0) is num ? (item['originalPrice'] as num).toDouble() : 0.0;

    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            image: image.isNotEmpty ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover) : null,
          ),
          child: image.isEmpty ? const Icon(Icons.diamond_outlined, color: Color(0xFFCCCCCC), size: 24) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF333333)), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(category, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                  if (originalPrice > price) ...[
                    const SizedBox(width: 8),
                    Text('\$${originalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF999999), decoration: TextDecoration.lineThrough)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===== DASHED DIVIDER =====
  Widget _buildDashedDivider() {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashWidth = 6.0;
          final dashCount = (constraints.maxWidth / (dashWidth * 2)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: 1,
                child: const DecoratedBox(decoration: BoxDecoration(color: Color(0xFFDDDDDD))),
              );
            }),
          );
        },
      ),
    );
  }

  // ===== ORDER SUMMARY =====
  Widget _buildOrderSummary(Map<String, dynamic> data) {
    return Column(
      children: [
        _summaryRow('Order Date', data['orderDate'] ?? ''),
        const SizedBox(height: 14),
        _summaryRow('Payment Method', data['paymentMethod'] ?? ''),
        const SizedBox(height: 14),
        _summaryRow('Promo code', data['promoCode'] ?? 'None'),
        const SizedBox(height: 14),
        _summaryRow('Delivery Type', data['deliveryType'] ?? ''),
        const SizedBox(height: 20),
        _buildDashedDivider(),
        const SizedBox(height: 20),
        _buildAddressSection(data['address'] ?? {}),
        const SizedBox(height: 24),
        _buildDashedDivider(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            Text('\$${(data['totalAmount'] ?? 0.0).toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressSection(Map<String, dynamic> address) {
    if (address.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Shipping Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        const SizedBox(height: 8),
        Text(address['name'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),
        Text(address['detail'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF777777))),
        Text('${address['city'] ?? ''}, ${address['phone'] ?? ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF777777))),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
        Flexible(
          child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
        ),
      ],
    );
  }

  // ===== FOOTER =====
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, offset: Offset(0, -1), blurRadius: 6)],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              LuxuryToast.show(context, message: 'Downloading E-Receipt...');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF808080),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              elevation: 0,
            ),
            child: const Text('Download E-Receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  // ===== SKELETON LOADER =====
  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _skeletonBox(double.infinity, 110, radius: 12),
          const SizedBox(height: 28),
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                _skeletonBox(60, 60, radius: 8),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _skeletonBox(140, 14, radius: 4),
                      const SizedBox(height: 6),
                      _skeletonBox(80, 12, radius: 4),
                      const SizedBox(height: 8),
                      _skeletonBox(60, 14, radius: 4),
                    ],
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 24),
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _skeletonBox(100, 14, radius: 4),
                _skeletonBox(120, 14, radius: 4),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _skeletonBox(double width, double height, {double radius = 0}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // ===== ERROR STATE =====
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Color(0xFFDDDDDD)),
          const SizedBox(height: 16),
          const Text('Error loading receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadReceipt,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF333333),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ===== FADE-IN ANIMATION WIDGET =====
class _FadeIn extends StatefulWidget {
  final Widget child;
  final int delay;
  const _FadeIn({required this.child, this.delay = 0});

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _offset = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

// ===== BARCODE CUSTOM PAINTER =====
class _BarcodePainter extends CustomPainter {
  final String data;
  _BarcodePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;

    // Generate deterministic bar widths from the data string
    final hash = data.hashCode.abs();
    final random = List.generate(60, (i) => ((hash * (i + 1) * 7) % 5) + 1);

    double x = 0;
    for (int i = 0; i < random.length && x < size.width; i++) {
      final barWidth = random[i].toDouble();
      if (i % 2 == 0) {
        canvas.drawRect(Rect.fromLTWH(x, 0, barWidth, size.height), paint);
      }
      x += barWidth + 1;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
