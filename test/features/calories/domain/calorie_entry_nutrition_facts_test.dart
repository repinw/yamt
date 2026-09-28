import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/calories/domain/calorie_entry_nutrition_facts.dart';
import 'package:yamt/features/calories/domain/calorie_nutrient_details.dart';

final _loggedAt = DateTime(2026, 2, 25, 8);

CalorieEntry _entry({CalorieNutrientDetails? details}) {
  return CalorieEntry.create(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Skyr',
    mealType: MealType.breakfast,
    consumedAmount: 250,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 60,
    per100Protein: 11,
    per100Carbs: 4,
    per100Fat: 0.2,
    nutrientDetails: details,
    loggedAt: _loggedAt,
    createdAt: _loggedAt,
    updatedAt: _loggedAt,
  );
}

void main() {
  test('per 100 lists the macros and the label nutrients', () {
    final facts = calorieEntryPer100Facts(
      _entry(
        details: const CalorieNutrientDetails(
          per100SaturatedFat: 0.1,
          per100Sugar: 4,
          per100Salt: 0.1,
        ),
      ),
    );

    expect(facts?.kcal, 60);
    expect(facts?.protein, 11);
    expect(facts?.carbs, 4);
    expect(facts?.fat, 0.2);
    expect(facts?.saturatedFat, 0.1);
    expect(facts?.sugar, 4);
    expect(facts?.salt, 0.1);
    expect(facts?.fiber, isNull);
  });

  test('eaten uses the totals and scales the label nutrients', () {
    final facts = calorieEntryEatenFacts(
      _entry(
        details: const CalorieNutrientDetails(per100Sugar: 4, per100Fiber: 2),
      ),
    );

    expect(facts.kcal, 150);
    expect(facts.protein, 27.5);
    expect(facts.carbs, 10);
    expect(facts.fat, 0.5);
    expect(facts.sugar, 10);
    expect(facts.fiber, 5);
    expect(facts.salt, isNull);
  });

  test('a bundle has no values per 100', () {
    final bundle = CalorieEntry.bundle(
      id: 'bundle-1',
      userId: 'user-1',
      name: 'Chili',
      mealType: MealType.lunch,
      totalKcal: 420,
      totalProtein: 28,
      totalCarbs: 35,
      totalFat: 18,
      bundleSourcePreparedMealId: 'prepared-1',
      bundleConsumedPortions: 1,
      bundleTotalPortions: 4,
      bundleComponents: const [
        CalorieEntryBundleComponent(
          name: 'Beans',
          amountLabel: '150 g',
          totalKcal: 420,
          totalProtein: 28,
          totalCarbs: 35,
          totalFat: 18,
        ),
      ],
      loggedAt: _loggedAt,
    );

    expect(calorieEntryPer100Facts(bundle), isNull);
    expect(calorieEntryEatenFacts(bundle).kcal, 420);
  });
}
