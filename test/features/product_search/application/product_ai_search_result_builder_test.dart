import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/application/'
    'product_ai_search_result_builder.dart';
import 'package:yamt/features/product_search/domain/product_ai_search_models.dart';

void main() {
  test('builds selected nutrition within AI kcal density range', () {
    final selection = buildProductAiNutritionSelection(
      draft: _draft(),
      weightGrams: 250,
      selectedPer100Kcal: 9999,
    );

    expect(selection.weightLabel, '250 g');
    expect(selection.per100Kcal, selection.maxPer100Kcal);
    expect(selection.per100Nutrition.per100Kcal, selection.maxPer100Kcal);
    expect(selection.portionNutrition.kcal, 600);
  });

  test('builds result item with resolved gram amount and AI nutrition', () {
    final baseItem = _item();
    final selection = buildProductAiNutritionSelection(
      draft: _draft(),
      weightGrams: 250,
      selectedPer100Kcal: 180,
    );

    final item = buildProductAiResultItem(
      baseItem: baseItem,
      selection: selection,
    );

    expect(item.name, 'Rice bowl');
    expect(item.brand, 'Kitchen');
    expect(item.barcode, isEmpty);
    expect(item.weight, '250 g');
    expect(item.initialAmount, 250);
    expect(item.currentAmount, 250);
    expect(item.amountUnit, InventoryAmountUnit.gram);
    expect(item.nutrition, same(selection.per100Nutrition));
  });

  test('builds eat selection only for eat-now action', () {
    final loggedAt = DateTime(2026, 5, 15, 12, 30);
    final selection = buildProductAiNutritionSelection(
      draft: _draft(),
      weightGrams: 250,
      selectedPer100Kcal: 180,
    );

    final eatSelection = buildProductAiEatSelection(
      eatNow: true,
      selection: selection,
      loggedAt: loggedAt,
      mealType: MealType.lunch,
    );

    expect(eatSelection?.inventoryAmount, 250);
    expect(eatSelection?.loggedAt, loggedAt);
    expect(eatSelection?.mealType, MealType.lunch);
    expect(
      buildProductAiEatSelection(
        eatNow: false,
        selection: selection,
        loggedAt: loggedAt,
        mealType: MealType.lunch,
      ),
      isNull,
    );
  });
}

ProductAiSearchDraft _draft() {
  return const ProductAiSearchDraft(
    name: 'Rice bowl',
    brand: 'Kitchen',
    ingredients: <ProductAiSearchIngredientRow>[
      ProductAiSearchIngredientRow(
        label: 'Rice',
        amountText: '200 g',
        amountGrams: 200,
        kcalMin: 250,
        kcalMax: 320,
        protein: 6,
        carbs: 70,
        fat: 1,
      ),
    ],
    totalWeightGrams: 250,
    totalKcalMin: 400,
    totalKcalMax: 600,
    defaultKcal: 500,
    portionNutrition: ProductAiSearchNutritionEstimate(
      kcal: 500,
      protein: 20,
      carbs: 60,
      fat: 15,
      salt: 1.2,
    ),
  );
}

InventoryItem _item() {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Draft',
    entryDate: DateTime(2026, 5, 15),
    storeName: 'Manual',
    quantity: 1,
    origin: InventoryItemOrigin.manualAdd,
  );
}
