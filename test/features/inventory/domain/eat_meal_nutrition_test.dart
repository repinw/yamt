import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/nutrition_facts.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/eat_meal_nutrition.dart';

void main() {
  test('sums the foods and scales the meal to 100 g', () {
    final meal = EatMealNutrition.combine(const [
      (
        eaten: NutritionFacts(kcal: 200, sugar: 2),
        amount: 50,
        unit: ConsumedUnit.grams,
      ),
      (
        eaten: NutritionFacts(kcal: 100, sugar: 4),
        amount: 150,
        unit: ConsumedUnit.grams,
      ),
    ]);

    expect(meal.total.kcal, 300);
    expect(meal.total.sugar, 6);
    expect(meal.per100?.kcal, 150);
    expect(meal.amounts, {ConsumedUnit.grams: 200});
  });

  test('leaves a total unknown when one food lacks the nutrient', () {
    final meal = EatMealNutrition.combine(const [
      (
        eaten: NutritionFacts(kcal: 200, sugar: 2),
        amount: 50,
        unit: ConsumedUnit.grams,
      ),
      (eaten: NutritionFacts(kcal: 100), amount: 150, unit: ConsumedUnit.grams),
    ]);

    expect(meal.total.sugar, isNull);
    expect(meal.listed.sugar, 2);
    expect(meal.total.salt, isNull);
    expect(meal.listed.salt, isNull);
  });

  test('has no per-100 values when grams and milliliters mix', () {
    final meal = EatMealNutrition.combine(const [
      (
        eaten: NutritionFacts(kcal: 128),
        amount: 200,
        unit: ConsumedUnit.milliliters,
      ),
      (eaten: NutritionFacts(kcal: 186), amount: 50, unit: ConsumedUnit.grams),
    ]);

    expect(meal.total.kcal, 314);
    expect(meal.per100, isNull);
    expect(meal.amounts, {
      ConsumedUnit.milliliters: 200,
      ConsumedUnit.grams: 50,
    });
  });
}
