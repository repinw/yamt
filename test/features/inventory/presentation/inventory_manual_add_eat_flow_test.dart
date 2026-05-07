import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/eat_selection.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';

void main() {
  test('resize immediate amount keeps identity and shrinks stock', () {
    final item = _amountItem(
      globalFoodItemId: 'off-milk',
      weight: '1 l',
      amountUnit: InventoryAmountUnit.milliliter,
      initialAmount: 1000,
      currentAmount: 1000,
    );
    final request = _request(inventoryAmount: 300);

    final resized = resizeInventoryManualAddItemToImmediateEatAmount(
      item: item,
      request: request,
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
    final request = _request(inventoryAmount: 2);

    final resized = resizeInventoryManualAddItemToImmediateEatAmount(
      item: item,
      request: request,
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
      final request = _request(inventoryAmount: 2);

      final resized = resizeInventoryManualAddItemToImmediateEatAmount(
        item: item,
        request: request,
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
    final request = _request(inventoryAmount: 750);

    final resized = resizeInventoryManualAddItemToImmediateEatAmount(
      item: item,
      request: request,
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
      defaultInventoryManualAddEatAmountUnit(milk),
      InventoryAmountUnit.milliliter,
    );
    expect(
      defaultInventoryManualAddEatAmountUnit(eggs),
      InventoryAmountUnit.piece,
    );
    expect(
      defaultInventoryManualAddEatAmountUnit(_plainItem()),
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
      resolveInventoryManualAddInitialEatAmount(
        item: milk,
        rawWeight: '1 l',
      ),
      1000,
    );
    expect(
      resolveInventoryManualAddInitialEatAmount(
        item: gramsItem,
        rawWeight: '1 l',
      ),
      isNull,
    );
  });

  test('eat request can be built from generic selection', () {
    final loggedAt = DateTime.parse('2026-04-13T20:00:00Z');
    final request = inventoryManualAddEatRequestFromSelection(
      EatSelection(
        inventoryAmount: 380,
        loggedAt: loggedAt,
        mealType: MealType.dinner,
      ),
    );

    expect(request?.inventoryAmount, 380);
    expect(request?.loggedAt, loggedAt);
    expect(request?.mealType, MealType.dinner);
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

InventoryItemEatRequest _request({required int inventoryAmount}) {
  return InventoryItemEatRequest(
    inventoryAmount: inventoryAmount,
    loggedAt: DateTime.parse('2026-04-13T20:00:00Z'),
    mealType: MealType.dinner,
  );
}

const _nutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 42,
  per100Protein: 3.4,
  per100Carbs: 4.9,
  per100Fat: 1.5,
);
