import 'package:flutter/material.dart';
import '../mock/mock_products.dart';

// 1. Tạo model cho món hàng trong giỏ (có thêm số lượng)
class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

// 2. Lớp quản lý logic Giỏ hàng
class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  // Thêm vào giỏ
  void addToCart(ProductModel product) {
    // Kiểm tra xem món này có trong giỏ chưa
    int index = _items.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      _items[index].quantity += 1; // Có rồi thì tăng số lượng
    } else {
      _items.add(CartItem(product: product)); // Chưa có thì thêm mới
    }
    notifyListeners(); // Thông báo cho App cập nhật lại giao diện
  }

  // Xóa khỏi giỏ
  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  // Tính tổng tiền
  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  // Tính tổng số lượng món hàng
  int get itemCount => _items.length;

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

