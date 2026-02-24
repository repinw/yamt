import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';

const String _storeLogName = 'FirestoreShoppingListItemStore';
const String _usersCollection = 'users';
const String _shoppingListCollection = 'shopping_list_items';
const int _maxFirestoreBatchOperations = 500;

class ShoppingListItemDocument {
  const ShoppingListItemDocument({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}

abstract interface class ShoppingListItemStore {
  Future<List<ShoppingListItemDocument>> readAll({required String userId});

  Stream<List<ShoppingListItemDocument>> watchAll({required String userId});

  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  });
}

class FirestoreShoppingListItemStore implements ShoppingListItemStore {
  const FirestoreShoppingListItemStore({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<List<ShoppingListItemDocument>> readAll({required String userId}) {
    return _collection(userId).get().then(_mapSnapshot);
  }

  @override
  Stream<List<ShoppingListItemDocument>> watchAll({required String userId}) {
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
        'Failed to replace shopping list items for user $userId',
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
    final collection = _collection(userId);
    final existingSnapshot = await collection.get();
    final operations = <FirestoreBatchWriteOperation>[
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

  List<FirestoreBatchWriteOperation> _deleteOperations({
    required QuerySnapshot<Map<String, dynamic>> existingSnapshot,
    required Map<String, Map<String, dynamic>> documentsById,
  }) {
    return existingSnapshot.docs
        .where((doc) => !documentsById.containsKey(doc.id))
        .map((doc) => FirestoreBatchWriteOperation.delete(doc.reference))
        .toList(growable: false);
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

  List<ShoppingListItemDocument> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map(_toDocument).toList(growable: false);
  }

  ShoppingListItemDocument _toDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return ShoppingListItemDocument(
      id: document.id,
      data: Map<String, dynamic>.from(document.data()),
    );
  }

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_shoppingListCollection);
  }
}
