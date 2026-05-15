import 'package:flutter/material.dart';
import 'package:jewelry_app/services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  Map<String, dynamic> _product = {};

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
    // Fetch sellers from Firestore if not already present
    if (!_product.containsKey('sellers') || (_product['sellers'] as List?)?.isEmpty == true) {
      _loadSellers();
    }
    _qty = 1;
    _selectedSize = '';
    _selectedVoucher = null;
    notifyListeners();
  }

  Future<void> _loadSellers() async {
    try {
      final sellers = await ProductService().getSellers();
      if (sellers.isNotEmpty) {
        _product['sellers'] = sellers;
        notifyListeners();
      }
    } catch (_) {
      // Silently handle — sellers section will just be hidden
    }
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