import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

class ShoppingQuickAddDialogKeys {
  const ShoppingQuickAddDialogKeys._();

  static const nameField = Key('shopping_quick_add_name_field');
  static const brandField = Key('shopping_quick_add_brand_field');
  static const confirmButton = Key('shopping_quick_add_confirm_button');
  static const cancelButton = Key('shopping_quick_add_cancel_button');
}

typedef ShoppingQuickAddSubmit =
    bool Function({required String name, required String brand});

Future<void> showShoppingQuickAddDialog({
  required BuildContext context,
  required AppLocalizations l10n,
  required ShoppingQuickAddSubmit onSubmit,
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
  final ShoppingQuickAddSubmit onSubmit;

  @override
  State<_ShoppingQuickAddDialog> createState() =>
      _ShoppingQuickAddDialogState();
}

class _ShoppingQuickAddDialogState extends State<_ShoppingQuickAddDialog> {
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  var _showNameError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  void _submit() {
    final added = widget.onSubmit(
      name: _nameController.text,
      brand: _brandController.text,
    );
    if (!added) {
      if (!_showNameError) {
        setState(() {
          _showNameError = true;
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.shoppingListAddAction),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: ShoppingQuickAddDialogKeys.nameField,
            controller: _nameController,
            autofocus: true,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (!_showNameError) {
                return;
              }
              setState(() {
                _showNameError = false;
              });
            },
            decoration: InputDecoration(
              labelText: widget.l10n.shoppingListNameFieldLabel,
              errorText: _showNameError
                  ? widget.l10n.shoppingListInvalidNameError
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: ShoppingQuickAddDialogKeys.brandField,
            controller: _brandController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: widget.l10n.shoppingListBrandFieldLabel,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: ShoppingQuickAddDialogKeys.cancelButton,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.l10n.inventoryReceiptReviewCancelAction),
        ),
        FilledButton(
          key: ShoppingQuickAddDialogKeys.confirmButton,
          onPressed: _submit,
          child: Text(widget.l10n.shoppingListAddAction),
        ),
      ],
    );
  }
}
