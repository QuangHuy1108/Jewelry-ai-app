import 'package:flutter/material.dart';

class ProductProvider extends ChangeNotifier {
  Map<String, dynamic> _product = {
    "id": "pd1",
    "name": "Gold Earring",
    "category": "Earrings",
    "basePrice": 1200.0,
    "images": [
      "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
      "https://i.postimg.cc/4yh339Lk/h7.jpg",
      "https://i.postimg.cc/cHWq3842/h8.jpg",
      "https://i.postimg.cc/zv06gtVy/h9.jpg",
      "https://i.postimg.cc/pL94mBxp/h10.jpg",
      "https://i.postimg.cc/43qyqfT2/h4.jpg",
    ],
    "stock": 10,
    "rating": 4.8,
    "reviews": 124,
  };

  String _selectedMaterial = 'Gold';
  String _selectedPurity = '18 KT';
  String _selectedSize = ''; 
  String _selectedGemstone = 'None';
  int _qty = 1;
  Map<String, dynamic>? _selectedVoucher;

  Map<String, dynamic> get product => _product;
  String get selectedMaterial => _selectedMaterial;
  String get selectedPurity => _selectedPurity;
  String get selectedSize => _selectedSize;
  String get selectedGemstone => _selectedGemstone;
  int get qty => _qty;
  Map<String, dynamic>? get selectedVoucher => _selectedVoucher;

  void initProduct(Map<String, dynamic> p) {
    _product = p;
    _qty = 1;
    _selectedSize = '';
    _selectedVoucher = null;
    notifyListeners();
  }

  void setMaterial(String v) { _selectedMaterial = v; notifyListeners(); }
  void setPurity(String v) { _selectedPurity = v; notifyListeners(); }
  void setSize(String v) { _selectedSize = v; notifyListeners(); }
  void setGemstone(String v) { _selectedGemstone = v; notifyListeners(); }
  void setQty(int v) { 
    final stock = _product['stock'] ?? 10;
    _qty = v.clamp(1, stock as int); 
    notifyListeners(); 
  }
  void setVoucher(Map<String, dynamic>? v) { _selectedVoucher = v; notifyListeners(); }

  double get priceBeforeVoucher {
    double base = _product['basePrice'] ?? 1200.0;
    if (_selectedMaterial == 'Platinum') base += 500;
    if (_selectedPurity == '22 KT') base += 300;
    if (_selectedGemstone == 'Diamond') base += 800;
    return base * _qty;
  }

  double get voucherDiscount {
    if (_selectedVoucher == null) return 0.0;
    double before = priceBeforeVoucher;
    if (before < (_selectedVoucher!['minSpend'] ?? 0)) return 0.0;

    if (_selectedVoucher!.containsKey('discountPercent')) {
      return before * (_selectedVoucher!['discountPercent'] / 100);
    } else if (_selectedVoucher!.containsKey('discountFixed')) {
      return (_selectedVoucher!['discountFixed'] as num).toDouble();
    }
    return 0.0;
  }

  double get finalPrice => priceBeforeVoucher - voucherDiscount;
}