import 'package:yamt/features/inventory/domain/global_food_item.dart';
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
    this.globalFoodItemId,
  });

  /// Creates a search result from a Firestore global food item.
  factory OffProductSearchResult.fromGlobalFoodItem(
    GlobalFoodItem item, {
    double score = 1.0,
  }) {
    return OffProductSearchResult(
      code: item.barcode ?? item.id,
      name: item.name,
      score: score,
      brand: item.brand,
      imageUrl: item.imageUrl,
      packageWeight: item.packageWeight,
      servingSize: item.servingSize,
      servingQuantity: item.servingQuantity,
      servingQuantityUnit: item.servingQuantityUnit,
      nutrition: item.nutrition,
      globalFoodItemId: item.id,
    );
  }

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

  /// Optional ID of the backing Firestore global food item.
  final String? globalFoodItemId;
}
