import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_action.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_framed_box.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_label_title.dart';
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

    final lines = <_Line>[
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

    return EatFramedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EatLabelTitle(text: l10n.eatPageItemTitle),
          for (final (index, line) in lines.indexed)
            _ActionLine(
              key: line.key,
              icon: line.icon,
              label: line.label,
              color: line.color,
              showRule: index < lines.length - 1,
              onPressed: line.onPressed,
            ),
        ],
      ),
    );
  }
}

typedef _Line = ({
  Key key,
  IconData icon,
  String label,
  Color color,
  VoidCallback? onPressed,
});

class _ActionLine extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.showRule = true,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool showRule;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final foreground = onPressed == null ? colors.muted : color;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: showRule ? BorderSide(color: colors.ink) : BorderSide.none,
        ),
      ),
      child: AppInkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              Icon(icon, color: foreground),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: foreground),
                ),
              ),
              if (onPressed != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: foreground,
                  size: AppSizes.actionChevron,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
