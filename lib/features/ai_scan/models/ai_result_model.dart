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
      type: json['type']?.toString() ?? 'Unknown',
      material: json['material']?.toString() ?? 'Unknown',
      gemstone: json['gemstone']?.toString() ?? 'Unknown',
      style: json['style']?.toString() ?? 'Unknown',
      estimatedPriceRange: json['estimated_price_range']?.toString() ?? 'N/A',
    );
  }
}
