import 'package:flutter/material.dart';
import '../../../../core/state/filter_state.dart';

class AdvancedFilterBottomSheet extends StatefulWidget {
  const AdvancedFilterBottomSheet({super.key});

  @override
  State<AdvancedFilterBottomSheet> createState() =>
      _AdvancedFilterBottomSheetState();
}

class _AdvancedFilterBottomSheetState extends State<AdvancedFilterBottomSheet> {
  // States
  List<String> selectedCategories = [];
  String selectedMaterial = "All";
  String selectedBrand = "All";
  int selectedReview = 0;
  RangeValues priceRange = const RangeValues(0, 1000);

  final List<String> categories = [
    "Rings",
    "Necklaces",
    "Bracelets",
    "Earrings",
    "Watches",
  ];
  final List<String> materials = ["All", "Gold", "Silver", "Platinum"];
  final List<String> brands = ["All", "Tiffany", "Cartier", "Bvlgari"];
  final List<int> reviewOptions = [5, 4, 3, 2];

  @override
  void initState() {
    super.initState();
    final state = FilterState();
    selectedCategories = List.from(state.categories);
    priceRange = RangeValues(state.minPrice ?? 0, state.maxPrice ?? 1000);
    selectedReview = state.rating;
    selectedMaterial = state.material;
    selectedBrand = state.brand;
  }

  void _resetFilters() {
    setState(() {
      selectedCategories.clear();
      selectedMaterial = "All";
      selectedBrand = "All";
      selectedReview = 0;
      priceRange = const RangeValues(0, 1000);
    });
  }

  void _applyFilters() {
    final bool isDefaultPrice = priceRange.start == 0 && priceRange.end == 1000;
    FilterState().applyAdvancedFilter(
      newCategories: selectedCategories,
      min: isDefaultPrice ? null : priceRange.start,
      max: isDefaultPrice ? null : priceRange.end,
      newRating: selectedReview,
      newMaterial: selectedMaterial,
      newBrand: selectedBrand,
      newSize: "All",
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildDragHandle(),
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  _buildSectionTitle("Category (Multi-select)"),
                  _buildChipListMulti(categories, selectedCategories, (val) {
                    setState(() {
                      if (selectedCategories.contains(val))
                        selectedCategories.remove(val);
                      else
                        selectedCategories.add(val);
                    });
                  }),
                  const SizedBox(height: 24),

                  _buildSectionTitle("Price Range"),
                  _buildPriceRange(),
                  const SizedBox(height: 24),

                  _buildSectionTitle("Rating"),
                  _buildReviews(),
                  const SizedBox(height: 24),

                  _buildSectionTitle("Material"),
                  _buildChipListSingle(
                    materials,
                    selectedMaterial,
                    (val) => setState(() => selectedMaterial = val),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle("Brand"),
                  _buildChipListSingle(
                    brands,
                    selectedBrand,
                    (val) => setState(() => selectedBrand = val),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      alignment: Alignment.center,
      child: const Text(
        "Advanced Filter",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
        ),
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

  Widget _buildChipListSingle(
    List<String> items,
    String selectedValue,
    Function(String) onSelect,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        final isSelected = item == selectedValue;
        return _buildChip(item, isSelected, () => onSelect(item));
      }).toList(),
    );
  }

  Widget _buildChipListMulti(
    List<String> items,
    List<String> selectedValues,
    Function(String) onToggle,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        final isSelected = selectedValues.contains(item);
        return _buildChip(item, isSelected, () => onToggle(item));
      }).toList(),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF808080),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRange() {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF2C2C2C),
            inactiveTrackColor: const Color(0xFFE0E0E0),
            thumbColor: Colors.white,
            overlayColor: const Color(0xFF2C2C2C).withOpacity(0.2),
            trackHeight: 4,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 10,
              elevation: 3,
            ),
          ),
          child: RangeSlider(
            values: priceRange,
            min: 0,
            max: 1000,
            divisions: 100,
            onChanged: (RangeValues values) =>
                setState(() => priceRange = values),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "\$${priceRange.start.round()}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                priceRange.end >= 1000
                    ? "\$1000+"
                    : "\$${priceRange.end.round()}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviews() {
    return Column(
      children: reviewOptions.map((rating) {
        final isSelected = selectedReview == rating;
        return GestureDetector(
          onTap: () => setState(() => selectedReview = isSelected ? 0 : rating),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
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
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      Icons.star,
                      size: 18,
                      color: index < rating
                          ? const Color(0xFFFFD700)
                          : const Color(0xFFCCCCCC),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "$rating★ & up",
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _resetFilters,
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
            flex: 2,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2C),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                "Apply Filters",
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
    );
  }
}
