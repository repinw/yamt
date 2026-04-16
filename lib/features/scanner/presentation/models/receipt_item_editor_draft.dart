import 'dart:convert';

import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Defines receipt item editor draft field.
enum ReceiptItemEditorDraftField {
  /// Documented member.
  name,

  /// Documented member.
  storeName,

  /// Documented member.
  quantity,

  /// Documented member.
  unitPrice,

  /// Documented member.
  weight,

  /// Documented member.
  brand,

  /// Documented member.
  category,

  /// Documented member.
  discounts,
}

/// Defines receipt item editor draft.
class ReceiptItemEditorDraft {
  /// The receipt item editor draft.
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

  /// Creates a [ReceiptItemEditorDraft] for from item.
  factory ReceiptItemEditorDraft.fromItem(InventoryItem item) {
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

  /// The name.
  final String name;

  /// The store name.
  final String storeName;

  /// The quantity text.
  final String quantityText;

  /// The unit price text.
  final String unitPriceText;

  /// The weight text.
  final String weightText;

  /// The brand text.
  final String brandText;

  /// The category text.
  final String categoryText;

  /// The discounts text.
  final String discountsText;

  /// Value for.
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
