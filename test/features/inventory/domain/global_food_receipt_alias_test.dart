import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_receipt_alias.dart';

GlobalFoodItem _item() {
  return GlobalFoodItem.create(
    id: 'milk',
    name: 'Whole Milk',
    brand: 'Milsani',
    storeName: 'Aldi',
    now: DateTime.parse('2026-03-01T10:00:00Z'),
  );
}

void main() {
  test('tryCreate normalizes store and OCR receipt text', () {
    final alias = GlobalFoodReceiptAlias.tryCreate(
      storeName: ' ALDI Süd ',
      receiptName: 'Waffelhörnchen 110ml',
      globalFoodItem: _item(),
      now: DateTime.parse('2026-03-01T12:00:00Z'),
    );

    expect(alias, isNotNull);
    expect(alias!.storeName, 'Aldi');
    expect(alias.normalizedStoreName, 'aldi');
    expect(alias.receiptName, 'Waffelhörnchen 110ml');
    expect(alias.normalizedReceiptName, 'waffelhoernchen 110ml');
    expect(alias.lookupKey, 'aldi|waffelhoernchen 110ml');
    expect(alias.selectionCount, 1);
    expect(alias.id, startsWith('receipt-alias-'));
  });

  test('tryCreate skips aliases without a reliable store key', () {
    final alias = GlobalFoodReceiptAlias.tryCreate(
      storeName: 'Unknown',
      receiptName: 'Milk',
      globalFoodItem: _item(),
      now: DateTime.parse('2026-03-01T12:00:00Z'),
    );

    expect(alias, isNull);
  });
}
