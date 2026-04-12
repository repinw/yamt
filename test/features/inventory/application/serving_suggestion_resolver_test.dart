import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/serving_suggestion_resolver.dart';
import 'package:yamt/features/inventory/domain/global_food_serving_suggestion.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

InventoryItem _amountItem({
  InventoryAmountUnit unit = InventoryAmountUnit.gram,
  int initialAmount = 1000,
  int currentAmount = 1000,
  String? servingSize,
  double? servingQuantity,
  String? servingQuantityUnit,
  String? weight,
}) {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Cheese',
    entryDate: DateTime.parse('2026-04-10T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountUnit: unit,
    servingSize: servingSize,
    servingQuantity: servingQuantity,
    servingQuantityUnit: servingQuantityUnit,
    weight: weight,
  );
}

GlobalFoodServingSuggestion _globalSuggestion({
  required String id,
  required double amount,
  required ConsumedUnit unit,
  int selectionCount = 1,
  int uniqueUserCount = 1,
}) {
  return GlobalFoodServingSuggestion(
    id: id,
    itemKey: 'global_off-cheese',
    globalFoodItemId: 'off-cheese',
    amount: amount,
    unit: unit,
    selectionCount: selectionCount,
    uniqueUserCount: uniqueUserCount,
    createdAt: DateTime.parse('2026-04-10T10:00:00Z'),
    updatedAt: DateTime.parse('2026-04-10T10:00:00Z'),
  );
}

void main() {
  const resolver = ServingSuggestionResolver();

  test('resolves personal default and orders inventory suggestions', () {
    final item = _amountItem(
      servingSize: '50 g',
      servingQuantity: 50,
      servingQuantityUnit: 'g',
    );
    final learned = GlobalFoodServingSuggestionSet(
      personalSuggestion: const ServingSizeSuggestion(
        amount: 35,
        unit: ConsumedUnit.grams,
      ),
      globalSuggestions: <GlobalFoodServingSuggestion>[
        GlobalFoodServingSuggestion(
          id: 'global_off-cheese_g_34000',
          itemKey: 'global_off-cheese',
          globalFoodItemId: 'off-cheese',
          amount: 34,
          unit: ConsumedUnit.grams,
          selectionCount: 2,
          uniqueUserCount: 2,
          createdAt: DateTime(2026, 4, 10, 10),
          updatedAt: DateTime(2026, 4, 10, 10),
        ),
      ],
    );

    final resolution = resolver.resolve(
      item: item,
      learned: learned,
      maxAmount: 1000,
      requiresManualPortion: false,
    );

    expect(resolution.inventoryDefaultAmount, 35);
    expect(
      resolution.inventoryServingOptions.map((option) => option.value),
      <int>[35, 34, 50],
    );
    expect(resolution.manualServingSuggestions, isEmpty);
  });

  test('dedupes manual suggestions across sources', () {
    final item = _amountItem(
      servingSize: '35 g',
      servingQuantity: 35,
      servingQuantityUnit: 'g',
    );
    final learned = GlobalFoodServingSuggestionSet(
      personalSuggestion: const ServingSizeSuggestion(
        amount: 35,
        unit: ConsumedUnit.grams,
      ),
      globalSuggestions: <GlobalFoodServingSuggestion>[
        _globalSuggestion(
          id: 'global_off-cheese_g_35000',
          amount: 35,
          unit: ConsumedUnit.grams,
        ),
      ],
    );

    final resolution = resolver.resolve(
      item: item,
      learned: learned,
      maxAmount: 1000,
      requiresManualPortion: true,
    );

    expect(resolution.manualServingSuggestions, hasLength(1));
    expect(resolution.manualServingSuggestions.single.amount, 35);
  });

  test('converts kg, cl, mg units to base units', () {
    final kgItem = _amountItem(
      servingQuantity: 0.25,
      servingQuantityUnit: 'kg',
    );
    final clItem = _amountItem(
      servingQuantity: 12.5,
      servingQuantityUnit: 'cl',
    );
    final mgItem = _amountItem(servingQuantity: 500, servingQuantityUnit: 'mg');
    const learned = GlobalFoodServingSuggestionSet.empty();

    final kgResolution = resolver.resolve(
      item: kgItem,
      learned: learned,
      maxAmount: 1000,
      requiresManualPortion: true,
    );
    final clResolution = resolver.resolve(
      item: clItem,
      learned: learned,
      maxAmount: 1000,
      requiresManualPortion: true,
    );
    final mgResolution = resolver.resolve(
      item: mgItem,
      learned: learned,
      maxAmount: 1000,
      requiresManualPortion: true,
    );

    expect(kgResolution.manualServingSuggestions.single.amount, 250);
    expect(
      kgResolution.manualServingSuggestions.single.unit,
      ConsumedUnit.grams,
    );
    expect(clResolution.manualServingSuggestions.single.amount, 125);
    expect(
      clResolution.manualServingSuggestions.single.unit,
      ConsumedUnit.milliliters,
    );
    expect(mgResolution.manualServingSuggestions.single.amount, 0.5);
    expect(
      mgResolution.manualServingSuggestions.single.unit,
      ConsumedUnit.grams,
    );
  });

  test('ignores negative or unknown structured serving units', () {
    final negativeItem = _amountItem(
      servingQuantity: -1,
      servingQuantityUnit: 'g',
    );
    final unknownUnitItem = _amountItem(
      servingQuantity: 1,
      servingQuantityUnit: 'oz',
    );
    const learned = GlobalFoodServingSuggestionSet.empty();

    final negativeResolution = resolver.resolve(
      item: negativeItem,
      learned: learned,
      maxAmount: 1000,
      requiresManualPortion: true,
    );
    final unknownResolution = resolver.resolve(
      item: unknownUnitItem,
      learned: learned,
      maxAmount: 1000,
      requiresManualPortion: true,
    );

    expect(negativeResolution.manualServingSuggestions, isEmpty);
    expect(unknownResolution.manualServingSuggestions, isEmpty);
  });

  test('drops serving suggestion when it matches package weight', () {
    final item = _amountItem(servingSize: '250 g', weight: '250 g');

    final resolution = resolver.resolve(
      item: item,
      learned: const GlobalFoodServingSuggestionSet.empty(),
      maxAmount: 1000,
      requiresManualPortion: true,
    );

    expect(resolution.manualServingSuggestions, isEmpty);
    expect(resolution.inventoryServingOptions, isEmpty);
  });
}
