import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_open_eat_stock.dart';
import 'package:yamt/features/inventory/domain/inventory_stock_count.dart';

InventoryItem _item({String weight = '', double? pieceWeight, String? unit}) =>
    InventoryItem.create(
      id: 'item',
      name: 'Flour',
      entryDate: DateTime(2026, 11, 12),
      storeName: 'Store',
      quantity: 1,
      weight: weight,
      servingQuantity: pieceWeight,
      servingQuantityUnit: pieceWeight == null ? null : unit ?? 'g',
    ).withDerivedAmount();

void main() {
  group('stockAmountQuestion', () {
    test('a food with a package size asks how much', () {
      final item = _item(weight: '500 g');

      for (final unit in [...InventoryAmountUnit.values, null]) {
        expect(stockAmountQuestion(item, unit), StockAmountQuestion.howMuch);
      }
    });

    test('a food without a package size asks for the pack weight', () {
      final item = _item();

      expect(
        stockAmountQuestion(item, InventoryAmountUnit.gram),
        StockAmountQuestion.packWeight,
      );
      expect(
        stockAmountQuestion(item, InventoryAmountUnit.milliliter),
        StockAmountQuestion.packWeight,
      );
      expect(stockAmountQuestion(item, null), StockAmountQuestion.packWeight);
    });

    test('a food without a package size for pieces asks how many', () {
      expect(
        stockAmountQuestion(_item(), InventoryAmountUnit.piece),
        StockAmountQuestion.howMany,
      );
    });

    test('pieces count, unless the line weighs and a piece has no weight', () {
      final loose = _item(weight: '6 Stück');
      final known = _item(weight: '6 Stück', pieceWeight: 60);

      expect(
        stockAmountQuestion(loose, InventoryAmountUnit.piece),
        StockAmountQuestion.howMany,
      );
      expect(
        stockAmountQuestion(loose, InventoryAmountUnit.gram),
        StockAmountQuestion.packWeight,
      );
      expect(
        stockAmountQuestion(known, InventoryAmountUnit.gram),
        StockAmountQuestion.howMany,
      );
    });
  });

  test('hasPieceWeight needs a weight in g or ml', () {
    expect(hasPieceWeight(_item(pieceWeight: 60)), isTrue);
    expect(hasPieceWeight(_item(pieceWeight: 60, unit: 'ml')), isTrue);
    expect(hasPieceWeight(_item(pieceWeight: 60, unit: 'pc')), isFalse);
    expect(hasPieceWeight(_item()), isFalse);
  });

  test('stockItemWithPackWeight makes one pack of the typed weight', () {
    final item = stockItemWithPackWeight(
      _item(),
      750,
      InventoryAmountUnit.milliliter,
    );

    expect(item.amountUnit, InventoryAmountUnit.milliliter);
    expect(item.initialAmount, 750);
    expect(item.currentAmount, 750);
    expect(item.quantity, 1);
    expect(item.initialQuantity, 1);
  });

  group('stockItemWithPieces', () {
    test('counts the pieces in thousandths with the typed weight', () {
      final item = stockItemWithPieces(_item(), 3, 60);

      expect(item.amountUnit, InventoryAmountUnit.piece);
      expect(item.amountScale, inventoryPieceAmountScale);
      expect(item.currentAmount, 3 * inventoryPieceAmountScale);
      expect(item.servingQuantity, 60);
      expect(item.servingQuantityUnit, 'g');
    });

    test('keeps the weight the food has', () {
      final item = stockItemWithPieces(_item(pieceWeight: 45), 2, 60);

      expect(item.servingQuantity, 45);
    });

    test('without a weight sets none', () {
      expect(stockItemWithPieces(_item(), 2, null).servingQuantity, isNull);
    });
  });

  test('stockRestOf: the rest when there is enough, else what is missing', () {
    expect(stockRestOf(500, 200), (rest: 300, missing: 0));
    expect(stockRestOf(200, 200), (rest: 0, missing: 0));
    expect(stockRestOf(150, 200), (rest: 0, missing: 50));
  });

  group('openStockStartCount', () {
    test('starts at the pieces of the package', () {
      expect(openStockStartCount(_item(weight: '6 Stück'), 2), 6);
    });

    test('else at what the recipe needs, else one', () {
      expect(openStockStartCount(_item(), 3), 3);
      expect(openStockStartCount(_item(), null), 1);
      expect(openStockStartCount(_item(weight: '500 g'), 0), 1);
    });
  });
}
