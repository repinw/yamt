import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';

const String _storeLogName = 'FirestoreKitchenUtensilStore';
const String _usersCollection = 'users';
const String _kitchenUtensilsCollection = 'kitchen_utensils';

/// Kitchen utensil document.
class KitchenUtensilDocument {
  /// Creates document wrapper.
  const new({required this.id, required this.data});

  /// Document id.
  final String id;

  /// Document data.
  final Map<String, dynamic> data;
}

/// Store for kitchen utensil documents.
abstract interface class KitchenUtensilStore {
  /// Reads all.
  Future<List<KitchenUtensilDocument>> readAll({required String userId});

  /// Watches all.
  Stream<List<KitchenUtensilDocument>> watchAll({required String userId});

  /// Upserts one.
  Future<bool> upsert({
    required String userId,
    required String utensilId,
    required Map<String, dynamic> data,
  });

  /// Deletes one.
  Future<bool> delete({required String userId, required String utensilId});
}

/// Stores kitchen utensils encrypted with the household key [_cipher].
class FirestoreKitchenUtensilStore implements KitchenUtensilStore {
  /// Creates Firestore store.
  const new({required this._firestore, required this._cipher});

  final FirebaseFirestore _firestore;
  final PayloadCipher _cipher;

  @override
  Future<List<KitchenUtensilDocument>> readAll({required String userId}) async {
    final collection = _collection(userId);
    return _mapDocuments(
      await collection.openAll(await collection.reference.get()),
    );
  }

  @override
  Stream<List<KitchenUtensilDocument>> watchAll({required String userId}) {
    final collection = _collection(userId);
    return collection.reference.snapshots().asyncMap(
      (snapshot) async => _mapDocuments(await collection.openAll(snapshot)),
    );
  }

  @override
  Future<bool> upsert({
    required String userId,
    required String utensilId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final collection = _collection(userId);
      await collection.reference
          .doc(utensilId)
          .set(await collection.seal(utensilId, data));
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to upsert kitchen utensil $utensilId for user $userId.',
        name: _storeLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<bool> delete({
    required String userId,
    required String utensilId,
  }) async {
    try {
      await _collection(userId).reference.doc(utensilId).delete();
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to delete kitchen utensil $utensilId for user $userId.',
        name: _storeLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  SealedCollection _collection(String userId) {
    return SealedCollection(
      _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_kitchenUtensilsCollection),
      cipher: _cipher,
    );
  }

  List<KitchenUtensilDocument> _mapDocuments(List<OpenedDocument> documents) {
    return documents
        .map(
          (document) =>
              KitchenUtensilDocument(id: document.id, data: document.data),
        )
        .toList(growable: false);
  }
}
