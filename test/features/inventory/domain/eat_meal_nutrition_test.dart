import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/domain/nutrition_facts.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/eat_meal_nutrition.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_pot_weighing.dart';

import '../../../support/prepared_meal_test_data.dart';

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

  test('a meal without foods adds up to nothing, not to unknown values', () {
    final meal = EatMealNutrition.combine(const []);

    expect(meal.total.kcal, 0);
    expect(meal.total.sugar, 0);
    expect(meal.listed.kcal, isNull);
    expect(meal.per100, isNull);
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

  test('per portion splits the totals and amounts, not per 100', () {
    final meal = EatMealNutrition.combine(const [
      (
        eaten: NutritionFacts(kcal: 500, protein: 20),
        amount: 200,
        unit: ConsumedUnit.grams,
      ),
      (eaten: NutritionFacts(kcal: 600), amount: 150, unit: ConsumedUnit.grams),
    ]);

    final portion = meal.perPortion(4);

    expect(portion.total.kcal, 275);
    expect(portion.total.protein, isNull);
    expect(portion.listed.protein, 5);
    expect(portion.amounts, {ConsumedUnit.grams: 87.5});
    expect(portion.per100?.kcal, meal.per100?.kcal);
    expect(meal.perPortion(1), same(meal));
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

  test('reads a typed amount as the stock takes it, up to the stock', () {
    final rice = InventoryItem.create(
      id: 'rice',
      name: 'Rice',
      entryDate: DateTime(2026, 10),
      storeName: 'Store',
      quantity: 1,
      initialAmount: 500,
      currentAmount: 250,
      amountUnit: InventoryAmountUnit.gram,
    );

    expect(typedMealFoodAmount(rice, '137'), 137);
    expect(typedMealFoodAmount(rice, ' 37,5 '), 38);
    expect(typedMealFoodAmount(rice, '250'), 250);
    expect(typedMealFoodAmount(rice, '250,4'), isNull);
    expect(typedMealFoodAmount(rice, '251'), isNull);
    expect(typedMealFoodAmount(rice, '0'), isNull);
    expect(typedMealFoodAmount(rice, ''), isNull);
    expect(typedMealFoodAmount(rice, 'abc'), isNull);
    // A food found by search is not limited by its stock.
    expect(typedMealFoodAmount(rice, '800', hasOpenStock: true), 800);
  });

  group('ofPreparedMeal', () {
    final rice = labeledIngredientTestData(
      labeledFoodTestData(
        id: 'rice',
        name: 'Reis',
        grams: 1000,
        label: riceLabelTestData,
      ),
      200,
    );
    final sauce = labeledIngredientTestData(
      labeledFoodTestData(
        id: 'sauce',
        name: 'Tomatensauce',
        grams: 500,
        label: sauceLabelTestData,
      ),
      300,
    );

    test('a weighed meal has every nutrient per 100 g', () {
      final meal = EatMealNutrition.ofPreparedMeal(
        labeledMealTestData(ingredients: [rice, rice])
            .copyWith(finalNetWeight: 500),
        0.5,
      );

      // The whole meal: 1400 kcal and 1 g salt in 500 g.
      expect(meal.per100?.kcal, 280);
      expect(meal.per100?.salt, closeTo(0.2, 1e-9));
      expect(meal.per100?.polyunsaturatedFat, isNull);
    });

    test('adds up every nutrient that all ingredients list', () {
      final meal = EatMealNutrition.ofPreparedMeal(
        labeledMealTestData(ingredients: [rice, rice]),
        0.5,
      );

      expect(meal.total.kcal, 700);
      expect(meal.total.fat, 2);
      expect(meal.total.carbs, 150);
      expect(meal.total.protein, 16);
      expect(meal.total.saturatedFat, 1);
      expect(meal.total.sugar, 2);
      expect(meal.total.fiber, 4);
      expect(meal.total.salt, 0.5);
      expect(meal.total.polyunsaturatedFat, isNull);
      expect(meal.per100, isNull);
      expect(meal.amounts, isEmpty);
    });

    test('leaves a nutrient that one ingredient lacks unknown but listed, '
        'and keeps the counted energy and macros', () {
      final meal = EatMealNutrition.ofPreparedMeal(
        labeledMealTestData(ingredients: [rice, sauce]),
        1,
      );

      expect(meal.total.kcal, 850);
      expect(meal.total.fat, 8);
      expect(meal.total.carbs, 168);
      expect(meal.total.protein, 20.5);
      expect(meal.total.sugar, isNull);
      expect(meal.listed.sugar, 2);
      expect(meal.total.salt, isNull);
      expect(meal.listed.salt, 0.5);
      expect(meal.listed.polyunsaturatedFat, isNull);
    });

    test('a meal without ingredients has only its energy and macros', () {
      final meal = EatMealNutrition.ofPreparedMeal(
        preparedMealTestData().copyWith(components: const []),
        0.25,
      );

      expect(meal.total.kcal, 100);
      expect(meal.total.carbs, 10);
      expect(meal.total.protein, 5);
      expect(meal.total.fat, 2);
      expect(meal.total.sugar, isNull);
      expect(meal.listed.sugar, isNull);
    });
  });

  group('per 100 g of a prepared meal', () {
    // 400 kcal, 8 g fat, 40 g carbs and 20 g protein in 4 portions.
    final meal = preparedMealTestData(totalPortions: 4, remainingPortions: 4);

    test('are unknown before the cooked meal was weighed', () {
      final nutrition = EatMealNutrition.ofPreparedMeal(meal, 0.25);

      expect(nutrition.per100, isNull);
      expect(nutrition.total.kcal, 100);
    });

    test('are unknown for a cooked weight of zero', () {
      final nutrition = EatMealNutrition.ofPreparedMeal(
        meal.copyWith(finalNetWeight: 0),
        0.25,
      );

      expect(nutrition.per100, isNull);
    });

    test('are the totals per 100 g of the cooked weight', () {
      final nutrition = EatMealNutrition.ofPreparedMeal(
        meal.copyWith(finalNetWeight: 800),
        0.25,
      );

      expect(nutrition.per100?.kcal, 50);
      expect(nutrition.per100?.fat, 1);
      expect(nutrition.per100?.carbs, 5);
      expect(nutrition.per100?.protein, 2.5);
      expect(nutrition.per100?.sugar, isNull);
      // The eaten portion stays as it is.
      expect(nutrition.total.kcal, 100);
      expect(nutrition.total.protein, 5);
    });

    test('do not change as portions are eaten', () {
      final nutrition = EatMealNutrition.ofPreparedMeal(
        meal.copyWith(finalNetWeight: 800, remainingPortions: 2),
        0.25,
      );

      expect(nutrition.per100?.kcal, 50);
    });

    test('follow a weighing of the pot', () {
      // Water evaporated: the 2 portions left (200 kcal) weigh 250 g, not
      // the 400 g that "Gekocht" would give.
      final nutrition = EatMealNutrition.ofPreparedMeal(
        meal.copyWith(
          finalNetWeight: 800,
          remainingPortions: 2,
          potWeighing: PreparedMealPotWeighing(
            netWeight: 250,
            weighedAt: DateTime(2026, 10, 10),
            remainingPortions: 2,
          ),
        ),
        0.25,
      );

      expect(nutrition.per100?.kcal, 80);
      expect(nutrition.per100?.protein, 4);
    });

    test('are unknown when nothing is left', () {
      final nutrition = EatMealNutrition.ofPreparedMeal(
        meal.copyWith(finalNetWeight: 800, remainingPortions: 0),
        0.25,
      );

      expect(nutrition.per100, isNull);
    });
  });
}
