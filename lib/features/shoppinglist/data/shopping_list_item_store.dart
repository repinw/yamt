import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_atomic_replace_service.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';

const String _storeLogName = 'FirestoreShoppingListItemStore';
const String _usersCollection = 'users';
const String _shoppingListCollection = 'shopping_list_items';

/// Defines shopping list item document.
class ShoppingListItemDocument {
  /// The shopping list item document.
  const new({required this.id, required this.data});

  /// The id.
  final String id;

  /// The data.
  final Map<String, dynamic> data;
}

/// Defines shopping list item store.
abstract interface class ShoppingListItemStore {
  /// Read all.
  Future<List<ShoppingListItemDocument>> readAll({required String userId});

  /// Watch all.
  Stream<List<ShoppingListItemDocument>> watchAll({required String userId});

  /// Replace all.
  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  });
}

/// Stores shopping list items encrypted with the household key [_cipher].
class FirestoreShoppingListItemStore implements ShoppingListItemStore {
  /// The firestore shopping list item store.
  const new({required this._firestore, required this._cipher});

  final FirebaseFirestore _firestore;
  final PayloadCipher _cipher;

  FirestoreAtomicReplaceService get _atomicReplaceService {
    return FirestoreAtomicReplaceService(firestore: _firestore);
  }

  @override
  Future<List<ShoppingListItemDocument>> readAll({
    required String userId,
  }) async {
    final collection = _collection(userId);
    return _mapDocuments(
      await collection.openAll(await collection.reference.get()),
    );
  }

  @override
  Stream<List<ShoppingListItemDocument>> watchAll({required String userId}) {
    final collection = _collection(userId);
    return collection.reference.snapshots().asyncMap(
      (snapshot) async => _mapDocuments(await collection.openAll(snapshot)),
    );
  }

  @override
  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    try {
      await _replaceAllUnsafe(userId: userId, documentsById: documentsById);
      return true;
    } on Object catch (error, stackTrace) {
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
    await collection.ensureAllSealed();
    await _atomicReplaceService.replaceAll(
      collection: collection.reference,
      documentsById: await collection.sealAll(documentsById),
    );
  }

  List<ShoppingListItemDocument> _mapDocuments(List<OpenedDocument> documents) {
    return documents
        .map(
          (document) =>
              ShoppingListItemDocument(id: document.id, data: document.data),
        )
        .toList(growable: false);
  }

  SealedCollection _collection(String userId) {
    return SealedCollection(
      _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_shoppingListCollection),
      cipher: _cipher,
    );
  }
}
