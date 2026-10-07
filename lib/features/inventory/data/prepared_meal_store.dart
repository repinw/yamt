import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_offline_writes.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';

const String _storeLogName = 'FirestorePreparedMealStore';
const String _householdsCollection = 'households';
const String _preparedMealsCollection = 'prepared_meals';

/// Defines prepared meal document.
class PreparedMealDocument {
  /// The prepared meal document.
  const new({required this.id, required this.data});

  /// The id.
  final String id;

  /// The data.
  final Map<String, dynamic> data;
}

/// Defines prepared meal store.
abstract interface class PreparedMealStore {
  /// Read all.
  Future<List<PreparedMealDocument>> readAll({required String householdId});

  /// Watch all.
  Stream<List<PreparedMealDocument>> watchAll({required String householdId});

  /// Writes the meal [id] with [data], sealed, without waiting for the
  /// server. Other meals stay untouched.
  Future<bool> save({
    required String householdId,
    required String id,
    required Map<String, dynamic> data,
  });

  /// Deletes the meal [id] without waiting for the server.
  Future<bool> delete({required String householdId, required String id});
}

/// Stores prepared meals encrypted with the household key [_cipher].
class FirestorePreparedMealStore implements PreparedMealStore {
  /// The firestore prepared meal store.
  const new({required this._firestore, required this._cipher});

  final FirebaseFirestore _firestore;
  final PayloadCipher _cipher;

  @override
  Future<List<PreparedMealDocument>> readAll({
    required String householdId,
  }) async {
    final collection = _collection(householdId);
    return _mapDocuments(
      await collection.openAll(await collection.reference.get()),
    );
  }

  @override
  Stream<List<PreparedMealDocument>> watchAll({required String householdId}) {
    final collection = _collection(householdId);
    return collection.reference.snapshots().asyncMap(
      (snapshot) async => _mapDocuments(await collection.openAll(snapshot)),
    );
  }

  @override
  Future<bool> save({
    required String householdId,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      final collection = _collection(householdId);
      final sealed = await collection.seal(id, data);
      commitBatchInBackground(
        _firestore.batch()..set(collection.reference.doc(id), sealed),
        failureMessage: 'Server rejected prepared meal $id.',
        logName: _storeLogName,
      );
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to save prepared meal $id for household $householdId.',
        name: _storeLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<bool> delete({required String householdId, required String id}) async {
    commitBatchInBackground(
      _firestore.batch()..delete(_collection(householdId).reference.doc(id)),
      failureMessage: 'Server rejected deleting prepared meal $id.',
      logName: _storeLogName,
    );
    return true;
  }

  SealedCollection _collection(String householdId) {
    return SealedCollection(
      _firestore
          .collection(_householdsCollection)
          .doc(householdId)
          .collection(_preparedMealsCollection),
      cipher: _cipher,
    );
  }

  List<PreparedMealDocument> _mapDocuments(List<OpenedDocument> documents) {
    return documents
        .map(
          (document) =>
              PreparedMealDocument(id: document.id, data: document.data),
        )
        .toList(growable: false);
  }
}
