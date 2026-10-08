import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_product_lookup_models.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_calorie_bridge_flow.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';

InventoryItem _amountItemWithNutrition({
  String id = 'inventory-1',
  String? barcode = '4061458029995',
}) {
  return InventoryItem.create(
    id: id,
    globalFoodItemId: 'off-4061458029995',
    name: 'Waffelhörnchen Haselnuss-Vanille',
    brand: 'Mucci',
    barcode: barcode,
    imageUrl: 'https://example.com/waffel.png',
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 215,
      per100Protein: 4.2,
      per100Carbs: 24.8,
      per100Fat: 9.6,
    ),
    entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
    storeName: 'Aldi',
    quantity: 2,
    initialQuantity: 2,
    initialAmount: 1000,
    currentAmount: 750,
    amountUnit: InventoryAmountUnit.gram,
  );
}

InventoryItem _portionItemWithNutrition() {
  return InventoryItem.create(
    id: 'item-portion',
    name: 'Milk',
    brand: 'Brand',
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 42,
      per100Protein: 3.4,
      per100Carbs: 4.9,
      per100Fat: 1.5,
    ),
    entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
    storeName: 'Store',
    quantity: 1,
  );
}

InventoryItem _itemWithoutNutrition() {
  return InventoryItem.create(
    id: 'item-no-nutrition',
    name: 'Milk',
    brand: 'Brand',
    entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: 750,
    amountUnit: InventoryAmountUnit.gram,
  );
}

void main() {
  test('buildProfileFromInventoryItem maps nutrition and barcode fallback', () {
    final item = _amountItemWithNutrition(barcode: null);

    final profile = InventoryCalorieBridgeFlow.buildProfileFromInventoryItem(
      item,
    );

    expect(profile, isNotNull);
    expect(profile?.barcode, 'inventory-inventory-1');
    expect(profile?.name, 'Waffelhörnchen Haselnuss-Vanille');
    expect(profile?.brand, 'Mucci');
    expect(profile?.per100Kcal, 215);
    expect(profile?.source, CalorieProductSource.userOverride);
    expect(profile?.offProductId, 'off-4061458029995');
  });

  test('buildProfileFromInventoryItem returns null without nutrition', () {
    final profile = InventoryCalorieBridgeFlow.buildProfileFromInventoryItem(
      _itemWithoutNutrition(),
    );

    expect(profile, isNull);
  });

  test('buildScannedSourceRef uses barcode information when available', () {
    final item = _amountItemWithNutrition();
    final profile = InventoryCalorieBridgeFlow.buildProfileFromInventoryItem(
      item,
    )!;

    final sourceRef = InventoryCalorieBridgeFlow.buildScannedSourceRef(
      item: item,
      profile: profile,
    );

    expect(sourceRef, isNotNull);
    expect(sourceRef?.barcode, '4061458029995');
    expect(sourceRef?.source, CalorieProductSource.userOverride);
    expect(sourceRef?.offProductId, 'off-4061458029995');
  });

  test('buildScannedSourceRef returns null when the item has no barcode', () {
    final item = _amountItemWithNutrition(barcode: null);
    final profile = InventoryCalorieBridgeFlow.buildProfileFromInventoryItem(
      item,
    )!;

    final sourceRef = InventoryCalorieBridgeFlow.buildScannedSourceRef(
      item: item,
      profile: profile,
    );

    expect(sourceRef, isNull);
  });

  test('buildInventoryContext uses fixed amount unit from the item', () {
    final item = _amountItemWithNutrition();
    final request = InventoryItemEatRequest(
      inventoryAmount: 250,
      loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
      mealType: MealType.lunch,
    );

    final context = InventoryCalorieBridgeFlow.buildInventoryContext(
      item: item,
      request: request,
    );

    expect(context.inventoryItemId, 'inventory-1');
    expect(context.inventoryAmountToRestore, 250);
    expect(context.consumedAmount, 250);
    expect(context.consumedUnit, ConsumedUnit.grams);
  });

  test('buildInventoryContext restores the staged amount, not the wish', () {
    final context = InventoryCalorieBridgeFlow.buildInventoryContext(
      item: _amountItemWithNutrition(),
      request: InventoryItemEatRequest(
        inventoryAmount: 250,
        loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
        mealType: MealType.lunch,
      ),
      stagedAmount: 180,
    );

    expect(context.inventoryAmountToRestore, 180);
    expect(context.consumedAmount, 250);
  });

  test('buildInventoryContext prefers manual portion for fixed-unit items', () {
    final item = _amountItemWithNutrition();
    final request = InventoryItemEatRequest(
      inventoryAmount: 250,
      loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
      mealType: MealType.lunch,
      calorieAmount: 180,
      calorieUnit: ConsumedUnit.grams,
    );

    final context = InventoryCalorieBridgeFlow.buildInventoryContext(
      item: item,
      request: request,
    );

    expect(context.inventoryItemId, 'inventory-1');
    expect(context.inventoryAmountToRestore, 250);
    expect(context.consumedAmount, 180);
    expect(context.consumedUnit, ConsumedUnit.grams);
  });

  test(
    'buildInventoryContext uses manual portion for non fixed-unit items',
    () {
      final item = _portionItemWithNutrition();
      final request = InventoryItemEatRequest(
        inventoryAmount: 1,
        loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
        mealType: MealType.lunch,
        calorieAmount: 2.5,
        calorieUnit: ConsumedUnit.grams,
      );

      final context = InventoryCalorieBridgeFlow.buildInventoryContext(
        item: item,
        request: request,
      );

      expect(context.inventoryItemId, 'item-portion');
      expect(context.consumedAmount, 2.5);
      expect(context.consumedUnit, ConsumedUnit.grams);
    },
  );

  test('buildInventoryContext keeps portion learning metadata', () {
    final item = _amountItemWithNutrition();
    final request = InventoryItemEatRequest(
      inventoryAmount: 75,
      loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
      mealType: MealType.lunch,
      portionBaseAmount: 25,
      portionBaseUnit: ConsumedUnit.grams,
      portionCount: 3,
      portionLabel: 'Scheibe',
    );

    final context = InventoryCalorieBridgeFlow.buildInventoryContext(
      item: item,
      request: request,
    );

    expect(context.consumedAmount, 75);
    expect(context.portionBaseAmount, 25);
    expect(context.portionBaseUnit, ConsumedUnit.grams);
    expect(context.portionCount, 3);
    expect(context.portionLabel, 'Scheibe');
  });

  test('buildInventoryContext keeps exact fixed-unit portion amount', () {
    final item = _amountItemWithNutrition();
    final request = InventoryItemEatRequest(
      inventoryAmount: 38,
      loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
      mealType: MealType.lunch,
      calorieAmount: 37.5,
      calorieUnit: ConsumedUnit.grams,
      portionBaseAmount: 37.5,
      portionBaseUnit: ConsumedUnit.grams,
      portionCount: 1,
      portionLabel: 'Scheibe',
    );

    final context = InventoryCalorieBridgeFlow.buildInventoryContext(
      item: item,
      request: request,
    );

    expect(context.inventoryAmountToRestore, 38);
    expect(context.consumedAmount, 37.5);
    expect(context.consumedUnit, ConsumedUnit.grams);
    expect(context.portionBaseAmount, 37.5);
    expect(context.portionCount, 1);
  });

  test('buildInventoryContext throws without manual portion when required', () {
    final item = _portionItemWithNutrition();
    final request = InventoryItemEatRequest(
      inventoryAmount: 1,
      loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
      mealType: MealType.lunch,
    );

    expect(
      () => InventoryCalorieBridgeFlow.buildInventoryContext(
        item: item,
        request: request,
      ),
      throwsStateError,
    );
  });

  CalorieEntry buildEntry({
    double portionCount = 3,
    String? label = 'Scheibe',
  }) {
    final item = _amountItemWithNutrition();
    final request = InventoryItemEatRequest(
      inventoryAmount: 75,
      loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
      mealType: MealType.lunch,
      portionBaseAmount: 25,
      portionBaseUnit: ConsumedUnit.grams,
      portionCount: portionCount,
      portionLabel: label,
    );
    return InventoryCalorieBridgeFlow.buildCalorieEntry(
      id: 'entry-1',
      userId: 'user-1',
      profile: InventoryCalorieBridgeFlow.buildProfileFromInventoryItem(item)!,
      inventoryContext: InventoryCalorieBridgeFlow.buildInventoryContext(
        item: item,
        request: request,
      ),
      request: request,
      now: DateTime.parse('2026-04-06T12:30:00Z'),
    );
  }

  test('buildCalorieEntry keeps the counted named portion', () {
    final entry = buildEntry();

    expect(entry.portionAmount, 25);
    expect(entry.portionLabel, 'Scheibe');
    expect(CalorieEntry.fromJson(entry.toJson()).portionAmount, 25);
  });

  test('buildCalorieEntry drops a portion that does not match the amount', () {
    expect(buildEntry(portionCount: 2).portionAmount, isNull);
    expect(buildEntry(portionCount: 2).portionLabel, isNull);
    expect(buildEntry(label: ' ').portionAmount, isNull);
    expect(buildEntry(label: ' ').portionLabel, isNull);
  });
}
