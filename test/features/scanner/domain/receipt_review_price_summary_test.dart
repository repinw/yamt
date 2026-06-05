import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/domain/receipt_review_price_summary.dart';

InventoryItem _item({
  required String id,
  required int quantity,
  required double unitPrice,
  bool isDeposit = false,
  bool isDiscount = false,
  Map<String, double> discounts = const <String, double>{},
}) {
  return InventoryItem.create(
    id: id,
    name: 'Item $id',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: quantity,
    unitPrice: unitPrice,
    discounts: discounts,
    isDeposit: isDeposit,
    isDiscount: isDiscount,
  );
}

ReceiptReviewItemDraft _draft({
  required String id,
  required int quantity,
  required double unitPrice,
  bool isDeposit = false,
  bool isDiscount = false,
  Map<String, double> discounts = const <String, double>{},
}) {
  return ReceiptReviewItemDraft(
    item: _item(
      id: id,
      quantity: quantity,
      unitPrice: unitPrice,
      isDeposit: isDeposit,
      isDiscount: isDiscount,
      discounts: discounts,
    ),
  );
}

void main() {
  const calculator = ReceiptReviewPriceSummaryCalculator();

  test('calculate returns total, storable and excluded sums', () {
    final summary = calculator.calculate([
      _draft(id: 'food-1', quantity: 2, unitPrice: 1.5),
      _draft(id: 'food-2', quantity: 1, unitPrice: 2),
      _draft(id: 'deposit', quantity: 1, unitPrice: 0.25, isDeposit: true),
    ]);

    expect(summary.totalPrice, 5.25);
    expect(summary.storablePrice, 5.0);
    expect(summary.excludedPrice, 0.25);
  });

  test('calculate returns zeros for empty item list', () {
    final summary = calculator.calculate(const <ReceiptReviewItemDraft>[]);

    expect(summary.totalPrice, 0.0);
    expect(summary.storablePrice, 0.0);
    expect(summary.excludedPrice, 0.0);
  });

  test('calculate includes merged discounts in totals', () {
    final summary = calculator.calculate([
      _draft(
        id: 'food-1',
        quantity: 2,
        unitPrice: 1.5,
        discounts: const <String, double>{'Rabatt': -0.5},
      ),
      _draft(id: 'food-2', quantity: 1, unitPrice: 2),
      _draft(id: 'deposit', quantity: 1, unitPrice: 0.25, isDeposit: true),
    ]);

    expect(summary.totalPrice, 4.75);
    expect(summary.storablePrice, 4.5);
    expect(summary.excludedPrice, 0.25);
  });
}
