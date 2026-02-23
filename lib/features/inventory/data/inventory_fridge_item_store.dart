import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';

const String _storeLogName = 'FirestoreInventoryFridgeItemStore';
const String _usersCollection = 'users';
const String _inventoryItemsCollection = 'inventory_items';

class InventoryFridgeItemDocument {
  const InventoryFridgeItemDocument({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}

abstract interface class InventoryFridgeItemStore {
  Future<List<InventoryFridgeItemDocument>> readAll({required String userId});

  Future<bool> replaceAll({
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
    return snapshot.docs.map(_toDocument).toList(growable: false);
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

  Future<void> _replaceAllUnsafe({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    final collection = _collection(userId);
    final existingSnapshot = await collection.get();
    final batch = _firestore.batch();

    _upsertDocuments(
      batch: batch,
      collection: collection,
      documentsById: documentsById,
    );
    _deleteMissingDocuments(
      batch: batch,
      existingSnapshot: existingSnapshot,
      documentsById: documentsById,
    );

    await batch.commit();
  }

  void _upsertDocuments({
    required WriteBatch batch,
    required CollectionReference<Map<String, dynamic>> collection,
    required Map<String, Map<String, dynamic>> documentsById,
  }) {
    for (final entry in documentsById.entries) {
      batch.set(collection.doc(entry.key), entry.value);
    }
  }

  void _deleteMissingDocuments({
    required WriteBatch batch,
    required QuerySnapshot<Map<String, dynamic>> existingSnapshot,
    required Map<String, Map<String, dynamic>> documentsById,
  }) {
    for (final existingDocument in existingSnapshot.docs) {
      if (!documentsById.containsKey(existingDocument.id)) {
        batch.delete(existingDocument.reference);
      }
    }
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
