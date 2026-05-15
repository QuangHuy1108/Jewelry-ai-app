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

  // ─── Search & Suggestions ─────────────────────────────────────────

  /// Returns all active products (used for client-side name filtering in search suggestions).
  Future<List<Map<String, dynamic>>> getAllProductNames() async {
    final snap = await _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, 'name': d.data()['name'] ?? ''}).toList();
  }

  /// Searches products whose name contains the query (case-insensitive via Firestore ordering trick).
  /// Falls back to fetching all active products and filtering client-side.
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final snap = await _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .get();
    final lowerQuery = query.toLowerCase();
    return snap.docs
        .where((d) => (d.data()['name'] ?? '').toString().toLowerCase().contains(lowerQuery))
        .map((d) => {'id': d.id, ...d.data()})
        .toList();
  }

  // ─── Related Products ─────────────────────────────────────────────

  /// Gets products in the same category, excluding the given product ID.
  Future<List<Map<String, dynamic>>> getSimilarProducts(String category, String excludeId) async {
    final snap = await _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs
        .where((d) => d.id != excludeId)
        .map((d) => {'id': d.id, ...d.data()})
        .toList();
  }

  /// Gets products in a DIFFERENT category (cross-sell recommendations).
  Future<List<Map<String, dynamic>>> getRecommendedProducts(String currentCategory, {int limit = 4}) async {
    final snap = await _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs
        .where((d) => d.data()['category'] != currentCategory)
        .take(limit)
        .map((d) => {'id': d.id, ...d.data()})
        .toList();
  }

  // ─── Reviews ──────────────────────────────────────────────────────

  /// Stream of reviews for a given product.
  Stream<QuerySnapshot<Map<String, dynamic>>> getReviewsStream(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Adds a review to a product's reviews subcollection.
  Future<void> addReview(String productId, Map<String, dynamic> review) {
    return _firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .add(review);
  }

  // ─── Sellers ───────────────────────────────────────────────────────

  /// Gets all sellers from the sellers collection.
  Future<List<Map<String, dynamic>>> getSellers() async {
    final snap = await _firestore.collection('sellers').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Gets a specific seller by ID.
  Future<Map<String, dynamic>?> getSellerById(String sellerId) async {
    final doc = await _firestore.collection('sellers').doc(sellerId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  // ─── Seeder ───────────────────────────────────────────────────────

  Future<void> seedDatabase() async {
    await _seedProducts();
    await _seedCategories();
    await _seedBanners();
    await _seedSellers();
    await _seedReviews();
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

  Future<void> _seedSellers() async {
    final sellersRef = _firestore.collection('sellers');
    final snap = await sellersRef.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    final sellers = [
      {
        'name': 'Jenny Doe',
        'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&h=150&fit=crop',
        'coverImage': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=1000&auto=format&fit=crop',
        'description': 'Expert jewelry consultant with over 10 years of experience in fine gemstones and precious metals. Helping you find the perfect piece for your special moments is my passion.',
        'experienceYears': 10,
        'totalSold': 1250,
        'returningCustomers': 85.0,
        'followersCount': 12400,
        'favoritesCount': 8900,
        'rating': 4.9,
        'ratings': {
          'Attitude': 4.9,
          'Consulting Skill': 4.8,
          'Product Knowledge': 5.0,
          'Honesty': 4.9,
          'After-sales Service': 4.7,
        },
      },
      {
        'name': 'Marcus Stone',
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop',
        'coverImage': 'https://images.unsplash.com/photo-1560250097-0b93528c311a?q=80&w=1000&auto=format&fit=crop',
        'description': 'Specializing in bespoke engagement rings and custom designs. With a background in gemology, I bring expertise and passion to every client consultation.',
        'experienceYears': 8,
        'totalSold': 980,
        'returningCustomers': 78.0,
        'followersCount': 9200,
        'favoritesCount': 6100,
        'rating': 4.7,
        'ratings': {
          'Attitude': 4.7,
          'Consulting Skill': 4.9,
          'Product Knowledge': 4.8,
          'Honesty': 4.6,
          'After-sales Service': 4.5,
        },
      },
    ];

    for (var s in sellers) {
      batch.set(sellersRef.doc(), s);
    }
    await batch.commit();
  }

  Future<void> _seedReviews() async {
    // Seed reviews into the first product that has no reviews subcollection
    final productsSnap = await _firestore.collection('products').limit(3).get();
    if (productsSnap.docs.isEmpty) return;

    for (final productDoc in productsSnap.docs) {
      final reviewsSnap = await productDoc.reference.collection('reviews').limit(1).get();
      if (reviewsSnap.docs.isNotEmpty) continue;

      final batch = _firestore.batch();
      final reviews = [
        {
          'name': 'Alex Johnson',
          'date': 'January 15, 2026',
          'rating': 5.0,
          'comment': 'Absolutely stunning! The gold quality is top-notch and the design is even better in person. Highly recommend for any gift.',
          'isVerified': true,
          'avatar': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Maria Garcia',
          'date': 'January 8, 2026',
          'rating': 4.0,
          'comment': 'Very beautiful earrings. They are a bit smaller than I expected based on the photos, but the craftsmanship is excellent.',
          'isVerified': true,
          'avatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'James Smith',
          'date': 'December 28, 2025',
          'rating': 5.0,
          'comment': 'Perfect anniversary gift! My wife loves them. Fast shipping and great packaging.',
          'isVerified': false,
          'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop',
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      for (var r in reviews) {
        batch.set(productDoc.reference.collection('reviews').doc(), r);
      }
      await batch.commit();
    }
  }
}
