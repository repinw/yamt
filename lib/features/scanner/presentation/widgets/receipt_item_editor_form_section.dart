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
    required this.initialDiscountEntries,
    required this.onDiscountEntriesChanged,
    required this.discountsErrorText,
  });

  final VoidCallback onSubmit;
  final ReceiptItemEditorTextValidator numberValidator;
  final ReceiptItemEditorTextValidator weightValidator;
  final List<MapEntry<String, String>> initialDiscountEntries;
  final ValueChanged<List<MapEntry<String, String>>> onDiscountEntriesChanged;
  final String? discountsErrorText;

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
        _ReceiptEditorDateField(
          name: ReceiptItemEditorFormFieldName.entryDate,
          label: l10n.inventoryReceiptReviewFieldEntryDate,
          noDateLabel: l10n.inventoryReceiptReviewNoDate,
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
        _ReceiptEditorDiscountRowsField(
          initialEntries: initialDiscountEntries,
          onChanged: onDiscountEntriesChanged,
          errorText: discountsErrorText,
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
    required this.onSubmit,
  });

  final List<ReceiptItemEditorDraftField> fields;
  final ReceiptItemEditorTextValidator numberValidator;
  final ReceiptItemEditorTextValidator weightValidator;
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

class _ReceiptEditorDiscountRowsField extends StatefulWidget {
  const _ReceiptEditorDiscountRowsField({
    required this.initialEntries,
    required this.onChanged,
    required this.errorText,
    required this.onSubmit,
  });

  final List<MapEntry<String, String>> initialEntries;
  final ValueChanged<List<MapEntry<String, String>>> onChanged;
  final String? errorText;
  final VoidCallback onSubmit;

  @override
  State<_ReceiptEditorDiscountRowsField> createState() =>
      _ReceiptEditorDiscountRowsFieldState();
}

class _ReceiptEditorDiscountRowsFieldState
    extends State<_ReceiptEditorDiscountRowsField> {
  late final List<_DiscountRowControllers> _rows;

  @override
  void initState() {
    super.initState();
    _rows = _buildRows(widget.initialEntries);
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.inventoryReceiptReviewFieldDiscounts,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          for (var index = 0; index < _rows.length; index++)
            _buildRow(context, l10n, index),
          TextButton.icon(
            key: const Key('receipt_review_discount_add_button'),
            onPressed: _addRow,
            icon: const Icon(Icons.add),
            label: Text(l10n.inventoryReceiptReviewAddDiscountAction),
          ),
          if (widget.errorText != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              widget.errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, AppLocalizations l10n, int index) {
    final row = _rows[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              key: Key('receipt_review_discount_name_$index'),
              controller: row.nameController,
              textInputAction: TextInputAction.next,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              onChanged: (_) => _notifyRowsChanged(),
              decoration: InputDecoration(
                labelText: l10n.inventoryReceiptReviewDiscountNameLabel,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: TextField(
              key: Key('receipt_review_discount_amount_$index'),
              controller: row.amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              onSubmitted: (_) => widget.onSubmit(),
              onChanged: (_) => _notifyRowsChanged(),
              decoration: InputDecoration(
                labelText: l10n.inventoryReceiptReviewDiscountAmountLabel,
              ),
            ),
          ),
          IconButton(
            key: Key('receipt_review_discount_remove_$index'),
            onPressed: _rows.length > 1 ? () => _removeRow(index) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
        ],
      ),
    );
  }

  void _addRow() {
    setState(() {
      _rows.add(_DiscountRowControllers.empty());
    });
    _notifyRowsChanged();
  }

  void _removeRow(int index) {
    final removed = _rows.removeAt(index);
    removed.dispose();
    setState(() {});
    _notifyRowsChanged();
  }

  void _notifyRowsChanged() {
    widget.onChanged(
      _rows
          .map(
            (row) => MapEntry<String, String>(
              row.nameController.text,
              row.amountController.text,
            ),
          )
          .toList(growable: false),
    );
  }

  List<_DiscountRowControllers> _buildRows(
    List<MapEntry<String, String>> initialEntries,
  ) {
    if (initialEntries.isEmpty) {
      return <_DiscountRowControllers>[_DiscountRowControllers.empty()];
    }
    return initialEntries
        .map(
          (entry) => _DiscountRowControllers(
            nameController: TextEditingController(text: entry.key),
            amountController: TextEditingController(text: entry.value),
          ),
        )
        .toList(growable: true);
  }
}

class _DiscountRowControllers {
  const _DiscountRowControllers({
    required this.nameController,
    required this.amountController,
  });

  factory _DiscountRowControllers.empty() {
    return _DiscountRowControllers(
      nameController: TextEditingController(),
      amountController: TextEditingController(),
    );
  }

  final TextEditingController nameController;
  final TextEditingController amountController;

  void dispose() {
    nameController.dispose();
    amountController.dispose();
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
