import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_combine_controller.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_result.dart';

/// Picks the foods that join the meal of an item hub, from the hub's item
/// card or from the meal's own add link.
abstract final class InventoryCombinePickFlow {
  /// Closes the hub of [hubItem], and the inventory page continues its meal
  /// in the selection mode (#654): [hubItem], when [includesHubItem] is set,
  /// and the foods picked so far start selected. Entered amounts of stock
  /// foods are not kept.
  static void pick({
    required BuildContext context,
    required WidgetRef ref,
    required InventoryItem hubItem,
    required bool includesHubItem,
  }) {
    // A second tap while the hub closes would pop the page below it.
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) {
      return;
    }
    Navigator.of(context).pop(
      InventoryItemHubCombine(
        picks: ref.read(inventoryItemCombineControllerProvider(hubItem.id)),
        includesItem: includesHubItem,
      ),
    );
  }
}
