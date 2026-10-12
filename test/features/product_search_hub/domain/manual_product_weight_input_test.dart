import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/domain/manual_product_weight_input.dart';

void main() {
  group('resolveManualProductWeightInput', () {
    test('parses standard gram, kilogram, and milliliter values', () {
      final grams = resolveManualProductWeightInput('500g');
      expect(grams.amount, '500');
      expect(grams.unit, InventoryAmountUnit.gram);
      expect(grams.normalizedWeight, '500 g');
      expect(grams.parsedAmount?.amount, 500);
      expect(grams.parsedAmount?.unit, InventoryAmountUnit.gram);
      expect(grams.parsedAmount?.scale, 1);

      final kilograms = resolveManualProductWeightInput('1.5kg');
      expect(kilograms.amount, '1500');
      expect(kilograms.unit, InventoryAmountUnit.gram);
      expect(kilograms.normalizedWeight, '1500 g');
      expect(kilograms.parsedAmount?.amount, 1500);
      expect(kilograms.parsedAmount?.unit, InventoryAmountUnit.gram);
      expect(kilograms.parsedAmount?.scale, 1);

      final milliliters = resolveManualProductWeightInput('330ml');
      expect(milliliters.amount, '330');
      expect(milliliters.unit, InventoryAmountUnit.milliliter);
      expect(milliliters.normalizedWeight, '330 ml');
      expect(milliliters.parsedAmount?.amount, 330);
      expect(milliliters.parsedAmount?.unit, InventoryAmountUnit.milliliter);
      expect(milliliters.parsedAmount?.scale, 1);
    });

    test(
      'returns empty fallback data for null, empty, and text-only input',
      () {
        for (final rawWeight in <String?>[null, '', 'nur text']) {
          final resolved = resolveManualProductWeightInput(rawWeight);

          expect(resolved.amount, '');
          expect(resolved.unit, InventoryAmountUnit.gram);
          expect(resolved.normalizedWeight, isNull);
          expect(resolved.parsedAmount, isNull);
        }
      },
    );

    test('scales fallback liter values to milliliters', () {
      final comma = resolveManualProductWeightInput('Flasche 1,5 l');
      final point = resolveManualProductWeightInput('Flasche 1.5 l');

      expect(comma.amount, '1500');
      expect(comma.unit, InventoryAmountUnit.milliliter);
      expect(comma.normalizedWeight, '1500 ml');
      expect(comma.parsedAmount?.amount, 1500);
      expect(comma.parsedAmount?.unit, InventoryAmountUnit.milliliter);

      expect(point.amount, '1500');
      expect(point.unit, InventoryAmountUnit.milliliter);
      expect(point.normalizedWeight, '1500 ml');
      expect(point.parsedAmount?.amount, 1500);
      expect(point.parsedAmount?.unit, InventoryAmountUnit.milliliter);
    });

    test('scales fallback kilogram values to grams', () {
      final resolved = resolveManualProductWeightInput('Packung 1,5 kg');

      expect(resolved.amount, '1500');
      expect(resolved.unit, InventoryAmountUnit.gram);
      expect(resolved.normalizedWeight, '1500 g');
      expect(resolved.parsedAmount?.amount, 1500);
      expect(resolved.parsedAmount?.unit, InventoryAmountUnit.gram);
    });

    test('uses fallback unit when no unit is present', () {
      final resolved = resolveManualProductWeightInput(
        '12',
        fallbackUnit: InventoryAmountUnit.piece,
      );

      expect(resolved.amount, '12');
      expect(resolved.unit, InventoryAmountUnit.piece);
      expect(resolved.normalizedWeight, '12 pc');
      expect(resolved.parsedAmount?.amount, 12000);
      expect(resolved.parsedAmount?.scale, inventoryPieceAmountScale);
    });

    test('does not parse packaging words or words containing g as gram', () {
      for (final input in [
        '1 Packung',
        '1 Glas',
        '1 Riegel',
        '1 Becher',
        '1 Flasche',
        '1 Dose',
        '1 Stück',
        '1 Stk.',
      ]) {
        final resolved = resolveManualProductWeightInput(input);
        expect(
          resolved.unit,
          InventoryAmountUnit.piece,
          reason: '$input should resolve to piece, not gram',
        );
        expect(resolved.amount, '1', reason: '$input amount should be 1');
        expect(resolved.normalizedWeight, '1 pc');
        expect(resolved.parsedAmount?.amount, 1000);
      }

      // "1 Gurke" does not have a recognized unit, so it must NOT trigger
      // the gram fallback
      final gurke = resolveManualProductWeightInput(
        '1 Gurke',
        fallbackUnit: InventoryAmountUnit.piece,
      );
      expect(gurke.unit, InventoryAmountUnit.piece);
      expect(gurke.amount, '1');
    });

    test('parses German unit names like Gramm, Kilo, Liter, Stück', () {
      final gramm = resolveManualProductWeightInput('500 Gramm');
      expect(gramm.amount, '500');
      expect(gramm.unit, InventoryAmountUnit.gram);
      expect(gramm.normalizedWeight, '500 g');

      final kilo = resolveManualProductWeightInput('2 Kilo');
      expect(kilo.amount, '2000');
      expect(kilo.unit, InventoryAmountUnit.gram);
      expect(kilo.normalizedWeight, '2000 g');

      final liter = resolveManualProductWeightInput('1 Liter');
      expect(liter.amount, '1000');
      expect(liter.unit, InventoryAmountUnit.milliliter);
      expect(liter.normalizedWeight, '1000 ml');

      final stueck = resolveManualProductWeightInput('3 Stück');
      expect(stueck.amount, '3');
      expect(stueck.unit, InventoryAmountUnit.piece);
      expect(stueck.normalizedWeight, '3 pc');
    });
  });

  group('resolveManualProductOcrWeightInput', () {
    test('returns null when OCR text has no amount', () {
      expect(
        resolveManualProductOcrWeightInput(
          'nur text',
          fallbackUnit: InventoryAmountUnit.gram,
        ),
        isNull,
      );
    });
  });

  group('withPackageWeight', () {
    InventoryItem item({
      int quantity = 2,
      int initialQuantity = 2,
      String? weight = '500 g',
    }) {
      final created = InventoryItem.create(
        id: 'item-1',
        name: 'Quark',
        entryDate: DateTime.parse('2026-04-02T10:00:00Z'),
        storeName: 'Kaufland',
        quantity: quantity,
        initialQuantity: initialQuantity,
        weight: weight,
      );
      return weight == null ? created : created.withDerivedAmount();
    }

    InventoryAmountParseResult? package(String weight) =>
        resolveManualProductWeightInput(weight).parsedAmount;

    test('the same size, however written, keeps the stock', () {
      final stocked = item(weight: '2x250g').copyWith(currentAmount: 300);

      final kept = stocked.withPackageWeight(
        weight: '500 g',
        package: package('500 g'),
      );

      expect(kept, same(stocked));
    });

    test('a cleared size drops the amount', () {
      final cleared = item().withPackageWeight(weight: null, package: null);

      expect(cleared.initialAmount, 0);
      expect(cleared.currentAmount, 0);
    });

    test('a new size scales the stock and keeps the share left', () {
      final eaten = item().copyWith(quantity: 1, currentAmount: 400);

      final resized = eaten.withPackageWeight(
        weight: '250 g',
        package: package('250 g'),
      );

      expect(resized.initialAmount, 500);
      expect(resized.currentAmount, 200);
      expect(resized.initialQuantity, 2);
    });

    test('a recent item with a stale package count stays one package', () {
      // One package of an old stock entry that held four.
      final recent = item(initialQuantity: 4).withDerivedAmount(quantity: 1);

      final resized = recent.withPackageWeight(
        weight: '400 g',
        package: package('400 g'),
      );

      expect(resized.initialAmount, 400);
      expect(resized.currentAmount, 400);
    });

    test('a size for a stock counted by packages counts what is left', () {
      final counted = item(quantity: 1, initialQuantity: 3, weight: null);

      final weighed = counted.withPackageWeight(
        weight: '500 g',
        package: package('500 g'),
      );

      expect(weighed.initialQuantity, 3);
      expect(weighed.initialAmount, 1500);
      expect(weighed.currentAmount, 500);
    });

    test('a new unit counts the packages the stored amount holds', () {
      final recent = item(initialQuantity: 4).withDerivedAmount(quantity: 1);

      final pieces = recent.withPackageWeight(
        weight: '6 Stk',
        package: package('6 Stk'),
      );

      expect(pieces.amountUnit, InventoryAmountUnit.piece);
      expect(pieces.initialQuantity, 1);
      expect(pieces.currentAmount, pieces.initialAmount);
    });
  });
}
