import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:jewelry_app/core/utils/luxury_toast.dart';
import '../../cart/providers/cart_provider.dart';
import '../../../router/app_router.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];
  List<Map<String, dynamic>> _cancelledOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      final all = snapshot.docs.map((d) {
        final data = Map<String, dynamic>.from(
          d.data() as Map<String, dynamic>,
        );
        data['orderId'] = d.id;
        return data;
      }).toList();

      if (mounted) {
        setState(() {
          _activeOrders = all.where((o) {
            final s = (o['status'] ?? '').toString().toLowerCase();
            return s == 'pending' || s == 'processing' || s == 'shipped';
          }).toList();
          _completedOrders = all.where((o) {
            final s = (o['status'] ?? '').toString().toLowerCase();
            return s.contains('deliver') || s.contains('complete');
          }).toList();
          _cancelledOrders = all.where((o) {
            final s = (o['status'] ?? '').toString().toLowerCase();
            return s == 'cancelled';
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList(_activeOrders, 'active'),
                  _buildOrderList(_completedOrders, 'completed'),
                  _buildOrderList(_cancelledOrders, 'cancelled'),
                ],
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
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF333333),
                size: 20,
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'My Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ===== TAB BAR =====
  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF333333),
        unselectedLabelColor: const Color(0xFF808080),
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
        ),
        indicatorColor: const Color(0xFF333333),
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(text: 'Active'),
          Tab(text: 'Completed'),
          Tab(text: 'Cancelled'),
        ],
      ),
    );
  }

  // ===== ORDER LIST =====
  Widget _buildOrderList(List<Map<String, dynamic>> orders, String tab) {
    if (_isLoading) return _buildSkeleton();
    if (orders.isEmpty) return _buildEmpty(tab);

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: const Color(0xFF333333),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          return _buildOrderCard(orders[index], tab);
        },
      ),
    );
  }

  // ===== ORDER CARD =====
  Widget _buildOrderCard(Map<String, dynamic> order, String tab) {
    final items = order['items'] as List<dynamic>? ?? [];
    final firstItem = items.isNotEmpty
        ? items[0] as Map<String, dynamic>
        : <String, dynamic>{};
    final name = firstItem['name'] ?? 'Unknown Item';
    final image = firstItem['image'] ?? '';
    final price = (order['totalAmount'] ?? 0.0) is num
        ? (order['totalAmount'] as num).toDouble()
        : 0.0;
    final itemCount = items.length;
    final status = order['status'] ?? '';

    return GestureDetector(
      onTap: () {
        // Navigate to e-receipt
        Navigator.pushNamed(context, AppRouter.eReceipt, arguments: order);
      },
      child: Opacity(
        opacity: 1.0,
        child: Container(
          padding: const EdgeInsets.only(bottom: 20),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  image: image.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(image),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: image.isEmpty
                    ? const Icon(
                        Icons.diamond_outlined,
                        color: Color(0xFFCCCCCC),
                        size: 26,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      itemCount > 1
                          ? '$itemCount items · ${_statusLabel(status)}'
                          : _statusLabel(status),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action button
              _buildActionButton(tab, order),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Widget _buildActionButton(String tab, Map<String, dynamic> order) {
    String label;
    VoidCallback onPressed;

    switch (tab) {
      case 'active':
        label = 'Track Order';
        onPressed = () {
          Navigator.pushNamed(context, AppRouter.trackOrder, arguments: order);
        };
        break;
      case 'completed':
        final isProductReviewed = order['isProductReviewed'] == true;
        final isSellerReviewed = order['isSellerReviewed'] == true;
        final isFullyReviewed = isProductReviewed && isSellerReviewed;
        label = isFullyReviewed ? 'Reviewed' : 'Leave Review';
        onPressed = isFullyReviewed
            ? () {}
            : () {
                Navigator.pushNamed(
                  context,
                  AppRouter.leaveReview,
                  arguments: order,
                );
              };
        break;
      case 'cancelled':
        label = 'Re-Order';
        onPressed = () => _reOrder(order);
        break;
      default:
        label = 'View';
        onPressed = () {};
    }

    return SizedBox(
      width: 110,
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              tab == 'completed' && order['isSellerReviewed'] == true
              ? Colors.grey.shade300
              : const Color(0xFF808080),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: tab == 'completed' && order['isSellerReviewed'] == true
                ? Colors.grey.shade600
                : Colors.white,
          ),
        ),
      ),
    );
  }

  void _reOrder(Map<String, dynamic> order) {
    final cart = context.read<CartProvider>();
    final items = order['items'] as List<dynamic>? ?? [];

    for (final item in items) {
      final product = item as Map<String, dynamic>;
      cart.addToCart(
        {
          'id': product['productId'] ?? product['id'],
          'name': product['name'] ?? '',
          'price': product['price'] ?? 0,
          'image': product['image'] ?? '',
          'category': product['category'] ?? '',
        },
        qty: product['quantity'] ?? 1,
        selectedOptions: product['selectedOptions'],
      );
    }

    LuxuryToast.show(context, message: 'Items added to cart');
    Navigator.pushNamed(context, AppRouter.cart);
  }

  // ===== SKELETON =====
  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (_, __) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skeletonBox(72, 72, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonBox(140, 14, radius: 4),
                const SizedBox(height: 8),
                _skeletonBox(90, 12, radius: 4),
                const SizedBox(height: 8),
                _skeletonBox(60, 14, radius: 4),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _skeletonBox(100, 36, radius: 18),
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

  // ===== EMPTY =====
  Widget _buildEmpty(String tab) {
    String message;
    IconData icon;
    switch (tab) {
      case 'active':
        message = 'No active orders';
        icon = Icons.local_shipping_outlined;
        break;
      case 'completed':
        message = 'No completed orders';
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        message = 'No cancelled orders';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'No orders found';
        icon = Icons.inbox_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: const Color(0xFFDDDDDD)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your orders will appear here',
            style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}
