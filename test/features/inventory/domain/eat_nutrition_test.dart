import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/eat_nutrition.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

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
}
