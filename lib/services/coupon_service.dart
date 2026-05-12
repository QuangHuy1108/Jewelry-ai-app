import 'package:cloud_firestore/cloud_firestore.dart';

class CouponService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream all active, non-expired coupons
  Stream<QuerySnapshot<Map<String, dynamic>>> getActiveCouponsStream() {
    return _firestore
        .collection('coupons')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Validate a coupon code (for manual entry)
  Future<Map<String, dynamic>?> validateCouponCode(String code) async {
    final snap = await _firestore
        .collection('coupons')
        .where('code', isEqualTo: code.toUpperCase())
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final data = snap.docs.first.data();
    data['docId'] = snap.docs.first.id;

    // Check expiry
    if (data['expiresAt'] != null) {
      final expiryDate = (data['expiresAt'] as Timestamp).toDate();
      if (expiryDate.isBefore(DateTime.now())) return null;
    }

    // Check usage limit
    if (data['maxUses'] != null && data['usedCount'] != null) {
      if (data['usedCount'] >= data['maxUses']) return null;
    }

    return data;
  }

  /// Increment usage count after successful order
  Future<void> incrementUsage(String couponDocId) async {
    await _firestore.collection('coupons').doc(couponDocId).update({
      'usedCount': FieldValue.increment(1),
    });
  }

  /// Seed initial coupons
  Future<void> seedCoupons() async {
    final ref = _firestore.collection('coupons');
    final snap = await ref.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    final coupons = [
      {
        "code": "WELCOME200",
        "title": "Welcome Offer",
        "description": "Get \$200 off on your first order",
        "condition": "Min. spend \$500. Valid for first order.",
        "discount": "Get \$200 OFF",
        "discountType": "fixed",
        "discountValue": 200.0,
        "minSpend": 500.0,
        "maxUses": 1000,
        "usedCount": 0,
        "isActive": true,
        "isExpired": false,
        "expiresAt": Timestamp.fromDate(DateTime.now().add(const Duration(days: 90))),
        "createdAt": FieldValue.serverTimestamp(),
      },
      {
        "code": "GOLDENSET",
        "title": "Golden Set Deal",
        "description": "15% off on Gold jewelry sets",
        "condition": "Valid for Gold jewelry sets only.",
        "discount": "Get 15% OFF",
        "discountType": "percent",
        "discountValue": 15.0,
        "minSpend": 0.0,
        "maxUses": 500,
        "usedCount": 0,
        "isActive": true,
        "isExpired": false,
        "expiresAt": Timestamp.fromDate(DateTime.now().add(const Duration(days: 60))),
        "createdAt": FieldValue.serverTimestamp(),
      },
      {
        "code": "FREESHIP",
        "title": "Free Shipping",
        "description": "Free shipping on orders over \$100",
        "condition": "Free shipping on all orders over \$100.",
        "discount": "Free Shipping",
        "discountType": "shipping",
        "discountValue": 0.0,
        "minSpend": 100.0,
        "maxUses": null,
        "usedCount": 0,
        "isActive": true,
        "isExpired": false,
        "expiresAt": null,
        "createdAt": FieldValue.serverTimestamp(),
      },
      {
        "code": "SUMMER25",
        "title": "Summer Sale",
        "description": "25% off entire summer collection",
        "condition": "Min. spend \$300. Ends soon!",
        "discount": "Get 25% OFF",
        "discountType": "percent",
        "discountValue": 25.0,
        "minSpend": 300.0,
        "maxUses": 200,
        "usedCount": 0,
        "isActive": true,
        "isExpired": false,
        "expiresAt": Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        "createdAt": FieldValue.serverTimestamp(),
      },
      {
        "code": "EXPIRED10",
        "title": "Halloween Special",
        "description": "10% off - expired",
        "condition": "Halloween special offer.",
        "discount": "Get 10% OFF",
        "discountType": "percent",
        "discountValue": 10.0,
        "minSpend": 0.0,
        "maxUses": 100,
        "usedCount": 100,
        "isActive": false,
        "isExpired": true,
        "expiresAt": Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))),
        "createdAt": FieldValue.serverTimestamp(),
      },
    ];

    for (var c in coupons) {
      batch.set(ref.doc(), c);
    }
    await batch.commit();
  }
}
