import 'package:collection/collection.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
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

/// A Vorrat pack and the stock amount an eat takes from it.
typedef InventoryPack = ({InventoryItem item, int amount});

/// The packs of the food [plan] eats that have stock left, with the stock
/// amount it takes from each, in the order [pickInventoryItemForPlan] takes
/// them.
///
/// Besides the planned pack and packs with its name and brand, a pack with
/// the planned pack's barcode holds the same food.
List<InventoryPack> inventoryPacksForPlan(
  CalorieEntry plan,
  List<InventoryItem> items,
) {
  String key(String name, String? brand) =>
      '${name.trim().toLowerCase()}|${brand?.trim().toLowerCase() ?? ''}';
  final planKey = key(plan.name, plan.brand);
  final planBarcode = _barcodeOf(
    items.firstWhereOrNull((item) => item.id == plan.sourceInventoryItemId),
  );
  final packs = [
    for (final item in items)
      if ((item.id == plan.sourceInventoryItemId ||
              key(item.name, item.brand) == planKey ||
              (planBarcode != null && _barcodeOf(item) == planBarcode)) &&
          consumableInventoryAmount(item) != null)
        if (inventoryAmountForPlan(plan, item) case final amount?)
          (item: item, amount: amount),
  ];
  return packs.sorted((a, b) => _compareEatOrder(a.item, b.item));
}

/// The packs with stock left that hold the product with [barcode], opened
/// packs first, then the oldest. Empty without a barcode.
List<InventoryItem> inventoryPacksWithBarcode(
  String? barcode,
  List<InventoryItem> items,
) {
  final wanted = normalizeBarcode(barcode ?? '');
  if (wanted.isEmpty) {
    return const [];
  }
  return items
      .where(
        (item) =>
            _barcodeOf(item) == wanted &&
            consumableInventoryAmount(item) != null,
      )
      .sorted(_compareEatOrder);
}

/// The barcode of [item] without separators, or null when it has none.
String? _barcodeOf(InventoryItem? item) {
  final barcode = normalizeBarcode(item?.barcode ?? '');
  return barcode.isEmpty ? null : barcode;
}

/// Opened packs first, then the oldest.
int _compareEatOrder(InventoryItem a, InventoryItem b) {
  if (a.isFullyAvailable != b.isFullyAvailable) {
    return a.isFullyAvailable ? 1 : -1;
  }
  // Bought first, eaten first: a receipt scanned late keeps its date.
  final aBought = a.receiptDate ?? a.entryDate;
  final bBought = b.receiptDate ?? b.entryDate;
  return aBought.compareTo(bBought);
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
/// pack's unit (see [inventoryStockAmountFor]). Null when the amount cannot
/// be told.
int? inventoryAmountForPlan(CalorieEntry plan, InventoryItem item) {
  final planned = plan.sourceInventoryAmountToRestore;
  if (item.id == plan.sourceInventoryItemId && planned != null) {
    return planned;
  }
  return inventoryStockAmountFor(item, plan.consumedAmount, plan.consumedUnit);
}

/// The stock of [item] that [amount] grams or milliliters ([unit]) take, in
/// the item's stored unit. A pack counted in pieces converts through the
/// weight of one piece. Null when the amount cannot be told.
int? inventoryStockAmountFor(
  InventoryItem item,
  double amount,
  ConsumedUnit unit,
) {
  final itemUnit = inventoryItemConsumedUnit(item);
  if (itemUnit != null) {
    // A pack without a tracked amount counts whole packs, not grams.
    if (itemUnit != unit || !item.usesAmountProgress) {
      return null;
    }
    final stock = (amount * item.amountScale).round();
    return stock < 1 ? null : stock;
  }
  // A pack without a size counts whole packs; its serving is no piece.
  if (item.amountUnit != InventoryAmountUnit.piece) {
    return null;
  }
  final pieceAmount = _pieceAmount(item, unit);
  if (pieceAmount == null) {
    return null;
  }
  // Pieces tracked by amount store fractions of a piece.
  final scale = item.usesAmountProgress ? item.amountScale : 1;
  final stock = (amount / pieceAmount * scale).round();
  return stock < 1 ? null : stock;
}

/// The stock of [pack] that [amount] of [from]'s stock holds, for another
/// pack of the same product: the same amount when both store it alike,
/// else converted through grams or milliliters. Null when it cannot be
/// told.
int? inventoryAmountInPack({
  required InventoryItem from,
  required int amount,
  required InventoryItem pack,
}) {
  if (from.amountUnit == pack.amountUnit &&
      from.amountScale == pack.amountScale &&
      from.usesAmountProgress == pack.usesAmountProgress) {
    return amount;
  }
  final eaten = inventoryStockInConsumedUnit(from, amount);
  if (eaten == null) {
    return null;
  }
  return inventoryStockAmountFor(pack, eaten.amount, eaten.unit);
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

/// The grams or milliliters that [amount] of [item]'s stock holds, in the
/// item's stored unit, the way back from [inventoryAmountForPlan]. Null
/// when they cannot be told, for a pack counted in whole packs or pieces
/// without a serving size.
({double amount, ConsumedUnit unit})? inventoryStockInConsumedUnit(
  InventoryItem item,
  int amount,
) {
  final scale = item.usesAmountProgress ? item.amountScale : 1;
  if (inventoryItemConsumedUnit(item) case final unit?) {
    return item.usesAmountProgress
        ? (amount: amount / item.amountScale, unit: unit)
        : null;
  }
  if (item.amountUnit != InventoryAmountUnit.piece) {
    return null;
  }
  for (final unit in ConsumedUnit.values) {
    if (_pieceAmount(item, unit) case final pieceAmount?) {
      return (amount: amount / scale * pieceAmount, unit: unit);
    }
  }
  return null;
}
