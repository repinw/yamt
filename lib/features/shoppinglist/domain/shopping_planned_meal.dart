import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/domain/meal_type.dart';

/// The planned meal a product is for: its local calendar day and meal.
typedef ShoppingPlannedMeal = ({DateTime day, MealType mealType});

/// Stores [meal] without words, so every member reads it in their language.
Map<String, String>? shoppingPlannedMealToJson(ShoppingPlannedMeal? meal) =>
    meal == null
    ? null
    : {'day': localDayKey(meal.day), 'meal_type': meal.mealType.jsonValue};

/// Reads what [shoppingPlannedMealToJson] stored; null when [json] is null.
/// Throws a [FormatException] for anything else.
ShoppingPlannedMeal? shoppingPlannedMealFromJson(Object? json) {
  if (json == null) return null;
  if (json case {
    'day': final String dayKey,
    'meal_type': final String mealKey,
  }) {
    final day = parseLocalDayKey(dayKey);
    final mealType = MealType.values
        .where((type) => type.jsonValue == mealKey)
        .firstOrNull;
    if (day != null && mealType != null) {
      return (day: day, mealType: mealType);
    }
  }
  throw FormatException('Expected a planned meal but got: $json');
}
