import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import '../../cart/providers/cart_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../../chat/screens/seller_chat_screen.dart';
import '../widgets/size_guide_bottom_sheet.dart';
import '../widgets/full_screen_gallery.dart';
import '../widgets/product_card.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  String _selectedPurity = '18 KT';
  bool _isDescriptionExpanded = false;
  bool _isLoading = true;
  late PageController _pageController;

  int _qty = 1;
  String _selectedSize = '';
  String _sizeError = '';
  final int _stock = 10;

  final List<String> _images = [
    "https://i.postimg.cc/4yh339Lk/h7.jpg",
    "https://i.postimg.cc/cHWq3842/h8.jpg",
    "https://i.postimg.cc/zv06gtVy/h9.jpg",
    "https://i.postimg.cc/pL94mBxp/h10.jpg",
    "https://i.postimg.cc/43qyqfT2/h4.jpg",
  ];

  final double _basePrice = 1200.0;
  double get _totalPrice => _selectedPurity == '22 KT' ? _basePrice + 300 : _basePrice;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedImageIndex);
    _loadProduct();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8), // Light Grey top area
      body: _isLoading ? _buildLoadingState() : _buildProductContent(),
      bottomNavigationBar: _isLoading ? null : _buildFooter(),
    );
  }

  Widget _buildProductContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final bool isTablet = screenWidth > 600;

        return Stack(
          children: [
            // Content
            SingleChildScrollView(
              child: isTablet
                  ? _buildTabletLayout(screenWidth)
                  : _buildMobileLayout(screenWidth),
            ),
            // Floating Header
            _buildHeader(),
          ],
        );
      },
    );
  }

  Widget _buildTabletLayout(double screenWidth) {
    return Padding(
      padding: const EdgeInsets.only(top: 80, bottom: 20, left: 20, right: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: _buildMediaGallery(isTablet: true, screenWidth: screenWidth),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 4,
            child: _buildContentCard(isTablet: true),
          ),
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

  Widget _buildHeader() {
    final String productId = "pd1";
    final isFavorite = Provider.of<WishlistProvider>(context).isInWishlist(productId);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCircularButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
            Row(
              children: [
                _buildCircularButton(
                  icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                  iconColor: isFavorite ? Colors.red : Colors.black,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Provider.of<WishlistProvider>(context, listen: false).toggleWishlist({
                      "id": productId,
                      "name": "Gold Earring",
                      "category": "Earrings",
                      "price": _totalPrice,
                      "originalPrice": 1500.0,
                      "rating": 4.8,
                      "image": _images[0],
                    });
                  },
                ),
                const SizedBox(width: 12),
                _buildCircularButton(
                  icon: Icons.share_outlined,
                  onTap: () {
                    Share.share('Check out this amazing Gold Earring for \$${_totalPrice.toStringAsFixed(0)}! https://jewelry-app.com/product/$productId');
                  },
                ),
                const SizedBox(width: 12),
                _buildCircularButton(
                  icon: Icons.chat_bubble_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SellerChatScreen(
                          initialProduct: {
                            "id": "pd1",
                            "name": "Gold Earring",
                            "category": "Earrings",
                            "price": _totalPrice,
                            "originalPrice": 1500.0,
                            "rating": 4.8,
                            "image": _images[0],
                          },
                          sellerName: 'Product Support',
                          sellerAvatar: 'https://i.pravatar.cc/150?u=support',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _buildMediaGallery({required bool isTablet, required double screenWidth}) {
    if (isTablet) {
      return SizedBox(
        height: 600, // Taller gallery for tablet
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: ListView.builder(
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildThumbnail(index),
                  );
                },
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedImageIndex = index;
                  });
                },
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return _buildGalleryImage(_images[index], index);
                },
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        height: 480,
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1), // ~80% width
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedImageIndex = index;
                    });
                  },
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return _buildGalleryImage(_images[index], index);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildThumbnail(index),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    }
  }

  Widget _buildThumbnail(int index) {
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedImageIndex == index
                ? const Color(0xFF333333)
                : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage(_images[index]),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryImage(String imageUrl, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImageGallery(
              images: _images,
              initialIndex: index,
            ),
          ),
        );
      },
      child: Hero(
        tag: 'product_image_$index',
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  Widget _buildContentCard({bool isTablet = false}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 0.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, isTablet ? 0 : 100 * value), // Don't translate slide up much on tablet
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: isTablet 
              ? BorderRadius.circular(24) 
              : const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            if (!isTablet)
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            if (isTablet)
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPrimaryInfo(),
            const SizedBox(height: 24),
            _buildAttributes(),
            const SizedBox(height: 24),
            _buildDescription(),
            const SizedBox(height: 24),
            _buildExpandableSection('Materials & Specifications', 'Crafted from solid 18K/22K gold, meticulously hand-polished to achieve an immaculate shine. Avoid exposing to harsh chemicals.'),
            _buildExpandableSection('Care & Maintenance', 'Clean gently with a soft cloth and mild soapy water. Store in the provided velvet pouch when not in use to prevent scratching.'),
            _buildExpandableSection('Shipping & Returns', 'Complimentary insured overnight shipping. Free returns within 30 days of purchase in unworn condition with original packaging.'),
            const SizedBox(height: 32),
            _buildRelatedProducts(),
            if (!isTablet) const SizedBox(height: 100), // Extra space for footer only for mobile
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Earrings',
              style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/review');
              },
              child: Row(
                children: const [
                  Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                  SizedBox(width: 4),
                  Text(
                    '4.8 (124 reviews)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Gold Earring',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildAttributes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Purity',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: ['18 KT', '22 KT'].map((purity) {
            final isSelected = _selectedPurity == purity;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedPurity = purity),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF333333) : Colors.white,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF333333) : const Color(0xFFEFEFEF),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    purity,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF333333),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Size',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => FractionallySizedBox(
                    heightFactor: 0.8,
                    child: SizeGuideBottomSheet(
                      initialSize: _selectedSize,
                      onSizeSelected: (size) {
                        setState(() {
                          _selectedSize = size;
                          _sizeError = '';
                        });
                      },
                    ),
                  ),
                );
              },
              child: const Text('Size Guide', style: TextStyle(decoration: TextDecoration.underline)),
            )
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ['5', '6', '7', '8', '9'].map((size) {
            final isSelected = _selectedSize == size;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedSize = size;
                _sizeError = '';
              }),
              child: Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  size,
                  style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
        ),
        if (_sizeError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(_sizeError, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 24),
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
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18),
                    onPressed: () => setState(() => _qty = _qty > 1 ? _qty - 1 : 1),
                  ),
                  Text('$_qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () => setState(() => _qty = _qty < _stock ? _qty + 1 : _stock),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription() {
    const descriptionText = 
      "This elegant gold earring is crafted with precision to bring out the natural glow of the wearer. "
      "Perfect for any occasion, from casual outings to formal events. "
      "Its timeless design ensures it remains a staple in your jewelry collection for years to come. "
      "Made with the highest quality gold, it's both durable and stunning.";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                descriptionText,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF777777),
                  height: 1.5,
                ),
                maxLines: _isDescriptionExpanded ? null : 3,
                overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _isDescriptionExpanded ? 'Read Less' : 'Read More',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection(String title, String content) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        iconColor: const Color(0xFF333333),
        collapsedIconColor: const Color(0xFF999999),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              content,
              style: const TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.5),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRelatedProducts() {
    final related = [
      {"id": "pd2", "name": "Diamond Ring", "price": 2500.0, "image": "https://i.postimg.cc/4yh339Lk/h7.jpg", "rating": 4.9, "category": "Rings"},
      {"id": "pd3", "name": "Silver Bracelet", "price": 450.0, "image": "https://i.postimg.cc/cHWq3842/h8.jpg", "rating": 4.5, "category": "Bracelets"},
      {"id": "pd4", "name": "Small Studs", "price": 120.0, "image": "https://i.postimg.cc/zv06gtVy/h9.jpg", "rating": 4.7, "category": "Earrings"},
      {"id": "pd5", "name": "Gold Chain", "price": 600.0, "image": "https://i.postimg.cc/pL94mBxp/h10.jpg", "rating": 4.8, "category": "Necklaces"},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'You May Also Like',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: related.length,
          itemBuilder: (context, index) {
            return ProductCard(
              product: related[index],
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductDetailScreen()),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 15,
        bottom: MediaQuery.of(context).padding.bottom + 15,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _stock == 0 ? null : () {
                if (_selectedSize.isEmpty) {
                  setState(() => _sizeError = 'Please select all required options before purchasing');
                  return;
                }
                final cart = Provider.of<CartProvider>(context, listen: false);
                cart.addToCart({
                  "id": "pd1", // mocked
                  "name": "Gold Earring",
                  "price": _totalPrice,
                  "image": _images[0],
                  "purity": _selectedPurity,
                  "size": _selectedSize,
                  "stock": _stock,
                }, qty: _qty);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to Shopping Bag')),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF333333)),
                foregroundColor: const Color(0xFF333333),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Add to Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _stock == 0 ? null : () {
                if (_selectedSize.isEmpty) {
                  setState(() => _sizeError = 'Please select all required options before purchasing');
                  return;
                }
                // Immediately proceed to checkout placeholder
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Proceeding to Checkout...')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _stock == 0 ? Colors.grey : const Color(0xFF333333),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: Text(
                _stock == 0 ? 'Out of Stock' : 'Buy Now',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Stack(
        children: [
          Column(
            children: [
              Container(height: 350, color: Colors.white),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 100, height: 14, color: Colors.white),
                      const SizedBox(height: 10),
                      Container(width: 200, height: 24, color: Colors.white),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          const CircleAvatar(radius: 25, backgroundColor: Colors.white),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(width: 100, height: 16, color: Colors.white),
                              const SizedBox(height: 6),
                              Container(width: 60, height: 14, color: Colors.white),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Container(width: 80, height: 16, color: Colors.white),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(width: 80, height: 40, color: Colors.white),
                          const SizedBox(width: 12),
                          Container(width: 80, height: 40, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
