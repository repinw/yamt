import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/application/inventory_combined_eat_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_amounts.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_combine_pick_flow.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_action.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_item_actions_card.dart';

/// Item card of the item hub. Besides the item's actions it holds the
/// rarer actions of the eat page: the inedible part, until the page shows
/// it, and combining with other foods, until a meal is started.
class InventoryItemHubActionsCard extends ConsumerWidget {
  /// Creates the card for the hub of [item].
  const new({
    required this.item,
    required this.isOnShoppingList,
    required this.actions,
    required this.onPicked,
    required this.offersEatActions,
    super.key,
  });

  /// The hub's item.
  final InventoryItem item;

  /// Whether the item is already on the shopping list.
  final bool isOnShoppingList;

  /// Item actions to show.
  final List<InventoryItemHubAction> actions;

  /// Called with the tapped item action.
  final ValueChanged<InventoryItemHubAction> onPicked;

  /// Whether the eat actions show: the item has stock and no meal is
  /// started.
  final bool offersEatActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheet = inventoryItemEatSheetControllerProvider(item: item);
    final offersInedible =
        offersEatActions &&
        ref.watch(
          sheet.select(
            (state) =>
                state.calculator.supportsInedibleAmountAdjustment &&
                !hasInedibleInput(state),
          ),
        );
    return EatItemActionsCard(
      isOnShoppingList: isOnShoppingList,
      actions: [
        for (final action in actions)
          // Only an AI food has an estimate to run again.
          if (action != InventoryItemHubAction.reanalyze ||
              item.productSnapshot.aiEstimate != null)
            action,
      ],
      onPicked: onPicked,
      onInedible: offersInedible
          ? () => ref.read(sheet.notifier).openInedible()
          : null,
      onCombine:
          offersEatActions && InventoryCombinedEatService.canCombine(item)
          ? () => InventoryCombinePickFlow.pick(
              context: context,
              ref: ref,
              hubItem: item,
              includesHubItem: true,
            )
          : null,
    );
  }
}
