import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/application/inventory_combined_eat_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_result.dart';

part 'inventory_item_combine_controller.g.dart';

/// Foods picked on the item hub of [hubItemId] to log together with it.
@riverpod
class InventoryItemCombineController extends _$InventoryItemCombineController {
  @override
  List<InventoryCombinePick> build(String hubItemId) {
    return const <InventoryCombinePick>[];
  }

  /// Stock items that can join the list: with nutrition values and stock,
  /// and neither the hub's item nor already picked. Sorted by name.
  List<InventoryItem> candidatesFrom(List<InventoryItem> items) {
    final taken = {hubItemId, ...state.map((pick) => pick.item.id)};
    return items
        .where(
          (item) =>
              !taken.contains(item.id) &&
              consumableInventoryAmount(item) != null &&
              InventoryCombinedEatService.canCombine(item),
        )
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// Adds [request] of [item] to the list.
  void add(InventoryItem item, InventoryItemEatRequest request) {
    state = [
      ...state,
      (
        item: item,
        request: request,
        component: InventoryCombinedEatService.componentFor(item, request),
      ),
    ];
  }

  /// Removes the food of [itemId].
  void remove(String itemId) {
    state = [
      for (final pick in state)
        if (pick.item.id != itemId) pick,
    ];
  }
}
