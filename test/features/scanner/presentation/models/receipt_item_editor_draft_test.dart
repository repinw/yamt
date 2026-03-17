import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/presentation/models/'
    'receipt_item_editor_draft.dart';

void main() {
  test('fromItem maps item fields and encodes discounts', () {
    final item = InventoryItem.create(
      id: 'item-1',
      name: 'Milk',
      entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
      storeName: 'Store',
      quantity: 2,
      unitPrice: 3.5,
      weight: '500g',
      brand: 'Brand',
      category: 'Dairy',
      discounts: const <String, double>{'coupon': 1.0},
    );

    final draft = ReceiptItemEditorDraft.fromItem(item);

    expect(draft.name, 'Milk');
    expect(draft.storeName, 'Store');
    expect(draft.quantityText, '2');
    expect(draft.unitPriceText, '3.5');
    expect(draft.weightText, '500g');
    expect(draft.brandText, 'Brand');
    expect(draft.categoryText, 'Dairy');
    expect(jsonDecode(draft.discountsText), <String, dynamic>{'coupon': 1.0});
  });

  test('fromItem uses empty strings for nullables and empty discounts', () {
    final item = InventoryItem.create(
      id: 'item-1',
      name: 'Milk',
      entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
      storeName: 'Store',
      quantity: 1,
      unitPrice: 1.0,
    );

    final draft = ReceiptItemEditorDraft.fromItem(item);

    expect(draft.weightText, isEmpty);
    expect(draft.brandText, isEmpty);
    expect(draft.categoryText, isEmpty);
    expect(draft.discountsText, isEmpty);
  });

  test('valueFor maps every draft field to the expected value', () {
    const draft = ReceiptItemEditorDraft(
      name: 'Name',
      storeName: 'Store',
      quantityText: '3',
      unitPriceText: '4.2',
      weightText: '250g',
      brandText: 'Brand',
      categoryText: 'Category',
      discountsText: '{"coupon":1.0}',
    );

    final expectedValues = <ReceiptItemEditorDraftField, String>{
      ReceiptItemEditorDraftField.name: 'Name',
      ReceiptItemEditorDraftField.storeName: 'Store',
      ReceiptItemEditorDraftField.quantity: '3',
      ReceiptItemEditorDraftField.unitPrice: '4.2',
      ReceiptItemEditorDraftField.weight: '250g',
      ReceiptItemEditorDraftField.brand: 'Brand',
      ReceiptItemEditorDraftField.category: 'Category',
      ReceiptItemEditorDraftField.discounts: '{"coupon":1.0}',
    };

    for (final field in ReceiptItemEditorDraftField.values) {
      expect(draft.valueFor(field), expectedValues[field]);
    }
  });
}
