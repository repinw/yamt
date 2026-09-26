import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/domain/nutrition_facts.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/eat_meal_nutrition.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';

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

  test('a food without an amount leaves the weight and per-100 unknown', () {
    final meal = EatMealNutrition.combine(const [
      (eaten: NutritionFacts(kcal: 200), amount: 50, unit: ConsumedUnit.grams),
      (eaten: NutritionFacts(), amount: 0, unit: ConsumedUnit.grams),
    ]);

    expect(meal.amounts, {ConsumedUnit.grams: 50});
    expect(meal.per100, isNull);
    expect(meal.total.kcal, isNull);
    expect(meal.listed.kcal, 200);
  });

  test('a request with its own calorie amount counts in that unit', () {
    final item = InventoryItem.create(
      id: 'eggs',
      name: 'Eggs',
      entryDate: DateTime(2026, 9, 27),
      storeName: 'Store',
      quantity: 6,
      nutrition: const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Kcal: 150,
        per100Protein: 13,
        per100Carbs: 1,
        per100Fat: 11,
      ),
    );

    final food = eatMealFoodOfRequest(
      item,
      InventoryItemEatRequest(
        inventoryAmount: 2,
        calorieAmount: 120,
        calorieUnit: ConsumedUnit.grams,
        loggedAt: DateTime(2026, 9, 27),
        mealType: MealType.breakfast,
      ),
    );

    expect(food?.amount, 120);
    expect(food?.unit, ConsumedUnit.grams);
    expect(food?.eaten.kcal, 180);
  });
}
