import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    this.suffixText,
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

  /// The suffix text.
  final String? suffixText;

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
    _controller = TextEditingController(text: '1');
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
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: widget.fieldLabel,
            suffixText: widget.suffixText,
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
    final parsed = int.tryParse((value ?? '').trim());
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

    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null) {
      return;
    }
    context.pop(parsed);
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
}
