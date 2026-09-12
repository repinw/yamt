import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';

void main() {
  const parser = InventoryAmountParser();

  group('InventoryAmountParser.tryParse', () {
    test('parses metric gram formats including German aliases', () {
      for (final raw in [
        '500g',
        '500 g',
        '500gr',
        '500 gr',
        '500gram',
        '500 gramm',
        '500 Gramm',
      ]) {
        final result = parser.tryParse(rawWeight: raw, quantity: 1);
        expect(result, isNotNull, reason: 'Failed to parse $raw');
        expect(result!.amount, 500);
        expect(result.unit, InventoryAmountUnit.gram);
        expect(result.scale, 1);
      }
    });

    test('parses kilogram formats and scales to grams', () {
      for (final raw in [
        '1.5kg',
        '1,5 kg',
        '1.5 kilo',
        '1.5 Kilo',
        '1.5 kilogramm',
        '1.5 Kilogramm',
      ]) {
        final result = parser.tryParse(rawWeight: raw, quantity: 1);
        expect(result, isNotNull, reason: 'Failed to parse $raw');
        expect(result!.amount, 1500);
        expect(result.unit, InventoryAmountUnit.gram);
        expect(result.scale, 1);
      }
    });

    test('parses milligram formats', () {
      final result = parser.tryParse(rawWeight: '2000mg', quantity: 1);
      expect(result, isNotNull);
      expect(result!.amount, 2);
      expect(result.unit, InventoryAmountUnit.gram);

      final german = parser.tryParse(rawWeight: '2000 Milligramm', quantity: 1);
      expect(german, isNotNull);
      expect(german!.amount, 2);
      expect(german.unit, InventoryAmountUnit.gram);
    });

    test('parses liquid volumes in ml, cl, dl, and l', () {
      final ml = parser.tryParse(rawWeight: '330ml', quantity: 1);
      expect(ml, isNotNull);
      expect(ml!.amount, 330);
      expect(ml.unit, InventoryAmountUnit.milliliter);

      final mlGerman = parser.tryParse(
        rawWeight: '330 Milliliter',
        quantity: 1,
      );
      expect(mlGerman, isNotNull);
      expect(mlGerman!.amount, 330);
      expect(mlGerman.unit, InventoryAmountUnit.milliliter);

      final cl = parser.tryParse(rawWeight: '33cl', quantity: 1);
      expect(cl, isNotNull);
      expect(cl!.amount, 330);
      expect(cl.unit, InventoryAmountUnit.milliliter);

      final dl = parser.tryParse(rawWeight: '5dl', quantity: 1);
      expect(dl, isNotNull);
      expect(dl!.amount, 500);
      expect(dl.unit, InventoryAmountUnit.milliliter);

      final liter = parser.tryParse(rawWeight: '1.5l', quantity: 1);
      expect(liter, isNotNull);
      expect(liter!.amount, 1500);
      expect(liter.unit, InventoryAmountUnit.milliliter);

      final literGerman = parser.tryParse(rawWeight: '1,5 Liter', quantity: 1);
      expect(literGerman, isNotNull);
      expect(literGerman!.amount, 1500);
      expect(literGerman.unit, InventoryAmountUnit.milliliter);
    });

    test('parses piece units with umlauts, dots, and packaging terms', () {
      final pieceTerms = [
        '1 pc',
        '1 pcs',
        '1 piece',
        '1 st',
        '1 st.',
        '1 stk',
        '1 stk.',
        '1 Stk.',
        '1 Stück',
        '1 stück',
        '1 stueck',
        '1 Flasche',
        '1 Dose',
        '1 Packung',
        '1 Pkg',
        '1 Pkg.',
        '1 Glas',
        '1 Becher',
        '1 Riegel',
        '1 Tafel',
        '1 Portion',
        '1 Beutel',
      ];

      for (final term in pieceTerms) {
        final result = parser.tryParse(rawWeight: term, quantity: 1);
        expect(result, isNotNull, reason: 'Failed to parse $term');
        expect(result!.amount, 1000, reason: 'Amount mismatch for $term');
        expect(
          result.unit,
          InventoryAmountUnit.piece,
          reason: 'Unit mismatch for $term',
        );
        expect(result.scale, inventoryPieceAmountScale);
      }
    });

    test('handles pack multiplier formats like 3 x 150 g', () {
      final pack = parser.tryParse(rawWeight: '3 x 150 g', quantity: 1);
      expect(pack, isNotNull);
      expect(pack!.amount, 450);
      expect(pack.unit, InventoryAmountUnit.gram);

      final packLiquid = parser.tryParse(rawWeight: '6 x 0.5 l', quantity: 1);
      expect(packLiquid, isNotNull);
      expect(packLiquid!.amount, 3000);
      expect(packLiquid.unit, InventoryAmountUnit.milliliter);

      final packPiece = parser.tryParse(rawWeight: '4 x 1 Stück', quantity: 1);
      expect(packPiece, isNotNull);
      expect(packPiece!.amount, 4000);
      expect(packPiece.unit, InventoryAmountUnit.piece);
    });

    test('multiplies by quantity parameter', () {
      final result = parser.tryParse(rawWeight: '250 g', quantity: 3);
      expect(result, isNotNull);
      expect(result!.amount, 750);
      expect(result.unit, InventoryAmountUnit.gram);
    });

    test('cleans estimated mark ℮, netto, ca., and tildes', () {
      final estimated = parser.tryParse(rawWeight: '500 g ℮', quantity: 1);
      expect(estimated, isNotNull);
      expect(estimated!.amount, 500);
      expect(estimated.unit, InventoryAmountUnit.gram);

      final netto = parser.tryParse(rawWeight: 'ca. 500g netto', quantity: 1);
      expect(netto, isNotNull);
      expect(netto!.amount, 500);
      expect(netto.unit, InventoryAmountUnit.gram);

      final tilde = parser.tryParse(rawWeight: '~ 250 ml', quantity: 1);
      expect(tilde, isNotNull);
      expect(tilde!.amount, 250);
      expect(tilde.unit, InventoryAmountUnit.milliliter);
    });

    test('uses fallbackUnit when unit is missing from string', () {
      final withFallback = parser.tryParse(
        rawWeight: '5',
        quantity: 1,
        fallbackUnit: InventoryAmountUnit.piece,
      );
      expect(withFallback, isNotNull);
      expect(withFallback!.amount, 5000);
      expect(withFallback.unit, InventoryAmountUnit.piece);

      final withoutFallback = parser.tryParse(rawWeight: '5', quantity: 1);
      expect(withoutFallback, isNull);
    });

    test('returns null for invalid or empty inputs', () {
      expect(parser.tryParse(rawWeight: null, quantity: 1), isNull);
      expect(parser.tryParse(rawWeight: '', quantity: 1), isNull);
      expect(parser.tryParse(rawWeight: 'nur text', quantity: 1), isNull);
      expect(parser.tryParse(rawWeight: '-500 g', quantity: 1), isNull);
      expect(parser.tryParse(rawWeight: '0 g', quantity: 1), isNull);
    });
  });

  group('formatInventoryAmountValue & parseInventoryAmountInput', () {
    test('formats and parses fractional piece amounts properly', () {
      final formatted = formatInventoryAmountValue(
        amount: 2500,
        unit: InventoryAmountUnit.piece,
        scale: inventoryPieceAmountScale,
      );
      expect(formatted, '2.5');

      final parsed = parseInventoryAmountInput(
        rawValue: formatted,
        unit: InventoryAmountUnit.piece,
        scale: inventoryPieceAmountScale,
      );
      expect(parsed, 2500);
    });

    test('formats whole piece amounts without trailing decimals', () {
      final formatted = formatInventoryAmountValue(
        amount: 1000,
        unit: InventoryAmountUnit.piece,
        scale: inventoryPieceAmountScale,
      );
      expect(formatted, '1');
    });

    test('formats whole gram amounts', () {
      final formatted = formatInventoryAmountValue(
        amount: 500,
        unit: InventoryAmountUnit.gram,
      );
      expect(formatted, '500');
    });
  });
}
