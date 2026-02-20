import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_parser.dart';
import 'package:yamt/features/scanner/data/receipt_to_fridge_item_mapper.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';

void main() {
  final fixedNow = DateTime.parse('2026-02-19T10:30:00.000Z');
  final mapper = DefaultReceiptToFridgeItemMapper(now: () => fixedNow);

  test('maps minified receipt payload to fridge item with root fallbacks', () {
    final extraction = ReceiptAnalysisExtraction(
      root: <String, dynamic>{
        's': 'Lidl',
        'rd': '2026-02-18T12:00:00.000Z',
        'l': 'de_DE',
      },
      items: const <ReceiptAnalysisItem>[
        ReceiptAnalysisItem(
          name: 'Milk',
          rawPayload: <String, dynamic>{
            'n': 'Milk',
            'q': '2',
            'p': '3,98',
            'w': '1l',
            'b': 'Milbona',
            'c': 'Dairy',
            'if': true,
            'd': <Map<String, dynamic>>[
              <String, dynamic>{'n': 'Coupon', 'a': '0,50'},
            ],
          },
        ),
      ],
    );

    final items = mapper.map(extraction);

    expect(items, hasLength(1));
    final item = items.single;
    expect(item.id, 'receipt-item-1771497000000000-0');
    expect(item.receiptId, 'receipt-1771497000000000');
    expect(item.name, 'Milk');
    expect(item.storeName, 'Lidl');
    expect(item.quantity, 2);
    expect(item.initialQuantity, 2);
    expect(item.unitPrice, closeTo(1.99, 0.0001));
    expect(item.weight, '1l');
    expect(item.initialAmount, 2000);
    expect(item.currentAmount, 2000);
    expect(item.amountUnit, FridgeAmountUnit.milliliter);
    expect(item.brand, 'Milbona');
    expect(item.category, 'Dairy');
    expect(item.discounts, <String, double>{'Coupon': 0.5});
    expect(item.language, 'de_DE');
    expect(item.receiptDate, DateTime.parse('2026-02-18T12:00:00.000Z'));
    expect(item.entryDate, fixedNow);
    expect(item.isDeposit, isFalse);
    expect(item.isDiscount, isFalse);
  });

  test('keeps non-food or discount lines as review-only entries', () {
    final extraction = ReceiptAnalysisExtraction(
      root: const <String, dynamic>{},
      items: const <ReceiptAnalysisItem>[
        ReceiptAnalysisItem(
          name: 'Ignored fallback',
          rawPayload: <String, dynamic>{
            'name': 'Bottle Return',
            'storeName': '',
            'quantity': 0,
            'totalPrice': 0,
            'isFood': false,
            'isDiscount': true,
            'discounts': <String, dynamic>{'Promo': '1.25', 'Broken': 'n/a'},
          },
        ),
      ],
    );

    final items = mapper.map(extraction);

    expect(items, hasLength(1));
    final item = items.single;
    expect(item.name, 'Bottle Return');
    expect(item.storeName, 'Unknown');
    expect(item.quantity, 1);
    expect(item.initialQuantity, 1);
    expect(item.unitPrice, 0);
    expect(item.initialAmount, 0);
    expect(item.currentAmount, 0);
    expect(item.amountUnit, isNull);
    expect(item.discounts, <String, double>{'Promo': 1.25});
    expect(item.isDeposit, isTrue);
    expect(item.isDiscount, isTrue);
    expect(item.isReviewOnly, isTrue);
    expect(item.canBeSavedToFridge, isFalse);
  });

  test('uses item-level metadata when present', () {
    final extraction = ReceiptAnalysisExtraction(
      root: const <String, dynamic>{'s': 'Root Store', 'l': 'de_DE'},
      items: const <ReceiptAnalysisItem>[
        ReceiptAnalysisItem(
          name: 'Bread',
          rawPayload: <String, dynamic>{
            'name': 'Bread',
            'storeName': 'Item Store',
            'language': 'en_US',
            'receiptDate': '2026-02-10T08:00:00.000Z',
          },
        ),
      ],
    );

    final item = mapper.map(extraction).single;

    expect(item.storeName, 'Item Store');
    expect(item.language, 'en_US');
    expect(item.receiptDate, DateTime.parse('2026-02-10T08:00:00.000Z'));
  });

  test('maps real Kaufland-style AI payload correctly', () {
    const parser = JsonReceiptAnalysisParser();
    const rawResponse = '''
{"i":[{"b":"Bitburger","c":"Bier","id":false,"if":true,"n":"Pils Stubbi","p":17.98,"q":2,"w":"20x0.33l"},{"b":"Kaufland","c":"Pfand","id":false,"if":false,"n":"Pfandartikel","p":6.2,"q":2,"w":"3.10"},{"b":"Kaufland","c":"Pfand","id":true,"if":false,"n":"Leergut Getränke","p":-6.4,"q":1,"w":"1"}],"l":"de_DE","rd":"2025-12-20","s":"Kaufland"}
''';

    final extraction = parser.parse(rawResponse);
    final items = mapper.map(extraction);

    expect(items, hasLength(3));

    final first = items[0];
    expect(first.name, 'Pils Stubbi');
    expect(first.storeName, 'Kaufland');
    expect(first.brand, 'Bitburger');
    expect(first.category, 'Bier');
    expect(first.weight, '20x0.33l');
    expect(first.initialAmount, 13200);
    expect(first.currentAmount, 13200);
    expect(first.amountUnit, FridgeAmountUnit.milliliter);
    expect(first.quantity, 2);
    expect(first.unitPrice, closeTo(8.99, 0.0001));
    expect(first.isDeposit, isFalse);
    expect(first.isDiscount, isFalse);
    expect(first.language, 'de_DE');
    expect(first.receiptDate, DateTime.parse('2025-12-20'));

    final second = items[1];
    expect(second.name, 'Pfandartikel');
    expect(second.quantity, 2);
    expect(second.unitPrice, closeTo(3.1, 0.0001));
    expect(second.initialAmount, 0);
    expect(second.currentAmount, 0);
    expect(second.amountUnit, isNull);
    expect(second.isDeposit, isTrue);
    expect(second.isDiscount, isFalse);
    expect(second.isReviewOnly, isTrue);

    final third = items[2];
    expect(third.name, 'Leergut Getränke');
    expect(third.unitPrice, closeTo(-6.4, 0.0001));
    expect(third.initialAmount, 0);
    expect(third.currentAmount, 0);
    expect(third.amountUnit, isNull);
    expect(third.isDeposit, isTrue);
    expect(third.isDiscount, isTrue);
    expect(third.language, 'de_DE');
    expect(third.receiptDate, DateTime.parse('2025-12-20'));
    expect(third.isReviewOnly, isTrue);
  });
}
