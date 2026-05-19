class AiResultModel {
  final String type;
  final String material;
  final String gemstone;
  final String style;
  final String estimatedPriceRange;

  AiResultModel({
    required this.type,
    required this.material,
    required this.gemstone,
    required this.style,
    required this.estimatedPriceRange,
  });

  factory AiResultModel.fromJson(Map<String, dynamic> json) {
    return AiResultModel(
      type: (json['type']?.toString() ?? 'unknown').trim().toLowerCase(),
      material: (json['material']?.toString() ?? 'unknown').trim().toLowerCase(),
      gemstone: (json['gemstone']?.toString() ?? 'unknown').trim().toLowerCase(),
      style: (json['style']?.toString() ?? 'unknown').trim().toLowerCase(),
      estimatedPriceRange: json['estimated_price_range']?.toString() ?? 'N/A',
    );
  }
}
