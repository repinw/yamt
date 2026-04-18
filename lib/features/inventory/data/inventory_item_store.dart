import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_atomic_replace_service.dart';

const String _storeLogName = 'FirestoreInventoryItemStore';
const String _usersCollection = 'users';
const String _inventoryItemsCollection = 'inventory_items';

/// Defines inventory item document.
class InventoryItemDocument {
  /// The inventory item document.
  const InventoryItemDocument({required this.id, required this.data});

  /// The id.
  final String id;

  /// The data.
  final Map<String, dynamic> data;
}

/// Defines inventory item store.
abstract interface class InventoryItemStore {
  /// Read all.
  Future<List<InventoryItemDocument>> readAll({required String userId});

  /// Watch all.
  Stream<List<InventoryItemDocument>> watchAll({required String userId});

  /// Replace all.
  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  });

  /// Upsert all.
  Future<bool> upsertAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  });
}

/// Defines firestore inventory item store.
class FirestoreInventoryItemStore implements InventoryItemStore {
  /// The firestore inventory item store.
  const FirestoreInventoryItemStore({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  FirestoreAtomicReplaceService get _atomicReplaceService {
    return FirestoreAtomicReplaceService(firestore: _firestore);
  }

  @override
  Future<List<InventoryItemDocument>> readAll({required String userId}) async {
    final snapshot = await _collection(userId).get();
    return _mapSnapshot(snapshot);
  }

  @override
  Stream<List<InventoryItemDocument>> watchAll({required String userId}) {
    return _collection(userId).snapshots().map(_mapSnapshot);
  }

  @override
  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    try {
      await _atomicReplaceService.replaceAll(
        collection: _collection(userId),
        documentsById: documentsById,
      );
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to replace inventory items for user $userId.',
        name: _storeLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<bool> upsertAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    try {
      await _atomicReplaceService.upsertAll(
        collection: _collection(userId),
        documentsById: documentsById,
      );
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to upsert inventory items for user $userId.',
        name: _storeLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_inventoryItemsCollection);
  }

  List<InventoryItemDocument> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(
          (document) => InventoryItemDocument(
            id: document.id,
            data: Map<String, dynamic>.from(document.data()),
          ),
        )
        .toList(growable: false);
  }
}
