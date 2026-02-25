import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/domain/receipt_item_input_parser.dart';

void main() {
  const parser = ReceiptItemInputParser();

  test('parseDouble handles grouped DE values', () {
    final parsed = parser.parseDouble('1.000,50', locale: 'de_DE');
    expect(parsed, 1000.5);
  });

  test('parseDouble handles grouped EN values in DE locale', () {
    final parsed = parser.parseDouble('1,000.50', locale: 'de_DE');
    expect(parsed, 1000.5);
  });

  test('parseNumbers requires integer quantity', () {
    final parsed = parser.parseNumbers(
      quantityText: '1,5',
      unitPriceText: '2,20',
      locale: 'de_DE',
    );
    expect(parsed, isNull);
  });

  test('parseDiscounts parses json map values', () {
    final parsed = parser.parseDiscounts(
      '{"coupon":"1.20","promo":0.5}',
      locale: 'en_US',
    );
    expect(parsed, isNotNull);
    expect(parsed!['coupon'], 1.2);
    expect(parsed['promo'], 0.5);
  });

  test('parseDiscounts parses key value pairs with decimal commas', () {
    final parsed = parser.parseDiscounts(
      'coupon=1,20, promo=0,50',
      locale: 'de_DE',
    );
    expect(parsed, isNotNull);
    expect(parsed!['coupon'], 1.2);
    expect(parsed['promo'], 0.5);
  });

  test('parseDiscounts returns null for invalid pair syntax', () {
    final parsed = parser.parseDiscounts('coupon 1.20', locale: 'en_US');
    expect(parsed, isNull);
  });

  test(
    'parseDiscountEntries parses structured rows and ignores empty ones',
    () {
      final parsed = parser.parseDiscountEntries(
        const <MapEntry<String, String>>[
          MapEntry<String, String>('coupon', '1,20'),
          MapEntry<String, String>('', ''),
        ],
        locale: 'de_DE',
      );
      expect(parsed, <String, double>{'coupon': 1.2});
    },
  );

  test('parseDiscountEntries returns null when row is incomplete', () {
    final parsed = parser.parseDiscountEntries(const <MapEntry<String, String>>[
      MapEntry<String, String>('coupon', ''),
    ], locale: 'en_US');
    expect(parsed, isNull);
  });
}
