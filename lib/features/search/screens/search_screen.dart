import 'dart:async';
import 'package:flutter/material.dart';
import '../../home/widgets/search_bar_widget.dart';
import '../widgets/suggestion_list.dart';
import '../widgets/recent_search_list.dart';
import 'search_results_screen.dart';
import '../../../../core/state/filter_state.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  String _query = "";
  bool isLoadingViews = true;

  final List<Map<String, dynamic>> recentViews = [
    {
      "name": "Luxury Gold Ring with Diamonds and nice shiny finish",
      "price": "\$1200",
      "oldPrice": "\$1500",
      "rating": "4.8",
      "image": "https://i.postimg.cc/cHWq3842/h8.jpg"
    },
    {
      "name": "Silver Choker Bracelet",
      "price": "\$450",
      "oldPrice": "\$600",
      "rating": "4.5",
      "image": "https://i.postimg.cc/4yh339Lk/h7.jpg"
    },
  ];
  
  List<String> suggestions = [];

  final List<String> _mockData = [
    "Diamond Ring",
    "Diamond Necklace",
    "Diamond Earrings",
    "Gold Ring",
    "Gold Necklace",
    "Gold Bracelet",
    "Silver Ring",
    "Silver Bracelet",
    "Ruby Pendant",
    "Sapphire Ring",
    "Pearl Necklace",
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isLoadingViews = false;
        });
      }
    });
    Future.microtask(() => _searchFocusNode.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    setState(() {
      _query = query;
    });

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.trim().isNotEmpty) {
        setState(() {
          suggestions = _mockData
              .where((item) => item.toLowerCase().contains(query.toLowerCase()))
              .toList();
        });
      } else {
        setState(() {
          suggestions.clear();
        });
      }
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      FilterState().addRecentSearch(query);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(initialQuery: query.trim()),
        ),
      );
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged("");
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: TweenAnimationBuilder<Offset>(
          tween: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          builder: (context, offset, child) {
            return FractionalTranslation(translation: offset, child: child);
          },
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _query.isEmpty
                    ? AnimatedBuilder(
                        animation: FilterState(),
                        builder: (context, _) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RecentSearchList(
                                  recentSearches: FilterState().recentSearches,
                                  onSelect: _onSearchSubmitted,
                                  onRemove: (val) => FilterState().removeRecentSearch(val),
                                  onClearAll: () => FilterState().clearRecentSearches(),
                                ),
                                const SizedBox(height: 24),
                                _buildTrendingSearch(),
                                const SizedBox(height: 24),
                                _buildRecentView(),
                              ],
                            ),
                          );
                        },
                      )
                    : SuggestionList(
                        suggestions: suggestions,
                        onSelect: _onSearchSubmitted,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _AnimatedBackButton(),
          const SizedBox(width: 12),
          Expanded(
            child: SearchBarWidget(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              onSubmitted: _onSearchSubmitted,
              onClear: _clearSearch,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingSearch() {
    final List<String> trending = ["Diamond Ring", "Minimalist Watch", "Pearl Earrings", "Platinum Band"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Trending Search",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: trending.map((item) {
            return GestureDetector(
              onTap: () => _onSearchSubmitted(item),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item,
                  style: const TextStyle(color: Color(0xFF555555)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Expanded(
              child: Text(
                "Recent View",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoadingViews)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _buildSkeletonItem(),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentViews.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final product = recentViews[index];
              return _AnimatedOpacityItem(
                onTap: () {},
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(product["image"], fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  product["name"],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    product["rating"],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                product["price"],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                product["oldPrice"],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSkeletonItem() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 16, width: double.infinity, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Container(height: 16, width: 100, color: Colors.grey.shade300),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedBackButton extends StatefulWidget {
  @override
  State<_AnimatedBackButton> createState() => _AnimatedBackButtonState();
}

class _AnimatedBackButtonState extends State<_AnimatedBackButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
        ),
      ),
    );
  }
}

class _AnimatedOpacityItem extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedOpacityItem({required this.child, required this.onTap});

  @override
  State<_AnimatedOpacityItem> createState() => _AnimatedOpacityItemState();
}

class _AnimatedOpacityItemState extends State<_AnimatedOpacityItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        opacity: _isPressed ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
