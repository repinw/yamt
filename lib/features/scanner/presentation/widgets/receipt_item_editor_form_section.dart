import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/scanner/presentation/models/receipt_item_editor_draft.dart';
import 'package:yamt/features/scanner/presentation/widgets/receipt_item_editor_discount_rows_field.dart';
import 'package:yamt/features/scanner/presentation/widgets/receipt_item_editor_form_field_metadata.dart';
import 'package:yamt/features/scanner/presentation/widgets/receipt_item_editor_weight_unit_fallback_option.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines receipt item editor form section.
class ReceiptItemEditorFormSection extends StatelessWidget {
  /// The receipt item editor form section.
  const ReceiptItemEditorFormSection({
    required this.onSubmit,
    required this.numberValidator,
    required this.weightValidator,
    required this.initialDiscountEntries,
    required this.onDiscountEntriesChanged,
    required this.discountsErrorText,
    this.showDiscountFields = true,
    this.showReviewOnlyFields = true,
    super.key,
  });

  /// The on submit.
  final VoidCallback onSubmit;

  /// The number validator.
  final String? Function(String? value) numberValidator;

  /// The weight validator.
  final String? Function(String? value) weightValidator;

  /// The initial discount entries.
  final List<MapEntry<String, String>> initialDiscountEntries;

  /// The on discount entries changed.
  final ValueChanged<List<MapEntry<String, String>>> onDiscountEntriesChanged;

  /// The discounts error text.
  final String? discountsErrorText;

  /// Whether to show receipt discount fields.
  final bool showDiscountFields;

  /// Whether to show receipt review-only classification fields.
  final bool showReviewOnlyFields;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReceiptEditorTextFieldsGroup(
          fields: ReceiptItemEditorFieldGroups.beforeEntryDate,
          numberValidator: numberValidator,
          weightValidator: weightValidator,
          onSubmit: onSubmit,
        ),
        _ReceiptEditorTextFieldsGroup(
          fields: ReceiptItemEditorFieldGroups.beforeWeightUnitFallback,
          numberValidator: numberValidator,
          weightValidator: weightValidator,
          onSubmit: onSubmit,
        ),
        const _ReceiptEditorWeightUnitField(),
        _ReceiptEditorTextFieldsGroup(
          fields: ReceiptItemEditorFieldGroups.afterWeightUnitFallback,
          numberValidator: numberValidator,
          weightValidator: weightValidator,
          onSubmit: onSubmit,
        ),
        if (showDiscountFields)
          ReceiptEditorDiscountRowsField(
            initialEntries: initialDiscountEntries,
            onChanged: onDiscountEntriesChanged,
            errorText: discountsErrorText,
            onSubmit: onSubmit,
          ),
        if (showReviewOnlyFields) ...[
          _ReceiptEditorSwitchField(
            name: ReceiptItemEditorFormFieldName.isDeposit,
            title: l10n.inventoryReceiptReviewFieldIsDeposit,
          ),
          _ReceiptEditorSwitchField(
            name: ReceiptItemEditorFormFieldName.isDiscount,
            title: l10n.inventoryReceiptReviewFieldIsDiscount,
          ),
        ],
      ],
    );
  }
}

class _ReceiptEditorTextFieldsGroup extends StatelessWidget {
  const _ReceiptEditorTextFieldsGroup({
    required this.fields,
    required this.numberValidator,
    required this.weightValidator,
    required this.onSubmit,
  });

  final List<ReceiptItemEditorDraftField> fields;
  final String? Function(String? value) numberValidator;
  final String? Function(String? value) weightValidator;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        for (final field in fields)
          _ReceiptEditorTextField(
            field: field,
            label: field.labelText(l10n),
            keyboardType: field.keyboardType,
            validator: _validatorFor(field),
            onSubmitted: onSubmit,
          ),
      ],
    );
  }

  String? Function(String? value)? _validatorFor(
    ReceiptItemEditorDraftField field,
  ) {
    return switch (field) {
      ReceiptItemEditorDraftField.quantity ||
      ReceiptItemEditorDraftField.unitPrice => numberValidator,
      ReceiptItemEditorDraftField.weight => weightValidator,
      _ => null,
    };
  }
}

class _ReceiptEditorTextField extends StatelessWidget {
  const _ReceiptEditorTextField({
    required this.field,
    required this.label,
    required this.keyboardType,
    required this.validator,
    required this.onSubmitted,
  });

  final ReceiptItemEditorDraftField field;
  final String label;
  final TextInputType? keyboardType;
  final String? Function(String? value)? validator;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: FormBuilderTextField(
        key: field.fieldKey,
        name: field.name,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.done,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        onSubmitted: (_) => onSubmitted(),
        onChanged: (_) => _revalidateLinkedFields(context),
        validator: validator,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  void _revalidateLinkedFields(BuildContext context) {
    final formState = FormBuilder.of(context);
    if (formState == null) {
      return;
    }
    for (final linkedField in field.linkedValidationFields) {
      formState.fields[linkedField.name]?.validate();
    }
  }
}

class _ReceiptEditorSwitchField extends StatelessWidget {
  const _ReceiptEditorSwitchField({required this.name, required this.title});

  final String name;
  final String title;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<bool>(
      name: name,
      builder: (field) {
        return SwitchListTile.adaptive(
          title: Text(title),
          value: field.value ?? false,
          onChanged: field.didChange,
        );
      },
    );
  }
}

class _ReceiptEditorWeightUnitField extends StatelessWidget {
  const _ReceiptEditorWeightUnitField();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: FormBuilderDropdown<ReceiptWeightUnitFallbackOption>(
        key: const Key('receipt_review_field_weight_unit_fallback'),
        name: ReceiptItemEditorFormFieldName.weightUnitFallbackOption,
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
        onChanged: (_) {
          final formState = FormBuilder.of(context);
          formState?.fields[ReceiptItemEditorDraftField.weight.name]
              ?.validate();
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
