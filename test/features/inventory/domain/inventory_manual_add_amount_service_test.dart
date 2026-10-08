import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_manual_add_amount_service.dart';

void main() {
  test('the rest of a package is what eating leaves, if any', () {
    final milk = _amountItem(
      globalFoodItemId: 'off-milk',
      weight: '1 l',
      amountUnit: InventoryAmountUnit.milliliter,
      initialAmount: 1000,
      currentAmount: 1000,
    );

    expect(inventoryManualAddRestAmount(item: milk, inventoryAmount: 300), 700);
    expect(
      inventoryManualAddRestAmount(item: milk, inventoryAmount: 1000),
      isNull,
    );
    expect(
      inventoryManualAddRestAmount(item: milk, inventoryAmount: 1200),
      isNull,
    );
    expect(
      inventoryManualAddRestAmount(item: milk, inventoryAmount: 0),
      isNull,
    );
  });

  test('resize immediate amount keeps identity and shrinks stock', () {
    final item = _amountItem(
      globalFoodItemId: 'off-milk',
      weight: '1 l',
      amountUnit: InventoryAmountUnit.milliliter,
      initialAmount: 1000,
      currentAmount: 1000,
    );
    final resized = resizeInventoryManualAddItemToConsumedAmount(
      item: item,
      inventoryAmount: 300,
    );

    expect(resized.globalFoodItemId, 'off-milk');
    expect(resized.weight, '300 ml');
    expect(resized.initialAmount, 300);
    expect(resized.currentAmount, 300);
    expect(resized.amountUnit, InventoryAmountUnit.milliliter);
  });

  test('resize immediate quantity item updates initial quantity', () {
    final item = InventoryItem.create(
      id: 'item-1',
      name: 'Eggs',
      entryDate: DateTime.parse('2026-04-13T10:00:00Z'),
      storeName: 'Added manually',
      quantity: 12,
      initialQuantity: 12,
      nutrition: _nutrition,
    );
    final resized = resizeInventoryManualAddItemToConsumedAmount(
      item: item,
      inventoryAmount: 2,
    );

    expect(resized.quantity, 2);
    expect(resized.initialQuantity, 2);
  });

  test(
    'resize immediate quantity item returns unchanged when already sized',
    () {
      final item = InventoryItem.create(
        id: 'item-1',
        name: 'Eggs',
        entryDate: DateTime.parse('2026-04-13T10:00:00Z'),
        storeName: 'Added manually',
        quantity: 2,
        initialQuantity: 2,
        nutrition: _nutrition,
      );
      final resized = resizeInventoryManualAddItemToConsumedAmount(
        item: item,
        inventoryAmount: 2,
      );

      expect(resized, item);
    },
  );

  test('resize immediate piece item preserves fractional scale', () {
    final item = _amountItem(
      weight: '1.5 pc',
      amountUnit: InventoryAmountUnit.piece,
      amountScale: inventoryPieceAmountScale,
      initialAmount: 1500,
      currentAmount: 1500,
    );
    final resized = resizeInventoryManualAddItemToConsumedAmount(
      item: item,
      inventoryAmount: 750,
    );

    expect(resized.weight, '0.75 pc');
    expect(resized.amountScale, inventoryPieceAmountScale);
    expect(resized.initialAmount, 750);
    expect(resized.currentAmount, 750);
  });

  test('safe amount scale falls back by unit', () {
    expect(
      safeInventoryManualAddAmountScale(
        unit: InventoryAmountUnit.gram,
        scale: 0,
      ),
      1,
    );
    expect(
      safeInventoryManualAddAmountScale(
        unit: InventoryAmountUnit.piece,
        scale: 0,
      ),
      inventoryPieceAmountScale,
    );
  });
}

InventoryItem _amountItem({
  required String weight,
  required InventoryAmountUnit amountUnit,
  required int initialAmount,
  required int currentAmount,
  String globalFoodItemId = 'off-item',
  int amountScale = 1,
}) {
  return InventoryItem.create(
    id: 'item-1',
    globalFoodItemId: globalFoodItemId,
    name: 'Milk',
    entryDate: DateTime.parse('2026-04-13T10:00:00Z'),
    storeName: 'Added manually',
    quantity: 1,
    weight: weight,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountScale: amountScale,
    amountUnit: amountUnit,
    nutrition: _nutrition,
  );
}

const _nutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 42,
  per100Protein: 3.4,
  per100Carbs: 4.9,
  per100Fat: 1.5,
);
