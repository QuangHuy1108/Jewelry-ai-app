import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../../product/widgets/product_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/product_grid_constants.dart';
import 'package:jewelry_app/services/product_service.dart';

class SimilarProductList extends StatefulWidget {
  const SimilarProductList({super.key});

  @override
  State<SimilarProductList> createState() => _SimilarProductListState();
}

class _SimilarProductListState extends State<SimilarProductList> {
  List<Map<String, dynamic>> _similarProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSimilarProducts());
  }

  Future<void> _loadSimilarProducts() async {
    final currentProduct = context.read<ProductProvider>().product;
    if (currentProduct.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final category = currentProduct['category'] ?? '';
      final productId = currentProduct['id'] ?? '';
      final results = await ProductService().getSimilarProducts(category, productId);
      if (mounted) {
        setState(() {
          _similarProducts = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2)),
      );
    }

    if (_similarProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Similar Products',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w600, 
            color: AppColors.ink,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: ProductGridConstants.horizontalListHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _similarProducts.length,
            separatorBuilder: (_, __) => const SizedBox(width: ProductGridConstants.horizontalCardSpacing),
            itemBuilder: (context, index) {
              return SizedBox(
                width: ProductGridConstants.horizontalCardWidth,
                child: ProductCard(product: _similarProducts[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
