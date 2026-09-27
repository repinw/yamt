import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

/// A photo of the food, sent with a food estimate request.
typedef FoodEstimatePhoto = ({String mimeType, Uint8List bytes});

/// How rich the preparation of an estimated food is assumed to be.
enum FoodEstimateLevel {
  /// Little oil, sauce, and fat.
  lean,

  /// A typical preparation.
  normal,

  /// Much oil, sauce, and fat.
  rich,
}

/// One component of an estimated food, for a normal preparation.
@immutable
class FoodEstimateIngredient {
  /// Creates an ingredient.
  const new({required this.name, required this.grams, required this.kcal});

  /// Ingredient name.
  final String name;

  /// Weight in the whole portion.
  final double grams;

  /// Energy in the whole portion.
  final double kcal;
}

/// AI estimate of a food from photos and a description.
@immutable
class FoodEstimate {
  /// Creates an estimate.
  const new({
    required this.name,
    required this.portionGrams,
    required this.kcalLean,
    required this.kcalRich,
    required this.per100,
    required this.ingredients,
  });

  /// Dish or food name.
  final String name;

  /// Weight of the whole portion.
  final double portionGrams;

  /// Energy of the whole portion for a lean preparation.
  final double kcalLean;

  /// Energy of the whole portion for a rich preparation.
  final double kcalRich;

  /// Nutrition per 100 g for a normal preparation.
  final GlobalFoodNutrition per100;

  /// Components of the portion for a normal preparation.
  final List<FoodEstimateIngredient> ingredients;

  /// Energy of the whole portion at [level].
  double portionKcal(FoodEstimateLevel level) => switch (level) {
    FoodEstimateLevel.lean => kcalLean,
    FoodEstimateLevel.normal => (per100.per100Kcal ?? 0) * portionGrams / 100,
    FoodEstimateLevel.rich => kcalRich,
  };

  /// Nutrition per 100 g at [level].
  ///
  /// A richer or leaner preparation mostly changes fat and sauce, but the
  /// estimate only knows the energy range, so every value scales with the
  /// energy.
  GlobalFoodNutrition per100At(FoodEstimateLevel level) {
    final factor = _factor(level);
    double? scale(double? value) => value == null ? null : value * factor;
    return per100.copyWith(
      per100Kcal: scale(per100.per100Kcal),
      per100Protein: scale(per100.per100Protein),
      per100Carbs: scale(per100.per100Carbs),
      per100Fat: scale(per100.per100Fat),
      per100Salt: scale(per100.per100Salt),
      per100SaturatedFat: scale(per100.per100SaturatedFat),
      per100PolyunsaturatedFat: scale(per100.per100PolyunsaturatedFat),
      per100Sugar: scale(per100.per100Sugar),
      per100Fiber: scale(per100.per100Fiber),
    );
  }

  /// Ingredients of [grams] of the food at [level], with their energy
  /// scaled like [per100At].
  List<FoodEstimateIngredient> ingredientsAt(
    FoodEstimateLevel level, {
    required double grams,
  }) {
    final factor = _factor(level);
    final share = portionGrams <= 0 ? 0.0 : grams / portionGrams;
    return [
      for (final ingredient in ingredients)
        FoodEstimateIngredient(
          name: ingredient.name,
          grams: ingredient.grams * share,
          kcal: ingredient.kcal * factor * share,
        ),
    ];
  }

  double _factor(FoodEstimateLevel level) {
    final normal = portionKcal(FoodEstimateLevel.normal);
    return normal <= 0 ? 1 : portionKcal(level) / normal;
  }
}
