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
  const FirestoreShoppingListItemStore({
    required FirebaseFirestore firestore,
    Future<void> Function()? onBeforeDeleteStaleDocuments,
  }) : _firestore = firestore,
       _onBeforeDeleteStaleDocuments = onBeforeDeleteStaleDocuments;

  final FirebaseFirestore _firestore;
  final Future<void> Function()? _onBeforeDeleteStaleDocuments;

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
    final collection = _collection(userId);
    final existingSnapshot = await collection.get();
    await _commitInChunks(
      _upsertOperations(collection: collection, documentsById: documentsById),
    );
    await _onBeforeDeleteStaleDocuments?.call();
    await _deleteStaleDocumentsIfUnchanged(
      staleDocuments: _staleDocuments(
        existingSnapshot: existingSnapshot,
        documentsById: documentsById,
      ),
    );
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

  Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> _staleDocuments({
    required QuerySnapshot<Map<String, dynamic>> existingSnapshot,
    required Map<String, Map<String, dynamic>> documentsById,
  }) {
    return existingSnapshot.docs.where(
      (doc) => !documentsById.containsKey(doc.id),
    );
  }

  Future<void> _deleteStaleDocumentsIfUnchanged({
    required Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>
    staleDocuments,
  }) async {
    for (final document in staleDocuments) {
      final expectedData = Map<String, dynamic>.from(document.data());
      await _firestore.runTransaction((transaction) async {
        final latestSnapshot = await transaction.get(document.reference);
        final latestData = latestSnapshot.data();
        if (!_deepEquals(latestData, expectedData)) {
          return;
        }
        transaction.delete(document.reference);
      });
    }
  }

  bool _deepEquals(Object? left, Object? right) {
    if (identical(left, right)) {
      return true;
    }
    if (left is Map && right is Map) {
      return _mapEquals(left, right);
    }
    if (left is List && right is List) {
      return _listEquals(left, right);
    }
    return left == right;
  }

  bool _mapEquals(Map left, Map right) {
    if (left.length != right.length) {
      return false;
    }
    for (final entry in left.entries) {
      if (!right.containsKey(entry.key)) {
        return false;
      }
      if (!_deepEquals(entry.value, right[entry.key])) {
        return false;
      }
    }
    return true;
  }

  bool _listEquals(List left, List right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (!_deepEquals(left[index], right[index])) {
        return false;
      }
    }
    return true;
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
