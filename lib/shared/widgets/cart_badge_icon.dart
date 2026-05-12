import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/cart/providers/cart_provider.dart';

class CartIconWithBadge extends StatelessWidget {
  final IconData iconData;
  final Color? iconColor;
  final double size;

  const CartIconWithBadge({
    super.key,
    this.iconData = Icons.shopping_cart_outlined,
    this.iconColor,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(iconData, color: iconColor, size: size),
        Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            final int totalItems = cartProvider.items.fold(0, (sum, item) => sum + (item['qty'] as int? ?? 1));
            
            if (totalItems == 0) return const SizedBox.shrink();
            
            return Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Center(
                  child: Text(
                    totalItems > 9 ? '9+' : '$totalItems',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
