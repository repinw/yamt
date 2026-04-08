import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_parser.dart';
import 'package:yamt/features/scanner/data/receipt_to_review_item_draft_mapper.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';

void main() {
  final fixedNow = DateTime.parse('2026-02-19T10:30:00.000Z');
  final mapper = DefaultReceiptToReviewItemDraftMapper(now: () => fixedNow);

  test('maps minified receipt payload with root fallbacks', () {
    final extraction = ReceiptAnalysisExtraction(
      root: <String, dynamic>{
        's': 'Lidl',
        'rd': '2026-02-18T12:00:00.000Z',
        'l': 'de_DE',
        'currency': 'EUR',
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

    final drafts = mapper.map(extraction);

    expect(drafts, hasLength(1));
    final item = drafts.single.item;
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
    expect(item.amountUnit, InventoryAmountUnit.milliliter);
    expect(item.brand, 'Milbona');
    expect(item.category, 'Dairy');
    expect(item.discounts, <String, double>{'Coupon': 0.5});
    expect(item.language, 'de_DE');
    expect(item.currencyCode, 'EUR');
    expect(item.receiptDate, DateTime.parse('2026-02-18T12:00:00.000Z'));
    expect(item.entryDate, fixedNow);
    expect(item.ocrName, 'Milk');
    expect(item.isDeposit, isFalse);
    expect(item.isDiscount, isFalse);
    expect(drafts.single.canBeSavedToInventory, isTrue);
  });

  test('normalizes Aldi store variants during mapping', () {
    final extraction = ReceiptAnalysisExtraction(
      root: <String, dynamic>{'s': 'Aldi Süd'},
      items: const <ReceiptAnalysisItem>[
        ReceiptAnalysisItem(
          name: 'Lasagne',
          rawPayload: <String, dynamic>{
            'n': 'Lasagne Bolognese',
            'storeName': 'ALDI SUED',
            'if': true,
          },
        ),
      ],
    );

    final drafts = mapper.map(extraction);

    expect(drafts.single.item.storeName, 'Aldi');
  });

  test('keeps non-food discount lines as review-only drafts', () {
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

    final draft = mapper.map(extraction).single;
    final item = draft.item;

    expect(item.name, 'Bottle Return');
    expect(item.storeName, 'Unknown');
    expect(item.quantity, 0);
    expect(item.initialQuantity, 0);
    expect(item.unitPrice, 0);
    expect(item.initialAmount, 0);
    expect(item.currentAmount, 0);
    expect(item.amountUnit, isNull);
    expect(item.discounts, <String, double>{'Promo': 1.25});
    expect(item.isDeposit, isTrue);
    expect(item.isDiscount, isTrue);
    expect(item.isReviewOnly, isTrue);
    expect(draft.canBeSavedToInventory, isFalse);
  });

  test('normalizes savable zero quantity to one', () {
    final extraction = ReceiptAnalysisExtraction(
      root: const <String, dynamic>{},
      items: const <ReceiptAnalysisItem>[
        ReceiptAnalysisItem(
          name: 'Milk',
          rawPayload: <String, dynamic>{
            'name': 'Milk',
            'quantity': 0,
            'totalPrice': 2.49,
            'isFood': true,
            'isDiscount': false,
          },
        ),
      ],
    );

    final item = mapper.map(extraction).single.item;

    expect(item.quantity, 1);
    expect(item.initialQuantity, 1);
    expect(item.unitPrice, 2.49);
  });

  test('reparses piece amount from name when weight is missing', () {
    final extraction = ReceiptAnalysisExtraction(
      root: const <String, dynamic>{},
      items: const <ReceiptAnalysisItem>[
        ReceiptAnalysisItem(
          name: 'bunte eier bh 10st',
          rawPayload: <String, dynamic>{'n': 'bunte eier bh 10st', 'p': '2,49'},
        ),
      ],
    );

    final item = mapper.map(extraction).single.item;

    expect(item.quantity, 10);
    expect(item.initialQuantity, 10);
    expect(item.weight, isNull);
    expect(item.initialAmount, 0);
    expect(item.currentAmount, 0);
    expect(item.amountUnit, isNull);
  });

  test('reparses multipack volume from name', () {
    final extraction = ReceiptAnalysisExtraction(
      root: const <String, dynamic>{},
      items: const <ReceiptAnalysisItem>[
        ReceiptAnalysisItem(
          name: 'Wasser 6x 1.5l',
          rawPayload: <String, dynamic>{'n': 'Wasser 6x 1.5l', 'p': '5,99'},
        ),
      ],
    );

    final item = mapper.map(extraction).single.item;

    expect(item.quantity, 6);
    expect(item.initialQuantity, 6);
    expect(item.weight, '1.5l');
    expect(item.initialAmount, 9000);
    expect(item.currentAmount, 9000);
    expect(item.amountUnit, InventoryAmountUnit.milliliter);
  });

  test('item currency overrides root currency during mapping', () {
    final extraction = ReceiptAnalysisExtraction(
      root: const <String, dynamic>{'currency': 'EUR'},
      items: const <ReceiptAnalysisItem>[
        ReceiptAnalysisItem(
          name: 'Imported snack',
          rawPayload: <String, dynamic>{
            'n': 'Imported snack',
            'q': 1,
            'p': 2.5,
            'currencyCode': 'USD',
          },
        ),
      ],
    );

    final item = mapper.map(extraction).single.item;

    expect(item.currencyCode, 'USD');
  });

  test('maps Kaufland-style AI payload into review drafts', () {
    const parser = JsonReceiptAnalysisParser();
    const rawResponse = '''
{"i":[{"b":"Bitburger","c":"Bier","id":false,"if":true,"n":"Pils Stubbi","p":17.98,"q":2,"w":"20x0.33l"},{"b":"Kaufland","c":"Pfand","id":false,"if":false,"n":"Pfandartikel","p":6.2,"q":2,"w":"3.10"},{"b":"Kaufland","c":"Pfand","id":true,"if":false,"n":"Leergut Getränke","p":-6.4,"q":1,"w":"1"}],"l":"de_DE","rd":"2025-12-20","s":"Kaufland"}
''';

    final extraction = parser.parse(rawResponse);
    final drafts = mapper.map(extraction);

    expect(drafts, hasLength(3));

    final first = drafts[0].item;
    expect(first.name, 'Pils Stubbi');
    expect(first.storeName, 'Kaufland');
    expect(first.brand, 'Bitburger');
    expect(first.category, 'Bier');
    expect(first.weight, '20x0.33l');
    expect(first.initialAmount, 13200);
    expect(first.currentAmount, 13200);
    expect(first.amountUnit, InventoryAmountUnit.milliliter);
    expect(first.quantity, 2);
    expect(first.unitPrice, closeTo(8.99, 0.0001));
    expect(first.isDeposit, isFalse);
    expect(first.isDiscount, isFalse);

    final second = drafts[1].item;
    expect(second.name, 'Pfandartikel');
    expect(second.isReviewOnly, isTrue);
    expect(drafts[1].canBeSavedToInventory, isFalse);

    final third = drafts[2].item;
    expect(third.name, 'Leergut Getränke');
    expect(third.isDeposit, isTrue);
    expect(third.isDiscount, isTrue);
    expect(third.isReviewOnly, isTrue);
  });
}
