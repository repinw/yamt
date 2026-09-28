import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/calories/domain/calorie_nutrient_details.dart';

/// Builds one diary entry for [components] eaten together.
///
/// The entry is named after its components (see [combinedFoodName]), and
/// its totals are the sums of the components. Like a prepared meal entry
/// it counts as 100 g of itself, so the per-100 values equal the totals.
CalorieEntry buildCombinedCalorieEntry({
  required String id,
  required String userId,
  required MealType mealType,
  required DateTime loggedAt,
  required DateTime now,
  required List<CalorieEntryBundleComponent> components,
  String? imageUrl,
  CalorieNutrientDetails? nutrientDetails,
}) {
  if (components.length < 2) {
    throw ArgumentError.value(
      components.length,
      'components',
      'A combined entry needs at least two foods.',
    );
  }
  double sum(double Function(CalorieEntryBundleComponent) value) {
    return components.fold(0, (total, component) => total + value(component));
  }

  final kcal = sum((component) => component.totalKcal);
  final protein = sum((component) => component.totalProtein);
  final carbs = sum((component) => component.totalCarbs);
  final fat = sum((component) => component.totalFat);
  return CalorieEntry(
    id: id,
    userId: userId,
    name: combinedFoodName(components.map((component) => component.name)),
    imageUrl: imageUrl,
    mealType: mealType,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: kcal,
    per100Protein: protein,
    per100Carbs: carbs,
    per100Fat: fat,
    totalKcal: kcal,
    totalProtein: protein,
    totalCarbs: carbs,
    totalFat: fat,
    loggedAt: loggedAt,
    createdAt: now,
    updatedAt: now,
    bundleComponents: components,
    nutrientDetails: nutrientDetails,
    isQuickEntry: false,
  );
}

/// Label nutrients of foods eaten together, per 100 g of the combined entry.
///
/// A combined entry counts as 100 g of itself, so each value is the sum of
/// what the foods' eaten amounts contain. A value is unknown when one food does
/// not list it.
CalorieNutrientDetails? combineCalorieNutrientDetails(
  Iterable<({CalorieNutrientDetails? details, double amount})> foods,
) {
  double? sum(double? Function(CalorieNutrientDetails details) value) {
    var total = 0.0;
    for (final food in foods) {
      final details = food.details;
      final per100 = details == null ? null : value(details);
      if (per100 == null) {
        return null;
      }
      total += per100 * food.amount / 100;
    }
    return total;
  }

  final combined = CalorieNutrientDetails(
    per100SaturatedFat: sum((details) => details.per100SaturatedFat),
    per100PolyunsaturatedFat: sum(
      (details) => details.per100PolyunsaturatedFat,
    ),
    per100Sugar: sum((details) => details.per100Sugar),
    per100Fiber: sum((details) => details.per100Fiber),
    per100Salt: sum((details) => details.per100Salt),
  );
  return combined.hasAnyValue ? combined : null;
}

/// Name of foods eaten together: distinct names joined with " + ", and a
/// name that appears several times counted once, such as "2× Apfel + Brot".
String combinedFoodName(Iterable<String> names) {
  final counts = <String, int>{};
  for (final name in names) {
    counts[name] = (counts[name] ?? 0) + 1;
  }
  return counts.entries
      .map(
        (entry) =>
            entry.value == 1 ? entry.key : '${entry.value}× ${entry.key}',
      )
      .join(' + ');
}
