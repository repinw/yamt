import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_list_page_keys.dart';
import 'package:yamt/features/shoppinglist/provider/shopping_list_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines shopping list clear crossed off action.
class ShoppingListClearCrossedOffAction extends StatelessWidget {
  /// The shopping list clear crossed off action.
  const ShoppingListClearCrossedOffAction({
    required this.crossedOffCount,
    required this.controller,
    required this.l10n,
    super.key,
  });

  /// The crossed off count.
  final int crossedOffCount;

  /// The controller.
  final ShoppingListController controller;

  /// The l10n.
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (crossedOffCount < 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          key: ShoppingListPageKeys.clearCrossedOffButton,
          onPressed: () => _onPressed(context),
          icon: const Icon(Icons.delete_sweep_outlined),
          label: Text(l10n.shoppingListClearCrossedOffAction(crossedOffCount)),
        ),
      ),
    );
  }

  Future<void> _onPressed(BuildContext context) async {
    final confirmed = await _confirmClearCrossedOff(context);
    if (confirmed != true) {
      return;
    }
    await controller.clearCrossedOffItems();
  }

  Future<bool?> _confirmClearCrossedOff(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.shoppingListClearCrossedOffDialogTitle),
          content: Text(l10n.shoppingListClearCrossedOffDialogMessage),
          actions: [
            TextButton(
              key: ShoppingListPageKeys.clearCrossedOffCancelButton,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.inventoryReceiptReviewCancelAction),
            ),
            FilledButton(
              key: ShoppingListPageKeys.clearCrossedOffConfirmButton,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.shoppingListClearCrossedOffConfirmAction),
            ),
          ],
        );
      },
    );
  }
}
