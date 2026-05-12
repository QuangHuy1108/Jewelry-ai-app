import 'package:flutter/material.dart';
import '../../../router/app_router.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final orderId = args?['orderId'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F8EF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF4CAF50).withAlpha(51), width: 3),
                  ),
                  child: const Icon(Icons.check_rounded, size: 52, color: Color(0xFF4CAF50)),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Order Placed Successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Thank you for your purchase.\nYour order has been confirmed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF999999), height: 1.5),
                ),
                const SizedBox(height: 24),

                // Order ID
                if (orderId.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Order ID: ', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                        Flexible(
                          child: Text(
                            orderId.length > 12 ? '${orderId.substring(0, 12)}...' : orderId,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],

                // Action Buttons
                Column(
                  children: [
                    // View E-Receipt
                    if (orderId.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRouter.eReceipt, arguments: {'orderId': orderId});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF333333),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                          ),
                          child: const Text('View E-Receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    const SizedBox(height: 12),
                    
                    // View My Orders
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(context, AppRouter.myOrders, (route) => route.settings.name == AppRouter.home);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF333333)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        ),
                        child: const Text('View My Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Continue Shopping
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(context, AppRouter.home, (route) => false);
                        },
                        child: const Text('Continue Shopping', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF777777))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
