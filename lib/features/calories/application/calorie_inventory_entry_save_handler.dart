import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';

part 'calorie_inventory_entry_save_handler.g.dart';

/// Persists an inventory-backed calorie entry with its pending stock change.
typedef CalorieInventoryEntrySaveHandler =
    Future<bool> Function({
      required CalorieEntry entry,
      required String pendingConsumptionId,
    });

/// Discards an uncommitted pending inventory consumption.
typedef CalorieInventoryPendingConsumptionDiscarder =
    Future<void> Function(String pendingConsumptionId);

/// Provides inventory-backed calorie entry persistence when inventory is wired.
@riverpod
CalorieInventoryEntrySaveHandler? calorieInventoryEntrySaveHandler(Ref ref) {
  return null;
}

/// Provides cleanup for pending inventory consumption when inventory is wired.
@riverpod
CalorieInventoryPendingConsumptionDiscarder?
calorieInventoryPendingConsumptionDiscarder(Ref ref) {
  return null;
}
