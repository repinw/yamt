import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/domain/manual_product_piece_weight.dart';

void main() {
  group('manualProductPieceWeightText', () {
    test('shows a serving in grams', () {
      expect(
        manualProductPieceWeightText((
          size: '1 Ei (60 g)',
          quantity: 60,
          quantityUnit: 'g',
        )),
        '60',
      );
    });

    test('converts kilograms', () {
      expect(
        manualProductPieceWeightText((
          size: null,
          quantity: 0.25,
          quantityUnit: 'kg',
        )),
        '250',
      );
    });

    test('shows a serving in milliliters', () {
      expect(
        manualProductPieceWeightText((
          size: null,
          quantity: 250,
          quantityUnit: 'ml',
        )),
        '250',
      );
    });

    test('is empty without a serving in grams or milliliters', () {
      expect(
        manualProductPieceWeightText((
          size: null,
          quantity: 1,
          quantityUnit: 'pc',
        )),
        '',
      );
      expect(
        manualProductPieceWeightText((
          size: null,
          quantity: null,
          quantityUnit: null,
        )),
        '',
      );
    });
  });

  group('resolveManualProductServing', () {
    const serving = (size: '1 Ei (60 g)', quantity: 60.0, quantityUnit: 'g');

    test('makes the grams of one piece the serving', () {
      expect(
        resolveManualProductServing(
          packageUnit: InventoryAmountUnit.piece,
          pieceWeightText: '55',
          serving: serving,
        ),
        (size: null, quantity: 55.0, quantityUnit: 'g'),
      );
    });

    test('keeps the serving and its label when the grams match', () {
      expect(
        resolveManualProductServing(
          packageUnit: InventoryAmountUnit.piece,
          pieceWeightText: '60',
          serving: serving,
        ),
        serving,
      );
    });

    test('keeps the serving for a package in grams or without input', () {
      expect(
        resolveManualProductServing(
          packageUnit: InventoryAmountUnit.gram,
          pieceWeightText: '55',
          serving: serving,
        ),
        serving,
      );
      expect(
        resolveManualProductServing(
          packageUnit: InventoryAmountUnit.piece,
          pieceWeightText: '',
          serving: serving,
        ),
        serving,
      );
    });
  });
}
