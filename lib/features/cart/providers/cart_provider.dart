import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  final List<Map> _items = [];

  List<Map> get items => _items;

  void addToCart(Map product, {int qty = 1}) {
    int existingIndex = _items.indexWhere(
      (item) => item['id'] == product['id'] && item['purity'] == product['purity'] && item['size'] == product['size']
    );

    if (existingIndex != -1) {
      int newQty = (_items[existingIndex]['qty'] ?? 1) + qty;
      int stock = product['stock'] ?? 99;
      _items[existingIndex]['qty'] = newQty > stock ? stock : newQty;
    } else {
      product['qty'] = qty;
      _items.add(product);
    }
    notifyListeners();
  }
}