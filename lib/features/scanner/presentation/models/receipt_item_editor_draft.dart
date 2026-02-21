import 'dart:convert';

import 'package:yamt/features/inventory/domain/fridge_item.dart';

enum ReceiptItemEditorDraftField {
  name,
  storeName,
  quantity,
  unitPrice,
  weight,
  brand,
  category,
  discounts,
}

class ReceiptItemEditorDraft {
  const ReceiptItemEditorDraft({
    required this.name,
    required this.storeName,
    required this.quantityText,
    required this.unitPriceText,
    required this.weightText,
    required this.brandText,
    required this.categoryText,
    required this.discountsText,
  });

  factory ReceiptItemEditorDraft.fromItem(FridgeItem item) {
    return ReceiptItemEditorDraft(
      name: item.name,
      storeName: item.storeName,
      quantityText: item.quantity.toString(),
      unitPriceText: item.unitPrice.toString(),
      weightText: item.weight ?? '',
      brandText: item.brand ?? '',
      categoryText: item.category ?? '',
      discountsText: ReceiptItemEditorDraft._encodeDiscounts(item.discounts),
    );
  }

  final String name;
  final String storeName;
  final String quantityText;
  final String unitPriceText;
  final String weightText;
  final String brandText;
  final String categoryText;
  final String discountsText;

  String valueFor(ReceiptItemEditorDraftField field) {
    return switch (field) {
      ReceiptItemEditorDraftField.name => name,
      ReceiptItemEditorDraftField.storeName => storeName,
      ReceiptItemEditorDraftField.quantity => quantityText,
      ReceiptItemEditorDraftField.unitPrice => unitPriceText,
      ReceiptItemEditorDraftField.weight => weightText,
      ReceiptItemEditorDraftField.brand => brandText,
      ReceiptItemEditorDraftField.category => categoryText,
      ReceiptItemEditorDraftField.discounts => discountsText,
    };
  }

  static String _encodeDiscounts(Map<String, double> discounts) {
    if (discounts.isEmpty) {
      return '';
    }
    return jsonEncode(discounts);
  }
}
