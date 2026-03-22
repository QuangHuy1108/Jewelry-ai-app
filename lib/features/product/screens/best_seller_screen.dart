import 'package:flutter/material.dart';
import '../widgets/best_seller_product_card.dart';
import '../../../router/app_navigation.dart';

class BestSellerScreen extends StatefulWidget {
  const BestSellerScreen({super.key});

  @override
  State<BestSellerScreen> createState() => _BestSellerScreenState();
}

class _BestSellerScreenState extends State<BestSellerScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadBestSellers();
  }

  Future<void> _loadBestSellers() async {
    setState(() => _isLoading = true);
    // Simulate API fetch delay
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _products = [
          {
            "id": "bs1",
            "name": "Diamond Halo Ring",
            "category": "Rings",
            "price": 2500,
            "originalPrice": 3200,
            "rating": 4.9,
            "image": "https://i.postimg.cc/4yh339Lk/h7.jpg",
          },
          {
            "id": "bs2",
            "name": "Gold Tennis Bracelet",
            "category": "Bracelets",
            "price": 1200,
            "rating": 4.8,
            "image": "https://i.postimg.cc/zv06gtVy/h9.jpg",
          },
          {
            "id": "bs3",
            "name": "Pearl Drop Earrings",
            "category": "Earrings",
            "price": 850,
            "originalPrice": 1100,
            "rating": 4.7,
            "image": "https://i.postimg.cc/cHWq3842/h8.jpg",
          },
          {
            "id": "bs4",
            "name": "Sapphire Pendant",
            "category": "Necklaces",
            "price": 3100,
            "rating": 5.0,
            "image": "https://i.postimg.cc/pL94mBxp/h10.jpg",
          },
          {
            "id": "bs5",
            "name": "Rose Gold Bangle",
            "category": "Bracelets",
            "price": 450,
            "originalPrice": 600,
            "rating": 4.6,
            "image": "https://i.postimg.cc/zv06gtVy/h9.jpg",
          },
          {
            "id": "bs6",
            "name": "Emerald Cut Ring",
            "category": "Rings",
            "price": 4200,
            "rating": 4.9,
            "image": "https://i.postimg.cc/4yh339Lk/h7.jpg",
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
                  ? _buildLoadingGrid()
                  : _products.isEmpty
                      ? _buildEmptyState()
                      : _buildProductGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 70, // Height: 60px - 80px
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Circular Back Button
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
                'Best Seller Product',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
          const SizedBox(width: 40), // Balance
        ],
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 20,
        childAspectRatio: 0.68, // To accommodate image + 3 lines of text
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const ShimmerProductCard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 80, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 16),
            const Text(
              'No best sellers found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadBestSellers,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333333),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
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
        crossAxisSpacing: 15,
        mainAxisSpacing: 20,
        childAspectRatio: 0.68,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        
        // Entrance: Fade-in staggered animation for grid items (Duration: 400ms)
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          // Calculate delay based on index for staggering
          builder: (context, value, child) {
            final staggerDelay = index * 50; 
            return FutureBuilder(
              future: Future.delayed(Duration(milliseconds: staggerDelay)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            );
          },
          child: BestSellerProductCard(
            product: product,
            onTap: () {
              AppNavigation.toProductDetail(context, product: product);
            },
          ),
        );
      },
    );
  }
}
