import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

/// Helper for converting Yamt's [GlobalFoodNutrition] into a nutrition map
/// for scanner product candidates.
abstract final class YamtNutritionConverter {
  /// Converts [nutrition] into a map of standard nutrition per 100g/ml keys.
  static Map<String, num>? toNutritionMap(GlobalFoodNutrition? nutrition) {
    if (nutrition == null) return null;
    final map = <String, num>{};
    if (nutrition.per100Kcal != null) {
      map['kcal'] = nutrition.per100Kcal!;
    }
    if (nutrition.per100Protein != null) {
      map['protein'] = nutrition.per100Protein!;
    }
    if (nutrition.per100Carbs != null) {
      map['carbs'] = nutrition.per100Carbs!;
    }
    if (nutrition.per100Fat != null) {
      map['fat'] = nutrition.per100Fat!;
    }
    return map.isEmpty ? null : map;
  }
}
