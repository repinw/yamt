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

  test('fromJson parses _100ml beverage nutrition fields', () {
    final nutrition = GlobalFoodNutrition.fromJson(const <String, dynamic>{
      'energy_kcal_100ml': 42.0,
      'proteins_100ml': 0.5,
      'carbohydrates_100ml': 10.6,
      'fat_100ml': 0.1,
      'salt_100ml': 0.02,
      'sugars_100ml': 10.6,
      'saturated_fat_100ml': 0.01,
      'polyunsaturated_fat_100ml': 0.01,
      'fiber_100ml': 0.2,
      'quality_status': 'verified',
    });

    expect(nutrition.per100Kcal, 42.0);
    expect(nutrition.per100Protein, 0.5);
    expect(nutrition.per100Carbs, 10.6);
    expect(nutrition.per100Fat, 0.1);
    expect(nutrition.per100Salt, 0.02);
    expect(nutrition.per100Sugar, 10.6);
    expect(nutrition.per100SaturatedFat, 0.01);
    expect(nutrition.per100PolyunsaturatedFat, 0.01);
    expect(nutrition.per100Fiber, 0.2);
    expect(nutrition.hasAnyNutritionValue, isTrue);
  });

  test(
    'fromJson converts kJ to kcal and sodium to salt when missing',
    () {
      final fromKj = GlobalFoodNutrition.fromJson(const <String, dynamic>{
        'energy_kj_100ml': 418.4,
        'sodium_100g': 0.4,
      });

      expect(fromKj.per100Kcal, closeTo(100.0, 0.01));
      expect(fromKj.per100Salt, closeTo(1.0, 0.01));
    },
  );
}
