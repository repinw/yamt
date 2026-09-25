import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Defines inventory item consumption extension extension.
extension InventoryItemConsumptionExtension on InventoryItem {
  /// Returns the newer timestamp while keeping `lastConsumedAt` monotonic.
  DateTime latestConsumedAtOr(DateTime candidate) {
    final current = lastConsumedAt;
    if (current == null || candidate.isAfter(current)) {
      return candidate;
    }
    return current;
  }
}

/// Defines pending inventory consumption.
class PendingInventoryConsumption {
  /// The pending inventory consumption.
  const new({required this.id, required this.itemId, required this.amount});

  /// The id.
  final String id;

  /// The item id.
  final String itemId;

  /// The amount.
  final int amount;
}

/// The stock of [item] that can be eaten, in its stored amount unit.
///
/// Items tracked by amount count their current amount. Other items count
/// their quantity. Returns null when nothing can be eaten.
int? consumableInventoryAmount(InventoryItem item) {
  if (item.usesAmountProgress) {
    if (item.amountUnit == null || item.currentAmount < 1) {
      return null;
    }
    return item.currentAmount;
  }
  if (item.quantity < 1) {
    return null;
  }
  return item.quantity;
}
