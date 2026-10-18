import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_template_from_items.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

import '../../../support/prepared_meal_test_data.dart';

void main() {
  final rice = labeledFoodTestData(
    id: 'rice',
    name: 'Rice',
    grams: 500,
    label: riceLabelTestData,
  );
  final sauce = labeledFoodTestData(
    id: 'sauce',
    name: 'sauce',
    grams: 300,
    label: sauceLabelTestData,
  );

  test('offers foods with stock and a full label, by name', () {
    final apple = labeledFoodTestData(
      id: 'apple',
      name: 'Apple',
      grams: 200,
      label: const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
        per100Kcal: 52,
      ),
    );
    final empty = rice.copyWith(id: 'empty', currentAmount: 0);

    expect(
      inventoryTemplateCandidates([sauce, apple, empty, rice])
          .map((item) => item.id),
      ['rice', 'sauce'],
    );
  });

  test('builds one portion with all of the stock', () {
    final now = DateTime.utc(2026, 10, 18, 12);

    final meal = preparedMealTemplateFromItems(
      [rice, sauce],
      name: 'Rice bowl',
      now: now,
    )!;

    expect(meal.name, 'Rice bowl');
    expect(meal.totalPortions, 1);
    expect(meal.createdAt, now);
    expect(
      meal.components.map((food) => (food.inventoryItemId, food.usedAmount)),
      [('rice', 500), ('sauce', 300)],
    );
    // 500 g rice at 350 kcal and 300 g sauce at 50 kcal per 100 g.
    expect(meal.totalKcal, closeTo(1900, 0.5));
  });

  test('gives null when a food cannot be counted', () {
    expect(
      preparedMealTemplateFromItems(
        [rice.copyWith(currentAmount: 0)],
        name: 'Empty',
        now: DateTime.utc(2026, 10, 18),
      ),
      isNull,
    );
  });
}
