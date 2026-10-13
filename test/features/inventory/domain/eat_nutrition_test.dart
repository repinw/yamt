import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/eat_nutrition.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

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
}
