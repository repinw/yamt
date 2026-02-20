import 'package:yamt/features/scanner/domain/receipt_item_editor_updater.dart';
import 'receipt_item_editor_draft.dart';

class _Unset {
  const _Unset();
}

class ReceiptItemEditorInlineErrorState {
  const ReceiptItemEditorInlineErrorState({
    this.quantityText,
    this.unitPriceText,
    this.weightText,
    this.discountsText,
  });

  static const empty = ReceiptItemEditorInlineErrorState();

  final String? quantityText;
  final String? unitPriceText;
  final String? weightText;
  final String? discountsText;

  bool get hasNumberError => quantityText != null || unitPriceText != null;

  bool get hasWeightError => weightText != null;

  bool get hasDiscountsError => discountsText != null;

  String? errorFor(ReceiptItemEditorDraftField field) {
    return switch (field) {
      ReceiptItemEditorDraftField.quantity => quantityText,
      ReceiptItemEditorDraftField.unitPrice => unitPriceText,
      ReceiptItemEditorDraftField.weight => weightText,
      ReceiptItemEditorDraftField.discounts => discountsText,
      _ => null,
    };
  }

  static const _unset = _Unset();

  ReceiptItemEditorInlineErrorState copyWith({
    Object? quantityText = _unset,
    Object? unitPriceText = _unset,
    Object? weightText = _unset,
    Object? discountsText = _unset,
  }) {
    return ReceiptItemEditorInlineErrorState(
      quantityText: _resolveTextValue(quantityText, this.quantityText),
      unitPriceText: _resolveTextValue(unitPriceText, this.unitPriceText),
      weightText: _resolveTextValue(weightText, this.weightText),
      discountsText: _resolveTextValue(discountsText, this.discountsText),
    );
  }

  ReceiptItemEditorInlineErrorState withApplyError({
    required ReceiptItemEditorApplyError error,
    required String errorText,
  }) {
    return switch (error) {
      ReceiptItemEditorApplyError.invalidNumber =>
        ReceiptItemEditorInlineErrorState(
          quantityText: errorText,
          unitPriceText: errorText,
        ),
      ReceiptItemEditorApplyError.invalidDiscounts =>
        ReceiptItemEditorInlineErrorState(discountsText: errorText),
      ReceiptItemEditorApplyError.invalidWeightUnit =>
        ReceiptItemEditorInlineErrorState(weightText: errorText),
    };
  }

  ReceiptItemEditorInlineErrorState clearNumbers() {
    return copyWith(
      quantityText: null,
      unitPriceText: null,
      weightText: _unset,
      discountsText: _unset,
    );
  }

  ReceiptItemEditorInlineErrorState clearWeight() {
    return copyWith(
      quantityText: _unset,
      unitPriceText: _unset,
      weightText: null,
      discountsText: _unset,
    );
  }

  ReceiptItemEditorInlineErrorState clearDiscounts() {
    return copyWith(
      quantityText: _unset,
      unitPriceText: _unset,
      weightText: _unset,
      discountsText: null,
    );
  }

  String? _resolveTextValue(Object? value, String? current) {
    if (identical(value, _unset)) {
      return current;
    }
    return value as String?;
  }
}
