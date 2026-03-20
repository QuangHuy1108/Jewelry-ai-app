import 'package:flutter/material.dart';

class FilterState extends ChangeNotifier {
  static final FilterState _instance = FilterState._internal();
  factory FilterState() => _instance;
  FilterState._internal();

  // Unified Filter Properties
  List<String> categories = [];
  double? minPrice;
  double? maxPrice;
  int rating = 0; // 0 = any
  String sort = "Popular";
  String material = "All";
  String brand = "All";
  String size = "All";

  List<String> recentSearches = ["Diamond Ring", "Gold Necklace", "Silver Bracelet"];

  void addRecentSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    recentSearches.remove(q);
    recentSearches.insert(0, q);
    notifyListeners();
  }

  void removeRecentSearch(String query) {
    recentSearches.remove(query);
    notifyListeners();
  }

  void clearRecentSearches() {
    recentSearches.clear();
    notifyListeners();
  }

  void setSort(String newSort) {
    if (sort != newSort) {
      sort = newSort;
      notifyListeners();
    }
  }

  void applyQuickFilter({
    required String category,
    required double? min,
    required double? max,
    required int newRating,
  }) {
    categories = category == "All" || category.isEmpty ? [] : [category];
    minPrice = min;
    maxPrice = max;
    rating = newRating;
    notifyListeners();
  }

  void applyAdvancedFilter({
    required List<String> newCategories,
    required double? min,
    required double? max,
    required int newRating,
    required String newMaterial,
    required String newBrand,
    required String newSize,
  }) {
    categories = List.from(newCategories);
    minPrice = min;
    maxPrice = max;
    rating = newRating;
    material = newMaterial;
    brand = newBrand;
    size = newSize;
    notifyListeners();
  }

  void removeFilter(String chipLabel) {
    if (categories.contains(chipLabel)) {
      categories.remove(chipLabel);
    } else if (chipLabel.startsWith("Under \$") || chipLabel.startsWith("Above \$") || chipLabel.contains(" - ")) {
      minPrice = null;
      maxPrice = null;
    } else if (chipLabel.contains("★")) {
      rating = 0;
    } else if (chipLabel == material) {
      material = "All";
    } else if (chipLabel == brand) {
      brand = "All";
    } else if (chipLabel == size) {
      size = "All";
    }
    notifyListeners();
  }

  void resetAll() {
    categories.clear();
    minPrice = null;
    maxPrice = null;
    rating = 0;
    sort = "Popular";
    material = "All";
    brand = "All";
    size = "All";
    notifyListeners();
  }

  List<String> getActiveFilterChips() {
    List<String> chips = [];
    chips.addAll(categories);
    
    if (minPrice != null && maxPrice != null) {
      chips.add("\$${minPrice!.toInt()} - \$${maxPrice!.toInt()}");
    } else if (maxPrice != null) {
      chips.add("Under \$${maxPrice!.toInt()}");
    } else if (minPrice != null) {
      chips.add("Above \$${minPrice!.toInt()}");
    }

    if (rating > 0) {
      chips.add("$rating★ & up");
    }
    
    if (material != "All") chips.add(material);
    if (brand != "All") chips.add(brand);
    if (size != "All") chips.add(size);
    
    return chips;
  }
}
