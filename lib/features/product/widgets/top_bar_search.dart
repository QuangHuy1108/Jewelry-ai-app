import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../../../shared/widgets/cart_badge_icon.dart';
import '../../../../router/app_navigation.dart';

class TopBarWithSearch extends StatefulWidget {
  final Map<String, dynamic> product;

  const TopBarWithSearch({super.key, required this.product});

  @override
  State<TopBarWithSearch> createState() => _TopBarWithSearchState();
}

class _TopBarWithSearchState extends State<TopBarWithSearch> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  List<String> _suggestions = [];

  final List<String> _allMockTags = [
    "Gold Bracelet", "Silver Ring", "Diamond Necklace", "Pearl Earring",
    "Platinum Chain", "Choker", "Tennis Bracelet", "Sapphire Ring",
    "Emerald Pendant"
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _hideOverlay();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.trim().isEmpty) {
        setState(() => _suggestions = []);
      } else {
        final lowerQuery = query.toLowerCase();
        final matches = _allMockTags
            .where((tag) => tag.toLowerCase().contains(lowerQuery))
            .take(3)
            .toList();
        setState(() => _suggestions = matches);
      }
      _overlayEntry?.markNeedsBuild();
    });
  }

  void _submitSearch(String query) {
    _focusNode.unfocus();
    _searchController.clear();
    setState(() => _suggestions = []);
    Navigator.pushNamed(context, '/search');
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        if (_suggestions.isEmpty && _searchController.text.isEmpty) return const SizedBox.shrink();

        return Positioned(
          width: renderBox.size.width - 120, // Approximate width of the search container
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 48), // Push it exactly below the bar
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _suggestions.isEmpty ? 1 : _suggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (_suggestions.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text("No suggestions", style: TextStyle(color: Colors.grey)),
                      );
                    }
                    final suggestion = _suggestions[index];
                    return InkWell(
                      onTap: () {
                        _submitSearch(suggestion);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(child: Text(suggestion, style: const TextStyle(fontSize: 14))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.select<WishlistProvider, bool>((w) => w.isInWishlist(widget.product['id']));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildCircularButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CompositedTransformTarget(
                link: _layerLink,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))
                    ]
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_searchController.text.isNotEmpty) {
                            _submitSearch(_searchController.text);
                          } else {
                            _submitSearch("");
                          }
                        },
                        child: Icon(Icons.search, color: Colors.grey.shade600, size: 18),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          onChanged: _onSearchChanged,
                          onSubmitted: _submitSearch,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildCircularButton(
              icon: isFavorite ? Icons.favorite : Icons.favorite_border,
              iconColor: isFavorite ? Colors.red : Colors.black,
              onTap: () => context.read<WishlistProvider>().toggleWishlist(widget.product),
            ),
            const SizedBox(width: 6),
            _buildCircularButton(
              icon: Icons.ios_share,
              onTap: () => Share.share('Check out this luxurious ${widget.product['name']}!'),
            ),
            const SizedBox(width: 6),
            _buildCircularButtonWidget(
              child: const CartIconWithBadge(iconData: Icons.shopping_bag_outlined, iconColor: Colors.black, size: 20),
              onTap: () => Navigator.pushNamed(context, '/cart'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularButton({required IconData icon, required VoidCallback onTap, Color iconColor = Colors.black}) {
    return _buildCircularButtonWidget(
      onTap: onTap,
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  Widget _buildCircularButtonWidget({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
