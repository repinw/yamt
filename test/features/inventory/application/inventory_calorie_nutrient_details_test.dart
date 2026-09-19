import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/inventory_calorie_nutrient_details.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

void main() {
  test('maps label nutrients beyond the macros', () {
    final details = calorieNutrientDetailsFrom(
      const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Kcal: 68,
        per100SaturatedFat: 0.1,
        per100Sugar: 4.1,
        per100Salt: 0.1,
      ),
    );

    expect(details?.per100SaturatedFat, 0.1);
    expect(details?.per100Sugar, 4.1);
    expect(details?.per100Salt, 0.1);
    expect(details?.per100Fiber, isNull);
  });

  test('returns null without extra nutrients', () {
    expect(calorieNutrientDetailsFrom(null), isNull);
    expect(
      calorieNutrientDetailsFrom(
        const GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
          per100Kcal: 68,
          per100Protein: 12,
        ),
      ),
      isNull,
    );
  });
}
