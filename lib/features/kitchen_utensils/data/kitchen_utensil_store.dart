import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';

const String _storeLogName = 'FirestoreKitchenUtensilStore';
const String _usersCollection = 'users';
const String _kitchenUtensilsCollection = 'kitchen_utensils';

/// Kitchen utensil document.
class KitchenUtensilDocument {
  /// Creates document wrapper.
  const KitchenUtensilDocument({required this.id, required this.data});

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

/// Firestore store for kitchen utensils.
class FirestoreKitchenUtensilStore implements KitchenUtensilStore {
  /// Creates Firestore store.
  const FirestoreKitchenUtensilStore({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<List<KitchenUtensilDocument>> readAll({
    required String userId,
  }) async {
    final snapshot = await _collection(userId).get();
    return _mapSnapshot(snapshot);
  }

  @override
  Stream<List<KitchenUtensilDocument>> watchAll({required String userId}) {
    return _collection(userId).snapshots().map(_mapSnapshot);
  }

  @override
  Future<bool> upsert({
    required String userId,
    required String utensilId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _collection(userId).doc(utensilId).set(data);
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
      await _collection(userId).doc(utensilId).delete();
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

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_kitchenUtensilsCollection);
  }

  List<KitchenUtensilDocument> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(
          (document) => KitchenUtensilDocument(
            id: document.id,
            data: Map<String, dynamic>.from(document.data()),
          ),
        )
        .toList(growable: false);
  }
}
