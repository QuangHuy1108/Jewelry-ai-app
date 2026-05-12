import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jewelry_app/core/utils/luxury_toast.dart';

class TrackOrderScreen extends StatefulWidget {
  const TrackOrderScreen({super.key});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnim;

  Map<String, dynamic> _order = {};
  int _currentStep = 1; // 0=Placed, 1=InProgress, 2=Shipped, 3=Delivered

  final List<Map<String, dynamic>> _steps = [
    {'title': 'Order Placed', 'desc': 'Your order has been placed', 'icon': Icons.receipt_long_outlined},
    {'title': 'In Progress', 'desc': 'Your order is being prepared', 'icon': Icons.inventory_2_outlined},
    {'title': 'Shipped', 'desc': 'Your order is on the way', 'icon': Icons.local_shipping_outlined},
    {'title': 'Delivered', 'desc': 'Your order has been delivered', 'icon': Icons.check_circle_outline},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _order.isEmpty) {
      _order = args;
      final status = _order['status'] ?? 'pending';
      _currentStep = _statusToStep(status);
    }
    _animController.forward();
  }

  int _statusToStep(String status) {
    switch (status) {
      case 'pending': return 0;
      case 'processing': return 1;
      case 'shipped': return 2;
      case 'delivered':
      case 'completed': return 3;
      default: return 1;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _order['items'] as List<dynamic>? ?? [];
    final firstItem = items.isNotEmpty ? items[0] as Map<String, dynamic> : <String, dynamic>{};
    final trackingId = _order['orderId'] ?? 'GU-20260322-7F3A';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AnimatedBuilder(
                animation: _slideAnim,
                builder: (context, child) {
                  return Opacity(
                    opacity: _slideAnim.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _slideAnim.value)),
                      child: child,
                    ),
                  );
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildProductBrief(firstItem, items.length),
                      const SizedBox(height: 24),
                      _buildOrderDetails(trackingId),
                      const SizedBox(height: 24),
                      _buildOrderStatus(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
              child: Text('Track Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ===== PRODUCT BRIEF =====
  Widget _buildProductBrief(Map<String, dynamic> item, int totalItems) {
    final name = item['name'] ?? 'Unknown Item';
    final image = item['image'] ?? '';
    final category = item['category'] ?? '';
    final qty = item['quantity'] ?? item['qty'] ?? 1;
    final price = (_order['totalAmount'] ?? 0.0) is num ? (_order['totalAmount'] as num).toDouble() : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
              image: image.isNotEmpty ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover) : null,
            ),
            child: image.isEmpty ? const Icon(Icons.diamond_outlined, color: Color(0xFFCCCCCC), size: 24) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  category.isNotEmpty ? '$category · Qty: $qty' : 'Qty: $qty',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
                ),
                if (totalItems > 1)
                  Text('+${totalItems - 1} more item${totalItems - 1 > 1 ? "s" : ""}', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
              ],
            ),
          ),
          Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        ],
      ),
    );
  }

  // ===== ORDER DETAILS =====
  Widget _buildOrderDetails(String trackingId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        const SizedBox(height: 16),
        _detailRow('Expected Delivery Date', 'Mar 25, 2026'),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tracking ID', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: trackingId));
                HapticFeedback.lightImpact();
                LuxuryToast.show(context, message: 'Tracking ID copied');
              },
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: trackingId));
                HapticFeedback.mediumImpact();
                LuxuryToast.show(context, message: 'Tracking ID copied');
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trackingId.length > 16 ? '${trackingId.substring(0, 16)}...' : trackingId,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.copy_outlined, size: 14, color: Color(0xFF999999)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
      ],
    );
  }

  // ===== ORDER STATUS TIMELINE =====
  Widget _buildOrderStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        const SizedBox(height: 20),
        ...List.generate(_steps.length, (index) {
          return _buildTimelineStep(index);
        }),
      ],
    );
  }

  Widget _buildTimelineStep(int index) {
    final step = _steps[index];
    final isCompleted = index <= _currentStep;
    final isActive = index == _currentStep;
    final isLast = index == _steps.length - 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column: circle + connector
        SizedBox(
          width: 36,
          child: Column(
            children: [
              // Circle indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? const Color(0xFF333333) : const Color(0xFFF0F0F0),
                  border: isActive
                      ? Border.all(color: const Color(0xFFD4AF37), width: 2.5)
                      : null,
                ),
                child: Icon(
                  isCompleted ? Icons.check : Icons.circle,
                  size: isCompleted ? 16 : 8,
                  color: isCompleted ? Colors.white : const Color(0xFFCCCCCC),
                ),
              ),
              // Connector line
              if (!isLast)
                _AnimatedLine(
                  isCompleted: index < _currentStep,
                  delay: index * 150,
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        // Middle column: text
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  step['title'] as String,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? const Color(0xFF333333) : const Color(0xFFBBBBBB),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  step['desc'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: isCompleted ? const Color(0xFF999999) : const Color(0xFFCCCCCC),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right column: icon
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Icon(
            step['icon'] as IconData,
            size: 22,
            color: isCompleted ? const Color(0xFF333333) : const Color(0xFFDDDDDD),
          ),
        ),
      ],
    );
  }
}

// ===== ANIMATED CONNECTOR LINE =====
class _AnimatedLine extends StatefulWidget {
  final bool isCompleted;
  final int delay;
  const _AnimatedLine({required this.isCompleted, this.delay = 0});

  @override
  State<_AnimatedLine> createState() => _AnimatedLineState();
}

class _AnimatedLineState extends State<_AnimatedLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _heightAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: 200 + widget.delay), () {
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
    return AnimatedBuilder(
      animation: _heightAnim,
      builder: (context, child) {
        return Container(
          width: 2.5,
          height: 40 * _heightAnim.value,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: widget.isCompleted ? const Color(0xFF333333) : const Color(0xFFE8E8E8),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      },
    );
  }
}
