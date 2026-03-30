import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

Future<void> showShoppingQuickAddDialog({
  required BuildContext context,
  required AppLocalizations l10n,
  required Future<bool> Function({required String name, required String brand})
  onSubmit,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return _ShoppingQuickAddDialog(l10n: l10n, onSubmit: onSubmit);
    },
  );
}

class _ShoppingQuickAddDialog extends StatefulWidget {
  const _ShoppingQuickAddDialog({required this.l10n, required this.onSubmit});

  final AppLocalizations l10n;
  final Future<bool> Function({required String name, required String brand})
  onSubmit;

  @override
  State<_ShoppingQuickAddDialog> createState() =>
      _ShoppingQuickAddDialogState();
}

class _ShoppingQuickAddDialogState extends State<_ShoppingQuickAddDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  var _isSubmitting = false;
  String? _submitErrorText;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _submitErrorText = null;
    });

    final added = await widget.onSubmit(
      name: _nameController.text,
      brand: _brandController.text,
    );
    if (!mounted) {
      return;
    }
    if (!added) {
      setState(() {
        _isSubmitting = false;
        _submitErrorText = widget.l10n.shoppingListAddFailedError;
      });
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.l10n.shoppingListAddAction),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final name = value?.trim() ?? '';
                if (name.isEmpty) {
                  return widget.l10n.shoppingListInvalidNameError;
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: widget.l10n.shoppingListNameFieldLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _brandController,
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: widget.l10n.shoppingListBrandFieldLabel,
              ),
            ),
            if (_submitErrorText != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _submitErrorText!,
                  style: TextStyle(color: colors.error),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(widget.l10n.inventoryReceiptReviewCancelAction),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: AppSizes.inlineProgressIndicator,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.progressStrokeWidth,
                  ),
                )
              : Text(widget.l10n.shoppingListAddAction),
        ),
      ],
    );
  }
}
