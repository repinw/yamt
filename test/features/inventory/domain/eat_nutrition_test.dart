import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/eat_nutrition.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_pot_weighing.dart';

import '../../../support/prepared_meal_test_data.dart';

void main() {
  test('scales per-100 values and keeps unknown values null', () {
    final nutrition = EatNutrition.fromPer100(
      const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Kcal: 64,
        per100Protein: 3,
      ),
      150,
    );

    expect(nutrition.eaten.kcal, 96);
    expect(nutrition.eaten.protein, 4.5);
    expect(nutrition.eaten.carbs, isNull);
    expect(nutrition.eaten.fat, isNull);
  });

  test('scales prepared meal totals', () {
    final nutrition = EatNutrition.ofPreparedMeal(preparedMealTestData(), 0.25);

    expect(nutrition.eaten.kcal, 100);
    expect(nutrition.eaten.carbs, 10);
    expect(nutrition.eaten.protein, 5);
    expect(nutrition.eaten.fat, 2);
  });

  group('per 100 g of a prepared meal', () {
    // 400 kcal, 8 g fat, 40 g carbs and 20 g protein in 4 portions.
    final meal = preparedMealTestData(totalPortions: 4, remainingPortions: 4);

    test('are unknown before the cooked meal was weighed', () {
      final nutrition = EatNutrition.ofPreparedMeal(meal, 0.25);

      expect(nutrition.per100, isNull);
      expect(nutrition.eaten.kcal, 100);
    });

    test('are unknown for a cooked weight of zero', () {
      final nutrition = EatNutrition.ofPreparedMeal(
        meal.copyWith(finalNetWeight: 0),
        0.25,
      );

      expect(nutrition.per100, isNull);
    });

    test('are the totals per 100 g of the cooked weight', () {
      final nutrition = EatNutrition.ofPreparedMeal(
        meal.copyWith(finalNetWeight: 800),
        0.25,
      );

      expect(nutrition.per100?.kcal, 50);
      expect(nutrition.per100?.fat, 1);
      expect(nutrition.per100?.carbs, 5);
      expect(nutrition.per100?.protein, 2.5);
      expect(nutrition.per100?.sugar, isNull);
      // The eaten portion stays as it is.
      expect(nutrition.eaten.kcal, 100);
      expect(nutrition.eaten.protein, 5);
    });

    test('do not change as portions are eaten', () {
      final nutrition = EatNutrition.ofPreparedMeal(
        meal.copyWith(finalNetWeight: 800, remainingPortions: 2),
        0.25,
      );

      expect(nutrition.per100?.kcal, 50);
    });

    test('follow a weighing of the pot', () {
      // Water evaporated: the 2 portions left (200 kcal) weigh 250 g, not
      // the 400 g that "Gekocht" would give.
      final nutrition = EatNutrition.ofPreparedMeal(
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
      final nutrition = EatNutrition.ofPreparedMeal(
        meal.copyWith(finalNetWeight: 800, remainingPortions: 0),
        0.25,
      );

      expect(nutrition.per100, isNull);
    });
  });
}
