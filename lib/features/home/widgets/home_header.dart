import 'dart:async';
import 'package:flutter/material.dart';
import '../../search/screens/search_results_screen.dart';
import '../../filter/widgets/quick_filter_bottom_sheet.dart';
import '../../../../core/state/filter_state.dart';
import 'search_bar_widget.dart';
import 'suggestion_dropdown.dart';
import '../../camera/screens/camera_screen.dart';

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
        _suggestions = _mockData
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
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C2C), // Dark Grey/Charcoal
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
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
                    "Location",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => const SizedBox(
                          height: 200,
                          child: Center(
                            child: Text("Location Selection (Bottom Sheet)"),
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: const [
                        Text(
                          "New York, USA",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/ai-scan'),
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('AI Scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildHeaderIcon(Icons.notifications_none, () {}),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

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
                  height: 45, // Match search bar height
                  width: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune, color: Colors.black87),
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
      child: Icon(
        icon,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
