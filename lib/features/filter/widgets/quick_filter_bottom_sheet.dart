import 'package:flutter/material.dart';
import '../../../../core/state/filter_state.dart';

class QuickFilterBottomSheet extends StatefulWidget {
  const QuickFilterBottomSheet({super.key});

  @override
  State<QuickFilterBottomSheet> createState() => _QuickFilterBottomSheetState();
}

class _QuickFilterBottomSheetState extends State<QuickFilterBottomSheet> {
  late String _category;
  late double? _minPrice;
  late double? _maxPrice;
  late int _rating;

  final List<String> _categories = ["All", "Rings", "Earrings", "Necklace"];

  @override
  void initState() {
    super.initState();
    final state = FilterState();
    _category =
        state.categories.isNotEmpty &&
            _categories.contains(state.categories.first)
        ? state.categories.first
        : "All";
    _minPrice = state.minPrice;
    _maxPrice = state.maxPrice;
    _rating = state.rating >= 4 ? 4 : 0;
  }

  void _reset() {
    setState(() {
      _category = "All";
      _minPrice = null;
      _maxPrice = null;
      _rating = 0;
    });
  }

  void _apply() {
    FilterState().applyQuickFilter(
      category: _category,
      min: _minPrice,
      max: _maxPrice,
      newRating: _rating,
    );
    Navigator.pop(context);
  }

  bool _isPriceSelected(double? min, double? max) {
    return _minPrice == min && _maxPrice == max;
  }

  void _setPrice(double? min, double? max) {
    setState(() {
      _minPrice = min;
      _maxPrice = max;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            "Quick Filter",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Category"),
                  _buildCategoryChips(),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Price"),
                  _buildPriceOptions(),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Rating"),
                  _buildRatingOption(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Footer Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      "Reset",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C2C2C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      "Apply",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.map((cat) {
        final isSelected = _category == cat;
        return GestureDetector(
          onTap: () => setState(() => _category = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2C2C2C)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              cat,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF808080),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceOptions() {
    return Column(
      children: [
        _buildRadioOption(
          "Under \$50",
          _isPriceSelected(null, 50),
          () => _setPrice(null, 50),
        ),
        _buildRadioOption(
          "\$50 - \$100",
          _isPriceSelected(50, 100),
          () => _setPrice(50, 100),
        ),
        _buildRadioOption(
          "Above \$100",
          _isPriceSelected(100, null),
          () => _setPrice(100, null),
        ),
        _buildRadioOption(
          "Any Price",
          _isPriceSelected(null, null),
          () => _setPrice(null, null),
        ),
      ],
    );
  }

  Widget _buildRatingOption() {
    return _buildRadioOption("4★ & up", _rating == 4, () {
      setState(() => _rating = _rating == 4 ? 0 : 4); // Toggle
    });
  }

  Widget _buildRadioOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2C2C2C)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 16, color: Color(0xFF555555)),
            ),
          ],
        ),
      ),
    );
  }
}
