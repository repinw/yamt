import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_offline_writes.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/data/calorie_entry_document_codec.dart';
import 'package:yamt/features/calories/data/calorie_product_image_url.dart';
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
const _usersCollection = 'users';
const _householdsCollection = 'households';
const _calorieEntriesCollection = 'calorie_entries';
const _inventoryItemsCollection = 'inventory_items';
const _inventoryActivityEventsCollection = 'inventory_activity_events';

/// Defines firestore inventory calorie entry commit store.
class FirestoreInventoryCalorieEntryCommitStore
    implements InventoryCalorieEntryCommitStore {
  /// The firestore inventory calorie entry commit store.
  const new({
    required this.firestore,
    required this.dataCipher,
    required this.householdCipher,
    required this.actor,
    this.mutationBuilder = const InventoryCalorieEntryCommitMutationBuilder(),
  });

  /// The Firestore instance.
  final FirebaseFirestore firestore;

  /// The signed-in user and the cipher for their diary, or `null` while the
  /// data key is not ready.
  final UserDataCipher? dataCipher;

  /// The active household and its key, or `null` while the household key is
  /// not ready.
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
    final cipher = dataCipher;
    final household = householdCipher;
    if (cipher == null || household == null) {
      log(
        'Cannot commit calorie entry ${entry.id}: no data or household key.',
        name: _commitStoreLogName,
      );
      return null;
    }
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

    // A batch instead of a transaction: Firestore queues batches while
    // offline, but transactions fail. The stock is computed from the local
    // copy, so two offline consumptions of the same item may overwrite each
    // other.
    try {
      final normalizedEntry = entry.copyWith(
        userId: cipher.uid,
        imageUrl: normalizeCalorieProductImageUrl(entry.imageUrl),
        updatedAt: DateTime.now(),
      );
      final entryRef = _calorieEntriesCollectionRef(cipher.uid)
          .doc(normalizedEntry.id);
      final batch = firestore.batch()
        ..set(
          entryRef,
          await encodeCalorieEntryDocument(
            normalizedEntry,
            reference: entryRef,
            cipher: cipher.cipher,
          ),
        );
      final results = <InventoryCalorieEntryCommitResult>[];
      for (final pending in pendingConsumptions) {
        final result = await _addItemChange(
          batch: batch,
          household: household,
          itemId: pending.itemId,
          amount: pending.amount,
          type: InventoryActivityEventType.itemConsumed,
          happenedAt: normalizedEntry.loggedAt,
          change: (item) => item.reducedBy(
            pending.amount,
            consumedAt: normalizedEntry.loggedAt,
          ),
        );
        if (result == null) {
          return null;
        }
        results.add(result);
      }
      commitBatchInBackground(
        batch,
        failureMessage:
            'Server rejected calorie entry ${entry.id} with inventory items '
            '${itemIds.join(', ')}.',
        logName: _commitStoreLogName,
      );
      return results;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to commit calorie entry ${entry.id} with inventory items '
        '${itemIds.join(', ')}.',
        name: _commitStoreLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<List<InventoryCalorieEntryCommitResult>?> deleteEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  }) async {
    final cipher = dataCipher;
    final household = householdCipher;
    if (cipher == null ||
        household == null ||
        amountsByItemId.values.any((amount) => amount < 1)) {
      log(
        'Cannot delete calorie entry ${entry.id} with its stock: no data key, '
        'no household key, or an amount below 1 ($amountsByItemId).',
        name: _commitStoreLogName,
      );
      return null;
    }
    try {
      final batch = firestore.batch()
        ..delete(_calorieEntriesCollectionRef(cipher.uid).doc(entry.id));
      final results = <InventoryCalorieEntryCommitResult>[];
      for (final MapEntry(key: itemId, value: amount)
          in amountsByItemId.entries) {
        final result = await _addItemChange(
          batch: batch,
          household: household,
          itemId: itemId,
          amount: amount,
          type: InventoryActivityEventType.itemRestored,
          happenedAt: DateTime.now(),
          change: (item) => item.restoredBy(amount),
        );
        // A missing item is skipped: the rest of the stock still comes back.
        if (result != null) {
          results.add(result);
        }
      }
      if (results.isNotEmpty) {
        commitBatchInBackground(
          batch,
          failureMessage: 'Server rejected deleting entry ${entry.id}.',
          logName: _commitStoreLogName,
        );
      }
      return results;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to delete calorie entry ${entry.id} with its stock.',
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
    if (storedItem == null) {
      log(
        'Inventory item $itemId no longer exists.',
        name: _commitStoreLogName,
      );
      return null;
    }

    final currentItem = InventoryItem.fromJson(
      Map<String, dynamic>.from(storedItem)..['id'] = inventorySnapshot.id,
    );
    final changedItem = change(currentItem);
    if (changedItem == null) {
      log(
        'Stock change of $amount rejected for item ${currentItem.id} '
        '(quantity=${currentItem.quantity}, '
        'currentAmount=${currentItem.currentAmount}).',
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

  CollectionReference<Map<String, dynamic>> _calorieEntriesCollectionRef(
    String userId,
  ) {
    return firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_calorieEntriesCollection);
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
