import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_row.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

InventoryItem _grams(String id, int amount) => InventoryItem.create(
  id: id,
  name: 'Mehl $id',
  entryDate: DateTime.utc(2026, 10, 9),
  storeName: 'Store',
  quantity: 1,
  initialAmount: 1000,
  currentAmount: amount,
  amountUnit: InventoryAmountUnit.gram,
);

InventoryItem _milliliters(String id, int amount) => InventoryItem.create(
  id: id,
  name: 'Milch $id',
  entryDate: DateTime.utc(2026, 10, 9),
  storeName: 'Store',
  quantity: 1,
  initialAmount: 1000,
  currentAmount: amount,
  amountUnit: InventoryAmountUnit.milliliter,
);

InventoryItem _eggs(String id, {required int pieces}) => InventoryItem.create(
  id: id,
  name: 'Eier $id',
  entryDate: DateTime.utc(2026, 10, 9),
  storeName: 'Store',
  quantity: 1,
  initialAmount: 10 * inventoryPieceAmountScale,
  currentAmount: pieces * inventoryPieceAmountScale,
  amountScale: inventoryPieceAmountScale,
  amountUnit: InventoryAmountUnit.piece,
);

InventoryItem _packs(String id, int quantity) => InventoryItem.create(
  id: id,
  name: 'Dose $id',
  entryDate: DateTime.utc(2026, 10, 9),
  storeName: 'Store',
  quantity: quantity,
  initialQuantity: quantity,
);

void main() {
  group('RecipeIngredientRow.stockLeft', () {
    test('is null without a stock item', () {
      expect(
        const RecipeIngredientRow(text: 'Salz').stockLeft(const {}),
        isNull,
      );
    });

    test('is the stock when nothing else holds it', () {
      final row = RecipeIngredientRow(
        text: '300 g Mehl',
        stockItems: [_grams('a', 700), _grams('b', 300)],
      );

      expect(row.stockLeft(const {}), (
        amount: 1000,
        unit: InventoryAmountUnit.gram,
      ));
    });

    test('takes away what other cook runs hold of each item', () {
      final row = RecipeIngredientRow(
        text: '300 g Mehl',
        stockItems: [_grams('a', 700), _grams('b', 300)],
      );

      expect(row.stockLeft(const {'a': 500, 'b': 100}), (
        amount: 400,
        unit: InventoryAmountUnit.gram,
      ));
    });

    test('never counts an item below 0', () {
      final row = RecipeIngredientRow(
        text: '300 g Mehl',
        stockItems: [_grams('a', 700), _grams('b', 300)],
      );

      expect(row.stockLeft(const {'a': 900}), (
        amount: 300,
        unit: InventoryAmountUnit.gram,
      ));
    });

    test('is 0 when everything is held', () {
      final row = RecipeIngredientRow(
        text: '300 g Mehl',
        stockItems: [_grams('a', 700)],
      );

      expect(row.stockLeft(const {'a': 700}), (
        amount: 0,
        unit: InventoryAmountUnit.gram,
      ));
    });

    test('adds grams and milliliters 1:1, in the unit of the first', () {
      final row = RecipeIngredientRow(
        text: '300 g Mehl',
        stockItems: [_grams('a', 700), _milliliters('b', 300)],
      );

      expect(row.stockLeft(const {}), (
        amount: 1000,
        unit: InventoryAmountUnit.gram,
      ));
    });

    test('does not add an item in another scale', () {
      final row = RecipeIngredientRow(
        text: '300 g Mehl',
        stockItems: [_grams('a', 700), _eggs('b', pieces: 6)],
      );

      expect(row.stockLeft(const {}), (
        amount: 700,
        unit: InventoryAmountUnit.gram,
      ));
    });

    test('takes what other runs hold off before it adds up', () {
      final row = RecipeIngredientRow(
        text: '300 g Mehl',
        stockItems: [_grams('a', 700), _milliliters('b', 300)],
      );

      expect(row.stockLeft(const {'b': 50}), (
        amount: 950,
        unit: InventoryAmountUnit.gram,
      ));
    });

    test('counts pieces as whole pieces after the held part', () {
      final row = RecipeIngredientRow(
        text: '3 Eier',
        stockItems: [_eggs('a', pieces: 6)],
      );

      expect(row.stockLeft({'a': 3 * inventoryPieceAmountScale}), (
        amount: 3,
        unit: InventoryAmountUnit.piece,
      ));
    });

    test('counts packs of an item without an amount in pieces', () {
      final row = RecipeIngredientRow(
        text: '2 Dosen Tomaten',
        stockItems: [_packs('a', 4)],
      );

      expect(row.stockLeft(const {'a': 1}), (
        amount: 3,
        unit: InventoryAmountUnit.piece,
      ));
    });
  });
}
