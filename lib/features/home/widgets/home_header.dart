import 'dart:async';
import 'package:flutter/material.dart';
import '../../search/screens/search_results_screen.dart';
import '../../filter/widgets/quick_filter_bottom_sheet.dart';
import '../../../../core/state/filter_state.dart';
import 'search_bar_widget.dart';
import 'suggestion_dropdown.dart';
import '../../../router/app_router.dart';
import 'package:provider/provider.dart';
import '../../notification/providers/notification_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'package:jewelry_app/services/product_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _searchBarKey = GlobalKey();
  
  Timer? _debounce;
  List<String> _suggestions = [];
  OverlayEntry? _overlayEntry;
  List<String> _allProductNames = [];
  String _currentLocation = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadProductNames();
    _loadSavedLocation();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Delay hiding so taps on dropdown can register
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) _removeOverlay();
        });
      } else if (_searchController.text.isNotEmpty && _suggestions.isNotEmpty) {
        _showOverlay();
      }
    });
  }

  Future<void> _loadProductNames() async {
    try {
      final products = await ProductService().getAllProductNames();
      if (mounted) {
        setState(() {
          _allProductNames = products.map((p) => p['name'].toString()).toSet().toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('userLocation');
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() => _currentLocation = saved);
    } else {
      // No saved location, try fetching current
      _refreshCurrentLocation();
    }
  }

  Future<void> _refreshCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = "${place.subAdministrativeArea ?? ''}, ${place.administrativeArea ?? ''}"
            .replaceAll(RegExp(r'^, |, $'), '');
        if (address.isEmpty) address = place.country ?? 'Unknown';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userLocation', address);

        if (mounted) setState(() => _currentLocation = address);
      }
    } catch (e) {
      debugPrint('Location refresh failed: $e');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  void _showOverlay() {
    if (_suggestions.isEmpty) {
      _removeOverlay();
      return;
    }
    
    if (_overlayEntry != null) {
      // Rebuild the overlay with new suggestions
      _overlayEntry?.markNeedsBuild();
      return;
    }

    final RenderBox? renderBox = _searchBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    
    _overlayEntry = OverlayEntry(
      builder: (context) {
        double targetWidth = size.width * 0.9;
        double dx = offset.dx + (size.width - targetWidth) / 2;
        double dy = offset.dy + size.height + 8; // Dropdown 8px below search bar

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _focusNode.unfocus();
                  _removeOverlay();
                },
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              left: dx,
              top: dy,
              width: targetWidth,
              child: SuggestionDropdown(
                suggestions: _suggestions,
                onSelect: (val) {
                  _removeOverlay();
                  _onSearchSubmitted(val);
                },
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _suggestions.clear();
      });
      _removeOverlay();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _suggestions = _allProductNames
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .take(3)
            .toList();
      });
      _showOverlay();
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;
    
    FilterState().addRecentSearch(query);

    _searchController.text = query;
    _focusNode.unfocus();
    _removeOverlay();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(initialQuery: query.trim()),
      ),
    );
  }

  void _onClear() {
    _searchController.clear();
    _onSearchChanged("");
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceBlack, // strict true void token
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Storefront Feed",
                    style: TextStyle(
                      color: AppColors.bodyMuted, 
                      fontSize: 12, 
                      letterSpacing: -0.12
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: _refreshCurrentLocation,
                    child: Row(
                      children: [
                        Text(
                          _currentLocation,
                          style: const TextStyle(
                            color: AppColors.bodyOnDark,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.374,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.bodyOnDark,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/ai-scan'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceTile1,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: AppColors.primaryOnDark.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.auto_awesome, color: AppColors.primaryOnDark, size: 14),
                          SizedBox(width: 4),
                          Text(
                            "AI Scan",
                            style: TextStyle(
                              color: AppColors.primaryOnDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildHeaderIcon(Icons.notifications_none, () => Navigator.pushNamed(context, AppRouter.notification)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 🔍 Search bar & Filter
          Row(
            children: [
              Expanded(
                key: _searchBarKey,
                child: SearchBarWidget(
                  controller: _searchController,
                  focusNode: _focusNode,
                  readOnly: false,
                  onChanged: _onSearchChanged,
                  onSubmitted: _onSearchSubmitted,
                  onClear: _onClear,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const QuickFilterBottomSheet(),
                  );
                },
                child: Container(
                  height: 44, // Match search input token height
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTile1,
                    borderRadius: BorderRadius.circular(9999), // full pill matching
                  ),
                  child: const Icon(Icons.tune, color: AppColors.bodyOnDark, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            icon,
            color: AppColors.bodyOnDark,
            size: 24,
          ),
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.unreadCount == 0) return const SizedBox.shrink();
              return Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary, // Brand action indicator
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${provider.unreadCount}',
                    style: const TextStyle(color: AppColors.bodyOnDark, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
