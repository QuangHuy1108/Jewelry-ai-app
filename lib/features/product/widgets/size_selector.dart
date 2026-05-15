import 'package:flutter/material.dart';
import 'size_guide_bottom_sheet.dart';
import '../../../core/theme/app_colors.dart';

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
            const Text(
              'Band Size', 
              style: TextStyle(
                fontSize: 17, // SF Pro body-strong token
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                letterSpacing: -0.374,
              ),
            ),
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
              child: const Text(
                'Size Guide', 
                style: TextStyle(
                  color: AppColors.primary, // pure Action Blue text-link token
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.224,
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ['5', '6', '7', '8', '9'].map((size) {
            final isSelected = selectedSize == size;
            return GestureDetector(
              onTap: () => onSizeSelected(size),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 48, // generous finger touch target token
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.ink : AppColors.canvas,
                  border: Border.all(
                    color: isSelected ? AppColors.ink : AppColors.hairline, 
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(9999), // full pill shape grammar
                ),
                child: Text(
                  size, 
                  style: TextStyle(
                    color: isSelected ? AppColors.bodyOnDark : AppColors.ink, 
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
