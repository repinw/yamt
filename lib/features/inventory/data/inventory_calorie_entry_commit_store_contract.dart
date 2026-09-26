import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/data/inventory_calorie_entry_commit_result.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';

/// Defines inventory calorie entry commit store.
abstract interface class InventoryCalorieEntryCommitStore {
  /// Saves [entry] and takes every pending consumption out of its stock item
  /// in one write. Returns the new stock per item in the given order, or
  /// null when nothing was written.
  Future<List<InventoryCalorieEntryCommitResult>?>
  commitEntryAndInventoryItems({
    required CalorieEntry entry,
    required List<PendingInventoryConsumption> pendingConsumptions,
  });
}
