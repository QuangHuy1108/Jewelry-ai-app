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

}
