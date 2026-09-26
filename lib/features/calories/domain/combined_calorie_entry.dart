import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/calories/domain/calorie_nutrient_details.dart';

/// Builds one diary entry for [components] eaten together.
///
/// The entry is named "A + B" after its components, and its totals are the
/// sums of the components. Like a prepared meal entry it counts as 100 g of
/// itself, so the per-100 values equal the totals.
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
    name: components.map((component) => component.name).join(' + '),
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
  );
}
