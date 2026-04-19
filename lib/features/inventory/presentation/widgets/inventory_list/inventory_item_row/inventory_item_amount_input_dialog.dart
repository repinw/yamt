import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Defines inventory item amount input dialog.
class InventoryItemAmountInputDialog extends StatefulWidget {
  /// The inventory item amount input dialog.
  const InventoryItemAmountInputDialog({
    required this.title,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.fieldLabel,
    required this.invalidAmountMessage,
    required this.maxAmount,
    super.key,
    this.quickFillLabel,
    this.suffixText,
    this.amountUnit,
    this.amountScale = 1,
  });

  /// The title.
  final String title;

  /// The confirm label.
  final String confirmLabel;

  /// The cancel label.
  final String cancelLabel;

  /// The field label.
  final String fieldLabel;

  /// The invalid amount message.
  final String invalidAmountMessage;

  /// The max amount.
  final int maxAmount;

  /// Optional label for quickly filling the remaining amount.
  final String? quickFillLabel;

  /// The suffix text.
  final String? suffixText;

  /// Optional amount unit for fractional input handling.
  final InventoryAmountUnit? amountUnit;

  /// Internal amount scale for amount-based units.
  final int amountScale;

  @override
  State<InventoryItemAmountInputDialog> createState() =>
      _InventoryItemAmountInputDialogState();
}

class _InventoryItemAmountInputDialogState
    extends State<InventoryItemAmountInputDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    final defaultAmount = widget.amountUnit == InventoryAmountUnit.piece &&
            widget.amountScale > 1
        ? widget.amountScale
        : 1;
    final initialAmount = widget.maxAmount < defaultAmount
        ? widget.maxAmount
        : defaultAmount;
    _controller = TextEditingController(
      text: widget.amountUnit == null
          ? '1'
          : formatInventoryAmountValue(
              amount: initialAmount,
              unit: widget.amountUnit!,
              scale: widget.amountScale,
            ),
    );
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('inventory_item_amount_dialog_field'),
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          keyboardType: TextInputType.numberWithOptions(
            decimal: widget.amountUnit != null &&
                inventoryAmountAllowsFractionalInput(
                  unit: widget.amountUnit!,
                  scale: widget.amountScale,
                ),
          ),
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: widget.fieldLabel,
            suffixText: widget.suffixText,
            suffixIcon: widget.quickFillLabel == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton(
                      key: const Key(
                        'inventory_item_amount_dialog_fill_button',
                      ),
                      onPressed: _fillMaxAmount,
                      child: Text(widget.quickFillLabel!),
                    ),
                  ),
            suffixIconConstraints: widget.quickFillLabel == null
                ? null
                : const BoxConstraints(),
          ),
          validator: _validateAmount,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('inventory_item_amount_dialog_cancel_button'),
          onPressed: context.pop,
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          key: const Key('inventory_item_amount_dialog_confirm_button'),
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }

  String? _validateAmount(String? value) {
    final parsed = _parseAmount(value ?? '');
    if (parsed == null) {
      return widget.invalidAmountMessage;
    }
    if (parsed < 1) {
      return widget.invalidAmountMessage;
    }
    if (parsed > widget.maxAmount) {
      return widget.invalidAmountMessage;
    }
    return null;
  }

  void _submit() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final parsed = _parseAmount(_controller.text);
    if (parsed == null) {
      return;
    }
    context.pop(parsed);
  }

  void _fillMaxAmount() {
    final value = widget.amountUnit == null
        ? widget.maxAmount.toString()
        : formatInventoryAmountValue(
            amount: widget.maxAmount,
            unit: widget.amountUnit!,
            scale: widget.amountScale,
          );
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      return;
    }
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  int? _parseAmount(String rawValue) {
    final amountUnit = widget.amountUnit;
    if (amountUnit == null) {
      final parsed = int.tryParse(rawValue.trim());
      if (parsed == null || parsed < 1) {
        return null;
      }
      return parsed;
    }

    return parseInventoryAmountInput(
      rawValue: rawValue,
      unit: amountUnit,
      scale: widget.amountScale,
    );
  }
}
