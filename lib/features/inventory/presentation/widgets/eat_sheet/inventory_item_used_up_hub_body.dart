import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/hero_tags.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_action.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_list_entry.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_header.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_scaffold.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Item hub of a used-up item: the header and the item card. The main
/// button puts it on the shopping list, and the trash button removes it.
class InventoryItemUsedUpHubBody extends StatelessWidget {
  /// Creates the body for [item].
  const new({
    required this.item,
    required this.isOnShoppingList,
    required this.actions,
    required this.onRun,
    super.key,
  });

  /// The used-up item.
  final InventoryItem item;

  /// Whether the item is already on the shopping list.
  final bool isOnShoppingList;

  /// The item card.
  final Widget actions;

  /// Runs a hub action.
  final ValueChanged<InventoryItemHubAction> onRun;

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
          : () => onRun(InventoryItemHubAction.addToShoppingList),
      onDelete: () => onRun(InventoryItemHubAction.remove),
      deleteTooltip: l10n.inventoryItemRemoveAction,
      cancelButtonKey: const Key('inventory_item_hub_close_button'),
      children: [
        EatPageHeader(
          title: item.name,
          brand: item.brand,
          imageUrl: item.imageUrl,
          heroTag: HeroTags.stockItemImage(item.id),
          fallbackLetter: inventoryPictureLetter(item.name),
        ),
        actions,
      ],
    );
  }
}
