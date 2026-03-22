import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/popular_product_list_item.dart';
import '../../../router/app_navigation.dart';

class PopularProductsScreen extends StatefulWidget {
  const PopularProductsScreen({super.key});

  @override
  State<PopularProductsScreen> createState() => _PopularProductsScreenState();
}

class _PopularProductsScreenState extends State<PopularProductsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadPopularProducts();
  }

  Future<void> _loadPopularProducts() async {
    setState(() => _isLoading = true);
    // Simulate API fetch delay
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _products = [
          {
            "id": "1",
            "name": "Classic Gold Hoops",
            "category": "Earrings",
            "price": 250,
            "originalPrice": 300,
            "rating": 4.8,
            "image": "https://i.postimg.cc/cHWq3842/h8.jpg",
          },
          {
            "id": "2",
            "name": "Silver Chain Bracelet",
            "category": "Bracelets",
            "price": 120,
            "rating": 4.5,
            "image": "https://i.postimg.cc/zv06gtVy/h9.jpg",
          },
          {
            "id": "3",
            "name": "Diamond Solitaire Ring",
            "category": "Rings",
            "price": 1500,
            "originalPrice": 1800,
            "rating": 4.9,
            "image": "https://i.postimg.cc/4yh339Lk/h7.jpg",
          },
          {
            "id": "4",
            "name": "Crystal Heart Necklace",
            "category": "Necklaces",
            "price": 85,
            "rating": 4.7,
            "image": "https://i.postimg.cc/pL94mBxp/h10.jpg",
          },
          {
            "id": "5",
            "name": "Rose Gold Studs",
            "category": "Earrings",
            "price": 180,
            "originalPrice": 220,
            "rating": 4.6,
            "image": "https://i.postimg.cc/cHWq3842/h8.jpg",
          },
          {
            "id": "6",
            "name": "Bangle with Charms",
            "category": "Bracelets",
            "price": 320,
            "rating": 4.8,
            "image": "https://i.postimg.cc/zv06gtVy/h9.jpg",
          },
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isLoading
                  ? _buildLoadingList()
                  : _products.isEmpty
                      ? _buildEmptyState()
                      : _buildPopularList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF333333), size: 20),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Popular Products',
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

  Widget _buildLoadingList() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const ShimmerPopularProductItem(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.layers_clear_outlined, size: 80, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 16),
            const Text(
              'Empty List',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Try browsing our categories to find products.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333333),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Browse Categories'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularList() {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    
    return GridView.builder(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: 20 + bottomPadding,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return PopularProductListItem(
          product: product,
          onTap: () {
            AppNavigation.toProductDetail(context, product: product);
          },
        );
      },
    );
  }
}

class ShimmerPopularProductItem extends StatelessWidget {
  const ShimmerPopularProductItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            ),
            // Content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: double.infinity, height: 12, color: Colors.white),
                    Container(width: 60, height: 14, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
