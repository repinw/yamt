import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';

const String _storeLogName = 'FirestoreInventoryFridgeItemStore';
const String _usersCollection = 'users';
const String _inventoryItemsCollection = 'inventory_items';
const int _maxFirestoreBatchOperations = 500;
const int _maxFirestoreTransactionWrites = 500;
const int _maxStaleDeleteCandidatesPerTransaction = 100;

class InventoryFridgeItemDocument {
  const InventoryFridgeItemDocument({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}

class _StaleDocumentDeleteCandidate {
  const _StaleDocumentDeleteCandidate({
    required this.reference,
    required this.expectedData,
  });

  final DocumentReference<Map<String, dynamic>> reference;
  final Map<String, dynamic> expectedData;
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
  }) : _firestore = firestore,
       _onBeforeDeleteStaleDocuments = null;

  const FirestoreInventoryFridgeItemStore.testing({
    required FirebaseFirestore firestore,
    Future<void> Function()? onBeforeDeleteStaleDocuments,
  }) : _firestore = firestore,
       _onBeforeDeleteStaleDocuments = onBeforeDeleteStaleDocuments;

  final FirebaseFirestore _firestore;
  final Future<void> Function()? _onBeforeDeleteStaleDocuments;

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
    final collection = _collection(userId);
    final existingSnapshot = await collection.get();
    final staleDeleteCandidates = _staleDeleteCandidates(
      existingSnapshot: existingSnapshot,
      documentsById: documentsById,
    );

    if (_canRunAtomicReplaceAll(
      upsertCount: documentsById.length,
      staleDeleteCount: staleDeleteCandidates.length,
    )) {
      await _onBeforeDeleteStaleDocuments?.call();
      await _replaceAllAtomically(
        collection: collection,
        documentsById: documentsById,
        staleDeleteCandidates: staleDeleteCandidates,
      );
      return;
    }

    await _commitInChunks(
      _upsertOperations(collection: collection, documentsById: documentsById),
    );
    await _onBeforeDeleteStaleDocuments?.call();
    await _deleteStaleDocumentsIfUnchanged(
      staleDeleteCandidates: staleDeleteCandidates,
    );
  }

  bool _canRunAtomicReplaceAll({
    required int upsertCount,
    required int staleDeleteCount,
  }) {
    return upsertCount + staleDeleteCount <= _maxFirestoreTransactionWrites;
  }

  Future<void> _replaceAllAtomically({
    required CollectionReference<Map<String, dynamic>> collection,
    required Map<String, Map<String, dynamic>> documentsById,
    required List<_StaleDocumentDeleteCandidate> staleDeleteCandidates,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final deleteReferences = <DocumentReference<Map<String, dynamic>>>[];

      for (final candidate in staleDeleteCandidates) {
        final latestSnapshot = await transaction.get(candidate.reference);
        if (!latestSnapshot.exists) {
          continue;
        }
        final latestData = latestSnapshot.data();
        if (!_deepEquals(latestData, candidate.expectedData)) {
          continue;
        }
        deleteReferences.add(candidate.reference);
      }

      for (final entry in documentsById.entries) {
        transaction.set(collection.doc(entry.key), entry.value);
      }

      for (final reference in deleteReferences) {
        transaction.delete(reference);
      }
    });
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

  List<FirestoreBatchWriteOperation> _upsertOperations({
    required CollectionReference<Map<String, dynamic>> collection,
    required Map<String, Map<String, dynamic>> documentsById,
  }) {
    return documentsById.entries
        .map(
          (entry) => FirestoreBatchWriteOperation.set(
            collection.doc(entry.key),
            entry.value,
          ),
        )
        .toList(growable: false);
  }

  List<_StaleDocumentDeleteCandidate> _staleDeleteCandidates({
    required QuerySnapshot<Map<String, dynamic>> existingSnapshot,
    required Map<String, Map<String, dynamic>> documentsById,
  }) {
    return existingSnapshot.docs
        .where((document) => !documentsById.containsKey(document.id))
        .map(
          (document) => _StaleDocumentDeleteCandidate(
            reference: document.reference,
            expectedData: Map<String, dynamic>.from(document.data()),
          ),
        )
        .toList(growable: false);
  }

  Future<void> _deleteStaleDocumentsIfUnchanged({
    required List<_StaleDocumentDeleteCandidate> staleDeleteCandidates,
  }) async {
    for (final chunk in FirestoreBatchChunker.chunk(
      operations: staleDeleteCandidates,
      maxChunkSize: _maxStaleDeleteCandidatesPerTransaction,
    )) {
      await _firestore.runTransaction((transaction) async {
        final deleteReferences = <DocumentReference<Map<String, dynamic>>>[];

        for (final candidate in chunk) {
          final latestSnapshot = await transaction.get(candidate.reference);
          if (!latestSnapshot.exists) {
            continue;
          }
          final latestData = latestSnapshot.data();
          if (!_deepEquals(latestData, candidate.expectedData)) {
            continue;
          }
          deleteReferences.add(candidate.reference);
        }

        for (final reference in deleteReferences) {
          transaction.delete(reference);
        }
      });
    }
  }

  bool _deepEquals(Object? left, Object? right) {
    return const DeepCollectionEquality().equals(left, right);
  }

  Future<void> _commitInChunks(
    List<FirestoreBatchWriteOperation> operations,
  ) async {
    for (final chunk in FirestoreBatchChunker.chunk(
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
