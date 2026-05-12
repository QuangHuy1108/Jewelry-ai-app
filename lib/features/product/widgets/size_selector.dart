import 'package:flutter/material.dart';
import 'size_guide_bottom_sheet.dart';

class SizeSelector extends StatelessWidget {
  final String selectedSize;
  final Function(String) onSizeSelected;

  const SizeSelector({
    super.key,
    required this.selectedSize,
    required this.onSizeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Select Size', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => FractionallySizedBox(
                    heightFactor: 0.8,
                    child: SizeGuideBottomSheet(
                      initialSize: selectedSize,
                      onSizeSelected: onSizeSelected,
                    ),
                  ),
                );
              },
              child: const Text('Size Guide', style: TextStyle(decoration: TextDecoration.underline)),
            )
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ['5', '6', '7', '8', '9'].map((size) {
            final isSelected = selectedSize == size;
            return GestureDetector(
              onTap: () => onSizeSelected(size),
              child: Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(size, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
