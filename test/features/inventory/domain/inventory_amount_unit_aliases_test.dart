import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_unit_aliases.dart';

void main() {
  test('servingInBaseUnit converts a serving to its base unit', () {
    expect(servingInBaseUnit(0.25, 'kg'), (
      unit: InventoryAmountUnit.gram,
      amount: 250.0,
    ));
    expect(servingInBaseUnit(12.5, ' CL '), (
      unit: InventoryAmountUnit.milliliter,
      amount: 125.0,
    ));
    expect(servingInBaseUnit(2, 'stück'), (
      unit: InventoryAmountUnit.piece,
      amount: 2.0 * inventoryPieceAmountScale,
    ));
  });

  test('servingInBaseUnit returns null for an unknown or missing unit', () {
    expect(servingInBaseUnit(1, 'oz'), isNull);
    expect(servingInBaseUnit(1, null), isNull);
  });

  test('isInventoryPieceWord tells piece words from container words', () {
    expect(isInventoryPieceWord('Stück'), isTrue);
    expect(isInventoryPieceWord(' pcs '), isTrue);
    expect(isInventoryPieceWord('Portion'), isFalse);
    expect(isInventoryPieceWord('Flasche'), isFalse);
    expect(isInventoryPieceWord(null), isFalse);
  });

  test('every piece word is a piece unit of the alias table', () {
    for (final word in [
      'pc',
      'pcs',
      'piece',
      'pieces',
      'st',
      'st.',
      'stk',
      'stk.',
      'stück',
      'stueck',
    ]) {
      expect(isInventoryPieceWord(word), isTrue);
      expect(
        resolveInventoryAmountUnitAlias(word)?.base,
        InventoryAmountUnit.piece,
      );
    }
  });
}
