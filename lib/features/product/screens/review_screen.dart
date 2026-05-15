import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductReviewScreen extends StatefulWidget {
  const ProductReviewScreen({super.key});

  @override
  State<ProductReviewScreen> createState() => _ProductReviewScreenState();
}

class _ProductReviewScreenState extends State<ProductReviewScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Verified', 'Latest', 'Detailed Reviews'];

  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = true;
  String _productId = '';

  late AnimationController _barController;
  late Animation<double> _barAnimation;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _barAnimation = CurvedAnimation(parent: _barController, curve: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Try to get productId from route arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) {
      _productId = args;
    } else if (args is Map<String, dynamic>) {
      _productId = args['productId']?.toString() ?? '';
    }
    if (_productId.isNotEmpty && _isLoadingReviews) {
      _loadReviews();
    } else if (_productId.isEmpty && _isLoadingReviews) {
      // Fallback: load reviews from the first available product
      _loadFallbackReviews();
    }
  }

  Future<void> _loadReviews() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('products')
          .doc(_productId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();
      if (mounted) {
        setState(() {
          _reviews = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          _isLoadingReviews = false;
        });
        _barController.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingReviews = false);
      _barController.forward();
    }
  }

  Future<void> _loadFallbackReviews() async {
    try {
      // Find any product that has reviews
      final productsSnap = await FirebaseFirestore.instance
          .collection('products')
          .limit(5)
          .get();
      for (final doc in productsSnap.docs) {
        final reviewsSnap = await doc.reference
            .collection('reviews')
            .orderBy('createdAt', descending: true)
            .get();
        if (reviewsSnap.docs.isNotEmpty) {
          _productId = doc.id;
          if (mounted) {
            setState(() {
              _reviews = reviewsSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
              _isLoadingReviews = false;
            });
            _barController.forward();
            return;
          }
        }
      }
      if (mounted) {
        setState(() => _isLoadingReviews = false);
        _barController.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingReviews = false);
      _barController.forward();
    }
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0.0;
    final total = _reviews.fold<double>(0, (acc, r) => acc + ((r['rating'] as num?)?.toDouble() ?? 0));
    return total / _reviews.length;
  }

  Map<int, double> get _ratingDistribution {
    if (_reviews.isEmpty) return {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    final dist = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _reviews) {
      final rating = ((r['rating'] as num?)?.toDouble() ?? 0).round().clamp(1, 5);
      dist[rating] = (dist[rating] ?? 0) + 1;
    }
    return dist.map((k, v) => MapEntry(k, v / _reviews.length));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 20),
                _buildRatingSummary(),
                const SizedBox(height: 30),
                _buildSearchBar(),
                const SizedBox(height: 20),
                _buildFilterChips(),
                const SizedBox(height: 20),
                _buildReviewList(),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Center(
        child: GestureDetector(
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
      ),
      title: const Text(
        'Review',
        style: TextStyle(
          color: Color(0xFF333333),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildRatingSummary() {
    final distribution = _ratingDistribution;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _averageRating.toStringAsFixed(1),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  Icons.star,
                  color: index < _averageRating.round() ? const Color(0xFFFFD700) : const Color(0xFFE0E0E0),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_reviews.length} Reviews',
              style: const TextStyle(color: Color(0xFF999999), fontSize: 14),
            ),
          ],
        ),
        const SizedBox(width: 40),
        Expanded(
          child: Column(
            children: [
              _buildRatingBar(5, distribution[5] ?? 0),
              _buildRatingBar(4, distribution[4] ?? 0),
              _buildRatingBar(3, distribution[3] ?? 0),
              _buildRatingBar(2, distribution[2] ?? 0),
              _buildRatingBar(1, distribution[1] ?? 0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBar(int star, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$star', style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(3),
              ),
              child: AnimatedBuilder(
                animation: _barAnimation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage * _barAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF999999)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search reviews...',
                hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterIconChip(),
          const SizedBox(width: 10),
          ..._filters.map((filter) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _buildFilterChip(filter),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterIconChip() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.tune, size: 20, color: Color(0xFF333333)),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF333333) : Colors.white,
          border: Border.all(color: isSelected ? const Color(0xFF333333) : const Color(0xFFEEEEEE)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF333333),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reviews.length,
      separatorBuilder: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Divider(color: Color(0xFFF5F5F5), height: 1),
      ),
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return _buildReviewCard(review);
      },
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: (review['avatar'] as String).isNotEmpty ? NetworkImage(review['avatar']) : null,
                ),
                if (review['isVerified'])
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle, color: Colors.blue, size: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review['name'],
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  ),
                  Text(
                    review['date'],
                    style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ],
              ),
            ),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  Icons.star,
                  color: index < review['rating'] ? const Color(0xFFFFD700) : const Color(0xFFE0E0E0),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          review['comment'],
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF777777),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
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
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/leave-review');
        },
        child: Container(
          height: 55,
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Center(
            child: Text(
              'Write Review',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
