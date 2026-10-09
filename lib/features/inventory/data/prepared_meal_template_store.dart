import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_offline_writes.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';

const String _storeLogName = 'FirestorePreparedMealTemplateStore';
const String _householdsCollection = 'households';
const String _preparedMealTemplatesCollection = 'prepared_meal_templates';

/// Defines prepared meal template document.
class PreparedMealTemplateDocument {
  /// The prepared meal template document.
  const new({required this.id, required this.data});

  /// The id.
  final String id;

  /// The data.
  final Map<String, dynamic> data;
}

/// Defines prepared meal template store.
abstract interface class PreparedMealTemplateStore {
  /// Read all.
  Future<List<PreparedMealTemplateDocument>> readAll({
    required String householdId,
  });

  /// Watch all.
  Stream<List<PreparedMealTemplateDocument>> watchAll({
    required String householdId,
  });

  /// Writes the template [id] alone; the other templates stay untouched.
  Future<bool> save({
    required String householdId,
    required String id,
    required Map<String, dynamic> data,
  });

  /// Deletes the template [id] alone.
  Future<bool> delete({required String householdId, required String id});
}

/// Stores prepared meal templates encrypted with the household key [_cipher].
class FirestorePreparedMealTemplateStore implements PreparedMealTemplateStore {
  /// The firestore prepared meal template store.
  const new({required this._firestore, required this._cipher});

  final FirebaseFirestore _firestore;
  final PayloadCipher _cipher;

  @override
  Future<List<PreparedMealTemplateDocument>> readAll({
    required String householdId,
  }) async {
    final collection = _collection(householdId);
    return _mapDocuments(
      await collection.openAll(await collection.reference.get()),
    );
  }

  @override
  Stream<List<PreparedMealTemplateDocument>> watchAll({
    required String householdId,
  }) {
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
        failureMessage: 'Server rejected prepared meal template $id.',
        logName: _storeLogName,
      );
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to save prepared meal template $id for household '
        '$householdId.',
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
      failureMessage: 'Server rejected deleting prepared meal template $id.',
      logName: _storeLogName,
    );
    return true;
  }

  SealedCollection _collection(String householdId) {
    return SealedCollection(
      _firestore
          .collection(_householdsCollection)
          .doc(householdId)
          .collection(_preparedMealTemplatesCollection),
      cipher: _cipher,
    );
  }

  List<PreparedMealTemplateDocument> _mapDocuments(
    List<OpenedDocument> documents,
  ) {
    return documents
        .map(
          (document) => PreparedMealTemplateDocument(
            id: document.id,
            data: document.data,
          ),
        )
        .toList(growable: false);
  }
}
