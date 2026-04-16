import 'package:flutter/material.dart';
import 'package:yamt/features/scanner/presentation/models/receipt_item_editor_draft.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines receipt item editor field groups.
class ReceiptItemEditorFieldGroups {
  /// The before entry date.
  static const beforeEntryDate = <ReceiptItemEditorDraftField>[
    ReceiptItemEditorDraftField.name,
  ];

  /// The before weight unit fallback.
  static const beforeWeightUnitFallback = <ReceiptItemEditorDraftField>[
    ReceiptItemEditorDraftField.quantity,
    ReceiptItemEditorDraftField.unitPrice,
    ReceiptItemEditorDraftField.weight,
  ];

  /// The after weight unit fallback.
  static const afterWeightUnitFallback = <ReceiptItemEditorDraftField>[
    ReceiptItemEditorDraftField.brand,
    ReceiptItemEditorDraftField.category,
  ];
}

/// Defines receipt item editor form field name.
class ReceiptItemEditorFormFieldName {
  /// Whether deposit.
  static const isDeposit = 'is_deposit';

  /// Whether discount.
  static const isDiscount = 'is_discount';

  /// The weight unit fallback option.
  static const weightUnitFallbackOption = 'weight_unit_fallback_option';
}

/// Defines receipt item editor draft field metadata extension.
extension ReceiptItemEditorDraftFieldMetadata on ReceiptItemEditorDraftField {
  /// The field key.
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

  /// The keyboard type.
  TextInputType? get keyboardType {
    return switch (this) {
      ReceiptItemEditorDraftField.quantity => TextInputType.number,
      ReceiptItemEditorDraftField.unitPrice =>
        const TextInputType.numberWithOptions(decimal: true),
      _ => null,
    };
  }

  /// The linked validation fields.
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

  /// Label text.
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
}
