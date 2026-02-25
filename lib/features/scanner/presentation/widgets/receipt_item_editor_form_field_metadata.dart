import 'package:flutter/material.dart';
import 'package:yamt/l10n/app_localizations.dart';
import '../models/receipt_item_editor_draft.dart';

class ReceiptItemEditorFieldGroups {
  static const beforeEntryDate = <ReceiptItemEditorDraftField>[
    ReceiptItemEditorDraftField.name,
  ];

  static const beforeWeightUnitFallback = <ReceiptItemEditorDraftField>[
    ReceiptItemEditorDraftField.storeName,
    ReceiptItemEditorDraftField.quantity,
    ReceiptItemEditorDraftField.unitPrice,
    ReceiptItemEditorDraftField.weight,
  ];

  static const afterWeightUnitFallback = <ReceiptItemEditorDraftField>[
    ReceiptItemEditorDraftField.brand,
    ReceiptItemEditorDraftField.category,
  ];
}

class ReceiptItemEditorFormFieldName {
  static const entryDate = 'entry_date';
  static const receiptDate = 'receipt_date';
  static const isDeposit = 'is_deposit';
  static const isDiscount = 'is_discount';
  static const weightUnitFallbackOption = 'weight_unit_fallback_option';
}

extension ReceiptItemEditorDraftFieldMetadata on ReceiptItemEditorDraftField {
  Key get fieldKey {
    return switch (this) {
      ReceiptItemEditorDraftField.name => const Key(
        'receipt_review_field_name',
      ),
      ReceiptItemEditorDraftField.storeName => const Key(
        'receipt_review_field_store_name',
      ),
      ReceiptItemEditorDraftField.quantity => const Key(
        'receipt_review_field_quantity',
      ),
      ReceiptItemEditorDraftField.unitPrice => const Key(
        'receipt_review_field_unit_price',
      ),
      ReceiptItemEditorDraftField.weight => const Key(
        'receipt_review_field_weight',
      ),
      ReceiptItemEditorDraftField.brand => const Key(
        'receipt_review_field_brand',
      ),
      ReceiptItemEditorDraftField.category => const Key(
        'receipt_review_field_category',
      ),
      ReceiptItemEditorDraftField.discounts => const Key(
        'receipt_review_field_discounts',
      ),
    };
  }

  TextInputType? get keyboardType {
    return switch (this) {
      ReceiptItemEditorDraftField.quantity => TextInputType.number,
      ReceiptItemEditorDraftField.unitPrice =>
        const TextInputType.numberWithOptions(decimal: true),
      _ => null,
    };
  }

  List<ReceiptItemEditorDraftField> get linkedValidationFields {
    return switch (this) {
      ReceiptItemEditorDraftField.quantity =>
        const <ReceiptItemEditorDraftField>[
          ReceiptItemEditorDraftField.unitPrice,
          ReceiptItemEditorDraftField.weight,
        ],
      ReceiptItemEditorDraftField.unitPrice =>
        const <ReceiptItemEditorDraftField>[
          ReceiptItemEditorDraftField.quantity,
        ],
      _ => const <ReceiptItemEditorDraftField>[],
    };
  }

  String labelText(AppLocalizations l10n) {
    return switch (this) {
      ReceiptItemEditorDraftField.name => l10n.inventoryReceiptReviewFieldName,
      ReceiptItemEditorDraftField.storeName =>
        l10n.inventoryReceiptReviewFieldStoreName,
      ReceiptItemEditorDraftField.quantity =>
        l10n.inventoryReceiptReviewFieldQuantity,
      ReceiptItemEditorDraftField.unitPrice =>
        l10n.inventoryReceiptReviewFieldUnitPrice,
      ReceiptItemEditorDraftField.weight =>
        l10n.inventoryReceiptReviewFieldWeight,
      ReceiptItemEditorDraftField.brand =>
        l10n.inventoryReceiptReviewFieldBrand,
      ReceiptItemEditorDraftField.category =>
        l10n.inventoryReceiptReviewFieldCategory,
      ReceiptItemEditorDraftField.discounts =>
        l10n.inventoryReceiptReviewFieldDiscounts,
    };
  }

  String? hintText(AppLocalizations l10n) {
    return switch (this) {
      ReceiptItemEditorDraftField.discounts =>
        l10n.inventoryReceiptReviewDiscountsHint,
      _ => null,
    };
  }
}
