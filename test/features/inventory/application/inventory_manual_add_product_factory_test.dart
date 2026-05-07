import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_manual_add_product_factory.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

void main() {
  test('draft item derives amount data from weight', () {
    final item = buildInventoryManualAddDraftItem(
      id: 'draft-1',
      now: DateTime.parse('2026-04-13T10:00:00Z'),
      storeName: 'Added manually',
      scannedBarcode: '4006381333931',
      name: 'Milk',
      weight: '1 l',
      nutrition: _nutrition,
    );

    expect(item.id, 'draft-1');
    expect(item.origin, InventoryItemOrigin.manualAdd);
    expect(item.currentAmount, 1000);
    expect(item.amountUnit, InventoryAmountUnit.milliliter);
  });

  test('global item keeps selected package size separate from inventory', () {
    final item = _milkItem(weight: '300 ml');
    const selectedProduct = OffProductSearchResult(
      code: '4006381333931',
      name: 'Milk',
      brand: 'Brand',
      score: 99,
      packageWeight: '1 l',
      servingSize: '250 ml',
      servingQuantity: 250,
      servingQuantityUnit: 'ml',
      nutrition: _nutrition,
    );

    final globalItem = buildInventoryManualAddGlobalFoodItem(
      item: item,
      barcode: '4006381333931',
      now: DateTime.parse('2026-04-13T10:00:00Z'),
      packageWeight: '1 l',
      manualGlobalFoodItemId: 'manual-1',
      selectedProduct: selectedProduct,
    );

    expect(globalItem.id, 'off-4006381333931');
    expect(globalItem.packageWeight, '1 l');
    expect(globalItem.servingSize, '250 ml');
    expect(globalItem.servingQuantity, 250);
    expect(globalItem.servingQuantityUnit, 'ml');
  });

  test('saved item uses inventory-local weight and resolved global id', () {
    final globalItem = GlobalFoodItem.create(
      id: 'off-4006381333931',
      name: 'Milk',
      now: DateTime.parse('2026-04-13T10:00:00Z'),
      brand: 'Brand',
      barcode: '4006381333931',
      packageWeight: '1 l',
      nutrition: _nutrition,
    );

    final savedItem = buildInventoryManualAddSavedItem(
      id: 'inventory-1',
      globalProduct: globalItem,
      globalSaved: true,
      now: DateTime.parse('2026-04-13T10:00:00Z'),
      storeName: 'Added manually',
      inventoryWeight: '300 ml',
    );

    expect(savedItem.id, 'inventory-1');
    expect(savedItem.globalFoodItemId, 'off-4006381333931');
    expect(savedItem.weight, '300 ml');
    expect(savedItem.initialAmount, 300);
    expect(savedItem.currentAmount, 300);
    expect(savedItem.amountUnit, InventoryAmountUnit.milliliter);
  });

  test('manual global food id includes barcode and normalized names', () {
    final item = _milkItem(weight: '300 ml');
    final unnamedItem = InventoryItem.create(
      id: 'item-2',
      name: '',
      entryDate: DateTime.parse('2026-04-13T10:00:00Z'),
      storeName: 'Added manually',
      quantity: 1,
    );

    expect(
      inventoryManualAddGlobalFoodItemIdFor(
        item: item,
        barcode: '4006381333931',
        manualGlobalFoodItemId: 'ignored',
      ),
      'off-4006381333931-milk-brand',
    );
    expect(
      inventoryManualAddGlobalFoodItemIdFor(
        item: item,
        barcode: null,
        manualGlobalFoodItemId: 'manual-1',
      ),
      'manual-food-manual-1',
    );
    expect(
      inventoryManualAddGlobalFoodItemIdFor(
        item: unnamedItem,
        barcode: '4006381333931',
        manualGlobalFoodItemId: 'ignored',
      ),
      'off-4006381333931',
    );
  });

  test('inventory weight normalizer trims empty values', () {
    expect(resolveInventoryManualAddInventoryWeight(' 300 ml '), '300 ml');
    expect(resolveInventoryManualAddInventoryWeight(' '), isNull);
    expect(resolveInventoryManualAddInventoryWeight(null), isNull);
  });
}

InventoryItem _milkItem({required String weight}) {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Milk',
    brand: 'Brand',
    barcode: '4006381333931',
    entryDate: DateTime.parse('2026-04-13T10:00:00Z'),
    storeName: 'Added manually',
    quantity: 1,
    weight: weight,
    nutrition: _nutrition,
  ).withDerivedAmount(weight: weight, quantity: 1);
}

const _nutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 42,
  per100Protein: 3.4,
  per100Carbs: 4.9,
  per100Fat: 1.5,
);
