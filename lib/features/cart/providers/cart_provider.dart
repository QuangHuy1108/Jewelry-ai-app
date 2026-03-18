import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  final List<Map> _items = [];

  List<Map> get items => _items;

  void addToCart(Map product) {
    _items.add(product);
    notifyListeners();
  }
}