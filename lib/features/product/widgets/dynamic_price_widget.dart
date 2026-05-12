import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';

class DynamicPriceWidget extends StatelessWidget {
  const DynamicPriceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        final before = provider.priceBeforeVoucher;
        final discount = provider.voucherDiscount;
        final finalPrice = provider.finalPrice;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Base Price & Options', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  Text('\$${before.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                ],
              ),
              if (discount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Voucher Discount', style: TextStyle(color: Colors.green, fontSize: 14)),
                    Text('-\$${discount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500, fontSize: 14)),
                  ],
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Final Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('\$${finalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF333333))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
