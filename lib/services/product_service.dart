import 'package:cloud_firestore/cloud_firestore.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Streams ──────────────────────────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> getBestSellersStream() {
    return _firestore
        .collection('products')
        .where('isBestSeller', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getPopularProductsStream() {
    return _firestore
        .collection('products')
        .where('isPopular', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getProductsByCategoryStream(String category) {
    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCategoriesStream() {
    return _firestore
        .collection('categories')
        .orderBy('order')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getBannersStream() {
    return _firestore
        .collection('banners')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getProductById(String productId) {
    return _firestore.collection('products').doc(productId).get();
  }

  // ─── Seeder ───────────────────────────────────────────────────────

  Future<void> seedDatabase() async {
    await _seedProducts();
    await _seedCategories();
    await _seedBanners();
  }

  Future<void> _seedProducts() async {
    final productsRef = _firestore.collection('products');
    final snap = await productsRef.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _firestore.batch();

    final products = [
      // ── Rings ──
      {
        "name": "Diamond Halo Ring",
        "price": 2500.0,
        "discountPrice": 2100.0,
        "category": "Rings",
        "categoryId": "rings",
        "images": [
          "https://i.postimg.cc/4yh339Lk/h7.jpg",
        ],
        "image": "https://i.postimg.cc/4yh339Lk/h7.jpg",
        "description": "A breathtaking diamond halo ring featuring a brilliant center stone surrounded by a halo of pave diamonds. Set in 18K white gold for enduring beauty.",
        "material": "18K White Gold",
        "stock": 8,
        "soldCount": 127,
        "rating": 4.9,
        "reviewCount": 89,
        "isBestSeller": true,
        "isPopular": false,
        "isFeatured": true,
        "isActive": true,
        "sizes": ["14", "15", "16", "17", "18"],
      },
      {
        "name": "Gold Solitaire Ring",
        "price": 1200.0,
        "discountPrice": null,
        "category": "Rings",
        "categoryId": "rings",
        "images": [
          "https://i.postimg.cc/cHWq3842/h8.jpg",
        ],
        "image": "https://i.postimg.cc/cHWq3842/h8.jpg",
        "description": "A timeless solitaire ring crafted in solid 22K gold. The minimalist design puts the focus on the exquisite center stone. Perfect for engagements or special occasions.",
        "material": "22K Gold",
        "stock": 15,
        "soldCount": 203,
        "rating": 4.8,
        "reviewCount": 156,
        "isBestSeller": true,
        "isPopular": true,
        "isFeatured": false,
        "isActive": true,
        "sizes": ["14", "15", "16", "17", "18", "19"],
      },
      {
        "name": "Emerald Cut Ring",
        "price": 4200.0,
        "discountPrice": 3800.0,
        "category": "Rings",
        "categoryId": "rings",
        "images": [
          "https://i.postimg.cc/4yh339Lk/h7.jpg",
        ],
        "image": "https://i.postimg.cc/4yh339Lk/h7.jpg",
        "description": "An extraordinary emerald-cut diamond ring that radiates sophistication. The step-cut facets create a mesmerizing hall-of-mirrors effect. Set in platinum.",
        "material": "Platinum",
        "stock": 3,
        "soldCount": 41,
        "rating": 4.9,
        "reviewCount": 32,
        "isBestSeller": false,
        "isPopular": false,
        "isFeatured": true,
        "isActive": true,
        "sizes": ["14", "15", "16", "17"],
      },

      // ── Necklaces ──
      {
        "name": "Pearl Pendant Necklace",
        "price": 890.0,
        "discountPrice": 750.0,
        "category": "Necklaces",
        "categoryId": "necklaces",
        "images": [
          "https://i.postimg.cc/pL94mBxp/h10.jpg",
        ],
        "image": "https://i.postimg.cc/pL94mBxp/h10.jpg",
        "description": "A lustrous freshwater pearl pendant suspended from a delicate 18K gold chain. The classic design makes it suitable for both everyday wear and formal occasions.",
        "material": "18K Gold + Pearl",
        "stock": 20,
        "soldCount": 312,
        "rating": 4.7,
        "reviewCount": 245,
        "isBestSeller": true,
        "isPopular": true,
        "isFeatured": false,
        "isActive": true,
        "sizes": ["40cm", "45cm", "50cm"],
      },
      {
        "name": "Sapphire Pendant",
        "price": 3100.0,
        "discountPrice": null,
        "category": "Necklaces",
        "categoryId": "necklaces",
        "images": [
          "https://i.postimg.cc/pL94mBxp/h10.jpg",
        ],
        "image": "https://i.postimg.cc/pL94mBxp/h10.jpg",
        "description": "A deep blue Ceylon sapphire set in a bezel of micro-pave diamonds. The pendant hangs from a handcrafted 18K white gold chain. A statement piece for the discerning collector.",
        "material": "18K White Gold + Sapphire",
        "stock": 5,
        "soldCount": 78,
        "rating": 5.0,
        "reviewCount": 52,
        "isBestSeller": true,
        "isPopular": false,
        "isFeatured": true,
        "isActive": true,
        "sizes": ["42cm", "45cm", "50cm"],
      },
      {
        "name": "Crystal Heart Necklace",
        "price": 350.0,
        "discountPrice": 280.0,
        "category": "Necklaces",
        "categoryId": "necklaces",
        "images": [
          "https://i.postimg.cc/pL94mBxp/h10.jpg",
        ],
        "image": "https://i.postimg.cc/pL94mBxp/h10.jpg",
        "description": "A romantic heart-shaped crystal pendant on a sterling silver chain. The faceted crystal catches light beautifully. A perfect gift for someone special.",
        "material": "Sterling Silver + Crystal",
        "stock": 50,
        "soldCount": 589,
        "rating": 4.6,
        "reviewCount": 412,
        "isBestSeller": false,
        "isPopular": true,
        "isFeatured": false,
        "isActive": true,
        "sizes": ["40cm", "45cm"],
      },

      // ── Bracelets ──
      {
        "name": "Gold Tennis Bracelet",
        "price": 1200.0,
        "discountPrice": 980.0,
        "category": "Bracelets",
        "categoryId": "bracelets",
        "images": [
          "https://i.postimg.cc/zv06gtVy/h9.jpg",
        ],
        "image": "https://i.postimg.cc/zv06gtVy/h9.jpg",
        "description": "A classic tennis bracelet featuring a continuous line of round brilliant diamonds. Set in 18K yellow gold with a secure clasp. The ultimate in everyday luxury.",
        "material": "18K Gold + Diamond",
        "stock": 12,
        "soldCount": 167,
        "rating": 4.8,
        "reviewCount": 134,
        "isBestSeller": true,
        "isPopular": false,
        "isFeatured": false,
        "isActive": true,
        "sizes": ["16cm", "17cm", "18cm", "19cm"],
      },
      {
        "name": "Silver Chain Bracelet",
        "price": 120.0,
        "discountPrice": null,
        "category": "Bracelets",
        "categoryId": "bracelets",
        "images": [
          "https://i.postimg.cc/zv06gtVy/h9.jpg",
        ],
        "image": "https://i.postimg.cc/zv06gtVy/h9.jpg",
        "description": "A versatile sterling silver chain bracelet with an adjustable lobster clasp. Lightweight enough for daily wear yet bold enough to make a statement.",
        "material": "Sterling Silver",
        "stock": 100,
        "soldCount": 823,
        "rating": 4.5,
        "reviewCount": 567,
        "isBestSeller": false,
        "isPopular": true,
        "isFeatured": false,
        "isActive": true,
        "sizes": ["16cm", "17cm", "18cm"],
      },
      {
        "name": "Rose Gold Bangle",
        "price": 450.0,
        "discountPrice": 380.0,
        "category": "Bracelets",
        "categoryId": "bracelets",
        "images": [
          "https://i.postimg.cc/zv06gtVy/h9.jpg",
        ],
        "image": "https://i.postimg.cc/zv06gtVy/h9.jpg",
        "description": "A sleek rose gold bangle with a minimalist design and a subtle diamond accent. The warm rose gold tone complements all skin tones.",
        "material": "14K Rose Gold",
        "stock": 25,
        "soldCount": 198,
        "rating": 4.6,
        "reviewCount": 145,
        "isBestSeller": false,
        "isPopular": false,
        "isFeatured": true,
        "isActive": true,
        "sizes": ["S", "M", "L"],
      },

      // ── Earrings ──
      {
        "name": "Classic Gold Hoops",
        "price": 250.0,
        "discountPrice": 200.0,
        "category": "Earrings",
        "categoryId": "earrings",
        "images": [
          "https://i.postimg.cc/cHWq3842/h8.jpg",
        ],
        "image": "https://i.postimg.cc/cHWq3842/h8.jpg",
        "description": "Timeless gold hoop earrings handcrafted in 18K yellow gold. The lightweight tubular design ensures comfortable all-day wear. A wardrobe essential.",
        "material": "18K Gold",
        "stock": 30,
        "soldCount": 445,
        "rating": 4.8,
        "reviewCount": 312,
        "isBestSeller": false,
        "isPopular": true,
        "isFeatured": false,
        "isActive": true,
        "sizes": ["Small", "Medium", "Large"],
      },
      {
        "name": "Pearl Drop Earrings",
        "price": 850.0,
        "discountPrice": 720.0,
        "category": "Earrings",
        "categoryId": "earrings",
        "images": [
          "https://i.postimg.cc/cHWq3842/h8.jpg",
        ],
        "image": "https://i.postimg.cc/cHWq3842/h8.jpg",
        "description": "Elegant pearl drop earrings featuring AAA-grade Akoya pearls on 18K gold settings. The teardrop silhouette creates a flattering frame for the face.",
        "material": "18K Gold + Akoya Pearl",
        "stock": 18,
        "soldCount": 234,
        "rating": 4.7,
        "reviewCount": 178,
        "isBestSeller": true,
        "isPopular": false,
        "isFeatured": true,
        "isActive": true,
        "sizes": ["One Size"],
      },
      {
        "name": "Rose Gold Studs",
        "price": 180.0,
        "discountPrice": 150.0,
        "category": "Earrings",
        "categoryId": "earrings",
        "images": [
          "https://i.postimg.cc/cHWq3842/h8.jpg",
        ],
        "image": "https://i.postimg.cc/cHWq3842/h8.jpg",
        "description": "Delicate rose gold stud earrings with a subtle hammered texture. Secured with butterfly backs for comfort. The perfect everyday earring.",
        "material": "14K Rose Gold",
        "stock": 45,
        "soldCount": 678,
        "rating": 4.4,
        "reviewCount": 489,
        "isBestSeller": false,
        "isPopular": true,
        "isFeatured": false,
        "isActive": true,
        "sizes": ["One Size"],
      },
    ];

    for (var p in products) {
      final docRef = productsRef.doc();
      batch.set(docRef, {
        ...p,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> _seedCategories() async {
    final catRef = _firestore.collection('categories');
    final snap = await catRef.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    final categories = [
      {"id": "rings", "name": "Rings", "icon": "diamond", "image": "https://i.postimg.cc/4yh339Lk/h7.jpg", "order": 1},
      {"id": "necklaces", "name": "Necklaces", "icon": "diamond", "image": "https://i.postimg.cc/pL94mBxp/h10.jpg", "order": 2},
      {"id": "bracelets", "name": "Bracelets", "icon": "diamond", "image": "https://i.postimg.cc/zv06gtVy/h9.jpg", "order": 3},
      {"id": "earrings", "name": "Earrings", "icon": "diamond", "image": "https://i.postimg.cc/cHWq3842/h8.jpg", "order": 4},
    ];

    for (var cat in categories) {
      batch.set(catRef.doc(cat['id'] as String), cat);
    }

    await batch.commit();
  }

  Future<void> _seedBanners() async {
    final bannerRef = _firestore.collection('banners');
    final snap = await bannerRef.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    final banners = [
      {
        "title": "Get Special Offer",
        "subtitle": "Up to 40%",
        "label": "Limited time!",
        "image": "https://i.postimg.cc/43qyqfT2/h4.jpg",
        "order": 1,
        "isActive": true,
      },
      {
        "title": "New Arrivals",
        "subtitle": "Spring Collection",
        "label": "Just landed!",
        "image": "https://i.postimg.cc/xC6HXDrd/h3.jpg",
        "order": 2,
        "isActive": true,
      },
      {
        "title": "Exclusive Deals",
        "subtitle": "Buy 2 Get 1 Free",
        "label": "Members only",
        "image": "https://i.postimg.cc/hGF0nBgP/h2.jpg",
        "order": 3,
        "isActive": true,
      },
    ];

    for (var b in banners) {
      batch.set(bannerRef.doc(), b);
    }

    await batch.commit();
  }
}
