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
}
