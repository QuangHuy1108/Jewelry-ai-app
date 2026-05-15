import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SellerProductTile extends StatelessWidget {
  final String productId;
  final String name;
  final double price;
  final String image;
  final bool isActive;

  const SellerProductTile({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 135,
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 70,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: image.isNotEmpty
                        ? Image.network(image, fit: BoxFit.cover)
                        : Container(
                            color: AppColors.canvasParchment,
                            child: const Icon(Icons.diamond_outlined, color: AppColors.inkMuted48),
                          ),
                  ),
                  // Status badge
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
