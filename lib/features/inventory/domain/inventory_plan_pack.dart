import 'package:collection/collection.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_unit_aliases.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';

/// The pack [plan] eats from, with the stock amount it takes there: a pack
/// of the planned food with stock left, opened packs first, then the oldest.
/// Returns null when the Vorrat has none.
///
/// The same food is the planned pack, or a pack with the same name and
/// brand. Either way [inventoryAmountForPlan] must tell its amount.
({InventoryItem item, int amount})? pickInventoryItemForPlan(
  CalorieEntry plan,
  List<InventoryItem> items,
) => inventoryPacksForPlan(plan, items).firstOrNull;

/// The packs of the food [plan] eats that have stock left, with the stock
/// amount it takes from each, in the order [pickInventoryItemForPlan] takes
/// them.
List<({InventoryItem item, int amount})> inventoryPacksForPlan(
  CalorieEntry plan,
  List<InventoryItem> items,
) {
  String key(String name, String? brand) =>
      '${name.trim().toLowerCase()}|${brand?.trim().toLowerCase() ?? ''}';
  final planKey = key(plan.name, plan.brand);
  final packs = [
    for (final item in items)
      if ((item.id == plan.sourceInventoryItemId ||
              key(item.name, item.brand) == planKey) &&
          consumableInventoryAmount(item) != null)
        if (inventoryAmountForPlan(plan, item) case final amount?)
          (item: item, amount: amount),
  ];
  return packs.sorted((a, b) {
    if (a.item.isFullyAvailable != b.item.isFullyAvailable) {
      return a.item.isFullyAvailable ? 1 : -1;
    }
    return a.item.entryDate.compareTo(b.item.entryDate);
  });
}

/// The stock amount to save with [changed], a plan whose eaten amount
/// changed from that of [previous]: none when [item], the planned pack, can
/// work it out from the new amount once eaten, else the saved amount
/// scaled to the new amount, at least one.
///
/// Working it out again keeps rounding from stacking up over several
/// edits; a pack counted without a size can only scale.
int? inventoryStockForChangedPlan({
  required CalorieEntry previous,
  required CalorieEntry changed,
  required InventoryItem? item,
}) {
  final stock = previous.sourceInventoryAmountToRestore;
  if (stock == null) {
    return null;
  }
  final unsaved = changed.copyWith(sourceInventoryAmountToRestore: null);
  if (item != null && inventoryAmountForPlan(unsaved, item) != null) {
    return null;
  }
  if (previous.consumedAmount <= 0) {
    return stock;
  }
  final scaled = (stock * changed.consumedAmount / previous.consumedAmount)
      .round();
  return scaled < 1 ? 1 : scaled;
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
    // A pack without a tracked amount counts whole packs, not grams.
    if (unit != plan.consumedUnit || !item.usesAmountProgress) {
      return null;
    }
    final amount = (plan.consumedAmount * item.amountScale).round();
    return amount < 1 ? null : amount;
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
  if (quantity == null || quantity <= 0) {
    return null;
  }
  final serving = servingInBaseUnit(quantity, item.servingQuantityUnit);
  if (serving == null) {
    return null;
  }
  final matches = switch (unit) {
    ConsumedUnit.grams => serving.unit == InventoryAmountUnit.gram,
    ConsumedUnit.milliliters => serving.unit == InventoryAmountUnit.milliliter,
  };
  return matches ? serving.amount : null;
}
