import 'package:flutter/foundation.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form_utils.dart';

/// Ingredient row shown in AI estimate review.
@immutable
class ProductAiSearchIngredientRow {
  /// Creates an ingredient row.
  const ProductAiSearchIngredientRow({
    required this.label,
    required this.amountText,
    required this.amountGrams,
    required this.kcalMin,
    required this.kcalMax,
    this.protein,
    this.carbs,
    this.fat,
  });

  /// Ingredient label.
  final String label;

  /// Display amount text, for example `120 - 150 g`.
  final String amountText;

  /// Estimated weight in grams.
  final double amountGrams;

  /// Minimum estimated kcal.
  final double kcalMin;

  /// Maximum estimated kcal.
  final double kcalMax;

  /// Estimated protein grams.
  final double? protein;

  /// Estimated carb grams.
  final double? carbs;

  /// Estimated fat grams.
  final double? fat;
}

/// Portion-level nutrition estimate produced by AI.
@immutable
class ProductAiSearchNutritionEstimate {
  /// Creates a portion nutrition estimate.
  const ProductAiSearchNutritionEstimate({
    required this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    this.salt,
    this.saturatedFat,
    this.polyunsaturatedFat,
    this.sugar,
    this.fiber,
  });

  /// Total kcal for portion.
  final double kcal;

  /// Protein grams for portion.
  final double? protein;

  /// Carb grams for portion.
  final double? carbs;

  /// Fat grams for portion.
  final double? fat;

  /// Salt grams for portion.
  final double? salt;

  /// Saturated fat grams for portion.
  final double? saturatedFat;

  /// Polyunsaturated fat grams for portion.
  final double? polyunsaturatedFat;

  /// Sugar grams for portion.
  final double? sugar;

  /// Fiber grams for portion.
  final double? fiber;

  /// Scale estimate proportionally.
  ProductAiSearchNutritionEstimate scaleBy(double factor) {
    return ProductAiSearchNutritionEstimate(
      kcal: kcal * factor,
      protein: _scaleOptional(protein, factor),
      carbs: _scaleOptional(carbs, factor),
      fat: _scaleOptional(fat, factor),
      salt: _scaleOptional(salt, factor),
      saturatedFat: _scaleOptional(saturatedFat, factor),
      polyunsaturatedFat: _scaleOptional(polyunsaturatedFat, factor),
      sugar: _scaleOptional(sugar, factor),
      fiber: _scaleOptional(fiber, factor),
    );
  }

  /// Scale estimate to a specific kcal target.
  ProductAiSearchNutritionEstimate scaleToKcal(double targetKcal) {
    if (kcal <= 0) {
      return ProductAiSearchNutritionEstimate(
        kcal: targetKcal,
        protein: protein,
        carbs: carbs,
        fat: fat,
        salt: salt,
        saturatedFat: saturatedFat,
        polyunsaturatedFat: polyunsaturatedFat,
        sugar: sugar,
        fiber: fiber,
      );
    }
    final factor = targetKcal / kcal;
    return scaleBy(factor);
  }

  /// Convert current portion estimate to per-100 nutrition.
  GlobalFoodNutrition toPer100Nutrition({
    required double grams,
    required GlobalFoodNutritionQualityStatus qualityStatus,
  }) {
    final factor = grams <= 0 ? 0.0 : 100 / grams;
    return GlobalFoodNutrition(
      qualityStatus: qualityStatus,
      per100Kcal: _roundToTwoDecimals(kcal * factor),
      per100Protein: _roundOptional(_scaleOptional(protein, factor)),
      per100Carbs: _roundOptional(_scaleOptional(carbs, factor)),
      per100Fat: _roundOptional(_scaleOptional(fat, factor)),
      per100Salt: _roundOptional(_scaleOptional(salt, factor)),
      per100SaturatedFat: _roundOptional(_scaleOptional(saturatedFat, factor)),
      per100PolyunsaturatedFat: _roundOptional(
        _scaleOptional(polyunsaturatedFat, factor),
      ),
      per100Sugar: _roundOptional(_scaleOptional(sugar, factor)),
      per100Fiber: _roundOptional(_scaleOptional(fiber, factor)),
    );
  }

  static double? _scaleOptional(double? value, double factor) {
    return value == null ? null : value * factor;
  }

  static double? _roundOptional(double? value) {
    return value == null ? null : _roundToTwoDecimals(value);
  }

  static double _roundToTwoDecimals(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}

/// Parsed AI review draft for manual product search.
@immutable
class ProductAiSearchDraft {
  /// Creates a draft.
  const ProductAiSearchDraft({
    required this.name,
    required this.ingredients,
    required this.totalWeightGrams,
    required this.totalKcalMin,
    required this.totalKcalMax,
    required this.defaultKcal,
    required this.portionNutrition,
    this.brand,
  });

  /// Generated product name.
  final String name;

  /// Optional brand.
  final String? brand;

  /// Ingredient rows.
  final List<ProductAiSearchIngredientRow> ingredients;

  /// Estimated total portion weight in grams.
  final double totalWeightGrams;

  /// Minimum total kcal.
  final double totalKcalMin;

  /// Maximum total kcal.
  final double totalKcalMax;

  /// Default selected kcal.
  final double defaultKcal;

  /// Portion-level nutrition estimate.
  final ProductAiSearchNutritionEstimate portionNutrition;

  /// Portion label stored with item.
  String get servingSizeLabel => '${_formatDouble(totalWeightGrams)} g';

  /// Total kcal text for review.
  String get totalKcalRangeLabel {
    return '${_formatDouble(totalKcalMin)} - '
        '${_formatDouble(totalKcalMax)} kcal';
  }

  /// Total weight text for review.
  String get totalWeightLabel => '${_formatDouble(totalWeightGrams)} g';

  /// Clamp kcal into AI-supported range.
  double clampKcal(double value) {
    return value.clamp(totalKcalMin, totalKcalMax);
  }

  /// Portion nutrition for selected kcal.
  ProductAiSearchNutritionEstimate nutritionForKcal(double value) {
    return portionNutrition.scaleToKcal(clampKcal(value));
  }

  /// Per-100 nutrition for selected kcal.
  GlobalFoodNutrition per100NutritionForKcal({
    required double value,
    required GlobalFoodNutritionQualityStatus qualityStatus,
  }) {
    return nutritionForKcal(value).toPer100Nutrition(
      grams: totalWeightGrams,
      qualityStatus: qualityStatus,
    );
  }

  static String _formatDouble(double value) {
    return formatManualProductDouble(value);
  }
}
