import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../../../router/app_navigation.dart';
import '../../../core/theme/app_colors.dart';

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.product['name'] ?? '';
    final String rawPrice = widget.product['price']?.toString() ?? '';
    final String price = rawPrice.startsWith('\$') ? rawPrice : '\$$rawPrice';
    final String imageUrl = widget.product['image'] ?? '';
    final String id = widget.product['id'] ?? '';
    
    final bool isFavorite = id.isNotEmpty
        ? Provider.of<WishlistProvider>(context).isInWishlist(id)
        : false;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: widget.onTap ?? () => AppNavigation.toProductDetail(context, product: widget.product),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(18), // rounded.lg token
            border: Border.all(color: AppColors.hairline, width: 1), // flat hairline border
            // zero shadow rule enforced on utility cards
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE CONTAINER (1:1 Ratio with inner rounded.sm)
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.canvasParchment, // standard Apple background pad
                        borderRadius: BorderRadius.circular(8), // rounded.sm inner
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.diamond_outlined, color: AppColors.inkMuted48),
                              )
                            : const Icon(Icons.diamond_outlined, color: AppColors.inkMuted48),
                      ),
                    ),
                    // Translucent circular icon button for favorites over photography
                    Positioned(
                      right: 6,
                      top: 6,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          if (id.isNotEmpty) {
                            Provider.of<WishlistProvider>(context, listen: false).toggleWishlist(widget.product);
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceChipTranslucent,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isFavorite ? const Color(0xFFE53935) : AppColors.ink,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // INFO TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600, 
                        fontSize: 14, // clean size for catalog items
                        color: AppColors.ink,
                        letterSpacing: -0.224,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            fontWeight: FontWeight.w400, 
                            fontSize: 14, 
                            color: AppColors.ink,
                            letterSpacing: -0.224,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          "Buy",
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: AppColors.primary, // pure Action Blue signal
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}