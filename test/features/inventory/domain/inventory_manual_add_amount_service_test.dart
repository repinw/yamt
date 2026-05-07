import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_manual_add_amount_service.dart';

void main() {
  test('consumable amount guards invalid items', () {
    final stockedQuantityItem = InventoryItem.create(
      id: 'item-stocked',
      name: 'Yogurt',
      entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
      storeName: 'Added manually',
      quantity: 3,
    );
    final stockedAmountItem = InventoryItem.create(
      id: 'item-amount',
      name: 'Milk',
      entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
      storeName: 'Added manually',
      quantity: 1,
      initialAmount: 1000,
      currentAmount: 750,
      amountUnit: InventoryAmountUnit.milliliter,
    );
    final quantitylessItem = InventoryItem.create(
      id: 'item-0',
      name: 'Nothing',
      entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
      storeName: 'Added manually',
      quantity: 0,
    );
    final depletedAmountItem = InventoryItem.create(
      id: 'item-1',
      name: 'Milk',
      entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
      storeName: 'Added manually',
      quantity: 1,
      initialAmount: 1000,
      amountUnit: InventoryAmountUnit.milliliter,
    );

    expect(resolveInventoryManualAddConsumableAmount(stockedQuantityItem), 3);
    expect(resolveInventoryManualAddConsumableAmount(stockedAmountItem), 750);
    expect(resolveInventoryManualAddConsumableAmount(quantitylessItem), isNull);
    expect(
      resolveInventoryManualAddConsumableAmount(depletedAmountItem),
      isNull,
    );
  });

  test('prompt requirement depends on resolved amount data', () {
    final amountItem = _amountItem(
      weight: '300 ml',
      amountUnit: InventoryAmountUnit.milliliter,
      initialAmount: 300,
      currentAmount: 300,
    );

    expect(requiresInventoryManualAddConsumedAmountPrompt(amountItem), isFalse);
    expect(
      requiresInventoryManualAddConsumedAmountPrompt(_plainItem()),
      isTrue,
    );
  });

  test('resolves prompted consumed amount on item', () {
    final item = _plainItem();

    final resolved = resolveInventoryManualAddItemAmount(
      item: item,
      amount: 300,
      unit: InventoryAmountUnit.milliliter,
    );

    expect(resolved.weight, '300 ml');
    expect(resolved.initialAmount, 300);
    expect(resolved.currentAmount, 300);
    expect(resolved.amountUnit, InventoryAmountUnit.milliliter);
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

  test('default eat unit uses serving hints when amount unit is missing', () {
    final milk = _plainItem(
      servingSize: '250 ml',
      servingQuantityUnit: 'ml',
    );
    final eggs = _plainItem(servingSize: '1 pc');

    expect(
      defaultInventoryManualAddConsumedAmountUnit(milk),
      InventoryAmountUnit.milliliter,
    );
    expect(
      defaultInventoryManualAddConsumedAmountUnit(eggs),
      InventoryAmountUnit.piece,
    );
    expect(
      defaultInventoryManualAddConsumedAmountUnit(_plainItem()),
      InventoryAmountUnit.gram,
    );
  });

  test('initial eat amount parses package weight only for matching unit', () {
    final milk = _amountItem(
      weight: '1 l',
      amountUnit: InventoryAmountUnit.milliliter,
      initialAmount: 1000,
      currentAmount: 1000,
    );
    final gramsItem = _amountItem(
      weight: '1 l',
      amountUnit: InventoryAmountUnit.gram,
      initialAmount: 1000,
      currentAmount: 1000,
    );

    expect(
      resolveInventoryManualAddInitialConsumedAmount(
        item: milk,
        rawWeight: '1 l',
      ),
      1000,
    );
    expect(
      resolveInventoryManualAddInitialConsumedAmount(
        item: gramsItem,
        rawWeight: '1 l',
      ),
      isNull,
    );
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

InventoryItem _plainItem({
  String? servingSize,
  String? servingQuantityUnit,
}) {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Food',
    entryDate: DateTime.parse('2026-04-13T10:00:00Z'),
    storeName: 'Added manually',
    quantity: 1,
    servingSize: servingSize,
    servingQuantityUnit: servingQuantityUnit,
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
