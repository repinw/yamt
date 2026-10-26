import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_action.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_action_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Item" card of the item hub: estimating an AI food again, shopping list,
/// edit and replace, drawn like a
/// second food label. [actions] picks the lines to show. Above them come the
/// rarer eat actions of the hub's eat page, when it passes them: the
/// inedible part and combining with other foods. Removing the item is the
/// page's trash button, so the card has no line for it.
class EatItemActionsCard extends StatelessWidget {
  /// Creates the card.
  const new({
    required this.isOnShoppingList,
    required this.onPicked,
    this.actions = InventoryItemHubAction.values,
    this.onInedible,
    this.onCombine,
    super.key,
  });

  /// Key of the line that estimates an AI food again.
  static const reanalyzeKey = Key('eat_item_action_reanalyze');

  /// Key of the line that opens the inedible part.
  static const inedibleKey = Key('eat_item_action_inedible');

  /// Key of the line that starts a meal with other foods.
  static const combineKey = Key('eat_item_action_combine');

  /// Actions to show, in the card's own order.
  final List<InventoryItemHubAction> actions;

  /// Opens the inedible part on the page. The line is hidden when null.
  final VoidCallback? onInedible;

  /// Picks other foods for a meal. The line is hidden when null.
  final VoidCallback? onCombine;

  /// Whether the item is already on the shopping list. The shopping list
  /// line is then disabled.
  final bool isOnShoppingList;

  /// Called with the tapped action.
  final ValueChanged<InventoryItemHubAction> onPicked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);

    final lines = <EatCardAction>[
      if (actions.contains(InventoryItemHubAction.reanalyze))
        (
          key: reanalyzeKey,
          icon: Icons.autorenew_rounded,
          label: l10n.foodEstimateReanalyze,
          color: colors.ink,
          onPressed: () => onPicked(InventoryItemHubAction.reanalyze),
        ),
      if (onInedible case final onInedible?)
        (
          key: inedibleKey,
          icon: Icons.content_cut_rounded,
          label: l10n.inventoryItemEatSheetInedibleAmountLabel,
          color: colors.ink,
          onPressed: onInedible,
        ),
      if (onCombine case final onCombine?)
        (
          key: combineKey,
          icon: Icons.add_rounded,
          label: l10n.eatPageCombineLink,
          color: colors.ink,
          onPressed: onCombine,
        ),
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
    ];

    return EatActionCard(title: l10n.eatPageItemTitle, actions: lines);
  }
}
