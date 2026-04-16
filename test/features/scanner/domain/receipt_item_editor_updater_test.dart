import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/domain/receipt_item_editor_updater.dart';

InventoryItem _sourceItem() {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Original',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Original Store',
    quantity: 1,
    unitPrice: 1.5,
  );
}

ReceiptItemEditorFormData _formData({
  String name = 'Edited',
  DateTime? entryDate,
  String storeName = 'Edited Store',
  String quantityText = '1',
  String unitPriceText = '1.50',
  String weightText = '250g',
  String brandText = 'Brand',
  String categoryText = 'Category',
  List<MapEntry<String, String>> discountEntries =
      const <MapEntry<String, String>>[],
  DateTime? receiptDate,
  bool isDeposit = false,
  bool isDiscount = false,
}) {
  return ReceiptItemEditorFormData(
    name: name,
    entryDate: entryDate ?? DateTime.parse('2026-02-20T10:00:00Z'),
    storeName: storeName,
    quantityText: quantityText,
    unitPriceText: unitPriceText,
    weightText: weightText,
    brandText: brandText,
    categoryText: categoryText,
    discountEntries: discountEntries,
    receiptDate: receiptDate,
    isDeposit: isDeposit,
    isDiscount: isDiscount,
  );
}

void main() {
  const updater = ReceiptItemEditorUpdater();

  test('apply returns updated item for valid form values', () {
    final result = updater.apply(
      sourceItem: _sourceItem(),
      formData: _formData(
        name: ' ',
        storeName: ' Edited Store ',
        quantityText: '2',
        unitPriceText: '3.50',
        brandText: ' ',
        categoryText: ' Dairy ',
        discountEntries: const <MapEntry<String, String>>[
          MapEntry<String, String>('coupon', '1.00'),
        ],
        receiptDate: DateTime.parse('2026-01-05'),
        isDeposit: true,
      ),
      locale: 'en_US',
      fallbackUnit: null,
    );

    expect(result, isA<ReceiptItemEditorApplySuccess>());
    final updated = (result as ReceiptItemEditorApplySuccess).item;

    expect(updated.name, 'Original');
    expect(updated.entryDate, DateTime.parse('2026-02-20T10:00:00Z'));
    expect(updated.storeName, 'Edited Store');
    expect(updated.quantity, 2);
    expect(updated.initialQuantity, 2);
    expect(updated.unitPrice, 3.5);
    expect(updated.weight, '250g');
    expect(updated.initialAmount, 500);
    expect(updated.currentAmount, 500);
    expect(updated.amountUnit, InventoryAmountUnit.gram);
    expect(updated.brand, isNull);
    expect(updated.category, 'Dairy');
    expect(updated.discounts, <String, double>{'coupon': -1.0});
    expect(updated.receiptDate, DateTime.parse('2026-01-05'));
    expect(updated.isDeposit, isTrue);
    expect(updated.isDiscount, isFalse);
  });

  test('apply normalizes Aldi store variants', () {
    final result = updater.apply(
      sourceItem: _sourceItem(),
      formData: _formData(storeName: ' ALDI Süd '),
      locale: 'en_US',
      fallbackUnit: null,
    );

    expect(result, isA<ReceiptItemEditorApplySuccess>());
    final updated = (result as ReceiptItemEditorApplySuccess).item;
    expect(updated.storeName, 'Aldi');
  });

  test('apply returns invalidNumber for invalid number input', () {
    final result = updater.apply(
      sourceItem: _sourceItem(),
      formData: _formData(quantityText: 'abc'),
      locale: 'en_US',
      fallbackUnit: null,
    );

    expect(result, isA<ReceiptItemEditorApplyFailure>());
    final failure = result as ReceiptItemEditorApplyFailure;
    expect(failure.error, ReceiptItemEditorApplyError.invalidNumber);
  });

  test('apply returns invalidDiscounts for invalid discount input', () {
    final result = updater.apply(
      sourceItem: _sourceItem(),
      formData: _formData(
        discountEntries: const <MapEntry<String, String>>[
          MapEntry<String, String>('coupon', 'abc'),
        ],
      ),
      locale: 'en_US',
      fallbackUnit: null,
    );

    expect(result, isA<ReceiptItemEditorApplyFailure>());
    final failure = result as ReceiptItemEditorApplyFailure;
    expect(failure.error, ReceiptItemEditorApplyError.invalidDiscounts);
  });

  test('apply returns invalidWeightUnit when unit cannot be resolved', () {
    final result = updater.apply(
      sourceItem: _sourceItem(),
      formData: _formData(weightText: '500'),
      locale: 'en_US',
      fallbackUnit: null,
    );

    expect(result, isA<ReceiptItemEditorApplyFailure>());
    final failure = result as ReceiptItemEditorApplyFailure;
    expect(failure.error, ReceiptItemEditorApplyError.invalidWeightUnit);
  });

  test('apply accepts no-unit weight when fallback unit is set', () {
    final result = updater.apply(
      sourceItem: _sourceItem(),
      formData: _formData(weightText: '500'),
      locale: 'en_US',
      fallbackUnit: InventoryAmountUnit.gram,
    );

    expect(result, isA<ReceiptItemEditorApplySuccess>());
    final updated = (result as ReceiptItemEditorApplySuccess).item;
    expect(updated.initialAmount, 500);
    expect(updated.currentAmount, 500);
    expect(updated.amountUnit, InventoryAmountUnit.gram);
  });

  test('apply normalizes savable zero quantity to one', () {
    final result = updater.apply(
      sourceItem: _sourceItem(),
      formData: _formData(quantityText: '0'),
      locale: 'en_US',
      fallbackUnit: null,
    );

    expect(result, isA<ReceiptItemEditorApplySuccess>());
    final updated = (result as ReceiptItemEditorApplySuccess).item;
    expect(updated.quantity, 1);
    expect(updated.initialQuantity, 1);
    expect(updated.initialAmount, 250);
  });

  test('apply keeps review-only zero quantity at zero', () {
    final result = updater.apply(
      sourceItem: _sourceItem(),
      formData: _formData(
        quantityText: '0',
        isDeposit: true,
      ),
      locale: 'en_US',
      fallbackUnit: null,
    );

    expect(result, isA<ReceiptItemEditorApplySuccess>());
    final updated = (result as ReceiptItemEditorApplySuccess).item;
    expect(updated.quantity, 0);
    expect(updated.initialQuantity, 0);
    expect(updated.initialAmount, 0);
  });
}
