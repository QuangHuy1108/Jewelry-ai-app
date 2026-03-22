import 'package:flutter/material.dart';

class SizeGuideBottomSheet extends StatefulWidget {
  final String initialSize;
  final Function(String) onSizeSelected;

  const SizeGuideBottomSheet({
    super.key,
    required this.initialSize,
    required this.onSizeSelected,
  });

  @override
  State<SizeGuideBottomSheet> createState() => _SizeGuideBottomSheetState();
}

class _SizeGuideBottomSheetState extends State<SizeGuideBottomSheet> {
  late String _selectedSize;
  final TextEditingController _customSizeController = TextEditingController();

  final List<Map<String, String>> westernSizes = [
    {'size': '5', 'diameter': '15.7 mm'},
    {'size': '6', 'diameter': '16.5 mm'},
    {'size': '7', 'diameter': '17.3 mm'},
    {'size': '8', 'diameter': '18.1 mm'},
    {'size': '9', 'diameter': '18.9 mm'},
  ];

  final List<Map<String, String>> easternSizes = [
    {'size': '10', 'diameter': '15.9 mm'},
    {'size': '12', 'diameter': '16.5 mm'},
    {'size': '14', 'diameter': '17.2 mm'},
    {'size': '16', 'diameter': '17.8 mm'},
    {'size': '18', 'diameter': '18.5 mm'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.initialSize;
    if (_selectedSize.isNotEmpty &&
        !westernSizes.any((e) => e['size'] == _selectedSize) &&
        !easternSizes.any((e) => e['size'] == _selectedSize)) {
      _customSizeController.text = _selectedSize;
    }
  }

  @override
  void dispose() {
    _customSizeController.dispose();
    super.dispose();
  }

  void _handleSizeSelection(String size) {
    setState(() => _selectedSize = size);
    _customSizeController.clear();
    widget.onSizeSelected(size);
    Navigator.pop(context);
  }

  void _handleCustomSizeSubmit() {
    if (_customSizeController.text.trim().isNotEmpty) {
      final customSize = _customSizeController.text.trim();
      setState(() => _selectedSize = customSize);
      widget.onSizeSelected(customSize);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Size Guide',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF333333)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSizeSection('Western Sizes', westernSizes),
                  const SizedBox(height: 32),
                  _buildSizeSection('Eastern Sizes', easternSizes),
                  const SizedBox(height: 32),
                  _buildCustomSizeSection(),
                  const SizedBox(height: 40), // Padding for bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSection(String title, List<Map<String, String>> sizes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: sizes.length,
          itemBuilder: (context, index) {
            final size = sizes[index]['size']!;
            final measurement = sizes[index]['diameter']!;
            final isSelected = _selectedSize == size;

            return GestureDetector(
              onTap: () => _handleSizeSelection(size),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF333333) : Colors.white,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF333333) : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      size,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      measurement,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Custom Size',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customSizeController,
                decoration: InputDecoration(
                  hintText: 'Enter specific dimension',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF333333)),
                  ),
                ),
                onSubmitted: (_) => _handleCustomSizeSubmit(),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _handleCustomSizeSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333333),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}
