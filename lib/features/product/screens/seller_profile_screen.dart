import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/seller_model.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
import '../../../core/theme/product_grid_constants.dart';
import 'package:jewelry_app/services/product_service.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  bool _isDescriptionExpanded = false;
  Seller? _seller;
  bool _isLoading = true;
  List<Map<String, dynamic>> _bestSellingProducts = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      _loadSellerData();
    }
  }

  Future<void> _loadSellerData() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final sellerId = args?['id']?.toString() ?? '';

    try {
      // Try loading from Firestore first
      if (sellerId.isNotEmpty) {
        final sellerData = await ProductService().getSellerById(sellerId);
        if (sellerData != null) {
          _applySellerData(sellerData);
          await _loadBestSellingProducts();
          return;
        }
      }

      // If no ID or not found in Firestore, try to get any seller from Firestore
      final sellers = await ProductService().getSellers();
      if (sellers.isNotEmpty) {
        final sellerData = sellers.first;
        // Override with navigation args if they have name/avatar
        if (args != null) {
          sellerData['name'] = args['name'] ?? sellerData['name'];
          sellerData['avatar'] = args['avatar'] ?? sellerData['avatar'];
        }
        _applySellerData(sellerData);
        await _loadBestSellingProducts();
        return;
      }

      // Final fallback: construct from route arguments alone
      if (args != null) {
        _applySellerData(args);
        await _loadBestSellingProducts();
      }
    } catch (_) {
      // Use route arguments as fallback
      if (args != null) {
        _applySellerData(args);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applySellerData(Map<String, dynamic> data) {
    final ratingsRaw = data['ratings'];
    Map<String, double> ratings = {};
    if (ratingsRaw is Map) {
      ratings = ratingsRaw.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    }

    _seller = Seller(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Seller',
      avatar: data['avatar'] ?? '',
      coverImage: data['coverImage'] ?? 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=1000&auto=format&fit=crop',
      description: data['description'] ?? '',
      experienceYears: (data['experienceYears'] as num?)?.toInt() ?? 0,
      totalSold: (data['totalSold'] as num?)?.toInt() ?? 0,
      returningCustomers: (data['returningCustomers'] as num?)?.toDouble() ?? 0,
      followersCount: (data['followersCount'] as num?)?.toInt() ?? 0,
      favoritesCount: (data['favoritesCount'] as num?)?.toInt() ?? 0,
      ratings: ratings,
      bestSellingProducts: _bestSellingProducts,
    );
  }

  Future<void> _loadBestSellingProducts() async {
    try {
      final products = await ProductService().searchProducts('');
      if (mounted) {
        setState(() {
          _bestSellingProducts = products.take(3).toList();
          _seller = _seller != null
              ? Seller(
                  id: _seller!.id,
                  name: _seller!.name,
                  avatar: _seller!.avatar,
                  coverImage: _seller!.coverImage,
                  description: _seller!.description,
                  experienceYears: _seller!.experienceYears,
                  totalSold: _seller!.totalSold,
                  returningCustomers: _seller!.returningCustomers,
                  followersCount: _seller!.followersCount,
                  favoritesCount: _seller!.favoritesCount,
                  ratings: _seller!.ratings,
                  bestSellingProducts: _bestSellingProducts,
                )
              : null;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF333333))),
      );
    }

    if (_seller == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
        body: const Center(child: Text('Seller not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicInfo(),
                  const SizedBox(height: 24),
                  _buildMetrics(),
                  const SizedBox(height: 32),
                  _buildDetailedRatings(),
                  const SizedBox(height: 32),
                  _buildBestSellingProducts(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover Image
        _seller!.coverImage.isNotEmpty
            ? Image.network(
                _seller!.coverImage,
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.3,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.3,
                  color: Colors.grey.shade300,
                ),
              )
            : Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.3,
                color: Colors.grey.shade300,
              ),
        // Back Button
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 10,
          child: CircleAvatar(
            backgroundColor: Colors.black26,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        // Chat Button
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 10,
          child: CircleAvatar(
            backgroundColor: Colors.black26,
            child: IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              onPressed: () {
                final product = context.read<ProductProvider>().product;
                Map<String, dynamic>? productCtx;
                if (product.isNotEmpty) {
                  final images = product['images'] as List<dynamic>?;
                  final firstImage = images?.firstWhere(
                    (u) => !u.toString().endsWith('.mp4'),
                    orElse: () => '',
                  ) ?? '';
                  productCtx = {
                    'id': product['id'] ?? '',
                    'name': product['name'] ?? '',
                    'image': firstImage,
                    'price': product['basePrice'],
                  };
                }
                Navigator.pushNamed(context, '/chat-detail', arguments: {
                  'sellerId': _seller!.id,
                  'sellerName': _seller!.name,
                  'sellerAvatar': _seller!.avatar,
                  'productContext': productCtx,
                });
              },
            ),
          ),
        ),
        // Avatar
        Positioned(
          bottom: -40,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundImage: _seller!.avatar.isNotEmpty ? NetworkImage(_seller!.avatar) : null,
              backgroundColor: Colors.grey.shade200,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48), // Padding for Avatar overlap
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _seller!.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Follow/Favorite Buttons
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _seller!.isFollowing = !_seller!.isFollowing;
                  if (_seller!.isFollowing) {
                    _seller!.followersCount++;
                  } else {
                    _seller!.followersCount--;
                  }
                  // In a real app, update Provider/API
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _seller!.isFollowing ? Colors.grey.shade300 : const Color(0xFF333333),
                foregroundColor: _seller!.isFollowing ? Colors.black : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                minimumSize: const Size(100, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
                _seller!.isFollowing ? 'Following' : 'Follow',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _seller!.isFavorite = !_seller!.isFavorite;
                  if (_seller!.isFavorite) {
                    _seller!.favoritesCount++;
                  } else {
                    _seller!.favoritesCount--;
                  }
                  // In a real app, update Provider/API
                });
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                side: const BorderSide(color: Color(0xFFEEEEEE)),
                minimumSize: const Size(100, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              icon: Icon(
                _seller!.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _seller!.isFavorite ? Colors.red : const Color(0xFF777777),
                size: 18,
              ),
              label: const Text('Favorite', style: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Text(
                  _seller!.description,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF777777), height: 1.5),
                  maxLines: _isDescriptionExpanded ? null : 3,
                  overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    _isDescriptionExpanded ? 'Show less' : 'Read more',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  ),
                  Icon(
                    _isDescriptionExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: const Color(0xFF333333),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetrics() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMetricItem('${_seller!.followersCount}', 'Followers'),
          _buildVerticalDivider(),
          _buildMetricItem('${_seller!.favoritesCount}', 'Favorites'),
          _buildVerticalDivider(),
          _buildMetricItem('${_seller!.returningCustomers.toInt()}%', 'Returning'),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: const Color(0xFFEEEEEE));
  }

  Widget _buildDetailedRatings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Service Quality', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        const SizedBox(height: 16),
        ..._seller!.ratings.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(entry.key, style: const TextStyle(fontSize: 14, color: Color(0xFF777777))),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            size: 14,
                            color: index < entry.value.floor() ? const Color(0xFFFFD700) : const Color(0xFFE0E0E0),
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          entry.value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildBestSellingProducts() {
    if (_seller!.bestSellingProducts.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Best Selling', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        const SizedBox(height: 16),
        SizedBox(
          height: ProductGridConstants.horizontalListHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _seller!.bestSellingProducts.length,
            itemBuilder: (context, index) {
              return Container(
                width: ProductGridConstants.horizontalCardWidth,
                margin: const EdgeInsets.only(right: ProductGridConstants.horizontalCardSpacing),
                child: ProductCard(
                  product: _seller!.bestSellingProducts[index],
                  onTap: () {
                    // Navigate to product detail
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
