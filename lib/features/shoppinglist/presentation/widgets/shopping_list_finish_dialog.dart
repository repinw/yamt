import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Asks whether the [cartCount] entries in the cart leave the list.
Future<bool> showShoppingListFinishDialog(
  BuildContext context, {
  required int cartCount,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.shoppingListFinishDialogTitle),
      content: Text(l10n.shoppingListFinishDialogMessage(cartCount)),
      actions: [
        TextButton(
          key: ShoppingListPageKeys.finishCancelButton,
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.inventoryReceiptReviewCancelAction),
        ),
        FilledButton(
          key: ShoppingListPageKeys.finishConfirmButton,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.shoppingListFinishConfirmAction),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
