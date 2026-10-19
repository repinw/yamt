import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

const _estimate = FoodEstimate(
  name: 'Döner Kebab',
  portionGrams: 400,
  kcalLean: 720,
  kcalRich: 960,
  per100: GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
    per100Kcal: 200,
    per100Fat: 10,
    per100Protein: 10,
  ),
  ingredients: [
    FoodEstimateIngredient(name: 'Fladenbrot', grams: 150, kcal: 400),
    FoodEstimateIngredient(name: 'Fleisch', grams: 250, kcal: 400),
  ],
);

void main() {
  test('portion energy follows the level', () {
    expect(_estimate.portionKcal(FoodEstimateLevel.lean), 720);
    expect(_estimate.portionKcal(FoodEstimateLevel.normal), 800);
    expect(_estimate.portionKcal(FoodEstimateLevel.rich), 960);
  });

  test('a rich preparation scales every value with the energy', () {
    final rich = _estimate.per100At(FoodEstimateLevel.rich);

    expect(rich.per100Kcal, closeTo(240, 0.001));
    expect(rich.per100Fat, closeTo(12, 0.001));
    expect(rich.per100Protein, closeTo(12, 0.001));
    expect(rich.per100Salt, isNull);
    expect(_estimate.per100At(FoodEstimateLevel.normal), _estimate.per100);
  });

  test('ingredients keep their weight and scale their energy', () {
    final lean = _estimate.ingredientsAt(FoodEstimateLevel.lean, grams: 400);

    expect(lean.map((i) => i.grams), [150, 250]);
    expect(lean.map((i) => i.kcal), [360, 360]);
  });

  test('ingredients follow the eaten amount', () {
    final half = _estimate.ingredientsAt(FoodEstimateLevel.normal, grams: 200);

    expect(half.map((i) => i.grams), [75, 125]);
    expect(half.map((i) => i.kcal), [200, 200]);
  });
}
