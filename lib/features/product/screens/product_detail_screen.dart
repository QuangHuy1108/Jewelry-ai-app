import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/product_provider.dart';

import '../widgets/size_selector.dart';
import '../widgets/full_screen_gallery.dart';
import '../widgets/product_video_player.dart';
import '../widgets/voucher_list_widget.dart';
import '../widgets/top_bar_search.dart';
import '../widgets/bottom_bar_cta.dart';
import '../widgets/collapsible_section.dart';
import '../widgets/recommendation_list.dart';
import '../widgets/similar_product_list.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  bool _isLoading = true;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedImageIndex);
    // Initialize product state in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().initProduct({
        "id": "pd1",
        "name": "Gold Earring",
        "category": "Earrings",
        "basePrice": 1200.0,
        "images": [
          "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
          "https://i.postimg.cc/4yh339Lk/h7.jpg",
          "https://i.postimg.cc/cHWq3842/h8.jpg",
          "https://i.postimg.cc/zv06gtVy/h9.jpg",
          "https://i.postimg.cc/pL94mBxp/h10.jpg",
          "https://i.postimg.cc/43qyqfT2/h4.jpg",
        ],
        "stock": 10,
        "rating": 4.8,
        "reviews": 124,
      });
      _loadProduct();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        body: _buildLoadingState(),
      );
    }

    final productData = context.watch<ProductProvider>().product;
    if (productData.isEmpty) return const Scaffold(body: Center(child: Text('Product not found')));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;
          return Column(
            children: [
              TopBarWithSearch(product: productData),
              Expanded(
                child: SingleChildScrollView(
                  child: isTablet
                      ? _buildTabletLayout(constraints.maxWidth)
                      : _buildMobileLayout(constraints.maxWidth),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const BottomBarCTA(),
    );
  }

  // Layouts
  Widget _buildTabletLayout(double screenWidth) {
    return Padding(
      padding: const EdgeInsets.only(top: 80, bottom: 20, left: 20, right: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: _buildMediaGallery(isTablet: true, screenWidth: screenWidth)),
          const SizedBox(width: 32),
          Expanded(flex: 4, child: _buildContentCard(isTablet: true)),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(double screenWidth) {
    return Column(
      children: [
        _buildMediaGallery(isTablet: false, screenWidth: screenWidth),
        _buildContentCard(isTablet: false),
      ],
    );
  }

  // Media Gallery
  Widget _buildMediaGallery({required bool isTablet, required double screenWidth}) {
    final images = context.read<ProductProvider>().product['images'] as List<dynamic>;
    return isTablet ? _buildTabletGalleryView(images) : _buildMobileGalleryView(images, screenWidth);
  }

  Widget _buildTabletGalleryView(List<dynamic> images) {
    return SizedBox(
      height: 600,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: ListView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildThumbnail(images[index], index),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _selectedImageIndex = i),
              itemCount: images.length,
              itemBuilder: (context, index) => _buildGalleryImage(images, images[index], index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileGalleryView(List<dynamic> images, double screenWidth) {
    return Container(
      height: 480,
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _selectedImageIndex = i),
                itemCount: images.length,
                itemBuilder: (context, index) => _buildGalleryImage(images, images[index], index),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: images.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildThumbnail(images[index], index),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildThumbnail(String url, int index) {
    return GestureDetector(
      onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: _selectedImageIndex == index ? const Color(0xFF333333) : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(8),
          image: url.endsWith('.mp4') || url.isEmpty ? null : DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
          color: url.endsWith('.mp4') || url.isEmpty ? Colors.black12 : null,
        ),
        child: url.endsWith('.mp4') ? const Icon(Icons.play_circle_outline, color: Colors.white) : null,
      ),
    );
  }

  Widget _buildGalleryImage(List<dynamic> rawImages, String imageUrl, int index) {
    if (imageUrl.endsWith('.mp4')) return ProductVideoPlayer(videoUrl: imageUrl);

    final List<String> images = rawImages.cast<String>();
    final filteredImages = images.where((url) => !url.endsWith('.mp4')).toList();
    final initialIndex = filteredImages.indexOf(imageUrl);

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => FullScreenImageGallery(
            images: filteredImages,
            initialIndex: initialIndex != -1 ? initialIndex : 0,
          ),
        ));
      },
      child: Hero(
        tag: 'product_image_$index',
        child: imageUrl.isEmpty 
            ? const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey))
            : Image.network(imageUrl, fit: BoxFit.contain, width: double.infinity, height: double.infinity),
      ),
    );
  }

  // Content Card
  Widget _buildContentCard({bool isTablet = false}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 0.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(offset: Offset(0, isTablet ? 0 : 100 * value), child: child);
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: isTablet ? BorderRadius.circular(24) : const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: isTablet ? 15 : 20, offset: Offset(0, isTablet ? 5 : -5)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPrimaryInfo(),
            const SizedBox(height: 24),
            _buildDynamicAttributes(),
            const SizedBox(height: 24),
            const CollapsibleSection(
              title: 'Product Details',
              content: "This elegant gold earring is crafted with precision to bring out the natural glow of the wearer. Perfect for any occasion, from casual outings to formal events. Its timeless design ensures it remains a staple in your jewelry collection for years to come. Made with the highest quality gold, it's both durable and stunning.",
              initiallyExpanded: true,
            ),
            const CollapsibleSection(
              title: 'Materials & Specifications',
              content: 'Crafted from solid 18K/22K gold, meticulously hand-polished to achieve an immaculate shine. Avoid exposing to harsh chemicals.',
            ),
            const CollapsibleSection(
              title: 'Care & Maintenance',
              content: 'Clean gently with a soft cloth and mild soapy water. Store in the provided velvet pouch when not in use to prevent scratching.',
            ),
            const CollapsibleSection(
              title: 'Shipping & Returns',
              content: 'Complimentary insured overnight shipping. Free returns within 30 days of purchase in unworn condition with original packaging.',
            ),
            const SizedBox(height: 24),
            RecommendationList(currentCategory: context.read<ProductProvider>().product['category'] ?? ''),
            const SizedBox(height: 24),
            const SimilarProductList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryInfo() {
    final product = context.read<ProductProvider>().product;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(product['category'] ?? '', style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/review'),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                  const SizedBox(width: 4),
                  Text('${product['rating']} (${product['reviews']} reviews)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(product['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
      ],
    );
  }

  Widget _buildDynamicAttributes() {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Purity
            const Text('Purity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: ['18 KT', '22 KT'].map((purity) {
                final isSelected = provider.selectedPurity == purity;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => provider.setPurity(purity),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF333333) : Colors.white,
                        border: Border.all(color: isSelected ? const Color(0xFF333333) : const Color(0xFFEFEFEF)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(purity, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF333333), fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Size
            SizeSelector(
              selectedSize: provider.selectedSize,
              onSizeSelected: (size) => provider.setSize(size),
            ),
            const SizedBox(height: 24),
            
            // Quantity
            Row(
              children: [
                const Text('Quantity:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: () => provider.setQty(provider.qty - 1)),
                      Text('${provider.qty}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => provider.setQty(provider.qty + 1)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Vouchers
            VoucherListWidget(
              currentPrice: provider.priceBeforeVoucher,
              onVoucherSelected: (voucher) => provider.setVoucher(voucher),
            ),
          ],
        );
      },
    );
  }


  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(height: 350, color: Colors.white),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
              padding: const EdgeInsets.all(20),
            ),
          ),
        ],
      ),
    );
  }
}
