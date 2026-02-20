import 'dart:convert';

import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/domain/receipt_item_editor_updater.dart';

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
      discountsText: _encodeDiscounts(item.discounts),
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

  ReceiptItemEditorDraft copyWith({
    String? name,
    String? storeName,
    String? quantityText,
    String? unitPriceText,
    String? weightText,
    String? brandText,
    String? categoryText,
    String? discountsText,
  }) {
    return ReceiptItemEditorDraft(
      name: name ?? this.name,
      storeName: storeName ?? this.storeName,
      quantityText: quantityText ?? this.quantityText,
      unitPriceText: unitPriceText ?? this.unitPriceText,
      weightText: weightText ?? this.weightText,
      brandText: brandText ?? this.brandText,
      categoryText: categoryText ?? this.categoryText,
      discountsText: discountsText ?? this.discountsText,
    );
  }

  ReceiptItemEditorDraft withField(
    ReceiptItemEditorDraftField field,
    String value,
  ) {
    return switch (field) {
      ReceiptItemEditorDraftField.name => copyWith(name: value),
      ReceiptItemEditorDraftField.storeName => copyWith(storeName: value),
      ReceiptItemEditorDraftField.quantity => copyWith(quantityText: value),
      ReceiptItemEditorDraftField.unitPrice => copyWith(unitPriceText: value),
      ReceiptItemEditorDraftField.weight => copyWith(weightText: value),
      ReceiptItemEditorDraftField.brand => copyWith(brandText: value),
      ReceiptItemEditorDraftField.category => copyWith(categoryText: value),
      ReceiptItemEditorDraftField.discounts => copyWith(discountsText: value),
    };
  }

  ReceiptItemEditorFormData toFormData({
    required DateTime entryDate,
    required DateTime? receiptDate,
    required bool isDeposit,
    required bool isDiscount,
  }) {
    return ReceiptItemEditorFormData(
      name: name,
      entryDate: entryDate,
      storeName: storeName,
      quantityText: quantityText,
      unitPriceText: unitPriceText,
      weightText: weightText,
      brandText: brandText,
      categoryText: categoryText,
      discountsText: discountsText,
      receiptDate: receiptDate,
      isDeposit: isDeposit,
      isDiscount: isDiscount,
    );
  }
}

String _encodeDiscounts(Map<String, double> discounts) {
  if (discounts.isEmpty) {
    return '';
  }
  return jsonEncode(discounts);
}
