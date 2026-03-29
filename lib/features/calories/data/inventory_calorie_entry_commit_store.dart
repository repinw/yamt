import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_product_image_url.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';

const _commitStoreLogName = 'InventoryCalorieEntryCommitStore';
const _usersCollection = 'users';
const _calorieEntriesCollection = 'calorie_entries';
const _inventoryItemsCollection = 'inventory_items';

final inventoryCalorieEntryCommitStoreProvider =
    Provider<InventoryCalorieEntryCommitStore>((ref) {
      final authState = ref.watch(authStateChangesProvider);
      final currentUserId = authState.asData?.value?.uid;
      final firestore = _resolveFirestore();
      if (firestore == null) {
        return const _UnavailableInventoryCalorieEntryCommitStore();
      }

      return FirestoreInventoryCalorieEntryCommitStore(
        firestore: firestore,
        currentUserId: currentUserId,
      );
    });

abstract interface class InventoryCalorieEntryCommitStore {
  Future<InventoryCalorieEntryCommitResult?> commitEntryAndInventory({
    required CalorieEntry entry,
    required PendingInventoryConsumption pendingConsumption,
  });
}

class InventoryCalorieEntryCommitResult {
  const InventoryCalorieEntryCommitResult({required this.committedItem});

  final InventoryItem committedItem;
}

class FirestoreInventoryCalorieEntryCommitStore
    implements InventoryCalorieEntryCommitStore {
  const FirestoreInventoryCalorieEntryCommitStore({
    required FirebaseFirestore firestore,
    required String? currentUserId,
  }) : _firestore = firestore,
       _currentUserId = currentUserId;

  final FirebaseFirestore _firestore;
  final String? _currentUserId;

  @override
  Future<InventoryCalorieEntryCommitResult?> commitEntryAndInventory({
    required CalorieEntry entry,
    required PendingInventoryConsumption pendingConsumption,
  }) async {
    final userId = _resolveUserId(entry.userId);
    if (userId == null || pendingConsumption.amount < 1) {
      return null;
    }

    try {
      return await _firestore.runTransaction((transaction) async {
        final inventoryRef = _inventoryCollection(
          userId,
        ).doc(pendingConsumption.itemId);
        final inventorySnapshot = await transaction.get(inventoryRef);
        if (!inventorySnapshot.exists) {
          return null;
        }

        final rawItem = Map<String, dynamic>.from(
          inventorySnapshot.data() ?? const <String, dynamic>{},
        );
        final id = rawItem['id'];
        if (id is! String || id.trim().isEmpty) {
          rawItem['id'] = inventorySnapshot.id;
        }

        final currentItem = InventoryItem.fromJson(rawItem);
        final committedItem = _buildCommittedItem(
          item: currentItem,
          amount: pendingConsumption.amount,
        );
        if (committedItem == null) {
          return null;
        }

        final normalizedEntry = entry.copyWith(
          userId: userId,
          imageUrl: normalizeCalorieProductImageUrl(entry.imageUrl),
          updatedAt: DateTime.now(),
        );

        transaction.set(
          _calorieEntriesCollectionRef(userId).doc(normalizedEntry.id),
          normalizedEntry.toJson(),
        );
        transaction.set(inventoryRef, committedItem.toJson());

        return InventoryCalorieEntryCommitResult(committedItem: committedItem);
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

  String? _resolveUserId(String entryUserId) {
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

FirebaseFirestore? _resolveFirestore() {
  try {
    return FirebaseFirestore.instance;
  } catch (error, stackTrace) {
    log(
      'Falling back to unavailable inventory calorie entry commit store.',
      name: _commitStoreLogName,
      error: error,
      stackTrace: stackTrace,
    );
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
