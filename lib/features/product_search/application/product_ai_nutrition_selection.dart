import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/product_search/domain/product_ai_search_models.dart';

/// User-adjusted nutrition selection for an AI product draft.
class ProductAiNutritionSelection {
  /// Creates a selection.
  const ProductAiNutritionSelection({
    required this.draft,
    required this.weightGrams,
    required this.weightLabel,
    required this.minPer100Kcal,
    required this.maxPer100Kcal,
    required this.basePer100Kcal,
    required this.per100Kcal,
    required this.per100Nutrition,
    required this.portionNutrition,
  });

  /// Source AI draft.
  final ProductAiSearchDraft draft;

  /// Selected portion weight in grams.
  final double weightGrams;

  /// Display and persistence weight label.
  final String weightLabel;

  /// Minimum per-100 kcal density.
  final double minPer100Kcal;

  /// Maximum per-100 kcal density.
  final double maxPer100Kcal;

  /// Default per-100 kcal density.
  final double basePer100Kcal;

  /// Selected per-100 kcal density.
  final double per100Kcal;

  /// Per-100 nutrition for inventory persistence.
  final GlobalFoodNutrition per100Nutrition;

  /// Nutrition for the selected portion.
  final ProductAiSearchNutritionEstimate portionNutrition;
}
