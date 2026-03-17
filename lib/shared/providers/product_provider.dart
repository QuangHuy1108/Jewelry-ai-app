import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/product_service.dart';
import '../mock/mock_products.dart';

// 1. Khai báo Service
final productServiceProvider = Provider((ref) => ProductService());

// 2. FutureProvider này sẽ tự động chạy và giữ dữ liệu cho chúng ta
final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final service = ref.watch(productServiceProvider);
  return service.getProducts();
});