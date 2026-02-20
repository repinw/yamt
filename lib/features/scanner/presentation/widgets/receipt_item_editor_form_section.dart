import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';
import '../models/receipt_item_editor_draft.dart';
import 'receipt_item_editor_form_field_metadata.dart';
import 'receipt_item_editor_weight_unit_fallback_option.dart';

typedef ReceiptItemEditorTextValidator = String? Function(String? value);

class ReceiptItemEditorFormSection extends StatelessWidget {
  const ReceiptItemEditorFormSection({
    super.key,
    required this.onSubmit,
    required this.numberValidator,
    required this.weightValidator,
    required this.discountsValidator,
  });

  final VoidCallback onSubmit;
  final ReceiptItemEditorTextValidator numberValidator;
  final ReceiptItemEditorTextValidator weightValidator;
  final ReceiptItemEditorTextValidator discountsValidator;

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
          discountsValidator: discountsValidator,
          onSubmit: onSubmit,
        ),
        _ReceiptEditorDateField(
          name: ReceiptItemEditorFormFieldName.entryDate,
          label: l10n.inventoryReceiptReviewFieldEntryDate,
          noDateLabel: l10n.inventoryReceiptReviewNoDate,
        ),
        _ReceiptEditorTextFieldsGroup(
          fields: ReceiptItemEditorFieldGroups.beforeWeightUnitFallback,
          numberValidator: numberValidator,
          weightValidator: weightValidator,
          discountsValidator: discountsValidator,
          onSubmit: onSubmit,
        ),
        const _ReceiptEditorWeightUnitField(),
        _ReceiptEditorTextFieldsGroup(
          fields: ReceiptItemEditorFieldGroups.afterWeightUnitFallback,
          numberValidator: numberValidator,
          weightValidator: weightValidator,
          discountsValidator: discountsValidator,
          onSubmit: onSubmit,
        ),
        _ReceiptEditorDateField(
          name: ReceiptItemEditorFormFieldName.receiptDate,
          label: l10n.inventoryReceiptReviewFieldReceiptDate,
          noDateLabel: l10n.inventoryReceiptReviewNoDate,
          allowClear: true,
          clearButtonKey: const Key('receipt_review_clear_receipt_date_button'),
        ),
        _ReceiptEditorSwitchField(
          name: ReceiptItemEditorFormFieldName.isDeposit,
          title: l10n.inventoryReceiptReviewFieldIsDeposit,
        ),
        _ReceiptEditorSwitchField(
          name: ReceiptItemEditorFormFieldName.isDiscount,
          title: l10n.inventoryReceiptReviewFieldIsDiscount,
        ),
      ],
    );
  }
}

class _ReceiptEditorTextFieldsGroup extends StatelessWidget {
  const _ReceiptEditorTextFieldsGroup({
    required this.fields,
    required this.numberValidator,
    required this.weightValidator,
    required this.discountsValidator,
    required this.onSubmit,
  });

  final List<ReceiptItemEditorDraftField> fields;
  final ReceiptItemEditorTextValidator numberValidator;
  final ReceiptItemEditorTextValidator weightValidator;
  final ReceiptItemEditorTextValidator discountsValidator;
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
            hintText: field.hintText(l10n),
            validator: _validatorFor(field),
            onSubmitted: onSubmit,
          ),
      ],
    );
  }

  ReceiptItemEditorTextValidator? _validatorFor(
    ReceiptItemEditorDraftField field,
  ) {
    return switch (field) {
      ReceiptItemEditorDraftField.quantity ||
      ReceiptItemEditorDraftField.unitPrice => numberValidator,
      ReceiptItemEditorDraftField.weight => weightValidator,
      ReceiptItemEditorDraftField.discounts => discountsValidator,
      _ => null,
    };
  }
}

class _ReceiptEditorTextField extends StatelessWidget {
  const _ReceiptEditorTextField({
    required this.field,
    required this.label,
    required this.keyboardType,
    required this.hintText,
    required this.validator,
    required this.onSubmitted,
  });

  final ReceiptItemEditorDraftField field;
  final String label;
  final TextInputType? keyboardType;
  final String? hintText;
  final ReceiptItemEditorTextValidator? validator;
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
        decoration: InputDecoration(labelText: label, hintText: hintText),
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

class _ReceiptEditorDateField extends StatelessWidget {
  const _ReceiptEditorDateField({
    required this.name,
    required this.label,
    required this.noDateLabel,
    this.allowClear = false,
    this.clearButtonKey,
  });

  final String name;
  final String label;
  final String noDateLabel;
  final bool allowClear;
  final Key? clearButtonKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FormBuilderField<DateTime?>(
      name: name,
      builder: (field) {
        final formattedDate = _formatDate(context, field.value);
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
                    onPressed: () => _pickDate(context, field),
                    child: Text(l10n.inventoryReceiptReviewSelectDateAction),
                  ),
                  if (allowClear)
                    TextButton(
                      key: clearButtonKey,
                      onPressed: () => field.didChange(null),
                      child: Text(l10n.inventoryReceiptReviewClearDateAction),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    FormFieldState<DateTime?> field,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: field.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!context.mounted || picked == null) {
      return;
    }
    field.didChange(DateUtils.dateOnly(picked));
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

String? _formatDate(BuildContext context, DateTime? value) {
  if (value == null) {
    return null;
  }
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(locale).format(value);
}
