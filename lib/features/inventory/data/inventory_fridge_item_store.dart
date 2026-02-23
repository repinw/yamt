import 'dart:developer' show log;
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

const String _storeLogName = 'FirestoreInventoryFridgeItemStore';
const String _usersCollection = 'users';
const String _inventoryItemsCollection = 'inventory_items';
const int _maxFirestoreBatchOperations = 500;

class InventoryFridgeItemDocument {
  const InventoryFridgeItemDocument({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}

abstract interface class InventoryFridgeItemStore {
  Future<List<InventoryFridgeItemDocument>> readAll({required String userId});

  Stream<List<InventoryFridgeItemDocument>> watchAll({required String userId});

  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  });

  Future<bool> upsertAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  });
}

class FirestoreInventoryFridgeItemStore implements InventoryFridgeItemStore {
  const FirestoreInventoryFridgeItemStore({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<List<InventoryFridgeItemDocument>> readAll({
    required String userId,
  }) async {
    final snapshot = await _collection(userId).get();
    return _mapSnapshot(snapshot);
  }

  @override
  Stream<List<InventoryFridgeItemDocument>> watchAll({required String userId}) {
    return _collection(userId).snapshots().map(_mapSnapshot);
  }

  @override
  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    try {
      await _replaceAllUnsafe(userId: userId, documentsById: documentsById);
      return true;
    } catch (error, stackTrace) {
      log(
        'Failed to replace inventory items for user $userId',
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
      await _upsertAllUnsafe(userId: userId, documentsById: documentsById);
      return true;
    } catch (error, stackTrace) {
      log(
        'Failed to upsert inventory items for user $userId',
        name: _storeLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> _replaceAllUnsafe({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    // Intentional tradeoff: read-diff-write without transaction.
    // Concurrent writers between read and commit can race.
    // For current inventory size this is acceptable.
    final collection = _collection(userId);
    final existingSnapshot = await collection.get();
    final operations = <_InventoryWriteOperation>[
      ..._upsertOperations(
        collection: collection,
        documentsById: documentsById,
      ),
      ..._deleteOperations(
        existingSnapshot: existingSnapshot,
        documentsById: documentsById,
      ),
    ];
    await _commitInChunks(operations);
  }

  Future<void> _upsertAllUnsafe({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    final collection = _collection(userId);
    final operations = _upsertOperations(
      collection: collection,
      documentsById: documentsById,
    );
    await _commitInChunks(operations);
  }

  List<_InventoryWriteOperation> _upsertOperations({
    required CollectionReference<Map<String, dynamic>> collection,
    required Map<String, Map<String, dynamic>> documentsById,
  }) {
    return documentsById.entries
        .map(
          (entry) => _InventoryWriteOperation.set(
            collection.doc(entry.key),
            entry.value,
          ),
        )
        .toList(growable: false);
  }

  List<_InventoryWriteOperation> _deleteOperations({
    required QuerySnapshot<Map<String, dynamic>> existingSnapshot,
    required Map<String, Map<String, dynamic>> documentsById,
  }) {
    return existingSnapshot.docs
        .where((document) => !documentsById.containsKey(document.id))
        .map((document) => _InventoryWriteOperation.delete(document.reference))
        .toList(growable: false);
  }

  Future<void> _commitInChunks(
    List<_InventoryWriteOperation> operations,
  ) async {
    for (final chunk in InventoryWriteOperationChunker.chunk(
      operations: operations,
      maxChunkSize: _maxFirestoreBatchOperations,
    )) {
      final batch = _firestore.batch();
      for (final operation in chunk) {
        operation.apply(batch);
      }
      await batch.commit();
    }
  }

  List<InventoryFridgeItemDocument> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map(_toDocument).toList(growable: false);
  }

  InventoryFridgeItemDocument _toDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return InventoryFridgeItemDocument(
      id: document.id,
      data: Map<String, dynamic>.from(document.data()),
    );
  }

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_inventoryItemsCollection);
  }
}

class InventoryWriteOperationChunker {
  const InventoryWriteOperationChunker._();

  static Iterable<List<T>> chunk<T>({
    required List<T> operations,
    required int maxChunkSize,
  }) sync* {
    if (maxChunkSize < 1) {
      throw ArgumentError.value(
        maxChunkSize,
        'maxChunkSize',
        'Must be greater than zero.',
      );
    }
    if (operations.isEmpty) {
      return;
    }

    for (var start = 0; start < operations.length; start += maxChunkSize) {
      final end = math.min(start + maxChunkSize, operations.length);
      yield operations.sublist(start, end);
    }
  }
}

class _InventoryWriteOperation {
  const _InventoryWriteOperation.set(this.reference, this.data)
    : _delete = false;

  const _InventoryWriteOperation.delete(this.reference)
    : data = null,
      _delete = true;

  final DocumentReference<Map<String, dynamic>> reference;
  final Map<String, dynamic>? data;
  final bool _delete;

  void apply(WriteBatch batch) {
    if (_delete) {
      batch.delete(reference);
      return;
    }
    batch.set(reference, data!);
  }
}
