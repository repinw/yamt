import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

/// Defines off product search result.
class OffProductSearchResult {
  /// The off product search result.
  const OffProductSearchResult({
    required this.code,
    required this.name,
    required this.score,
    this.brand,
    this.imageUrl,
    this.packageWeight,
    this.servingSize,
    this.servingQuantity,
    this.servingQuantityUnit,
    this.nutrition,
  });

  /// The code.
  final String code;

  /// The name.
  final String name;

  /// The score.
  final double score;

  /// The brand.
  final String? brand;

  /// The image url.
  final String? imageUrl;

  /// The package weight.
  final String? packageWeight;

  /// The serving size.
  final String? servingSize;

  /// The serving quantity.
  final double? servingQuantity;

  /// The serving quantity unit.
  final String? servingQuantityUnit;

  /// The nutrition.
  final GlobalFoodNutrition? nutrition;
}
