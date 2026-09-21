import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_offline_writes.dart';
import 'package:yamt/features/calories/data/calorie_product_image_url.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
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
const _calorieEntriesCollection = 'calorie_entries';
const _inventoryItemsCollection = 'inventory_items';
const _inventoryActivityEventsCollection = 'inventory_activity_events';

/// Defines firestore inventory calorie entry commit store.
class FirestoreInventoryCalorieEntryCommitStore
    implements InventoryCalorieEntryCommitStore {
  /// The firestore inventory calorie entry commit store.
  const new({
    required this.firestore,
    required this.currentUserId,
    required this.inventoryOwnerUserId,
    required this.actor,
    this.mutationBuilder = const InventoryCalorieEntryCommitMutationBuilder(),
  });

  /// The Firestore instance.
  final FirebaseFirestore firestore;

  /// The current user ID.
  final String? currentUserId;

  /// The inventory owner user ID.
  final String? inventoryOwnerUserId;

  /// The inventory activity actor.
  final InventoryActivityActor? actor;

  /// The mutation builder.
  final InventoryCalorieEntryCommitMutationBuilder mutationBuilder;

  @override
  Future<InventoryCalorieEntryCommitResult?> commitEntryAndInventory({
    required CalorieEntry entry,
    required PendingInventoryConsumption pendingConsumption,
  }) async {
    final entryUserId = _resolveEntryUserId(entry.userId);
    final inventoryUserId = _resolveInventoryUserId();
    if (entryUserId == null || inventoryUserId == null) {
      log(
        'Cannot commit calorie entry ${entry.id}: no user id resolved '
        '(entryUserId=${entry.userId}, '
        'currentUserId=$currentUserId, '
        'inventoryOwnerUserId=$inventoryOwnerUserId).',
        name: _commitStoreLogName,
      );
      return null;
    }
    if (pendingConsumption.amount < 1) {
      log(
        'Cannot commit calorie entry ${entry.id}: invalid pending amount '
        '${pendingConsumption.amount} for item ${pendingConsumption.itemId}.',
        name: _commitStoreLogName,
      );
      return null;
    }

    log(
      'Committing calorie entry ${entry.id} with inventory item '
      '${pendingConsumption.itemId} for inventory owner $inventoryUserId '
      '(amount=${pendingConsumption.amount}).',
      name: _commitStoreLogName,
    );

    // A batch instead of a transaction: Firestore queues batches while
    // offline, but transactions fail. The stock is computed from the local
    // copy, so two offline consumptions of the same item may overwrite each
    // other.
    try {
      final inventoryRef = _inventoryCollection(inventoryUserId)
          .doc(pendingConsumption.itemId);
      final inventorySnapshot = await readDocumentLocalFirst(inventoryRef);
      if (!inventorySnapshot.exists) {
        log(
          'Inventory item ${pendingConsumption.itemId} no longer exists '
          'while committing calorie entry ${entry.id}.',
          name: _commitStoreLogName,
        );
        return null;
      }

      final rawItem = Map<String, dynamic>.from(
        inventorySnapshot.data() ?? const <String, dynamic>{},
      )..['id'] = inventorySnapshot.id;

      final currentItem = InventoryItem.fromJson(rawItem);
      final committedItem = mutationBuilder.buildCommittedItem(
        item: currentItem,
        amount: pendingConsumption.amount,
        consumedAt: entry.loggedAt,
      );
      if (committedItem == null) {
        log(
          'Inventory commit rejected for calorie entry ${entry.id} '
          '(itemId=${currentItem.id}, '
          'quantity=${currentItem.quantity}, '
          'currentAmount=${currentItem.currentAmount}, '
          'requestedAmount=${pendingConsumption.amount}, '
          'usesAmountProgress=${currentItem.usesAmountProgress}).',
          name: _commitStoreLogName,
        );
        return null;
      }

      final normalizedEntry = entry.copyWith(
        userId: entryUserId,
        imageUrl: normalizeCalorieProductImageUrl(entry.imageUrl),
        updatedAt: DateTime.now(),
      );

      final batch = firestore.batch()
        ..set(
          _calorieEntriesCollectionRef(entryUserId).doc(normalizedEntry.id),
          normalizedEntry.toJson(),
        )
        ..update(
          inventoryRef,
          mutationBuilder.buildInventoryUpdate(committedItem),
        );
      final activityEvent = mutationBuilder.buildActivityEvent(
        actor: actor,
        beforeItem: currentItem,
        afterItem: committedItem,
        amount: pendingConsumption.amount,
        happenedAt: normalizedEntry.loggedAt,
      );
      if (activityEvent != null) {
        batch.set(
          _activityEventsCollectionRef(inventoryUserId).doc(activityEvent.id),
          activityEvent.toJson(),
        );
      }
      commitBatchInBackground(
        batch,
        failureMessage:
            'Server rejected calorie entry ${entry.id} with inventory item '
            '${pendingConsumption.itemId}.',
        logName: _commitStoreLogName,
      );

      log(
        'Batch queued for calorie entry ${entry.id} '
        '(itemId=${committedItem.id}, '
        'nextQuantity=${committedItem.quantity}, '
        'nextCurrentAmount=${committedItem.currentAmount}).',
        name: _commitStoreLogName,
      );

      return InventoryCalorieEntryCommitResult(
        itemId: committedItem.id,
        quantity: committedItem.quantity,
        currentAmount: committedItem.currentAmount,
      );
    } on Object catch (error, stackTrace) {
      log(
        'Failed to commit calorie entry ${entry.id} with inventory item '
        '${pendingConsumption.itemId}.',
        name: _commitStoreLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  String? _resolveEntryUserId(String entryUserId) {
    final trimmedCurrentUserId = currentUserId?.trim();
    if (trimmedCurrentUserId != null && trimmedCurrentUserId.isNotEmpty) {
      return trimmedCurrentUserId;
    }

    final normalizedEntryUserId = entryUserId.trim();
    if (normalizedEntryUserId.isNotEmpty) {
      return normalizedEntryUserId;
    }
    return null;
  }

  String? _resolveInventoryUserId() {
    final trimmedInventoryOwnerUserId = inventoryOwnerUserId?.trim();
    if (trimmedInventoryOwnerUserId != null &&
        trimmedInventoryOwnerUserId.isNotEmpty) {
      return trimmedInventoryOwnerUserId;
    }

    final trimmedCurrentUserId = currentUserId?.trim();
    if (trimmedCurrentUserId != null && trimmedCurrentUserId.isNotEmpty) {
      return trimmedCurrentUserId;
    }
    return null;
  }

  CollectionReference<Map<String, dynamic>> _inventoryCollection(
    String userId,
  ) {
    return firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_inventoryItemsCollection);
  }

  CollectionReference<Map<String, dynamic>> _calorieEntriesCollectionRef(
    String userId,
  ) {
    return firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_calorieEntriesCollection);
  }

  CollectionReference<Map<String, dynamic>> _activityEventsCollectionRef(
    String userId,
  ) {
    return firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_inventoryActivityEventsCollection);
  }
}
