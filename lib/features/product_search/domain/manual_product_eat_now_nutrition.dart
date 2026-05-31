import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

/// Whether nutrition can support direct eat-now calorie logging.
bool hasRequiredEatNowNutrition(GlobalFoodNutrition? nutrition) {
  return nutrition?.per100Kcal != null &&
      nutrition?.per100Carbs != null &&
      nutrition?.per100Protein != null &&
      nutrition?.per100Fat != null;
}
