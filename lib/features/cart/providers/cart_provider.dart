import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  bool get isAllSelected => _items.isNotEmpty && _items.every((item) => item['isSelected'] == true);

  void addToCart(Map<String, dynamic> product, {int qty = 1, Map<String, dynamic>? selectedOptions}) {
    // Construct default map natively bridging backward compatibility with older `addToCart` calls.
    final Map<String, dynamic> options = selectedOptions ?? {
      'size': product['size'] ?? 'N/A',
      'material': product['material'] ?? 'Gold',
      'purity': product['purity'] ?? '18 KT',
      'gemstone': product['gemstone'] ?? 'None',
      'color': product['color'] ?? 'N/A',
    };

    int existingIndex = _items.indexWhere((item) {
      if (item['id'] != product['id']) return false;
      final currentOptions = item['selectedOptions'] as Map<String, dynamic>?;
      if (currentOptions == null) return false;
      
      return currentOptions['size'] == options['size'] &&
             currentOptions['material'] == options['material'] &&
             currentOptions['purity'] == options['purity'] &&
             currentOptions['gemstone'] == options['gemstone'] &&
             currentOptions['color'] == options['color'];
    });

    if (existingIndex != -1) {
      int newQty = (_items[existingIndex]['qty'] ?? 1) + qty;
      int stock = product['stock'] ?? 99;
      _items[existingIndex]['qty'] = newQty > stock ? stock : newQty;
    } else {
      final itemPrice = product['price'] ?? product['basePrice'] ?? 0.0;
      _items.add({
        'id': product['id'],
        'name': product['name'] ?? 'Unknown Item',
        'price': itemPrice,
        'originalPrice': itemPrice,
        'category': product['category'] ?? '',
        'image': product['image'] ?? ((product['images'] != null && product['images'].isNotEmpty) ? product['images'][0] : ''),
        'qty': qty,
        'stock': product['stock'] ?? 99,
        'isSelected': true,
        'selectedOptions': options,
      });
    }
    notifyListeners();
  }

  void toggleItemSelection(int index) {
    _items[index]['isSelected'] = !(_items[index]['isSelected'] ?? false);
    notifyListeners();
  }

  void toggleAllSelection(bool select) {
    for (var item in _items) {
      item['isSelected'] = select;
    }
    notifyListeners();
  }

  void updateItemOptions(int index, Map<String, dynamic> newOptions, {double? specificPriceUpdate}) {
    _items[index]['selectedOptions'] = newOptions;
    if (specificPriceUpdate != null) {
      _items[index]['price'] = specificPriceUpdate;
    }
    notifyListeners();
  }

  void applyVoucher(int index, Map<String, dynamic> voucher) {
    _items[index]['voucher'] = voucher;
    
    // Minimal recalculation logic based on discount string
    double basePrice = _items[index]['price'] ?? 1200.0;
    String discountStr = voucher['discount'] ?? '';
    
    if (discountStr.contains('%')) {
      // e.g "Get 15% OFF"
      RegExp regExp = RegExp(r'(\d+)%');
      Match? match = regExp.firstMatch(discountStr);
      if (match != null) {
        double percent = double.tryParse(match.group(1) ?? '0') ?? 0;
        _items[index]['price'] = basePrice * (1 - percent / 100);
      }
    } else if (discountStr.contains('\$')) {
      // e.g "Get $200 OFF"
      RegExp regExp = RegExp(r'\$(\d+)');
      Match? match = regExp.firstMatch(discountStr);
      if (match != null) {
        double amount = double.tryParse(match.group(1) ?? '0') ?? 0;
        _items[index]['price'] = basePrice - amount < 0 ? 0.0 : basePrice - amount;
      }
    }
    
    notifyListeners();
  }

  List<Map<String, dynamic>> get selectedItems =>
      _items.where((item) => item['isSelected'] == true).toList();

  void removeSelectedItems() {
    _items.removeWhere((item) => item['isSelected'] == true);
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }
  
  void updateQty(int index, int newQty) {
    int stock = _items[index]['stock'] ?? 99;
    if (newQty < 1) {
      removeItem(index);
    } else {
      _items[index]['qty'] = newQty > stock ? stock : newQty;
      notifyListeners();
    }
  }

  double get totalSelectedPrice {
    double total = 0;
    for (var item in _items) {
      if (item['isSelected'] == true) {
        double price = (item['price'] ?? 0.0) is num ? (item['price'] as num).toDouble() : 0.0;
        int qty = item['qty'] as int? ?? 1;
        total += price * qty;
      }
    }
    return total;
  }

  double get totalSelectedOriginalPrice {
    double total = 0;
    for (var item in _items) {
      if (item['isSelected'] == true) {
        double orig = (item['originalPrice'] ?? item['price'] ?? 0.0) is num
            ? ((item['originalPrice'] ?? item['price']) as num).toDouble()
            : 0.0;
        int qty = item['qty'] as int? ?? 1;
        total += orig * qty;
      }
    }
    return total;
  }

  double get totalDiscount => totalSelectedOriginalPrice - totalSelectedPrice;

  double get deliveryCharge => _items.any((i) => i['isSelected'] == true) ? 20.0 : 0.0;

  double get tax => 0.0;

  double get grandTotal => totalSelectedPrice + deliveryCharge + tax;
}