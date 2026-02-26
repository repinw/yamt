import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_processor.dart';

FridgeItem _item({
  required String id,
  required String name,
  required double unitPrice,
  int quantity = 1,
  bool isDeposit = false,
  bool isDiscount = false,
  String storeName = 'Store',
  DateTime? receiptDate,
}) {
  return FridgeItem(
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

void main() {
  const processor = ReceiptReviewItemProcessor();

  test('merges discount line into previous savable item', () {
    final result = processor.process(<FridgeItem>[
      _item(id: 'item-1', name: 'Gurken', unitPrice: 2.0),
      _item(id: 'discount', name: 'Rabatt', unitPrice: -0.5, isDeposit: true),
    ]);

    expect(result.items, hasLength(1));
    expect(result.items.single.discounts['Rabatt'], -0.5);
  });

  test('merges consecutive discount rows into same previous item', () {
    final result = processor.process(<FridgeItem>[
      _item(id: 'item-1', name: 'Gurken', unitPrice: 2.0),
      _item(id: 'discount-1', name: 'Rabatt A', unitPrice: -0.5),
      _item(id: 'discount-2', name: 'Rabatt B', unitPrice: -0.2),
    ]);

    expect(result.items, hasLength(1));
    expect(result.items.single.discounts['Rabatt A'], -0.5);
    expect(result.items.single.discounts['Rabatt B'], -0.2);
  });

  test('first discount item stays as standalone row', () {
    final result = processor.process(<FridgeItem>[
      _item(id: 'discount', name: 'Rabatt', unitPrice: -0.5),
      _item(id: 'item-1', name: 'Gurken', unitPrice: 2.0),
    ]);

    expect(result.items, hasLength(2));
    expect(result.items.first.isDiscount, isTrue);
    expect(result.items.last.discounts, isEmpty);
  });

  test('leergut line remains standalone deposit row', () {
    final result = processor.process(<FridgeItem>[
      _item(id: 'item-1', name: 'Gurken', unitPrice: 2.0),
      _item(id: 'deposit-1', name: 'Leergut', unitPrice: -0.5),
    ]);

    expect(result.items, hasLength(2));
    expect(result.items.first.discounts, isEmpty);
    expect(result.items.last.isDeposit, isTrue);
    expect(result.items.last.isDiscount, isFalse);
  });

  test('derives store and receipt date metadata from processed items', () {
    final date = DateTime.parse('2026-03-01');
    final result = processor.process(<FridgeItem>[
      _item(
        id: 'item-1',
        name: 'Gurken',
        unitPrice: 2.0,
        storeName: '  ',
        receiptDate: null,
      ),
      _item(
        id: 'item-2',
        name: 'Tomaten',
        unitPrice: 3.0,
        storeName: 'My Store',
        receiptDate: date,
      ),
    ]);

    expect(result.metadata.storeName, 'My Store');
    expect(result.metadata.receiptDate, date);
  });
}
