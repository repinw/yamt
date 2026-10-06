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

  /// Deletes [entry] and gives each item of [amountsByItemId] its amount
  /// back in one write. Items that no longer exist are skipped. Returns the
  /// new stock of the restored items, an empty list when no item exists (then
  /// nothing was written), or null when nothing was written.
  Future<List<InventoryCalorieEntryCommitResult>?> deleteEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  });
}
