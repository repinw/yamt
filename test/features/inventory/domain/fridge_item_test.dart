import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';

FridgeItem _quantityItem({
  required int quantity,
  required int initialQuantity,
}) {
  return FridgeItem(
    id: 'item-1',
    name: 'Milk',
    entryDate: DateTime.parse('2026-02-20T08:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: initialQuantity,
    unitPrice: 1.0,
  );
}

FridgeItem _amountItem({
  required int currentAmount,
  required int initialAmount,
}) {
  return FridgeItem(
    id: 'item-2',
    name: 'Juice',
    entryDate: DateTime.parse('2026-02-20T08:00:00Z'),
    storeName: 'Store',
    quantity: 2,
    initialQuantity: 2,
    unitPrice: 1.0,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountUnit: FridgeAmountUnit.milliliter,
  );
}

void main() {
  test('quantity-based items are consumed when quantity drops', () {
    final untouched = _quantityItem(quantity: 3, initialQuantity: 3);
    final partiallyConsumed = _quantityItem(quantity: 2, initialQuantity: 3);
    final fullyConsumed = _quantityItem(quantity: 0, initialQuantity: 3);

    expect(untouched.usesAmountProgress, isFalse);
    expect(untouched.isConsumed, isFalse);
    expect(untouched.isFullyConsumed, isFalse);

    expect(partiallyConsumed.isConsumed, isTrue);
    expect(partiallyConsumed.isFullyConsumed, isFalse);

    expect(fullyConsumed.isConsumed, isTrue);
    expect(fullyConsumed.isFullyConsumed, isTrue);
  });

  test('amount-based items are consumed when current amount drops', () {
    final untouched = _amountItem(currentAmount: 1000, initialAmount: 1000);
    final partiallyConsumed = _amountItem(
      currentAmount: 350,
      initialAmount: 1000,
    );
    final fullyConsumed = _amountItem(currentAmount: 0, initialAmount: 1000);

    expect(untouched.usesAmountProgress, isTrue);
    expect(untouched.isConsumed, isFalse);
    expect(untouched.isFullyConsumed, isFalse);

    expect(partiallyConsumed.isConsumed, isTrue);
    expect(partiallyConsumed.isFullyConsumed, isFalse);

    expect(fullyConsumed.isConsumed, isTrue);
    expect(fullyConsumed.isFullyConsumed, isTrue);
  });

  test('barcode status resolves pending and missing states', () {
    final missing = _quantityItem(quantity: 1, initialQuantity: 1);
    final pending = missing.copyWith(
      barcodeLookupRequestedAt: DateTime.parse('2026-02-20T10:00:00Z'),
    );
    final resolved = pending.copyWith(
      barcode: '4006381333931',
      barcodeResolvedAt: DateTime.parse('2026-02-20T10:05:00Z'),
    );

    expect(missing.barcodeStatus, InventoryBarcodeStatus.missing);
    expect(pending.barcodeStatus, InventoryBarcodeStatus.pending);
    expect(resolved.barcodeStatus, InventoryBarcodeStatus.resolved);
  });

  test('resolvedFoodFingerprint falls back to normalized name and brand', () {
    final item = _quantityItem(quantity: 1, initialQuantity: 1).copyWith(
      name: 'Organic Milk 3.5%',
      brand: 'Acme Foods',
      foodFingerprint: null,
    );

    expect(item.resolvedFoodFingerprint, 'organic_milk_3_5__acme_foods');
  });
}
