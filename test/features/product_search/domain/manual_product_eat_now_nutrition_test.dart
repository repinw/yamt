import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/product_search/domain/'
    'manual_product_eat_now_nutrition.dart';

void main() {
  test('hasRequiredEatNowNutrition requires kcal and core macros', () {
    expect(hasRequiredEatNowNutrition(null), isFalse);
    expect(
      hasRequiredEatNowNutrition(
        const GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
          per100Kcal: 100,
          per100Protein: 10,
          per100Fat: 3,
        ),
      ),
      isFalse,
    );
    expect(
      hasRequiredEatNowNutrition(
        const GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
          per100Kcal: 100,
          per100Protein: 10,
          per100Fat: 3,
          per100Carbs: 20,
        ),
      ),
      isTrue,
    );
  });
}
