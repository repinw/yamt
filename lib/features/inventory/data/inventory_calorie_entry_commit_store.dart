// Commit store stays class-based for provider overrides and test fakes.

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/inventory/data/'
    'firestore_inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';

part 'inventory_calorie_entry_commit_store.g.dart';

/// The inventory calorie entry commit store provider.
@riverpod
InventoryCalorieEntryCommitStore inventoryCalorieEntryCommitStore(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final diary = ref.watch(calorieLogRepositoryProvider);
  if (firestore == null || diary is! FirestoreCalorieLogRepository) {
    return const _UnavailableInventoryCalorieEntryCommitStore();
  }

  return FirestoreInventoryCalorieEntryCommitStore(
    firestore: firestore,
    diary: diary,
    householdCipher: ref.watch(householdCipherProvider),
    actor: ref.watch(inventoryActivityActorProvider),
  );
}

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

  /// Saves [entry] and gives each item of [amountsByItemId] its amount back
  /// in one write. Items that no longer exist are skipped. Returns like
  /// [deleteEntryAndRestoreItems].
  Future<List<InventoryCalorieEntryCommitResult>?> saveEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  });
}

/// Defines inventory calorie entry commit result.
class InventoryCalorieEntryCommitResult {
  /// The inventory calorie entry commit result.
  const new({
    required this.itemId,
    required this.quantity,
    required this.currentAmount,
  });

  /// The item id.
  final String itemId;

  /// The quantity.
  final int quantity;

  /// The current amount.
  final int currentAmount;
}

class _UnavailableInventoryCalorieEntryCommitStore
    implements InventoryCalorieEntryCommitStore {
  const new();

  @override
  Future<List<InventoryCalorieEntryCommitResult>?>
  commitEntryAndInventoryItems({
    required CalorieEntry entry,
    required List<PendingInventoryConsumption> pendingConsumptions,
  }) async {
    return null;
  }

  @override
  Future<List<InventoryCalorieEntryCommitResult>?> deleteEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  }) async {
    return null;
  }

  @override
  Future<List<InventoryCalorieEntryCommitResult>?> saveEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  }) async {
    return null;
  }
}
