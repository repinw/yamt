import 'package:yamt/features/inventory/domain/inventory_item.dart';

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
