import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_product_image_url.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';

const _commitStoreLogName = 'InventoryCalorieEntryCommitStore';
const _usersCollection = 'users';
const _calorieEntriesCollection = 'calorie_entries';
const _inventoryItemsCollection = 'inventory_items';

final inventoryCalorieEntryCommitStoreProvider =
    Provider<InventoryCalorieEntryCommitStore>((ref) {
      final currentUserId = ref
          .watch(authStateChangesProvider)
          .asData
          ?.value
          ?.uid;
      final inventoryOwnerUserId = ref.watch(
        effectiveHouseholdDataOwnerUserIdProvider,
      );
      final firestore = ref.watch(firebaseFirestoreProvider);
      if (firestore == null) {
        return const _UnavailableInventoryCalorieEntryCommitStore();
      }

      return FirestoreInventoryCalorieEntryCommitStore(
        firestore: firestore,
        currentUserId: currentUserId,
        inventoryOwnerUserId: inventoryOwnerUserId,
      );
    });

abstract interface class InventoryCalorieEntryCommitStore {
  Future<InventoryCalorieEntryCommitResult?> commitEntryAndInventory({
    required CalorieEntry entry,
    required PendingInventoryConsumption pendingConsumption,
  });
}

class InventoryCalorieEntryCommitResult {
  const InventoryCalorieEntryCommitResult({
    required this.itemId,
    required this.quantity,
    required this.currentAmount,
  });

  final String itemId;
  final int quantity;
  final int currentAmount;
}

class FirestoreInventoryCalorieEntryCommitStore
    implements InventoryCalorieEntryCommitStore {
  const FirestoreInventoryCalorieEntryCommitStore({
    required FirebaseFirestore firestore,
    required String? currentUserId,
    required String? inventoryOwnerUserId,
  }) : _firestore = firestore,
       _currentUserId = currentUserId,
       _inventoryOwnerUserId = inventoryOwnerUserId;

  final FirebaseFirestore _firestore;
  final String? _currentUserId;
  final String? _inventoryOwnerUserId;

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
        'currentUserId=$_currentUserId, '
        'inventoryOwnerUserId=$_inventoryOwnerUserId).',
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

    try {
      return await _firestore.runTransaction((transaction) async {
        final inventoryRef = _inventoryCollection(
          inventoryUserId,
        ).doc(pendingConsumption.itemId);
        final inventorySnapshot = await transaction.get(inventoryRef);
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
        final committedItem = _buildCommittedItem(
          item: currentItem,
          amount: pendingConsumption.amount,
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

        transaction.set(
          _calorieEntriesCollectionRef(entryUserId).doc(normalizedEntry.id),
          normalizedEntry.toJson(),
        );
        transaction.update(inventoryRef, _buildInventoryUpdate(committedItem));

        log(
          'Transaction prepared for calorie entry ${entry.id} '
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
      });
    } catch (error, stackTrace) {
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
    final currentUserId = _currentUserId?.trim();
    if (currentUserId != null && currentUserId.isNotEmpty) {
      return currentUserId;
    }

    final normalizedEntryUserId = entryUserId.trim();
    if (normalizedEntryUserId.isNotEmpty) {
      return normalizedEntryUserId;
    }
    return null;
  }

  String? _resolveInventoryUserId() {
    final inventoryOwnerUserId = _inventoryOwnerUserId?.trim();
    if (inventoryOwnerUserId != null && inventoryOwnerUserId.isNotEmpty) {
      return inventoryOwnerUserId;
    }

    final currentUserId = _currentUserId?.trim();
    if (currentUserId != null && currentUserId.isNotEmpty) {
      return currentUserId;
    }
    return null;
  }

  CollectionReference<Map<String, dynamic>> _inventoryCollection(
    String userId,
  ) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_inventoryItemsCollection);
  }

  CollectionReference<Map<String, dynamic>> _calorieEntriesCollectionRef(
    String userId,
  ) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_calorieEntriesCollection);
  }
}

class _UnavailableInventoryCalorieEntryCommitStore
    implements InventoryCalorieEntryCommitStore {
  const _UnavailableInventoryCalorieEntryCommitStore();

  @override
  Future<InventoryCalorieEntryCommitResult?> commitEntryAndInventory({
    required CalorieEntry entry,
    required PendingInventoryConsumption pendingConsumption,
  }) async {
    return null;
  }
}

InventoryItem? _buildCommittedItem({
  required InventoryItem item,
  required int amount,
}) {
  if (amount < 1) {
    return null;
  }

  if (item.usesAmountProgress) {
    if (item.currentAmount < amount) {
      return null;
    }

    final nextCurrentAmount = item.currentAmount - amount;
    return item.copyWith(
      currentAmount: nextCurrentAmount,
      quantity: _quantityForCurrentAmount(
        item: item,
        currentAmount: nextCurrentAmount,
      ),
    );
  }

  if (item.quantity < amount) {
    return null;
  }
  return item.copyWith(quantity: item.quantity - amount);
}

int _quantityForCurrentAmount({
  required InventoryItem item,
  required int currentAmount,
}) {
  final initialAmount = item.initialAmount;
  final initialQuantity = item.initialQuantity;
  if (initialAmount < 1 || initialQuantity < 1) {
    return item.quantity;
  }

  final ratio = currentAmount / initialAmount;
  final projectedQuantity = (initialQuantity * ratio).ceil();
  if (projectedQuantity < 0) {
    return 0;
  }
  if (projectedQuantity > initialQuantity) {
    return initialQuantity;
  }
  return projectedQuantity;
}

Map<String, dynamic> _buildInventoryUpdate(InventoryItem item) {
  return <String, dynamic>{
    'quantity': item.quantity,
    'current_amount': item.currentAmount,
  };
}
