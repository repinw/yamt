import 'package:flutter/material.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows the missing barcode prompt for manual inventory add.
Future<String?> showInventoryManualAddMissingBarcodeDialog({
  required BuildContext context,
}) {
  return showDialog<String?>(
    context: context,
    builder: (dialogContext) {
      return const _ManualMissingBarcodeDialog();
    },
  );
}

/// Shows the eat amount prompt for manual inventory add.
Future<InventoryManualAddEatAmountDialogResult?>
showInventoryManualAddEatAmountDialog({
  required BuildContext context,
  required InventoryAmountUnit initialUnit,
}) {
  return showDialog<InventoryManualAddEatAmountDialogResult>(
    context: context,
    builder: (dialogContext) {
      return _ManualEatAmountDialog(initialUnit: initialUnit);
    },
  );
}

class _ManualMissingBarcodeDialog extends StatefulWidget {
  const _ManualMissingBarcodeDialog();

  @override
  State<_ManualMissingBarcodeDialog> createState() {
    return _ManualMissingBarcodeDialogState();
  }
}

class _ManualMissingBarcodeDialogState
    extends State<_ManualMissingBarcodeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.inventoryManualAddMissingBarcodeTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.inventoryManualAddMissingBarcodeMessage),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('inventory_manual_add_missing_barcode_field'),
              controller: _barcodeController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.inventoryManualAddMissingBarcodeLabel,
              ),
              validator: _validateBarcode,
              onFieldSubmitted: (_) => _submitBarcode(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('inventory_manual_add_missing_barcode_cancel_button'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.inventoryReceiptReviewCancelAction),
        ),
        TextButton(
          key: const Key('inventory_manual_add_missing_barcode_skip_button'),
          onPressed: () => Navigator.of(context).pop(''),
          child: Text(l10n.inventoryManualAddMissingBarcodeSaveWithout),
        ),
        FilledButton(
          key: const Key('inventory_manual_add_missing_barcode_save_button'),
          onPressed: _submitBarcode,
          child: Text(l10n.inventoryManualAddMissingBarcodeSave),
        ),
      ],
    );
  }

  String? _validateBarcode(String? value) {
    final barcode = normalizeBarcode(value ?? '');
    if (barcode.isEmpty) {
      return AppLocalizations.of(
        context,
      )!.inventoryManualAddMissingBarcodeRequired;
    }
    return null;
  }

  void _submitBarcode() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    Navigator.of(context).pop(normalizeBarcode(_barcodeController.text));
  }
}

/// Result from the manual add eat amount dialog.
class InventoryManualAddEatAmountDialogResult {
  /// The manual add eat amount dialog result.
  const InventoryManualAddEatAmountDialogResult({
    required this.amount,
    required this.unit,
  });

  /// The parsed amount.
  final int amount;

  /// The selected unit.
  final InventoryAmountUnit unit;
}

class _ManualEatAmountDialog extends StatefulWidget {
  const _ManualEatAmountDialog({required this.initialUnit});

  final InventoryAmountUnit initialUnit;

  @override
  State<_ManualEatAmountDialog> createState() => _ManualEatAmountDialogState();
}

class _ManualEatAmountDialogState extends State<_ManualEatAmountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final FocusNode _amountFocusNode;
  late InventoryAmountUnit _selectedUnit;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _amountFocusNode = FocusNode()..addListener(_handleFocusChanged);
    _selectedUnit = widget.initialUnit;
  }

  @override
  void dispose() {
    _amountFocusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amountScale = _selectedUnit == InventoryAmountUnit.piece
        ? inventoryPieceAmountScale
        : 1;
    final allowsFractionalInput = inventoryAmountAllowsFractionalInput(
      unit: _selectedUnit,
      scale: amountScale,
    );

    return AlertDialog(
      title: Text(l10n.inventoryBarcodePortionDialogTitle),
      content: Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('inventory_manual_add_eat_amount_field'),
                controller: _amountController,
                focusNode: _amountFocusNode,
                autofocus: true,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: allowsFractionalInput,
                ),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.inventoryItemEatSheetAmountLabel,
                ),
                validator: _validateAmount,
                onFieldSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 112,
              child: DropdownButtonFormField<InventoryAmountUnit>(
                key: const Key('inventory_manual_add_eat_unit_field'),
                initialValue: _selectedUnit,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<InventoryAmountUnit>(
                    value: InventoryAmountUnit.gram,
                    child: Text(l10n.inventoryUnitGram),
                  ),
                  DropdownMenuItem<InventoryAmountUnit>(
                    value: InventoryAmountUnit.milliliter,
                    child: Text(l10n.inventoryUnitMilliliter),
                  ),
                  DropdownMenuItem<InventoryAmountUnit>(
                    value: InventoryAmountUnit.piece,
                    child: Text(l10n.inventoryUnitPiece),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedUnit = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('inventory_manual_add_eat_cancel_button'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.inventoryReceiptReviewCancelAction),
        ),
        FilledButton(
          key: const Key('inventory_manual_add_eat_confirm_button'),
          onPressed: _submit,
          child: Text(l10n.inventoryBarcodePortionDialogConfirmAction),
        ),
      ],
    );
  }

  String? _validateAmount(String? value) {
    final parsed = parseInventoryAmountInput(
      rawValue: value ?? '',
      unit: _selectedUnit,
      scale: _selectedUnit == InventoryAmountUnit.piece
          ? inventoryPieceAmountScale
          : 1,
    );
    if (parsed == null || parsed < 1) {
      return AppLocalizations.of(context)!.inventoryReceiptReviewInvalidNumber;
    }
    return null;
  }

  void _submit() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final parsed = parseInventoryAmountInput(
      rawValue: _amountController.text,
      unit: _selectedUnit,
      scale: _selectedUnit == InventoryAmountUnit.piece
          ? inventoryPieceAmountScale
          : 1,
    );
    if (parsed == null) {
      return;
    }

    Navigator.of(context).pop(
      InventoryManualAddEatAmountDialogResult(
        amount: parsed,
        unit: _selectedUnit,
      ),
    );
  }

  void _handleFocusChanged() {
    if (!_amountFocusNode.hasFocus) {
      return;
    }
    _amountController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _amountController.text.length,
    );
  }
}
