import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

void main() {
  test('fromJson maps partial quality status to unverified', () {
    final nutrition = GlobalFoodNutrition.fromJson(const <String, dynamic>{
      'quality_status': 'partial',
      'energy_kcal_100g': 70.0,
    });

    expect(
      nutrition.qualityStatus,
      GlobalFoodNutritionQualityStatus.unverified,
    );
    expect(nutrition.per100Kcal, 70);
  });

  test('hasEuMandatoryNutritionDeclaration checks all mandatory fields', () {
    const complete = GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 70,
      per100Fat: 1,
      per100SaturatedFat: 0.2,
      per100Carbs: 12,
      per100Sugar: 8,
      per100Protein: 3,
      per100Salt: 0.1,
    );
    const incomplete = GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 70,
      per100Fat: 1,
      per100Carbs: 12,
      per100Protein: 3,
    );

    expect(complete.hasEuMandatoryNutritionDeclaration, isTrue);
    expect(incomplete.hasEuMandatoryNutritionDeclaration, isFalse);
  });
}
