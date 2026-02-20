import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/l10n/app_localizations.dart';
import 'receipt_item_editor_draft.dart';
import 'receipt_item_editor_form_field_metadata.dart';
import 'receipt_item_editor_inline_error_state.dart';

enum ReceiptWeightUnitFallbackOption {
  auto,
  gram,
  milliliter,
  piece;

  FridgeAmountUnit? resolve({required FridgeAmountUnit? autoFallback}) {
    return switch (this) {
      ReceiptWeightUnitFallbackOption.auto => autoFallback,
      ReceiptWeightUnitFallbackOption.gram => FridgeAmountUnit.gram,
      ReceiptWeightUnitFallbackOption.milliliter => FridgeAmountUnit.milliliter,
      ReceiptWeightUnitFallbackOption.piece => FridgeAmountUnit.piece,
    };
  }

  static ReceiptWeightUnitFallbackOption fromUnit(FridgeAmountUnit? unit) {
    return switch (unit) {
      FridgeAmountUnit.gram => ReceiptWeightUnitFallbackOption.gram,
      FridgeAmountUnit.milliliter => ReceiptWeightUnitFallbackOption.milliliter,
      FridgeAmountUnit.piece => ReceiptWeightUnitFallbackOption.piece,
      null => ReceiptWeightUnitFallbackOption.auto,
    };
  }
}

class ReceiptItemEditorFormValues {
  const ReceiptItemEditorFormValues({
    required this.draft,
    required this.inlineErrors,
    required this.entryDate,
    required this.receiptDate,
    required this.isDeposit,
    required this.isDiscount,
    required this.weightUnitFallbackOption,
  });

  final ReceiptItemEditorDraft draft;
  final ReceiptItemEditorInlineErrorState inlineErrors;
  final DateTime entryDate;
  final DateTime? receiptDate;
  final bool isDeposit;
  final bool isDiscount;
  final ReceiptWeightUnitFallbackOption weightUnitFallbackOption;
}

class ReceiptItemEditorFormActions {
  const ReceiptItemEditorFormActions({
    required this.onPickEntryDate,
    required this.onPickReceiptDate,
    required this.onClearReceiptDate,
    required this.onWeightUnitChanged,
    required this.onIsDepositChanged,
    required this.onIsDiscountChanged,
    required this.onTextChanged,
    required this.onSubmit,
  });

  final Future<void> Function() onPickEntryDate;
  final Future<void> Function() onPickReceiptDate;
  final VoidCallback onClearReceiptDate;
  final ValueChanged<ReceiptWeightUnitFallbackOption> onWeightUnitChanged;
  final ValueChanged<bool> onIsDepositChanged;
  final ValueChanged<bool> onIsDiscountChanged;
  final void Function(ReceiptItemEditorDraftField field, String value)
  onTextChanged;
  final VoidCallback onSubmit;
}

class ReceiptItemEditorFormSection extends StatelessWidget {
  const ReceiptItemEditorFormSection({
    super.key,
    required this.values,
    required this.actions,
  });

  final ReceiptItemEditorFormValues values;
  final ReceiptItemEditorFormActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReceiptEditorTextFieldsGroup(
          fields: ReceiptItemEditorFieldGroups.beforeEntryDate,
          values: values,
          actions: actions,
        ),
        _ReceiptEditorDateField(
          label: l10n.inventoryReceiptReviewFieldEntryDate,
          value: values.entryDate,
          noDateLabel: l10n.inventoryReceiptReviewNoDate,
          onSelectTap: actions.onPickEntryDate,
        ),
        _ReceiptEditorTextFieldsGroup(
          fields: ReceiptItemEditorFieldGroups.beforeWeightUnitFallback,
          values: values,
          actions: actions,
        ),
        _ReceiptEditorWeightUnitField(
          value: values.weightUnitFallbackOption,
          onChanged: actions.onWeightUnitChanged,
        ),
        _ReceiptEditorTextFieldsGroup(
          fields: ReceiptItemEditorFieldGroups.afterWeightUnitFallback,
          values: values,
          actions: actions,
        ),
        _ReceiptEditorDateField(
          label: l10n.inventoryReceiptReviewFieldReceiptDate,
          value: values.receiptDate,
          noDateLabel: l10n.inventoryReceiptReviewNoDate,
          onSelectTap: actions.onPickReceiptDate,
          onClearTap: actions.onClearReceiptDate,
          clearButtonKey: const Key('receipt_review_clear_receipt_date_button'),
        ),
        SwitchListTile.adaptive(
          title: Text(l10n.inventoryReceiptReviewFieldIsDeposit),
          value: values.isDeposit,
          onChanged: actions.onIsDepositChanged,
        ),
        SwitchListTile.adaptive(
          title: Text(l10n.inventoryReceiptReviewFieldIsDiscount),
          value: values.isDiscount,
          onChanged: actions.onIsDiscountChanged,
        ),
      ],
    );
  }
}

class _ReceiptEditorTextFieldsGroup extends StatelessWidget {
  const _ReceiptEditorTextFieldsGroup({
    required this.fields,
    required this.values,
    required this.actions,
  });

  final List<ReceiptItemEditorDraftField> fields;
  final ReceiptItemEditorFormValues values;
  final ReceiptItemEditorFormActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        for (final field in fields)
          _ReceiptEditorTextField(
            field: field,
            value: values.draft.valueFor(field),
            label: field.labelText(l10n),
            keyboardType: field.keyboardType,
            hintText: field.hintText(l10n),
            errorText: values.inlineErrors.errorFor(field),
            onTextChanged: actions.onTextChanged,
            onSubmitted: actions.onSubmit,
          ),
      ],
    );
  }
}

class _ReceiptEditorTextField extends StatelessWidget {
  const _ReceiptEditorTextField({
    required this.field,
    required this.value,
    required this.label,
    required this.keyboardType,
    required this.hintText,
    required this.errorText,
    required this.onTextChanged,
    required this.onSubmitted,
  });

  final ReceiptItemEditorDraftField field;
  final String value;
  final String label;
  final TextInputType? keyboardType;
  final String? hintText;
  final String? errorText;
  final void Function(ReceiptItemEditorDraftField field, String value)
  onTextChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: FormBuilderTextField(
        key: field.fieldKey,
        name: field.name,
        initialValue: value,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.done,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        onSubmitted: (_) => onSubmitted(),
        onChanged: (nextValue) => onTextChanged(field, nextValue ?? ''),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          errorText: errorText,
        ),
      ),
    );
  }
}

class _ReceiptEditorDateField extends StatelessWidget {
  const _ReceiptEditorDateField({
    required this.label,
    required this.value,
    required this.noDateLabel,
    required this.onSelectTap,
    this.onClearTap,
    this.clearButtonKey,
  });

  final String label;
  final DateTime? value;
  final String noDateLabel;
  final Future<void> Function() onSelectTap;
  final VoidCallback? onClearTap;
  final Key? clearButtonKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formattedDate = _formatDate(context, value);
    final valueText = formattedDate ?? noDateLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xxs * 2),
          Text(valueText),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              TextButton(
                onPressed: onSelectTap,
                child: Text(l10n.inventoryReceiptReviewSelectDateAction),
              ),
              if (onClearTap != null)
                TextButton(
                  key: clearButtonKey,
                  onPressed: onClearTap,
                  child: Text(l10n.inventoryReceiptReviewClearDateAction),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptEditorWeightUnitField extends StatelessWidget {
  const _ReceiptEditorWeightUnitField({
    required this.value,
    required this.onChanged,
  });

  static const _fieldName = 'weight_unit_fallback_option';

  final ReceiptWeightUnitFallbackOption value;
  final ValueChanged<ReceiptWeightUnitFallbackOption> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: FormBuilderDropdown<ReceiptWeightUnitFallbackOption>(
        key: const Key('receipt_review_field_weight_unit_fallback'),
        name: _fieldName,
        initialValue: value,
        decoration: InputDecoration(
          labelText: l10n.inventoryReceiptReviewFieldWeightUnitFallback,
        ),
        items: [
          for (final option in ReceiptWeightUnitFallbackOption.values)
            DropdownMenuItem<ReceiptWeightUnitFallbackOption>(
              key: option.optionKey,
              value: option,
              child: Text(option.labelText(l10n)),
            ),
        ],
        onChanged: (nextValue) {
          if (nextValue == null) {
            return;
          }
          onChanged(nextValue);
        },
      ),
    );
  }
}

extension on ReceiptWeightUnitFallbackOption {
  Key get optionKey {
    return switch (this) {
      ReceiptWeightUnitFallbackOption.auto => const Key(
        'receipt_review_weight_unit_option_auto',
      ),
      ReceiptWeightUnitFallbackOption.gram => const Key(
        'receipt_review_weight_unit_option_gram',
      ),
      ReceiptWeightUnitFallbackOption.milliliter => const Key(
        'receipt_review_weight_unit_option_milliliter',
      ),
      ReceiptWeightUnitFallbackOption.piece => const Key(
        'receipt_review_weight_unit_option_piece',
      ),
    };
  }

  String labelText(AppLocalizations l10n) {
    return switch (this) {
      ReceiptWeightUnitFallbackOption.auto =>
        l10n.inventoryReceiptReviewWeightUnitAuto,
      ReceiptWeightUnitFallbackOption.gram =>
        l10n.inventoryReceiptReviewWeightUnitGram,
      ReceiptWeightUnitFallbackOption.milliliter =>
        l10n.inventoryReceiptReviewWeightUnitMilliliter,
      ReceiptWeightUnitFallbackOption.piece =>
        l10n.inventoryReceiptReviewWeightUnitPiece,
    };
  }
}

String? _formatDate(BuildContext context, DateTime? value) {
  if (value == null) {
    return null;
  }
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(locale).format(value);
}
