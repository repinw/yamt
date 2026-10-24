import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/domain/food_estimate_item.dart';

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
  test('the item holds the amount, the estimated portion and the estimate', () {
    final item = buildFoodEstimateItem(
      baseItem: InventoryItem.create(
        id: 'item-1',
        name: 'Placeholder',
        brand: 'Old brand',
        entryDate: DateTime.parse('2026-04-20T12:00:00Z'),
        storeName: 'Rewe',
        quantity: 1,
      ),
      estimate: _estimate,
      level: FoodEstimateLevel.rich,
      grams: 250,
      description: 'Döner mit allem',
    );

    expect(item.name, 'Döner Kebab');
    expect(item.brand, isNull);
    expect(item.weight, '250 g');
    expect(item.servingSize, '400 g');
    expect(item.servingQuantity, 400);
    expect(item.nutrition?.per100Kcal, closeTo(240, 0.001));
    // The mark keeps the meal out of the shared catalog (#701).
    expect(item.aiEstimated, isTrue);
    expect(
      item.productSnapshot.aiEstimate,
      const SavedFoodEstimate(
        estimate: _estimate,
        level: FoodEstimateLevel.rich,
        description: 'Döner mit allem',
      ),
    );
  });
}
