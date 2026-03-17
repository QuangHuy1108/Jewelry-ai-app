import 'package:cloud_firestore/cloud_firestore.dart';
// Đảm bảo import đúng file nơi bạn đang để ProductModel
import 'package:jewelry_app/shared/mock/mock_products.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Hàm lấy danh sách sản phẩm từ Firebase về
  Future<List<ProductModel>> getProducts() async {
    try {
      final snapshot = await _db.collection('products').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ProductModel(
          id: doc.id,
          name: data['name'] ?? '',
          price: (data['price'] ?? 0).toDouble(),
          imageUrl: data['imageUrl'] ?? '',
          description: data['description'] ?? '',
        );
      }).toList();
    } catch (e) {
      print("Lỗi khi lấy dữ liệu: $e");
      return [];
    }
  }
}