import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../../product/widgets/size_selector.dart';

class EditCartItemSheet extends StatefulWidget {
  final int itemIndex;
  final Map<String, dynamic> currentItem;

  const EditCartItemSheet({
    super.key,
    required this.itemIndex,
    required this.currentItem,
  });

  @override
  State<EditCartItemSheet> createState() => _EditCartItemSheetState();
}

class _EditCartItemSheetState extends State<EditCartItemSheet> {
  late String _tempSize;
  late String _tempPurity;
  late String _tempMaterial;
  late String _tempGemstone;

  @override
  void initState() {
    super.initState();
    final options = widget.currentItem['selectedOptions'] as Map<String, dynamic>? ?? {};
    _tempSize = options['size'] ?? 'Ring - US 7';
    _tempPurity = options['purity'] ?? '18 KT';
    _tempMaterial = options['material'] ?? 'Gold';
    _tempGemstone = options['gemstone'] ?? 'None';
  }

  double _recalculatePrice() {
    double base = 1200.0; // Minimal baseline logic mirroring product_provider for consistency test
    if (_tempMaterial == 'Platinum') base += 500;
    if (_tempPurity == '22 KT') base += 300;
    if (_tempGemstone == 'Diamond') base += 800;
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Edit Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.black),
              )
            ],
          ),
          const SizedBox(height: 24),
          _buildSelectorGroup('Material', ['Gold', 'Silver', 'Platinum'], _tempMaterial, (val) => setState(() => _tempMaterial = val)),
          const SizedBox(height: 16),
          _buildSelectorGroup('Purity', ['14 KT', '18 KT', '22 KT', '24 KT'], _tempPurity, (val) => setState(() => _tempPurity = val)),
          const SizedBox(height: 16),
          SizeSelector(
            selectedSize: _tempSize,
            onSizeSelected: (size) => setState(() => _tempSize = size),
          ),
          const SizedBox(height: 16),
          _buildSelectorGroup('Gemstone', ['None', 'Diamond', 'Ruby', 'Sapphire'], _tempGemstone, (val) => setState(() => _tempGemstone = val)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final options = {
                  'size': _tempSize,
                  'material': _tempMaterial,
                  'purity': _tempPurity,
                  'gemstone': _tempGemstone,
                  'color': 'N/A'
                };
                context.read<CartProvider>().updateItemOptions(
                  widget.itemIndex, 
                  options,
                  specificPriceUpdate: _recalculatePrice()
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333333),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSelectorGroup(String title, List<String> options, String currentOption, Function(String) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            bool isSelected = opt == currentOption;
            return GestureDetector(
              onTap: () => onSelect(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF333333) : Colors.white,
                  border: Border.all(color: isSelected ? const Color(0xFF333333) : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        )
      ],
    );
  }
}
