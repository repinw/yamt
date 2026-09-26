import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_eat_sheet_result.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_result.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_item_actions_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_header.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_scaffold.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/inventory_item_eat_sheet_body.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Item hub: the eat page of a stock item plus the item's own actions.
///
/// Pops with an [InventoryItemHubResult]. An item without stock to eat shows
/// only its actions, and the main button puts it on the shopping list.
class InventoryItemHubPage extends StatelessWidget {
  /// Creates the hub for [item].
  const new({required this.item, required this.isOnShoppingList, super.key});

  /// The stock item.
  final InventoryItem item;

  /// Whether the item is already on the shopping list.
  final bool isOnShoppingList;

  @override
  Widget build(BuildContext context) {
    final actions = EatItemActionsCard(
      isOnShoppingList: isOnShoppingList,
      onPicked: (action) => _pop(context, InventoryItemHubPick(action)),
    );
    if (consumableInventoryAmount(item) == null) {
      return _UsedUpHubBody(
        item: item,
        isOnShoppingList: isOnShoppingList,
        actions: actions,
      );
    }
    return InventoryItemEatSheetBody(
      item: item,
      confirmIntent: InventoryItemEatSheetIntent.logOnly,
      footer: actions,
      onSubmitted: (result) =>
          _pop(context, InventoryItemHubEat(result.request)),
    );
  }
}

void _pop(BuildContext context, InventoryItemHubResult result) {
  Navigator.of(context).pop(result);
}

class _UsedUpHubBody extends StatelessWidget {
  const new({
    required this.item,
    required this.isOnShoppingList,
    required this.actions,
  });

  final InventoryItem item;
  final bool isOnShoppingList;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EatPageScaffold(
      whenControl: const SizedBox.shrink(),
      kcal: null,
      confirmButtonKey: const Key('inventory_item_hub_shopping_list_button'),
      confirmLabel: l10n.inventoryItemAddToListAction,
      onConfirm: isOnShoppingList
          ? null
          : () => _pop(
              context,
              const InventoryItemHubPick(
                InventoryItemHubAction.addToShoppingList,
              ),
            ),
      cancelButtonKey: const Key('inventory_item_hub_close_button'),
      children: [
        EatPageHeader(
          title: item.name,
          brand: item.brand,
          imageUrl: item.imageUrl,
        ),
        actions,
      ],
    );
  }
}
