import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_offline_writes.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_mutation_builder.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_result.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_store_contract.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';

const _commitStoreLogName = 'InventoryCalorieEntryCommitStore';
const _householdsCollection = 'households';
const _inventoryItemsCollection = 'inventory_items';
const _inventoryActivityEventsCollection = 'inventory_activity_events';

/// Defines firestore inventory calorie entry commit store.
class FirestoreInventoryCalorieEntryCommitStore
    implements InventoryCalorieEntryCommitStore {
  /// The firestore inventory calorie entry commit store.
  const new({
    required this.firestore,
    required this.diary,
    required this.householdCipher,
    required this.actor,
    this.mutationBuilder = const InventoryCalorieEntryCommitMutationBuilder(),
  });

  /// The Firestore instance.
  final FirebaseFirestore firestore;

  /// The diary repository, which stages the entry write.
  final FirestoreCalorieLogRepository diary;

  /// The household cipher, or `null` while its key is not ready.
  final HouseholdCipher? householdCipher;

  /// The inventory activity actor.
  final InventoryActivityActor? actor;

  /// The mutation builder.
  final InventoryCalorieEntryCommitMutationBuilder mutationBuilder;

  @override
  Future<List<InventoryCalorieEntryCommitResult>?>
  commitEntryAndInventoryItems({
    required CalorieEntry entry,
    required List<PendingInventoryConsumption> pendingConsumptions,
  }) async {
    final itemIds = pendingConsumptions.map((pending) => pending.itemId);
    if (pendingConsumptions.isEmpty ||
        itemIds.toSet().length != pendingConsumptions.length ||
        pendingConsumptions.any((pending) => pending.amount < 1)) {
      log(
        'Cannot commit calorie entry ${entry.id}: invalid pending '
        'consumptions $itemIds.',
        name: _commitStoreLogName,
      );
      return null;
    }
    return await _write(
      entry,
      keepEntry: true,
      skipMissingItems: false,
      type: InventoryActivityEventType.itemConsumed,
      happenedAt: entry.loggedAt,
      changes: {
        for (final pending in pendingConsumptions)
          pending.itemId: (
            pending.amount,
            (item) =>
                item.reducedBy(pending.amount, consumedAt: entry.loggedAt),
          ),
      },
    );
  }

  @override
  Future<List<InventoryCalorieEntryCommitResult>?> deleteEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  }) => _restore(entry, amountsByItemId, keepEntry: false);

  @override
  Future<List<InventoryCalorieEntryCommitResult>?> saveEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  }) => _restore(entry, amountsByItemId, keepEntry: true);

  Future<List<InventoryCalorieEntryCommitResult>?> _restore(
    CalorieEntry entry,
    Map<String, int> amounts, {
    required bool keepEntry,
  }) async {
    if (amounts.values.any((amount) => amount < 1)) {
      log(
        'Cannot restore stock for entry ${entry.id}: $amounts.',
        name: _commitStoreLogName,
      );
      return null;
    }
    return await _write(
      entry,
      keepEntry: keepEntry,
      // A missing item is skipped: the rest of the stock still comes back.
      skipMissingItems: true,
      type: InventoryActivityEventType.itemRestored,
      happenedAt: DateTime.now(),
      changes: {
        for (final MapEntry(key: itemId, value: amount) in amounts.entries)
          itemId: (amount, (item) => item.restoredBy(amount)),
      },
    );
  }

  /// Saves [entry] with [keepEntry] or deletes it otherwise, and applies
  /// [changes] to their items, all in one batch: Firestore queues batches
  /// offline, but transactions fail. The stock comes from the local copy, so
  /// two offline writes to the same item may overwrite each other.
  Future<List<InventoryCalorieEntryCommitResult>?> _write(
    CalorieEntry entry, {
    required bool keepEntry,
    required bool skipMissingItems,
    required InventoryActivityEventType type,
    required DateTime happenedAt,
    required Map<String, (int, InventoryItem? Function(InventoryItem))> changes,
  }) async {
    final household = householdCipher;
    if (diary.dataCipher == null || household == null) {
      log(
        'Cannot write calorie entry ${entry.id}: no data or household key.',
        name: _commitStoreLogName,
      );
      return null;
    }
    try {
      final batch = firestore.batch();
      final results = <InventoryCalorieEntryCommitResult>[];
      for (final MapEntry(key: itemId, value: (amount, change))
          in changes.entries) {
        final result = await _addItemChange(
          batch: batch,
          household: household,
          itemId: itemId,
          amount: amount,
          type: type,
          happenedAt: happenedAt,
          change: change,
        );
        if (result != null) {
          results.add(result);
        } else if (!skipMissingItems) {
          return null;
        }
      }
      if (results.isNotEmpty) {
        // Staged last, so the diary cache changes only when the batch is
        // committed.
        if (keepEntry) {
          await diary.stage(batch, entry);
        } else {
          diary.stageDelete(batch, entry.id);
        }
        commitBatchInBackground(
          batch,
          failureMessage: 'Server rejected entry ${entry.id} with its stock.',
          logName: _commitStoreLogName,
        );
      }
      return results;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to write calorie entry ${entry.id} with its stock.',
        name: _commitStoreLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Adds the stock change of item [itemId] and its activity event to
  /// [batch]. Returns null when the item is gone or [change] rejects it.
  Future<InventoryCalorieEntryCommitResult?> _addItemChange({
    required WriteBatch batch,
    required HouseholdCipher household,
    required String itemId,
    required int amount,
    required InventoryActivityEventType type,
    required DateTime happenedAt,
    required InventoryItem? Function(InventoryItem item) change,
  }) async {
    final inventoryCollection = _inventoryCollection(household);
    final inventoryRef = inventoryCollection.reference.doc(itemId);
    final inventorySnapshot = await readDocumentLocalFirst(inventoryRef);
    final storedItem = await inventoryCollection.open(inventorySnapshot);
    final currentItem = storedItem == null
        ? null
        : InventoryItem.fromJson(
            Map<String, dynamic>.from(storedItem)
              ..['id'] = inventorySnapshot.id,
          );
    final changedItem = currentItem == null ? null : change(currentItem);
    if (storedItem == null || currentItem == null || changedItem == null) {
      log(
        'Stock change of $amount rejected for item $itemId: the item is gone '
        'or its stock does not allow it.',
        name: _commitStoreLogName,
      );
      return null;
    }

    // The item is encrypted as a whole, so the batch writes the full
    // document instead of updating single fields.
    batch.set(
      inventoryRef,
      await inventoryCollection.seal(inventoryRef.id, {
        ...storedItem,
        ...mutationBuilder.buildInventoryUpdate(changedItem),
      }),
    );
    final activityEvent = mutationBuilder.buildActivityEvent(
      type: type,
      actor: actor,
      beforeItem: currentItem,
      afterItem: changedItem,
      amount: amount,
      happenedAt: happenedAt,
    );
    if (activityEvent != null) {
      final activityCollection = _activityEventsCollection(household);
      batch.set(
        activityCollection.reference.doc(activityEvent.id),
        await activityCollection.seal(activityEvent.id, activityEvent.toJson()),
      );
    }
    return InventoryCalorieEntryCommitResult(
      itemId: changedItem.id,
      quantity: changedItem.quantity,
      currentAmount: changedItem.currentAmount,
    );
  }

  SealedCollection _inventoryCollection(HouseholdCipher household) {
    return SealedCollection(
      firestore
          .collection(_householdsCollection)
          .doc(household.householdId)
          .collection(_inventoryItemsCollection),
      cipher: household.cipher,
      plaintextFields: inventoryItemPlaintextFields,
    );
  }

  SealedCollection _activityEventsCollection(HouseholdCipher household) {
    return SealedCollection(
      firestore
          .collection(_householdsCollection)
          .doc(household.householdId)
          .collection(_inventoryActivityEventsCollection),
      cipher: household.cipher,
      plaintextFields: inventoryActivityEventPlaintextFields,
    );
  }
}
