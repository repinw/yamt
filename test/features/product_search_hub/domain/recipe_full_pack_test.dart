import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/domain/recipe_full_pack.dart';

InventoryItem _item({
  String weight = '',
  int quantity = 1,
  double? pieceWeight,
}) => InventoryItem.create(
  id: 'item',
  name: 'Flour',
  entryDate: DateTime(2026, 11, 12),
  storeName: 'Store',
  quantity: quantity,
  weight: weight,
  servingQuantity: pieceWeight,
  servingQuantityUnit: pieceWeight == null ? null : 'g',
).withDerivedAmount();

void main() {
  group('a product with a package size enters one full pack', () {
    test('in grams for a line in grams, ml or pieces', () {
      final item = _item(weight: '500 g');

      expect(item.amountUnit, InventoryAmountUnit.gram);
      expect(recipeFullPackAmount(item, InventoryAmountUnit.gram), 500);
      expect(recipeFullPackAmount(item, InventoryAmountUnit.milliliter), 500);
      expect(recipeFullPackAmount(item, InventoryAmountUnit.piece), 500);
      expect(recipeFullPackAmount(item, null), 500);
    });

    test('kilograms and liters count in grams and milliliters', () {
      final kilo = _item(weight: '1 kg');
      final liter = _item(weight: '1 l');

      expect(recipeFullPackAmount(kilo, InventoryAmountUnit.gram), 1000);
      expect(recipeFullPackAmount(liter, InventoryAmountUnit.milliliter), 1000);
    });

    test('pieces with a piece weight enter the whole pack', () {
      final eggs = _item(weight: '6 Stück', pieceWeight: 60);

      expect(eggs.amountUnit, InventoryAmountUnit.piece);
      expect(
        recipeFullPackAmount(eggs, InventoryAmountUnit.gram),
        eggs.initialAmount,
      );
      expect(
        recipeFullPackAmount(eggs, InventoryAmountUnit.piece),
        eggs.initialAmount,
      );
    });
  });

  group('the app has to ask', () {
    test('when the product has no package size', () {
      final item = _item();

      expect(item.usesAmountProgress, isFalse);
      for (final unit in InventoryAmountUnit.values) {
        expect(recipeFullPackAmount(item, unit), isNull);
      }
      expect(recipeFullPackAmount(item, null), isNull);
    });

    test('when a pack of pieces has no piece weight and the line counts '
        'grams or ml', () {
      final eggs = _item(weight: '6 Stück');

      expect(eggs.amountUnit, InventoryAmountUnit.piece);
      expect(recipeFullPackAmount(eggs, InventoryAmountUnit.gram), isNull);
      expect(
        recipeFullPackAmount(eggs, InventoryAmountUnit.milliliter),
        isNull,
      );
    });

    test('but not when the line counts pieces', () {
      final eggs = _item(weight: '6 Stück');

      expect(
        recipeFullPackAmount(eggs, InventoryAmountUnit.piece),
        eggs.initialAmount,
      );
    });
  });
}
