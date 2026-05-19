import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../../../shared/widgets/cart_badge_icon.dart';
import '../../../core/theme/app_colors.dart';
import 'package:jewelry_app/services/product_service.dart';
import '../../share/widgets/glass_share_modal.dart';

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
  List<String> _allProductTags = [];

  @override
  void initState() {
    super.initState();
    _loadProductTags();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    });
  }

  Future<void> _loadProductTags() async {
    try {
      final products = await ProductService().getAllProductNames();
      if (mounted) {
        setState(() {
          _allProductTags = products.map((p) => p['name'].toString()).toSet().toList();
        });
      }
    } catch (_) {}
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
        final matches = _allProductTags
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
          width: renderBox.size.width - 120,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 48),
            child: Material(
              elevation: 0,
              borderRadius: BorderRadius.circular(16),
              color: AppColors.canvas,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.hairline, width: 1),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.canvas,
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _suggestions.isEmpty ? 1 : _suggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.hairline),
                  itemBuilder: (context, index) {
                    if (_suggestions.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text("No suggestions", style: TextStyle(color: AppColors.inkMuted48)),
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
                            const Icon(Icons.search, size: 16, color: AppColors.inkMuted48),
                            const SizedBox(width: 8),
                            Expanded(child: Text(suggestion, style: const TextStyle(fontSize: 14, color: AppColors.ink))),
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
                  height: 44, // standard 44px pill token height
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(9999), // round.pill
                    border: Border.all(color: AppColors.hairline, width: 1), // flat hairline outline
                    // strict enforcement of single shadow rule
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
                        child: const Icon(Icons.search, color: AppColors.ink, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          onChanged: _onSearchChanged,
                          onSubmitted: _submitSearch,
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            hintText: 'Search collection...',
                            hintStyle: TextStyle(
                              color: AppColors.inkMuted48, 
                              fontSize: 14, // SF Pro body alignment
                              letterSpacing: -0.224,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            color: AppColors.ink, 
                            fontSize: 14,
                            letterSpacing: -0.224,
                          ),
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
              iconColor: isFavorite ? const Color(0xFFE53935) : AppColors.ink,
              onTap: () => context.read<WishlistProvider>().toggleWishlist(widget.product),
            ),
            const SizedBox(width: 6),
            _buildCircularButton(
              icon: Icons.ios_share,
              onTap: () => GlassShareModal.show(context, product: widget.product),
            ),
            const SizedBox(width: 6),
            _buildCircularButtonWidget(
              child: const CartIconWithBadge(iconData: Icons.shopping_bag_outlined, iconColor: AppColors.ink, size: 20),
              onTap: () => Navigator.pushNamed(context, '/cart'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularButton({required IconData icon, required VoidCallback onTap, Color iconColor = AppColors.ink}) {
    return _buildCircularButtonWidget(
      onTap: onTap,
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  Widget _buildCircularButtonWidget({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44, // standard touch target circular float button size token
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.canvas,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.hairline, width: 1), // flat profile
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
