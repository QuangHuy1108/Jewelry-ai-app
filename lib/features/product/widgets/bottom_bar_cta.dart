import 'package:jewelry_app/core/utils/luxury_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/theme/app_colors.dart';

class BottomBarCTA extends StatelessWidget {
  const BottomBarCTA({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.canvasParchment, // clean signature background base for bottom CTA bar
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05), width: 1)),
        // single shadow rule enforcement: zero legacy container elevation
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPriceSection(),
          const SizedBox(height: 16),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        final before = provider.priceBeforeVoucher;
        final discount = provider.voucherDiscount;
        final finalPrice = provider.finalPrice;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total Due', 
                  style: TextStyle(
                    color: AppColors.inkMuted48, 
                    fontSize: 13, 
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.08,
                  ),
                ),
                if (discount > 0)
                  Row(
                    children: [
                      Text(
                        '\$${before.toStringAsFixed(2)}', 
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough, 
                          color: AppColors.inkMuted48, 
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '-\$${discount.toStringAsFixed(2)}', 
                        style: const TextStyle(
                          color: Color(0xFF34C759), // pure Apple success system color
                          fontWeight: FontWeight.w600, 
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const Spacer(),
            Text(
              '\$${finalPrice.toStringAsFixed(2)}', 
              style: const TextStyle(
                fontWeight: FontWeight.w600, 
                fontSize: 28, // SF Pro display size token
                color: AppColors.ink,
                letterSpacing: 0.196, // precise Apple display letter-spacing formula
                height: 1.0,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        final stock = provider.product['stock'] ?? 0;
        final isOutOfStock = stock == 0;

        return Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Add to Bag',
                variant: ButtonVariant.secondaryPill,
                isExpanded: true,
                isDisabled: isOutOfStock,
                onPressed: () => _handleAddToCart(context, provider),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: isOutOfStock ? 'Sold Out' : 'Checkout',
                variant: ButtonVariant.primaryPill,
                isExpanded: true,
                isDisabled: isOutOfStock,
                onPressed: () => _handleBuyNow(context, provider),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleAddToCart(BuildContext context, ProductProvider provider) {
    if (provider.selectedSize.isEmpty || provider.selectedMaterial.isEmpty || provider.selectedPurity.isEmpty) {
      LuxuryToast.show(context, message: 'Please select all required options (Size, Material, Purity).');
      return;
    }

    final rawImages = provider.product['images'] as List<dynamic>;
    final List<String> images = rawImages.cast<String>();

    final cart = context.read<CartProvider>();
    cart.addToCart({
      "id": provider.product['id'],
      "name": provider.product['name'],
      "price": provider.finalPrice,
      "image": images.firstWhere((url) => !url.endsWith('.mp4'), orElse: () => images.first),
      "purity": provider.selectedPurity,
      "size": provider.selectedSize,
      "stock": provider.product['stock'],
      "voucher": provider.selectedVoucher,
    }, qty: provider.qty);

    LuxuryToast.show(context, message: 'Added to Shopping Bag');
  }

  void _handleBuyNow(BuildContext context, ProductProvider provider) {
    if (provider.selectedSize.isEmpty || provider.selectedMaterial.isEmpty || provider.selectedPurity.isEmpty) {
      LuxuryToast.show(context, message: 'Please select all required options (Size, Material, Purity).');
      return;
    }
    LuxuryToast.show(context, message: 'Proceeding to Secure Checkout...');
  }
}
