import 'package:collection/collection.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_unit_aliases.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';

/// The pack [plan] eats from: a pack of the planned food with stock left,
/// opened packs first, then the oldest. Returns null when the Vorrat has
/// none.
///
/// The same food is the planned pack, or a pack with the same name and
/// brand whose stock amount [inventoryAmountForPlan] can tell.
InventoryItem? pickInventoryItemForPlan(
  CalorieEntry plan,
  List<InventoryItem> items,
) => inventoryPacksForPlan(plan, items).firstOrNull;

/// The packs of the food [plan] eats that have stock left, in the order
/// [pickInventoryItemForPlan] takes them.
List<InventoryItem> inventoryPacksForPlan(
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
                inventoryAmountForPlan(plan, item) != null)) &&
        consumableInventoryAmount(item) != null,
  );
  return packs.sorted((a, b) {
    if (a.isFullyAvailable != b.isFullyAvailable) {
      return a.isFullyAvailable ? 1 : -1;
    }
    return a.entryDate.compareTo(b.entryDate);
  });
}

/// The stock amount [plan] takes from [item], in the item's stored unit:
/// the planned amount from the planned pack, else the eaten amount in the
/// pack's unit. A pack counted in pieces converts through the weight of one
/// piece. Null when the amount cannot be told.
int? inventoryAmountForPlan(CalorieEntry plan, InventoryItem item) {
  final planned = plan.sourceInventoryAmountToRestore;
  if (item.id == plan.sourceInventoryItemId && planned != null) {
    return planned;
  }
  final unit = inventoryItemConsumedUnit(item);
  if (unit != null) {
    return unit == plan.consumedUnit ? plan.consumedAmount.round() : null;
  }
  // A pack without a size counts whole packs; its serving is no piece.
  if (item.amountUnit != InventoryAmountUnit.piece) {
    return null;
  }
  final pieceAmount = _pieceAmount(item, plan.consumedUnit);
  if (pieceAmount == null) {
    return null;
  }
  // Pieces tracked by amount store fractions of a piece.
  final scale = item.usesAmountProgress ? item.amountScale : 1;
  final amount = (plan.consumedAmount / pieceAmount * scale).round();
  return amount < 1 ? null : amount;
}

/// The grams or milliliters of one piece of [item] in [unit], from its
/// serving size, or null.
double? _pieceAmount(InventoryItem item, ConsumedUnit unit) {
  final quantity = item.servingQuantity;
  final serving = resolveInventoryAmountUnitAlias(item.servingQuantityUnit);
  if (quantity == null || quantity <= 0 || serving == null) {
    return null;
  }
  final matches = switch (unit) {
    ConsumedUnit.grams => serving.base == InventoryAmountUnit.gram,
    ConsumedUnit.milliliters => serving.base == InventoryAmountUnit.milliliter,
  };
  return matches ? quantity * serving.multiplier : null;
}
