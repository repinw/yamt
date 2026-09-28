import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';

/// Builds a quick entry: calories and macros the user typed in by hand,
/// without a food behind them.
///
/// The typed values are the totals, and a macro that was not typed counts as
/// 0 g. Like a prepared meal entry it counts as 100 g of itself, so the
/// per-100 values equal the totals.
CalorieEntry buildQuickCalorieEntry({
  required String id,
  required String userId,
  required String name,
  required MealType mealType,
  required DateTime loggedAt,
  required DateTime now,
  required double kcal,
  double? protein,
  double? carbs,
  double? fat,
}) {
  final totalProtein = protein ?? 0;
  final totalCarbs = carbs ?? 0;
  final totalFat = fat ?? 0;
  return CalorieEntry(
    id: id,
    userId: userId,
    name: name,
    mealType: mealType,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: kcal,
    per100Protein: totalProtein,
    per100Carbs: totalCarbs,
    per100Fat: totalFat,
    totalKcal: kcal,
    totalProtein: totalProtein,
    totalCarbs: totalCarbs,
    totalFat: totalFat,
    loggedAt: loggedAt,
    createdAt: now,
    updatedAt: now,
    isQuickEntry: true,
  );
}
