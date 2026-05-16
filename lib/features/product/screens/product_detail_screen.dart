import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/product_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'package:jewelry_app/services/product_service.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProduct();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final provider = context.read<ProductProvider>();

    if (args != null && args.isNotEmpty) {
      // If full product data was passed via navigation, use it directly
      if (args.containsKey('basePrice') || args.containsKey('images')) {
        provider.initProduct(args);
      } else {
        // Minimal data passed (e.g. from card) — fetch full record from Firestore
        final productId = args['id']?.toString() ?? '';
        if (productId.isNotEmpty) {
          try {
            final doc = await ProductService().getProductById(productId);
            if (doc.exists) {
              provider.initProduct({'id': doc.id, ...doc.data()!});
            } else {
              provider.initProduct({...args, 'basePrice': _parsePrice(args['price']), 'images': [args['image'] ?? '']});
            }
          } catch (_) {
            provider.initProduct({...args, 'basePrice': _parsePrice(args['price']), 'images': [args['image'] ?? '']});
          }
        } else {
          provider.initProduct({...args, 'basePrice': _parsePrice(args['price']), 'images': [args['image'] ?? '']});
        }
      }
    }
    // else: provider keeps its current product state (could already be set)

    if (mounted) setState(() => _isLoading = false);
  }

  double _parsePrice(dynamic price) {
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price.replaceAll('\$', '').replaceAll(',', '')) ?? 0.0;
    return 0.0;
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
          color: AppColors.canvas, // signature absolute canvas token
          borderRadius: isTablet ? BorderRadius.circular(24) : const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: AppColors.hairline, width: 1), // flat hairline profile
          // zero container shadow rule enforced
        ),
        padding: const EdgeInsets.all(24), // token spacing.lg alignment
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSellerSection(),
            const SizedBox(height: 24),
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
            Text(
              (product['category'] ?? '').toString().toUpperCase(), 
              style: const TextStyle(
                fontSize: 11, // clean brand subhead alignment
                fontWeight: FontWeight.w600,
                color: AppColors.inkMuted48,
                letterSpacing: 0.5,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/review'),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFF5A623), size: 14), // subtle curated gold tone
                  const SizedBox(width: 4),
                  Text(
                    '${product['rating']} (${product['reviews']} reviews)', 
                    style: const TextStyle(
                      fontSize: 13, 
                      fontWeight: FontWeight.w600, 
                      color: AppColors.ink,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          product['name'] ?? '', 
          style: const TextStyle(
            fontSize: 28, // SF Pro Display Token
            fontWeight: FontWeight.w600, 
            color: AppColors.ink,
            letterSpacing: 0.196,
            height: 1.14,
          ),
        ),
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
            const Text(
              'Gold Material Purity', 
              style: TextStyle(
                fontSize: 17, // SF Pro body-strong token
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                letterSpacing: -0.374,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: ['18 KT', '22 KT'].map((purity) {
                final isSelected = provider.selectedPurity == purity;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => provider.setPurity(purity),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.ink : AppColors.canvas,
                        border: Border.all(
                          color: isSelected ? AppColors.ink : AppColors.hairline,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(9999), // configurator pill token
                      ),
                      child: Text(
                        purity, 
                        style: TextStyle(
                          color: isSelected ? AppColors.bodyOnDark : AppColors.ink, 
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quantity', 
                  style: TextStyle(
                    fontSize: 17, // body-strong token
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    letterSpacing: -0.374,
                  ),
                ),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    border: Border.all(color: AppColors.hairline, width: 1),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16, color: AppColors.ink), 
                        onPressed: () => provider.setQty(provider.qty - 1),
                        splashRadius: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${provider.qty}', 
                          style: const TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.w600, 
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16, color: AppColors.ink), 
                        onPressed: () => provider.setQty(provider.qty + 1),
                        splashRadius: 20,
                      ),
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

  Widget _buildSellerSection() {
    final product = context.read<ProductProvider>().product;
    final sellers = product['sellers'] as List<dynamic>?;
    if (sellers == null || sellers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Consultants', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sellers.length,
            itemBuilder: (context, index) {
              final seller = sellers[index];
              final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
              final isMe = (seller['userId'] != null && seller['userId'] == currentUserUid) || seller['id'] == currentUserUid;

              return Container(
                width: MediaQuery.of(context).size.width * 0.7,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEFEFEF)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/seller-profile', arguments: seller),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: (seller['avatar'] as String).isNotEmpty ? NetworkImage(seller['avatar']) : null,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/seller-profile', arguments: seller),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              seller['name'],
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Color(0xFFFFD700), size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  '${seller['rating']} Rating',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    isMe
                        ? const SizedBox(width: 48, height: 48)
                        : IconButton(
                            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF333333), size: 20),
                            onPressed: () {
                              final productContext = {
                                'id': product['id'] ?? '',
                                'name': product['name'] ?? '',
                                'image': (product['images'] as List<dynamic>?)?.firstWhere(
                                  (u) => !u.toString().endsWith('.mp4'), orElse: () => '') ?? '',
                                'price': product['basePrice'],
                              };
                              Navigator.pushNamed(
                                context,
                                '/chat-detail',
                                arguments: {
                                  'sellerId': (seller['userId'] as String?) ?? (seller['id'] as String? ?? ''),
                                  'sellerName': seller['name'] ?? 'Seller',
                                  'sellerAvatar': seller['avatar'] ?? '',
                                  'productContext': productContext,
                                },
                              );
                            },
                          ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
