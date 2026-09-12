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

  test(
    'tryCreate skips aliases with single characters, pure digits, or noise',
    () {
      expect(
        GlobalFoodReceiptAlias.tryCreate(
          storeName: 'Lidl',
          receiptName: 'B',
          globalFoodItem: _item(),
          now: DateTime.parse('2026-03-01T12:00:00Z'),
        ),
        isNull,
      );
      expect(
        GlobalFoodReceiptAlias.tryCreate(
          storeName: 'Lidl',
          receiptName: '1',
          globalFoodItem: _item(),
          now: DateTime.parse('2026-03-01T12:00:00Z'),
        ),
        isNull,
      );
      expect(
        GlobalFoodReceiptAlias.tryCreate(
          storeName: 'Lidl',
          receiptName: '99',
          globalFoodItem: _item(),
          now: DateTime.parse('2026-03-01T12:00:00Z'),
        ),
        isNull,
      );
      expect(
        GlobalFoodReceiptAlias.tryCreate(
          storeName: 'Lidl',
          receiptName: 'EUR',
          globalFoodItem: _item(),
          now: DateTime.parse('2026-03-01T12:00:00Z'),
        ),
        isNull,
      );
      expect(
        GlobalFoodReceiptAlias.tryCreate(
          storeName: 'Lidl',
          receiptName: 'Rabatt',
          globalFoodItem: _item(),
          now: DateTime.parse('2026-03-01T12:00:00Z'),
        ),
        isNull,
      );
    },
  );

  test(
    'buildGlobalFoodReceiptAliasSearchTokens filters short, '
    'numeric, and noise tokens',
    () {
      final tokens = buildGlobalFoodReceiptAliasSearchTokens(
        'FRISCHKAESE B 200G',
      );

      expect(tokens, contains('frischkaese b 200g'));
      expect(tokens, contains('frischkaeseb200g'));
      expect(tokens, contains('frischkaese'));
      expect(tokens, contains('200g'));
      expect(tokens, isNot(contains('b')));
      expect(tokens.every((token) => token.length >= 3), isTrue);
      expect(tokens.any((token) => RegExp(r'^\d+$').hasMatch(token)), isFalse);
    },
  );
}
