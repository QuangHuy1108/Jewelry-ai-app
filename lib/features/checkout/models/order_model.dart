import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;
  final String userId;
  final List<Map<String, dynamic>> items;
  final double subTotal;
  final double discount;
  final double shippingFee;
  final double totalAmount;
  final String paymentMethod;
  final String shippingMethod;
  final Map<String, dynamic> address;
  final String status;
  final Timestamp createdAt;
  final Map<String, dynamic>? voucher;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.subTotal,
    required this.discount,
    required this.shippingFee,
    required this.totalAmount,
    required this.paymentMethod,
    required this.shippingMethod,
    required this.address,
    this.status = 'pending',
    Timestamp? createdAt,
    this.voucher,
  }) : createdAt = createdAt ?? Timestamp.now();

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'items': items.map((item) => {
        'productId': item['id'] ?? '',
        'name': item['name'] ?? '',
        'image': item['image'] ?? '',
        'price': item['price'] ?? 0,
        'originalPrice': item['originalPrice'] ?? item['price'] ?? 0,
        'quantity': item['qty'] ?? 1,
        'selectedOptions': item['selectedOptions'] ?? {},
      }).toList(),
      'subTotal': subTotal,
      'discount': discount,
      'shippingFee': shippingFee,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'shippingMethod': shippingMethod,
      'address': address,
      'status': status,
      'createdAt': createdAt,
      if (voucher != null) 'voucher': voucher,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderId: map['orderId'] ?? '',
      userId: map['userId'] ?? '',
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      subTotal: (map['subTotal'] ?? 0.0).toDouble(),
      discount: (map['discount'] ?? 0.0).toDouble(),
      shippingFee: (map['shippingFee'] ?? 0.0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      shippingMethod: map['shippingMethod'] ?? '',
      address: Map<String, dynamic>.from(map['address'] ?? {}),
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      voucher: map['voucher'],
    );
  }
}
