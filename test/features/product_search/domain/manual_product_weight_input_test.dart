import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/product_search/domain/manual_product_weight_input.dart';

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
}
