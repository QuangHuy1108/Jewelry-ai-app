import 'package:flutter/material.dart';
import 'product_card.dart';
import '../../product/screens/product_detail_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/product_grid_constants.dart';
import 'package:jewelry_app/services/product_service.dart';

class RecommendationList extends StatefulWidget {
  final String currentCategory;

  const RecommendationList({super.key, required this.currentCategory});

  @override
  State<RecommendationList> createState() => _RecommendationListState();
}

class _RecommendationListState extends State<RecommendationList> {
  List<Map<String, dynamic>> _recommended = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      final results = await ProductService().getRecommendedProducts(widget.currentCategory);
      if (mounted) {
        setState(() {
          _recommended = results;
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

    if (_recommended.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Complete Your Set',
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
            itemCount: _recommended.length,
            separatorBuilder: (_, __) => const SizedBox(width: ProductGridConstants.horizontalCardSpacing),
            itemBuilder: (context, index) {
              return SizedBox(
                width: ProductGridConstants.horizontalCardWidth,
                child: ProductCard(
                  product: _recommended[index],
                  onTap: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProductDetailScreen()));
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
