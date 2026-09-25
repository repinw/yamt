import 'package:meta/meta.dart';
import 'package:yamt/core/domain/nutrition_facts.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

const _per100Basis = 100;

/// Nutrition of the amount being eaten, with the per-100 values when known.
@immutable
class EatNutrition {
  /// Creates eat nutrition.
  const new({required this.eaten, this.per100, this.amount});

  /// Scales per-100 values of [nutrition] to [amount] grams or milliliters.
  factory fromPer100(GlobalFoodNutrition nutrition, double amount) {
    final per100 = _per100Facts(nutrition);
    return EatNutrition(
      eaten: per100.scaled(amount / _per100Basis),
      per100: per100,
      amount: amount,
    );
  }

  /// Per-100 values of [nutrition] while the eaten amount is unknown.
  factory per100Only(GlobalFoodNutrition nutrition) {
    return EatNutrition(
      eaten: const NutritionFacts(),
      per100: _per100Facts(nutrition),
    );
  }

  /// Scales the totals of [meal] by [multiplier].
  factory ofPreparedMeal(PreparedMeal meal, double multiplier) {
    return EatNutrition(
      eaten: NutritionFacts(
        kcal: meal.totalKcal * multiplier,
        carbs: meal.totalCarbs * multiplier,
        protein: meal.totalProtein * multiplier,
        fat: meal.totalFat * multiplier,
      ),
    );
  }

  /// Nutrients of the eaten amount.
  final NutritionFacts eaten;

  /// Nutrients per 100 g or ml, or null when unknown.
  final NutritionFacts? per100;

  /// Eaten grams or milliliters, or null when unknown.
  final double? amount;
}

NutritionFacts _per100Facts(GlobalFoodNutrition nutrition) {
  return NutritionFacts(
    kcal: nutrition.per100Kcal,
    fat: nutrition.per100Fat,
    saturatedFat: nutrition.per100SaturatedFat,
    polyunsaturatedFat: nutrition.per100PolyunsaturatedFat,
    carbs: nutrition.per100Carbs,
    sugar: nutrition.per100Sugar,
    fiber: nutrition.per100Fiber,
    protein: nutrition.per100Protein,
    salt: nutrition.per100Salt,
  );
}
