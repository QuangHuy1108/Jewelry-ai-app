import 'package:flutter/material.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  // States
  String selectedCategory = "All";
  String selectedColor = "All";
  String selectedMaterial = "All";
  int selectedReview =
      0; // 0 means all or any, 5 means 5 stars etc. Let's use string or int.
  RangeValues priceRange = const RangeValues(100, 700);

  final List<String> categories = [
    "All",
    "Rings",
    "Necklaces",
    "Bracelets",
    "Earrings",
    "Watches",
  ];
  final List<String> colors = [
    "All",
    "Gold",
    "Silver",
    "Rose Gold",
    "Platinum",
  ];
  final List<String> materials = [
    "All",
    "Diamond",
    "Pearl",
    "Ruby",
    "Sapphire",
  ];
  final List<int> reviewOptions = [5, 4, 3, 2, 1];

  void _resetFilters() {
    setState(() {
      selectedCategory = "All";
      selectedColor = "All";
      selectedMaterial = "All";
      selectedReview = 0;
      priceRange = const RangeValues(100, 700);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: TweenAnimationBuilder<Offset>(
          tween: Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, offset, child) {
            return FractionalTranslation(translation: offset, child: child);
          },
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildSectionTitle("Category"),
                      _buildChipList(
                        categories,
                        selectedCategory,
                        (val) => setState(() => selectedCategory = val),
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle("Price Range"),
                      _buildPriceRange(),
                      const SizedBox(height: 24),

                      _buildSectionTitle("Reviews"),
                      _buildReviews(),
                      const SizedBox(height: 24),

                      _buildSectionTitle("Color"),
                      _buildChipList(
                        colors,
                        selectedColor,
                        (val) => setState(() => selectedColor = val),
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle("Material"),
                      _buildChipList(
                        materials,
                        selectedMaterial,
                        (val) => setState(() => selectedMaterial = val),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _AnimatedScaleButton(
              onTap: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.center,
            child: Text(
              "Filter",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
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
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildChipList(
    List<String> items,
    String selectedValue,
    Function(String) onSelect,
  ) {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item == selectedValue;
          return GestureDetector(
            onTap: () => onSelect(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF808080)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(25), // Pill-shaped
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: isSelected ? Colors.white : const Color(0xFF808080),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceRange() {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF808080),
            inactiveTrackColor: const Color(0xFFE0E0E0),
            thumbColor: Colors.white,
            overlayColor: const Color(0xFF808080).withOpacity(0.2),
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
            onChanged: (RangeValues values) {
              setState(() {
                priceRange = values;
              });
            },
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
                  color: Color(0xFF333333),
                ),
              ),
              Text(
                "\$${priceRange.end.round()}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
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
          onTap: () {
            setState(() {
              // Click again to unselect, or select
              selectedReview = isSelected ? 0 : rating;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                // Radio button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF808080)
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
                              color: Color(0xFF808080),
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Stars
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      Icons.star,
                      size: 18,
                      color: index < rating
                          ? const Color(0xFFFFD700)
                          : const Color(0xFFCCCCCC),
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  "$rating Stars",
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
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AnimatedScaleButton(
              onTap: _resetFilters,
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Text(
                  "Reset Filter",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555555), // Grey text
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _AnimatedScaleButton(
              onTap: () {
                // Apply logic
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF808080), // Dark Grey
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  "Apply",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedScaleButton({required this.child, required this.onTap});

  @override
  State<_AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<_AnimatedScaleButton> {
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
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
