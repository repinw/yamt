import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/data/inventory_calorie_entry_commit_result.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';

/// Defines inventory calorie entry commit store.
abstract interface class InventoryCalorieEntryCommitStore {
  /// Commit entry and inventory.
  Future<InventoryCalorieEntryCommitResult?> commitEntryAndInventory({
    required CalorieEntry entry,
    required PendingInventoryConsumption pendingConsumption,
  });
}
