import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/domain/receipt_item_editor_updater.dart';
import 'package:yamt/l10n/app_localizations.dart';
import 'receipt_item_editor_action_row.dart';
import 'receipt_item_editor_draft.dart';
import 'receipt_item_editor_form_section.dart';
import 'receipt_item_editor_inline_error_state.dart';

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

  late ReceiptItemEditorDraft _draft;
  var _inlineErrors = ReceiptItemEditorInlineErrorState.empty;
  late DateTime _entryDate;
  DateTime? _receiptDate;
  late bool _isDeposit;
  late bool _isDiscount;
  late ReceiptWeightUnitFallbackOption _weightUnitFallbackOption;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _draft = ReceiptItemEditorDraft.fromItem(item);
    _entryDate = item.entryDate;
    _receiptDate = item.receiptDate;
    _isDeposit = item.isDeposit;
    _isDiscount = item.isDiscount;
    _weightUnitFallbackOption = ReceiptWeightUnitFallbackOption.fromUnit(
      item.amountUnit,
    );
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
              child: ReceiptItemEditorFormSection(
                values: _formValues,
                actions: _formActions,
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

  Future<void> _pickEntryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() {
      _entryDate = DateUtils.dateOnly(picked);
    });
  }

  Future<void> _pickReceiptDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receiptDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() {
      _receiptDate = DateUtils.dateOnly(picked);
    });
  }

  void _clearReceiptDate() {
    setState(() {
      _receiptDate = null;
    });
  }

  ReceiptItemEditorFormValues get _formValues {
    return ReceiptItemEditorFormValues(
      draft: _draft,
      inlineErrors: _inlineErrors,
      entryDate: _entryDate,
      receiptDate: _receiptDate,
      isDeposit: _isDeposit,
      isDiscount: _isDiscount,
      weightUnitFallbackOption: _weightUnitFallbackOption,
    );
  }

  ReceiptItemEditorFormActions get _formActions {
    return ReceiptItemEditorFormActions(
      onPickEntryDate: _pickEntryDate,
      onPickReceiptDate: _pickReceiptDate,
      onClearReceiptDate: _clearReceiptDate,
      onWeightUnitChanged: _updateWeightUnit,
      onIsDepositChanged: _updateIsDeposit,
      onIsDiscountChanged: _updateIsDiscount,
      onTextChanged: _onTextChanged,
      onSubmit: _applyChanges,
    );
  }

  void _updateWeightUnit(ReceiptWeightUnitFallbackOption value) {
    setState(() {
      _weightUnitFallbackOption = value;
    });
  }

  void _updateIsDeposit(bool value) {
    setState(() {
      _isDeposit = value;
    });
  }

  void _updateIsDiscount(bool value) {
    setState(() {
      _isDiscount = value;
    });
  }

  void _onTextChanged(ReceiptItemEditorDraftField field, String value) {
    _draft = _draft.withField(field, value);

    final nextInlineErrors = switch (field) {
      ReceiptItemEditorDraftField.quantity ||
      ReceiptItemEditorDraftField.unitPrice =>
        _inlineErrors.hasNumberError ? _inlineErrors.clearNumbers() : null,
      ReceiptItemEditorDraftField.weight =>
        _inlineErrors.hasWeightError ? _inlineErrors.clearWeight() : null,
      ReceiptItemEditorDraftField.discounts =>
        _inlineErrors.hasDiscountsError ? _inlineErrors.clearDiscounts() : null,
      _ => null,
    };
    if (nextInlineErrors == null) {
      return;
    }

    setState(() {
      _inlineErrors = nextInlineErrors;
    });
  }

  void _applyChanges() {
    final locale = Localizations.localeOf(context).toString();
    final fallbackUnit = _weightUnitFallbackOption.resolve(
      autoFallback: widget.item.amountUnit,
    );
    final result = _itemUpdater.apply(
      sourceItem: widget.item,
      formData: _draft.toFormData(
        entryDate: _entryDate,
        receiptDate: _receiptDate,
        isDeposit: _isDeposit,
        isDiscount: _isDiscount,
      ),
      locale: locale,
      fallbackUnit: fallbackUnit,
    );

    switch (result) {
      case ReceiptItemEditorApplySuccess(:final item):
        Navigator.of(context).pop(item);
      case ReceiptItemEditorApplyFailure(:final error):
        final l10n = AppLocalizations.of(context)!;
        _showInlineError(l10n, error);
    }
  }

  String _errorTextForApplyError(
    AppLocalizations l10n,
    ReceiptItemEditorApplyError error,
  ) {
    return switch (error) {
      ReceiptItemEditorApplyError.invalidNumber =>
        l10n.inventoryReceiptReviewInvalidNumber,
      ReceiptItemEditorApplyError.invalidDiscounts =>
        l10n.inventoryReceiptReviewInvalidDiscounts,
      ReceiptItemEditorApplyError.invalidWeightUnit =>
        l10n.inventoryReceiptReviewInvalidWeightUnit,
    };
  }

  void _showInlineError(
    AppLocalizations l10n,
    ReceiptItemEditorApplyError error,
  ) {
    final errorText = _errorTextForApplyError(l10n, error);
    setState(() {
      _inlineErrors = ReceiptItemEditorInlineErrorState.empty.withApplyError(
        error: error,
        errorText: errorText,
      );
    });
  }
}
