import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_processor.dart';

InventoryItem _item({
  required String id,
  required String name,
  required double unitPrice,
  int quantity = 1,
  bool isDeposit = false,
  bool isDiscount = false,
  String storeName = 'Store',
  DateTime? receiptDate,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: storeName,
    quantity: quantity,
    unitPrice: unitPrice,
    isDeposit: isDeposit,
    isDiscount: isDiscount,
    receiptDate: receiptDate,
  );
}

ReceiptReviewItemDraft _draft({
  required String id,
  required String name,
  required double unitPrice,
  int quantity = 1,
  bool isDeposit = false,
  bool isDiscount = false,
  String storeName = 'Store',
  DateTime? receiptDate,
}) {
  return ReceiptReviewItemDraft(
    item: _item(
      id: id,
      name: name,
      unitPrice: unitPrice,
      quantity: quantity,
      isDeposit: isDeposit,
      isDiscount: isDiscount,
      storeName: storeName,
      receiptDate: receiptDate,
    ),
  );
}

void main() {
  const processor = ReceiptReviewItemProcessor();

  test('merges discount line into previous savable item', () {
    final result = processor.process(<ReceiptReviewItemDraft>[
      _draft(id: 'item-1', name: 'Gurken', unitPrice: 2),
      _draft(id: 'discount', name: 'Rabatt', unitPrice: -0.5, isDeposit: true),
    ]);

    expect(result.items, hasLength(1));
    expect(result.items.single.item.discounts['Rabatt'], -0.5);
  });

  test('merges consecutive discount rows into same previous item', () {
    final result = processor.process(<ReceiptReviewItemDraft>[
      _draft(id: 'item-1', name: 'Gurken', unitPrice: 2),
      _draft(id: 'discount-1', name: 'Rabatt A', unitPrice: -0.5),
      _draft(id: 'discount-2', name: 'Rabatt B', unitPrice: -0.2),
    ]);

    expect(result.items, hasLength(1));
    expect(result.items.single.item.discounts['Rabatt A'], -0.5);
    expect(result.items.single.item.discounts['Rabatt B'], -0.2);
  });

  test('first discount item stays as standalone row', () {
    final result = processor.process(<ReceiptReviewItemDraft>[
      _draft(id: 'discount', name: 'Rabatt', unitPrice: -0.5),
      _draft(id: 'item-1', name: 'Gurken', unitPrice: 2),
    ]);

    expect(result.items, hasLength(2));
    expect(result.items.first.item.isDiscount, isTrue);
    expect(result.items.last.item.discounts, isEmpty);
  });

  test('leergut line remains standalone deposit row', () {
    final result = processor.process(<ReceiptReviewItemDraft>[
      _draft(id: 'item-1', name: 'Gurken', unitPrice: 2),
      _draft(id: 'deposit-1', name: 'Leergut', unitPrice: -0.5),
    ]);

    expect(result.items, hasLength(2));
    expect(result.items.first.item.discounts, isEmpty);
    expect(result.items.last.item.isDeposit, isTrue);
    expect(result.items.last.item.isDiscount, isFalse);
  });

  test(
    'moves likely non-food rows to bottom but keeps deposit rows in place',
    () {
      final result = processor.process(<ReceiptReviewItemDraft>[
        _draft(id: 'food-1', name: 'Gurken', unitPrice: 2),
        _draft(
          id: 'non-food-1',
          name: 'Toilettenpapier',
          unitPrice: 4,
          isDeposit: true,
        ),
        _draft(
          id: 'deposit-1',
          name: 'Pfand',
          unitPrice: 0.25,
          isDeposit: true,
        ),
      ]);

      expect(
        result.items.map((draft) => draft.item.name).toList(),
        <String>['Gurken', 'Pfand', 'Toilettenpapier'],
      );
    },
  );

  test('keeps regular savable rows in place when not flagged as non-food', () {
    final result = processor.process(<ReceiptReviewItemDraft>[
      _draft(id: 'food-1', name: 'Gurken', unitPrice: 2),
      _draft(id: 'food-2', name: 'Tomaten', unitPrice: 3),
    ]);

    expect(
      result.items.map((draft) => draft.item.name).toList(),
      <String>['Gurken', 'Tomaten'],
    );
  });

  test('derives store and receipt date metadata from processed items', () {
    final date = DateTime.parse('2026-03-01');
    final result = processor.process(<ReceiptReviewItemDraft>[
      _draft(
        id: 'item-1',
        name: 'Gurken',
        unitPrice: 2,
        storeName: '  ',
      ),
      _draft(
        id: 'item-2',
        name: 'Tomaten',
        unitPrice: 3,
        storeName: 'My Store',
        receiptDate: date,
      ),
    ]);

    expect(result.metadata.storeName, 'My Store');
    expect(result.metadata.receiptDate, date);
  });
}
