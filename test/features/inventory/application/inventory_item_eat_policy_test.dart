import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';

InventoryItem _inventoryItem({
  required String id,
  required String name,
  required int quantity,
  int initialAmount = 0,
  int currentAmount = 0,
  InventoryAmountUnit? amountUnit,
  GlobalFoodNutrition? nutrition,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-04-06T08:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: quantity,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountUnit: amountUnit,
    nutrition: nutrition,
  );
}

InventoryItemEatRequest _eatRequest({
  int inventoryAmount = 100,
  double? calorieAmount,
  ConsumedUnit? calorieUnit,
}) {
  return InventoryItemEatRequest(
    inventoryAmount: inventoryAmount,
    loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
    mealType: MealType.lunch,
    calorieAmount: calorieAmount,
    calorieUnit: calorieUnit,
  );
}

const _nutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 215,
  per100Protein: 4.2,
  per100Carbs: 24.8,
  per100Fat: 9.6,
);

void main() {
  group('InventoryItemEatRequest', () {
    test('tracks manual calorie portions and portion learning metadata', () {
      final plainRequest = _eatRequest();
      final portionRequest = InventoryItemEatRequest(
        inventoryAmount: 1,
        loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
        mealType: MealType.lunch,
        calorieAmount: 250,
        calorieUnit: ConsumedUnit.grams,
        portionBaseAmount: 125,
        portionBaseUnit: ConsumedUnit.grams,
        portionCount: 2,
        portionLabel: '2 servings',
      );

      expect(plainRequest.hasManualCaloriePortion, isFalse);
      expect(plainRequest.hasPortionLearning, isFalse);
      expect(portionRequest.hasManualCaloriePortion, isTrue);
      expect(portionRequest.hasPortionLearning, isTrue);
      expect(portionRequest.portionLabel, '2 servings');
    });

    test('requires calorie amount and unit to be provided together', () {
      expect(
        () => InventoryItemEatRequest(
          inventoryAmount: 1,
          loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
          mealType: MealType.lunch,
          calorieAmount: 250,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('requires complete portion learning metadata', () {
      expect(
        () => InventoryItemEatRequest(
          inventoryAmount: 1,
          loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
          mealType: MealType.lunch,
          portionBaseAmount: 125,
          portionBaseUnit: ConsumedUnit.grams,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  test('recognizes gram and milliliter items as fixed calorie units', () {
    final gramItem = _inventoryItem(
      id: 'gram-item',
      name: 'Yogurt',
      quantity: 1,
      initialAmount: 500,
      currentAmount: 500,
      amountUnit: InventoryAmountUnit.gram,
    );
    final milliliterItem = _inventoryItem(
      id: 'ml-item',
      name: 'Milk',
      quantity: 1,
      initialAmount: 1000,
      currentAmount: 1000,
      amountUnit: InventoryAmountUnit.milliliter,
    );
    final quantityOnlyItem = _inventoryItem(
      id: 'piece-item',
      name: 'Apple',
      quantity: 3,
    );
    final missingAmountProgressItem = _inventoryItem(
      id: 'missing-progress',
      name: 'Water',
      quantity: 1,
      amountUnit: InventoryAmountUnit.gram,
    );

    expect(inventoryItemUsesFixedCalorieUnit(gramItem), isTrue);
    expect(inventoryItemUsesFixedCalorieUnit(milliliterItem), isTrue);
    expect(inventoryItemUsesFixedCalorieUnit(quantityOnlyItem), isFalse);
    expect(
      inventoryItemUsesFixedCalorieUnit(missingAmountProgressItem),
      isFalse,
    );
  });

  test('flags manual calorie portions only for non fixed-unit items', () {
    final gramItem = _inventoryItem(
      id: 'gram-item',
      name: 'Yogurt',
      quantity: 1,
      initialAmount: 500,
      currentAmount: 500,
      amountUnit: InventoryAmountUnit.gram,
    );
    final quantityOnlyItem = _inventoryItem(
      id: 'piece-item',
      name: 'Apple',
      quantity: 3,
    );

    expect(inventoryItemRequiresManualCaloriePortion(gramItem), isFalse);
    expect(inventoryItemRequiresManualCaloriePortion(quantityOnlyItem), isTrue);
  });

  test('maps inventory amount units to consumed units', () {
    final gramItem = _inventoryItem(
      id: 'gram-item',
      name: 'Yogurt',
      quantity: 1,
      initialAmount: 500,
      currentAmount: 500,
      amountUnit: InventoryAmountUnit.gram,
    );
    final milliliterItem = _inventoryItem(
      id: 'ml-item',
      name: 'Milk',
      quantity: 1,
      initialAmount: 1000,
      currentAmount: 1000,
      amountUnit: InventoryAmountUnit.milliliter,
    );
    final quantityOnlyItem = _inventoryItem(
      id: 'piece-item',
      name: 'Apple',
      quantity: 3,
    );

    expect(inventoryItemConsumedUnit(gramItem), ConsumedUnit.grams);
    expect(inventoryItemConsumedUnit(milliliterItem), ConsumedUnit.milliliters);
    expect(inventoryItemConsumedUnit(quantityOnlyItem), isNull);
  });

  test('allows direct save for fixed units and manual piece portions', () {
    final gramItem = _inventoryItem(
      id: 'gram-item',
      name: 'Yogurt',
      quantity: 1,
      initialAmount: 500,
      currentAmount: 500,
      amountUnit: InventoryAmountUnit.gram,
      nutrition: _nutrition,
    );
    final noNutritionItem = _inventoryItem(
      id: 'no-nutrition',
      name: 'Yogurt',
      quantity: 1,
      initialAmount: 500,
      currentAmount: 500,
      amountUnit: InventoryAmountUnit.gram,
    );
    final quantityOnlyItem = _inventoryItem(
      id: 'piece-item',
      name: 'Apple',
      quantity: 3,
      nutrition: _nutrition,
    );

    expect(
      canDirectlySaveInventoryItemEatRequest(gramItem, _eatRequest()),
      isTrue,
    );
    expect(
      canDirectlySaveInventoryItemEatRequest(noNutritionItem, _eatRequest()),
      isFalse,
    );
    expect(
      canDirectlySaveInventoryItemEatRequest(
        quantityOnlyItem,
        _eatRequest(calorieAmount: 1.5, calorieUnit: ConsumedUnit.grams),
      ),
      isTrue,
    );
    expect(
      canDirectlySaveInventoryItemEatRequest(quantityOnlyItem, _eatRequest()),
      isFalse,
    );
  });

  test('fixed-unit manual calorie portion can still be saved directly', () {
    final gramItem = _inventoryItem(
      id: 'gram-item',
      name: 'Yogurt',
      quantity: 1,
      initialAmount: 500,
      currentAmount: 500,
      amountUnit: InventoryAmountUnit.gram,
      nutrition: _nutrition,
    );

    final request = _eatRequest(
      inventoryAmount: 120,
      calorieAmount: 95,
      calorieUnit: ConsumedUnit.grams,
    );

    expect(canDirectlySaveInventoryItemEatRequest(gramItem, request), isTrue);
  });
}
