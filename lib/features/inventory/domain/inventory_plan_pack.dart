import 'package:collection/collection.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';

/// The pack [plan] eats from: a pack of the planned food with stock left,
/// opened packs first, then the oldest. Returns null when the Vorrat has
/// none.
///
/// The same food is the planned pack, or a pack with the same name and
/// brand that counts in the plan's unit.
InventoryItem? pickInventoryItemForPlan(
  CalorieEntry plan,
  List<InventoryItem> items,
) {
  String key(String name, String? brand) =>
      '${name.trim().toLowerCase()}|${brand?.trim().toLowerCase() ?? ''}';
  final planKey = key(plan.name, plan.brand);
  final packs = items.where(
    (item) =>
        (item.id == plan.sourceInventoryItemId ||
            (key(item.name, item.brand) == planKey &&
                inventoryItemConsumedUnit(item) == plan.consumedUnit)) &&
        consumableInventoryAmount(item) != null,
  );
  return packs.sorted((a, b) {
    if (a.isFullyAvailable != b.isFullyAvailable) {
      return a.isFullyAvailable ? 1 : -1;
    }
    return a.entryDate.compareTo(b.entryDate);
  }).firstOrNull;
}
