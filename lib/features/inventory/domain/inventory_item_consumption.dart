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
  const PendingInventoryConsumption({
    required this.id,
    required this.itemId,
    required this.amount,
  });

  /// The id.
  final String id;

  /// The item id.
  final String itemId;

  /// The amount.
  final int amount;
}
