import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_action.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_action_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Item" card of the item hub: shopping list, edit, replace and remove,
/// drawn like a second food label. [actions] picks the lines to show.
class EatItemActionsCard extends StatelessWidget {
  /// Creates the card.
  const new({
    required this.isOnShoppingList,
    required this.onPicked,
    this.actions = InventoryItemHubAction.values,
    super.key,
  });

  /// Actions to show, in the card's own order.
  final List<InventoryItemHubAction> actions;

  /// Whether the item is already on the shopping list. The shopping list
  /// line is then disabled.
  final bool isOnShoppingList;

  /// Called with the tapped action.
  final ValueChanged<InventoryItemHubAction> onPicked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final error = Theme.of(context).colorScheme.error;

    final lines = <EatCardAction>[
      if (actions.contains(InventoryItemHubAction.addToShoppingList))
        (
          key: const Key('eat_item_action_shopping_list'),
          icon: Icons.shopping_cart_outlined,
          label: isOnShoppingList
              ? l10n.eatPageOnShoppingList
              : l10n.inventoryItemAddToShoppingListAction,
          color: colors.ink,
          onPressed: isOnShoppingList
              ? null
              : () => onPicked(InventoryItemHubAction.addToShoppingList),
        ),
      if (actions.contains(InventoryItemHubAction.edit))
        (
          key: const Key('eat_item_action_edit'),
          icon: Icons.edit_outlined,
          label: l10n.inventoryReceiptReviewEditAction,
          color: colors.ink,
          onPressed: () => onPicked(InventoryItemHubAction.edit),
        ),
      if (actions.contains(InventoryItemHubAction.replace))
        (
          key: const Key('eat_item_action_replace'),
          icon: Icons.swap_horiz_rounded,
          label: l10n.eatPageReplaceProduct,
          color: colors.ink,
          onPressed: () => onPicked(InventoryItemHubAction.replace),
        ),
      if (actions.contains(InventoryItemHubAction.remove))
        (
          key: const Key('eat_item_action_remove'),
          icon: Icons.delete_outline_rounded,
          label: l10n.inventoryItemRemoveAction,
          color: error,
          onPressed: () => onPicked(InventoryItemHubAction.remove),
        ),
    ];

    return EatActionCard(title: l10n.eatPageItemTitle, actions: lines);
  }
}
