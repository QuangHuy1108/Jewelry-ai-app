import 'package:flutter/material.dart';
import '../widgets/special_offer_card.dart';

class SpecialOffersScreen extends StatefulWidget {
  const SpecialOffersScreen({super.key});

  @override
  State<SpecialOffersScreen> createState() => _SpecialOffersScreenState();
}

class _SpecialOffersScreenState extends State<SpecialOffersScreen> {
  bool _isLoading = true;
  final List<Map<String, dynamic>> _offers = [];

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    // Simulate API fetch delay
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _offers.addAll([
          {
            'tag': 'Limited time!',
            'title': 'Summer Collection',
            'discount': '40',
          },
          {
            'tag': 'New Arrival',
            'title': 'Diamond Rings',
            'discount': '25',
          },
          {
            'tag': 'Exclusive',
            'title': 'Gold Necklaces',
            'discount': '15',
          },
          {
            'tag': 'Clearance',
            'title': 'Silver Bracelets',
            'discount': '50',
          },
        ]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        bottom: false, // Handle bottom safe area in the ListView
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _offers.isEmpty
                      ? _buildEmptyState()
                      : _buildOffersList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 70, // Height: 60px - 80px as requested
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFFFFFFFF),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF333333), size: 20),
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Special Offers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
          const SizedBox(width: 40), // Balance the flex layout to center the title
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 40),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return const ShimmerOfferCard();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Empty Offers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No promotions are currently active.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersList() {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    
    return ListView.separated(
      // Ensure the bottom-most banner has enough padding-bottom
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 16 + bottomPadding, 
      ),
      itemCount: _offers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final offer = _offers[index];
        return TweenAnimationBuilder<double>(
          // Slide-up or Fade-in animation for list items
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: SpecialOfferCard(
            tag: offer['tag'],
            title: offer['title'],
            discount: offer['discount'],
            onOrderNow: () {
              // Navigating user to a specific product category
              debugPrint('Navigate to category for: ${offer['title']}');
            },
          ),
        );
      },
    );
  }
}
