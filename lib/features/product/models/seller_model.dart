class Seller {
  final String id;
  final String name;
  final String avatar;
  final String coverImage;
  final String description;
  final Map<String, double> ratings;
  final int experienceYears;
  final int totalSold;
  final double returningCustomers;
  int followersCount;
  int favoritesCount;
  bool isFollowing;
  bool isFavorite;
  final List<Map<String, dynamic>> bestSellingProducts;

  Seller({
    required this.id,
    required this.name,
    required this.avatar,
    required this.coverImage,
    required this.description,
    required this.ratings,
    required this.experienceYears,
    required this.totalSold,
    required this.returningCustomers,
    required this.followersCount,
    required this.favoritesCount,
    this.isFollowing = false,
    this.isFavorite = false,
    required this.bestSellingProducts,
  });

  double get averageRating {
    if (ratings.isEmpty) return 0.0;
    return ratings.values.reduce((a, b) => a + b) / ratings.length;
  }

  factory Seller.mock() {
    return Seller(
      id: 's1',
      name: 'Jenny Doe',
      avatar: 'https://i.pravatar.cc/150?u=jenny',
      coverImage: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=1000&auto=format&fit=crop',
      description: 'Expert jewelry consultant with over 10 years of experience in fine gemstones and precious metals. Helping you find the perfect piece for your special moments is my passion. Whether it is an engagement ring or a custom necklace, I am here to guide you through the process with honesty and expertise.',
      experienceYears: 10,
      totalSold: 1250,
      returningCustomers: 85.0,
      followersCount: 12400,
      favoritesCount: 8900,
      ratings: {
        'Attitude': 4.9,
        'Consulting Skill': 4.8,
        'Product Knowledge': 5.0,
        'Honesty': 4.9,
        'After-sales Service': 4.7,
      },
      bestSellingProducts: [
        {"id": "c1", "name": "Gold Necklace", "price": 1200.0, "image": "https://i.postimg.cc/pL94mBxp/h10.jpg", "category": "Necklaces", "rating": 4.9},
        {"id": "c2", "name": "Silver Bracelet", "price": 450.0, "image": "https://i.postimg.cc/cHWq3842/h8.jpg", "category": "Bracelets", "rating": 4.5},
        {"id": "c3", "name": "Diamond Studs", "price": 850.0, "image": "https://i.postimg.cc/zv06gtVy/h9.jpg", "category": "Earrings", "rating": 4.8},
      ],
    );
  }
}
