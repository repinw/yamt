import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

void main() {
  test('PreparedMeal JSON roundtrip keeps nested component snapshot', () {
    final imageBase64 = base64Encode(<int>[1, 2, 3, 4]);
    final sourceItem = InventoryItem.create(
      id: 'item-1',
      name: 'Rice',
      entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
      storeName: 'Store',
      quantity: 1,
      initialQuantity: 1,
      initialAmount: 500,
      currentAmount: 350,
      amountUnit: InventoryAmountUnit.gram,
      nutrition: const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Kcal: 360,
        per100Protein: 7,
        per100Carbs: 79,
        per100Fat: 1,
      ),
    );
    final meal = PreparedMeal(
      id: 'meal-1',
      name: 'Rice bowl',
      imageBase64: imageBase64,
      totalPortions: 4,
      remainingPortions: 3,
      totalKcal: 720,
      totalProtein: 14,
      totalCarbs: 158,
      totalFat: 2,
      createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
      updatedAt: DateTime.parse('2026-03-27T12:05:00Z'),
      components: [
        PreparedMealComponent(
          inventoryItemId: sourceItem.id,
          name: sourceItem.name,
          brand: sourceItem.brand,
          imageUrl: sourceItem.imageUrl,
          usedAmount: 200,
          usedUnit: InventoryAmountUnit.gram,
          totalKcal: 720,
          totalProtein: 14,
          totalCarbs: 158,
          totalFat: 2,
          sourceItemSnapshot: sourceItem,
        ),
      ],
    );

    final roundtrip = PreparedMeal.fromJson(meal.toJson());

    expect(roundtrip, meal.copyWith(imageBase64: null));
    expect(roundtrip.imageBase64, isNull);
    expect(meal.imageBytes, hasLength(4));
    expect(roundtrip.components.single.sourceItemSnapshot, sourceItem);
  });
}
