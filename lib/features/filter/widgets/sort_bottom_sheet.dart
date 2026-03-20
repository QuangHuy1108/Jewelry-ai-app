import 'package:flutter/material.dart';
import '../../../../core/state/filter_state.dart';

class SortBottomSheet extends StatelessWidget {
  const SortBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> sortOptions = [
      "Popular",
      "Newest",
      "Price Low → High",
      "Price High → Low",
    ];
    final String currentSort = FilterState().sort;

    return Container(
      padding: const EdgeInsets.only(bottom: 24, top: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              "Sort By",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...sortOptions.map((option) {
            final isSelected = currentSort == option;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected
                      ? const Color(0xFF2C2C2C)
                      : const Color(0xFF555555),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Color(0xFF2C2C2C))
                  : null,
              onTap: () {
                FilterState().setSort(option);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}
