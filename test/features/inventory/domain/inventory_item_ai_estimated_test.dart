import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_stock_changes.dart';

const _aiEstimate = SavedFoodEstimate(
  estimate: FoodEstimate(
    name: 'Eier mit Speck',
    portionGrams: 250,
    kcalLean: 400,
    kcalRich: 600,
    per100: GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
      per100Kcal: 200,
      per100Fat: 15,
    ),
    ingredients: [
      FoodEstimateIngredient(name: 'Eier', grams: 150, kcal: 220),
      FoodEstimateIngredient(name: 'Speck', grams: 100, kcal: 280),
    ],
  ),
  level: FoodEstimateLevel.rich,
  description: 'Rührei mit Speck',
);

InventoryItem _item({bool aiEstimated = false}) => InventoryItem.create(
  id: 'item-1',
  name: 'Eier mit Speck',
  entryDate: DateTime.parse('2026-10-13T10:00:00Z'),
  storeName: 'Manual',
  quantity: 1,
  aiEstimated: aiEstimated,
);

void main() {
  test('the AI mark survives the stored form and copies (#701)', () {
    final item = _item(aiEstimated: true);

    final stored = InventoryItem.fromJson(item.toJson());

    expect(stored.aiEstimated, isTrue);
    expect(stored, item);
    expect(stored.copyWith(name: 'Eier').aiEstimated, isTrue);
  });

  test('a stored item without the mark is no AI estimate', () {
    final json = _item().toJson()..remove('ai_estimated');

    expect(InventoryItem.fromJson(json).aiEstimated, isFalse);
  });

  test('the AI estimate survives the stored form and copies (#763)', () {
    final item = _item(aiEstimated: true);
    final withEstimate = item.copyWith(
      productSnapshot: item.productSnapshot.copyWith(aiEstimate: _aiEstimate),
    );

    final stored = InventoryItem.fromJson(
      jsonDecode(jsonEncode(withEstimate.toJson())) as Map<String, dynamic>,
    );

    expect(stored, withEstimate);
    expect(
      stored.copyWith(name: 'Eier').productSnapshot.aiEstimate,
      _aiEstimate,
    );
    expect(
      InventoryItem.fromJson(item.toJson()).productSnapshot.aiEstimate,
      isNull,
    );
  });

  test('a swap to another food drops the estimate (#763)', () {
    final item = _item(aiEstimated: true);
    final swapped = buildSwappedItem(
      sourceItem: item.copyWith(
        productSnapshot: item.productSnapshot.copyWith(aiEstimate: _aiEstimate),
      ),
      resolvedProduct: GlobalFoodItem.create(
        id: 'off-skyr',
        name: 'Skyr',
        now: DateTime.parse('2026-10-13T10:00:00Z'),
      ),
      weight: null,
      canReferenceGlobalItem: true,
    );

    expect(swapped.productSnapshot.aiEstimate, isNull);
  });

  test('a swap to a new AI food keeps its estimate (#763)', () {
    const newEstimate = SavedFoodEstimate(
      estimate: FoodEstimate(
        name: 'Porridge',
        portionGrams: 300,
        kcalLean: 280,
        kcalRich: 420,
        per100: GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
          per100Kcal: 110,
        ),
        ingredients: [],
      ),
      level: FoodEstimateLevel.normal,
      description: 'Haferbrei',
    );
    final item = _item(aiEstimated: true);
    InventoryItem swapTo({required bool aiEstimated}) => buildSwappedItem(
      sourceItem: item.copyWith(
        productSnapshot: item.productSnapshot.copyWith(aiEstimate: _aiEstimate),
      ),
      resolvedProduct: GlobalFoodItem.create(
        id: 'global-food-porridge',
        name: 'Porridge',
        now: DateTime.parse('2026-10-13T10:00:00Z'),
      ),
      weight: null,
      canReferenceGlobalItem: false,
      aiEstimated: aiEstimated,
      aiEstimate: newEstimate,
    );

    expect(swapTo(aiEstimated: true).productSnapshot.aiEstimate, newEstimate);
    expect(swapTo(aiEstimated: false).productSnapshot.aiEstimate, isNull);
  });
}
