import 'package:yamt/features/calories/domain/calorie_nutrient_details.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

/// Label nutrients of [nutrition] beyond the macros, or `null` when it has
/// none of them.
CalorieNutrientDetails? calorieNutrientDetailsFrom(
  GlobalFoodNutrition? nutrition,
) {
  if (nutrition == null) {
    return null;
  }
  final details = CalorieNutrientDetails(
    per100SaturatedFat: nutrition.per100SaturatedFat,
    per100PolyunsaturatedFat: nutrition.per100PolyunsaturatedFat,
    per100Sugar: nutrition.per100Sugar,
    per100Fiber: nutrition.per100Fiber,
    per100Salt: nutrition.per100Salt,
  );
  return details.hasAnyValue ? details : null;
}
