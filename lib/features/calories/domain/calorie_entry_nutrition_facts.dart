import 'package:yamt/core/domain/nutrition_facts.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';

/// Label nutrients of [entry] per 100 g or ml, or null for a bundle or a
/// quick entry, which know only their totals.
NutritionFacts? calorieEntryPer100Facts(CalorieEntry entry) {
  if (entry.isBundle || entry.isQuickEntry) {
    return null;
  }
  final details = entry.nutrientDetails;
  return NutritionFacts(
    kcal: entry.per100Kcal,
    fat: entry.per100Fat,
    saturatedFat: details?.per100SaturatedFat,
    polyunsaturatedFat: details?.per100PolyunsaturatedFat,
    carbs: entry.per100Carbs,
    sugar: details?.per100Sugar,
    fiber: details?.per100Fiber,
    protein: entry.per100Protein,
    salt: details?.per100Salt,
  );
}

/// Label nutrients of the eaten amount of [entry]: the stored totals, and
/// the other label nutrients scaled to the consumed amount.
NutritionFacts calorieEntryEatenFacts(CalorieEntry entry) {
  final details = entry.nutrientDetails;
  final factor = entry.consumedAmount / 100;
  double? scaled(double? per100) => per100 == null ? null : per100 * factor;
  return NutritionFacts(
    kcal: entry.totalKcal,
    fat: entry.totalFat,
    saturatedFat: scaled(details?.per100SaturatedFat),
    polyunsaturatedFat: scaled(details?.per100PolyunsaturatedFat),
    carbs: entry.totalCarbs,
    sugar: scaled(details?.per100Sugar),
    fiber: scaled(details?.per100Fiber),
    protein: entry.totalProtein,
    salt: scaled(details?.per100Salt),
  );
}
