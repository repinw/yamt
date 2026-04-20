import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/product_search/domain/'
    'product_ai_search_models.dart';

void main() {
  test('toPer100Nutrition scales and rounds portion values', () {
    const estimate = ProductAiSearchNutritionEstimate(
      kcal: 820,
      protein: 40,
      carbs: 72,
      fat: 40,
      salt: 1.5,
    );

    final per100Nutrition = estimate.toPer100Nutrition(
      grams: 400,
      qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
    );

    expect(per100Nutrition.per100Kcal, 205);
    expect(per100Nutrition.per100Protein, 10);
    expect(per100Nutrition.per100Carbs, 18);
    expect(per100Nutrition.per100Fat, 10);
    expect(per100Nutrition.per100Salt, 0.38);
  });

  test('nutritionForKcal clamps into draft kcal range', () {
    const draft = ProductAiSearchDraft(
      name: 'Pelmeni',
      ingredients: <ProductAiSearchIngredientRow>[],
      totalWeightGrams: 300,
      totalKcalMin: 600,
      totalKcalMax: 900,
      defaultKcal: 750,
      portionNutrition: ProductAiSearchNutritionEstimate(
        kcal: 750,
        protein: 30,
        carbs: 60,
        fat: 30,
      ),
    );

    final low = draft.nutritionForKcal(100);
    final high = draft.nutritionForKcal(1200);

    expect(low.kcal, 600);
    expect(low.protein, 24);
    expect(high.kcal, 900);
    expect(high.protein, 36);
  });
}
