import 'package:flutter/material.dart';

class WishlistProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _items = [
    {
      "id": "1",
      "name": "Gold Necklace",
      "category": "Necklace",
      "price": 960.0,
      "originalPrice": 1200.0,
      "rating": 4.8,
      "image": "https://i.postimg.cc/pL94mBxp/h10.jpg",
    },
    {
      "id": "2",
      "name": "Diamond Ring",
      "category": "Rings",
      "price": 2200.0,
      "originalPrice": 2500.0,
      "rating": 4.9,
      "image": "https://i.postimg.cc/4yh339Lk/h7.jpg",
    },
    {
      "id": "3",
      "name": "Silver Bracelet",
      "category": "Bracelets",
      "price": 450.0,
      "originalPrice": 500.0,
      "rating": 4.5,
      "image": "https://i.postimg.cc/cHWq3842/h8.jpg",
    },
    {
      "id": "4",
      "name": "Small Studs",
      "category": "Earrings",
      "price": 120.0,
      "originalPrice": 150.0,
      "rating": 4.2,
      "image": "https://i.postimg.cc/zv06gtVy/h9.jpg",
    },
  ];

  List<Map<String, dynamic>> get items => _items;

  void removeFromWishlist(String id) {
    _items.removeWhere((item) => item['id'] == id);
    notifyListeners();
  }

  void addToWishlist(Map<String, dynamic> item) {
    if (!_items.any((i) => i['id'] == item['id'])) {
      _items.add(item);
      notifyListeners();
    }
  }

  void toggleWishlist(Map<String, dynamic> item) {
    final String id = item['id'];
    if (isInWishlist(id)) {
      removeFromWishlist(id);
    } else {
      addToWishlist(item);
    }
  }

  bool isInWishlist(String id) {
    return _items.any((item) => item['id'] == id);
  }
}
