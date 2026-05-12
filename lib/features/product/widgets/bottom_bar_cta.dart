import 'package:jewelry_app/core/utils/luxury_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../providers/product_provider.dart';

class BottomBarCTA extends StatelessWidget {
  const BottomBarCTA({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
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
                const Text('Total Price', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.normal)),
                if (discount > 0)
                  Row(
                    children: [
                      Text('\$${before.toStringAsFixed(2)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 14)),
                      const SizedBox(width: 8),
                      Text('-\$${discount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
              ],
            ),
            const Spacer(),
            Text('\$${finalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Color(0xFF333333))),
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
              child: OutlinedButton(
                onPressed: isOutOfStock ? null : () => _handleAddToCart(context, provider),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF333333)),
                  foregroundColor: const Color(0xFF333333),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Add to Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isOutOfStock ? null : () => _handleBuyNow(context, provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOutOfStock ? Colors.grey : const Color(0xFF333333),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: Text(isOutOfStock ? 'Out of Stock' : 'Buy Now', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    LuxuryToast.show(context, message: 'Proceeding to Checkout...');
  }
}
