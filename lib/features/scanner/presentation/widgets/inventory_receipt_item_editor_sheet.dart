import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/domain/receipt_item_editor_updater.dart';
import 'package:yamt/features/scanner/domain/receipt_item_input_parser.dart';
import 'package:yamt/l10n/app_localizations.dart';
import '../models/receipt_item_editor_draft.dart';
import 'receipt_item_editor_action_row.dart';
import 'receipt_item_editor_form_field_metadata.dart';
import 'receipt_item_editor_form_section.dart';
import 'receipt_item_editor_weight_unit_fallback_option.dart';

class InventoryReceiptItemEditorSheet extends StatefulWidget {
  const InventoryReceiptItemEditorSheet({super.key, required this.item});

  final FridgeItem item;

  @override
  State<InventoryReceiptItemEditorSheet> createState() =>
      _InventoryReceiptItemEditorSheetState();
}

class _InventoryReceiptItemEditorSheetState
    extends State<InventoryReceiptItemEditorSheet> {
  static const _itemUpdater = ReceiptItemEditorUpdater();
  static const _inputParser = ReceiptItemInputParser();

  final _formKey = GlobalKey<FormBuilderState>();
  late final Map<String, dynamic> _initialFormValues;
  late List<MapEntry<String, String>> _discountEntries;
  String? _discountsErrorText;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    final draft = ReceiptItemEditorDraft.fromItem(item);
    _discountEntries = _toDiscountEntries(item.discounts);
    _initialFormValues = {
      for (final field in ReceiptItemEditorDraftField.values)
        if (field != ReceiptItemEditorDraftField.discounts)
          field.name: draft.valueFor(field),
      ReceiptItemEditorFormFieldName.entryDate: item.entryDate,
      ReceiptItemEditorFormFieldName.receiptDate: item.receiptDate,
      ReceiptItemEditorFormFieldName.isDeposit: item.isDeposit,
      ReceiptItemEditorFormFieldName.isDiscount: item.isDiscount,
      ReceiptItemEditorFormFieldName.weightUnitFallbackOption:
          ReceiptWeightUnitFallbackOption.fromUnit(item.amountUnit),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final insets = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl + insets,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.inventoryReceiptReviewEditTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            FormBuilder(
              key: _formKey,
              initialValue: _initialFormValues,
              child: ReceiptItemEditorFormSection(
                onSubmit: _applyChanges,
                numberValidator: _validateNumbers,
                weightValidator: _validateWeight,
                initialDiscountEntries: _discountEntries,
                onDiscountEntriesChanged: _onDiscountEntriesChanged,
                discountsErrorText: _discountsErrorText,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ReceiptItemEditorActionRow(
              onCancelTap: () => Navigator.of(context).pop(),
              onApplyTap: _applyChanges,
            ),
          ],
        ),
      ),
    );
  }

  void _applyChanges() {
    final formState = _formKey.currentState;
    if (formState == null) {
      return;
    }

    final isValid = formState.saveAndValidate();
    if (!isValid) {
      return;
    }

    final formValues = Map<String, dynamic>.from(formState.value);
    final fallbackOption = _readFormValue(
      values: formValues,
      name: ReceiptItemEditorFormFieldName.weightUnitFallbackOption,
      fallback: ReceiptWeightUnitFallbackOption.fromUnit(
        widget.item.amountUnit,
      ),
    );
    final result = _itemUpdater.apply(
      sourceItem: widget.item,
      formData: _toFormData(formValues),
      locale: _locale,
      fallbackUnit: fallbackOption.resolve(
        autoFallback: widget.item.amountUnit,
      ),
    );

    switch (result) {
      case ReceiptItemEditorApplySuccess(:final item):
        Navigator.of(context).pop(item);
      case ReceiptItemEditorApplyFailure(:final error):
        _showApplyError(error);
    }
  }

  ReceiptItemEditorFormData _toFormData(Map<String, dynamic> values) {
    return ReceiptItemEditorFormData(
      name: _readFormValue(
        values: values,
        name: ReceiptItemEditorDraftField.name.name,
        fallback: '',
      ),
      entryDate: _readFormValue(
        values: values,
        name: ReceiptItemEditorFormFieldName.entryDate,
        fallback: widget.item.entryDate,
      ),
      storeName: _readFormValue(
        values: values,
        name: ReceiptItemEditorDraftField.storeName.name,
        fallback: '',
      ),
      quantityText: _readFormValue(
        values: values,
        name: ReceiptItemEditorDraftField.quantity.name,
        fallback: '',
      ),
      unitPriceText: _readFormValue(
        values: values,
        name: ReceiptItemEditorDraftField.unitPrice.name,
        fallback: '',
      ),
      weightText: _readFormValue(
        values: values,
        name: ReceiptItemEditorDraftField.weight.name,
        fallback: '',
      ),
      brandText: _readFormValue(
        values: values,
        name: ReceiptItemEditorDraftField.brand.name,
        fallback: '',
      ),
      categoryText: _readFormValue(
        values: values,
        name: ReceiptItemEditorDraftField.category.name,
        fallback: '',
      ),
      discountEntries: List<MapEntry<String, String>>.from(_discountEntries),
      receiptDate: _readNullableDate(
        values: values,
        name: ReceiptItemEditorFormFieldName.receiptDate,
      ),
      isDeposit: _readFormValue(
        values: values,
        name: ReceiptItemEditorFormFieldName.isDeposit,
        fallback: false,
      ),
      isDiscount: _readFormValue(
        values: values,
        name: ReceiptItemEditorFormFieldName.isDiscount,
        fallback: false,
      ),
    );
  }

  String? _validateNumbers(String? _) {
    final numbers = _inputParser.parseNumbers(
      quantityText: _currentTextValue(ReceiptItemEditorDraftField.quantity),
      unitPriceText: _currentTextValue(ReceiptItemEditorDraftField.unitPrice),
      locale: _locale,
    );
    if (numbers != null) {
      return null;
    }
    final l10n = AppLocalizations.of(context)!;
    return l10n.inventoryReceiptReviewInvalidNumber;
  }

  String? _validateWeight(String? value) {
    final weightText = (value ?? '').trim();
    if (weightText.isEmpty) {
      return null;
    }

    final quantity = _inputParser.parseInt(
      _currentTextValue(ReceiptItemEditorDraftField.quantity),
      locale: _locale,
    );
    if (quantity == null) {
      return null;
    }

    final fallbackOption = _currentWeightFallbackOption();
    final updated = widget.item.withDerivedAmount(
      weight: weightText,
      quantity: quantity < 0 ? 0 : quantity,
      fallbackUnit: fallbackOption.resolve(
        autoFallback: widget.item.amountUnit,
      ),
    );
    final hasUnresolvedWeight =
        updated.initialAmount == 0 && updated.amountUnit == null;
    if (!hasUnresolvedWeight) {
      return null;
    }

    final l10n = AppLocalizations.of(context)!;
    return l10n.inventoryReceiptReviewInvalidWeightUnit;
  }

  void _showApplyError(ReceiptItemEditorApplyError error) {
    final l10n = AppLocalizations.of(context)!;
    final message = switch (error) {
      ReceiptItemEditorApplyError.invalidNumber =>
        l10n.inventoryReceiptReviewInvalidNumber,
      ReceiptItemEditorApplyError.invalidDiscounts =>
        l10n.inventoryReceiptReviewInvalidDiscounts,
      ReceiptItemEditorApplyError.invalidWeightUnit =>
        l10n.inventoryReceiptReviewInvalidWeightUnit,
    };
    final fields = switch (error) {
      ReceiptItemEditorApplyError.invalidNumber => <String>[
        ReceiptItemEditorDraftField.quantity.name,
        ReceiptItemEditorDraftField.unitPrice.name,
      ],
      ReceiptItemEditorApplyError.invalidDiscounts => const <String>[],
      ReceiptItemEditorApplyError.invalidWeightUnit => <String>[
        ReceiptItemEditorDraftField.weight.name,
      ],
    };

    if (error == ReceiptItemEditorApplyError.invalidDiscounts) {
      setState(() {
        _discountsErrorText = message;
      });
    }

    for (final field in fields) {
      _formKey.currentState?.fields[field]?.invalidate(message);
    }
  }

  void _onDiscountEntriesChanged(List<MapEntry<String, String>> entries) {
    setState(() {
      _discountEntries = entries;
      _discountsErrorText = null;
    });
  }

  String _currentTextValue(ReceiptItemEditorDraftField field) {
    return _readFormValue(
      values: _currentValues,
      name: field.name,
      fallback: '',
    );
  }

  ReceiptWeightUnitFallbackOption _currentWeightFallbackOption() {
    return _readFormValue(
      values: _currentValues,
      name: ReceiptItemEditorFormFieldName.weightUnitFallbackOption,
      fallback: ReceiptWeightUnitFallbackOption.fromUnit(
        widget.item.amountUnit,
      ),
    );
  }

  Map<String, dynamic> get _currentValues {
    final stateValues = _formKey.currentState?.instantValue;
    if (stateValues == null) {
      return _initialFormValues;
    }
    return stateValues;
  }

  T _readFormValue<T>({
    required Map<String, dynamic> values,
    required String name,
    required T fallback,
  }) {
    final value = values[name];
    if (value is T) {
      return value;
    }
    return fallback;
  }

  DateTime? _readNullableDate({
    required Map<String, dynamic> values,
    required String name,
  }) {
    final value = values[name];
    return value is DateTime ? value : null;
  }

  String get _locale {
    return Localizations.localeOf(context).toString();
  }

  List<MapEntry<String, String>> _toDiscountEntries(
    Map<String, double> discounts,
  ) {
    if (discounts.isEmpty) {
      return const <MapEntry<String, String>>[];
    }
    return discounts.entries
        .map(
          (entry) =>
              MapEntry<String, String>(entry.key, entry.value.toString()),
        )
        .toList(growable: false);
  }
}
