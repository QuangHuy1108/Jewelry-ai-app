class ProductModel {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
  });

  // Hàm này giúp đóng gói dữ liệu thành dạng Map (Từ điển) để gửi lên Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
    };
  }
}