import 'package:flutter/material.dart';

class ProductReviewScreen extends StatefulWidget {
  const ProductReviewScreen({super.key});

  @override
  State<ProductReviewScreen> createState() => _ProductReviewScreenState();
}

class _ProductReviewScreenState extends State<ProductReviewScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Verified', 'Latest', 'Detailed Reviews'];

  final List<Map<String, dynamic>> _reviews = [
    {
      "name": "Alex Johnson",
      "date": "2 days ago",
      "rating": 5.0,
      "comment": "Absolutely stunning! The gold quality is top-notch and the design is even better in person. Highly recommend for any gift.",
      "isVerified": true,
      "avatar": "https://i.pravatar.cc/150?u=alex"
    },
    {
      "name": "Maria Garcia",
      "date": "1 week ago",
      "rating": 4.0,
      "comment": "Very beautiful earrings. They are a bit smaller than I expected based on the photos, but the craftsmanship is excellent.",
      "isVerified": true,
      "avatar": "https://i.pravatar.cc/150?u=maria"
    },
    {
      "name": "James Smith",
      "date": "2 weeks ago",
      "rating": 5.0,
      "comment": "Perfect anniversary gift! My wife loves them. Fast shipping and great packaging.",
      "isVerified": false,
      "avatar": "https://i.pravatar.cc/150?u=james"
    },
  ];

  late AnimationController _barController;
  late Animation<double> _barAnimation;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _barAnimation = CurvedAnimation(parent: _barController, curve: Curves.easeOut);
    _barController.forward();
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
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '4.9',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            Row(
              children: List.generate(
                5,
                (index) => const Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '124 Reviews',
              style: TextStyle(color: Color(0xFF999999), fontSize: 14),
            ),
          ],
        ),
        const SizedBox(width: 40),
        Expanded(
          child: Column(
            children: [
              _buildRatingBar(5, 0.8),
              _buildRatingBar(4, 0.15),
              _buildRatingBar(3, 0.03),
              _buildRatingBar(2, 0.01),
              _buildRatingBar(1, 0.01),
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
                  backgroundImage: NetworkImage(review['avatar']),
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
