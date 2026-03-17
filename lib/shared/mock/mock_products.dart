// KHÔNG CẦN LỆNH IMPORT NÀO Ở ĐÂY NỮA NHÉ!

// 1. Khuôn mẫu sản phẩm (Product Model) nằm luôn tại đây
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

final List<ProductModel> mockProducts = [
  ProductModel(
    id: 'ring_001',
    name: 'Nhẫn Kim Cương Vàng Trắng 18K',
    price: 2500.0,
    // Ảnh nhẫn kim cương mới
    imageUrl: 'https://images.unsplash.com/photo-1605100804763-247f67b2548e?auto=format&fit=crop&q=80&w=1000',
    description: 'Chiếc nhẫn đính kim cương tự nhiên lấp lánh, thiết kế tối giản, tôn vinh vẻ đẹp vĩnh cửu.',
  ),
  ProductModel(
    id: 'necklace_001',
    name: 'Dây Chuyền Vàng Hồng Nguyên Khối',
    price: 1800.0,
    // Ảnh dây chuyền mới
    imageUrl: 'https://images.unsplash.com/photo-1599643478524-fb66f7f2b1f6?auto=format&fit=crop&q=80&w=1000',
    description: 'Dây chuyền vàng hồng nguyên khối mang vẻ đẹp thanh lịch, phù hợp cho những buổi tiệc sang trọng.',
  ),
];