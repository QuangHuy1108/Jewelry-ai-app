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
  List<Map<String, dynamic>> _sellerReviews = [];
  bool _isLoadingReviews = true;
  bool _isLoadingSellerReviews = true;
  String _productId = '';
  String _sellerId = '';

  late TabController _tabController;

  late AnimationController _barController;
  late Animation<double> _barAnimation;
  Map<String, dynamic>? _productArgs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _searchController.addListener(_onSearchChanged);
    _barController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _barAnimation = CurvedAnimation(parent: _barController, curve: Curves.easeOut);
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Try to get productId from route arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) {
      _productId = args;
    } else if (args is Map<String, dynamic>) {
      _productId = (args['id'] ?? args['productId'])?.toString() ?? '';
      _sellerId = args['sellerId']?.toString() ?? '';
      _productArgs = args;
    }
    if (_productId.isNotEmpty && _isLoadingReviews) {
      _loadReviews();
    } else if (_productId.isEmpty && _isLoadingReviews) {
      _loadFallbackReviews();
    }
    if (_sellerId.isNotEmpty && _isLoadingSellerReviews) {
      _loadSellerReviews();
    } else {
      _isLoadingSellerReviews = false;
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

  Future<void> _loadSellerReviews() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(_sellerId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();
      if (mounted) {
        setState(() {
          _sellerReviews = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          _isLoadingSellerReviews = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSellerReviews = false);
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

  List<Map<String, dynamic>> get _currentReviews {
    return _tabController.index == 0 ? _reviews : _sellerReviews;
  }

  double get _averageRating {
    if (_currentReviews.isEmpty) return 0.0;
    final total = _currentReviews.fold<double>(0, (acc, r) => acc + ((r['rating'] as num?)?.toDouble() ?? 0));
    return total / _currentReviews.length;
  }

  Map<int, double> get _ratingDistribution {
    if (_currentReviews.isEmpty) return {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    final dist = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _currentReviews) {
      final rating = ((r['rating'] as num?)?.toDouble() ?? 0).round().clamp(1, 5);
      dist[rating] = (dist[rating] ?? 0) + 1;
    }
    return dist.map((k, v) => MapEntry(k, v / _currentReviews.length));
  }

  List<Map<String, dynamic>> get _filteredReviews {
    var result = _currentReviews;
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((r) => 
        (r['comment']?.toString().toLowerCase() ?? '').contains(query) ||
        (r['name']?.toString().toLowerCase() ?? '').contains(query)
      ).toList();
    }
    if (_selectedFilter == 'Verified') {
      result = result.where((r) => r['isVerified'] == true).toList();
    } else if (_selectedFilter == 'Detailed Reviews') {
      result = result.where((r) => (r['comment']?.toString().length ?? 0) > 20).toList();
    }
    return result;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Recently';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      return timestamp;
    } else {
      return 'Recently';
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReviewTabContent(),
                _buildReviewTabContent(),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildReviewTabContent() {
    final bool isLoading = _tabController.index == 0 ? _isLoadingReviews : _isLoadingSellerReviews;
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }
    return ListView(
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
        'Reviews',
        style: TextStyle(
          color: Color(0xFF333333),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      bottom: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF333333),
        unselectedLabelColor: const Color(0xFF999999),
        indicatorColor: const Color(0xFF333333),
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Product Reviews'),
          Tab(text: 'Seller Reviews'),
        ],
      ),
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
              '${_currentReviews.length} Reviews',
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
    final reviewsToDisplay = _filteredReviews;
    if (reviewsToDisplay.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text("No reviews match your filters.", style: TextStyle(color: Colors.grey))),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviewsToDisplay.length,
      separatorBuilder: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Divider(color: Color(0xFFF5F5F5), height: 1),
      ),
      itemBuilder: (context, index) {
        final review = reviewsToDisplay[index];
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
                  backgroundImage: (review['avatar']?.toString() ?? '').isNotEmpty ? NetworkImage(review['avatar']) : null,
                  backgroundColor: Colors.grey.shade200,
                  child: (review['avatar']?.toString() ?? '').isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        review['name'] ?? 'Anonymous User',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                      ),
                      if (review['isVerified'] == true) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.check_circle, color: Colors.blue, size: 14),
                        const SizedBox(width: 4),
                        const Text('Verified Purchase', style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                  Text(
                    _formatDate(review['createdAt'] ?? review['date']),
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
          review['comment'] ?? '',
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
          Navigator.pushNamed(context, '/leave-review', arguments: _productArgs);
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
