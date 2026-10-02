import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_atomic_replace_service.dart';
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

  /// Replace all. A stored document missing from [documentsById] is
  /// deleted only when [parse] reads its data without throwing.
  Future<bool> replaceAll({
    required String householdId,
    required Map<String, Map<String, dynamic>> documentsById,
    required void Function(String id, Map<String, dynamic> data) parse,
  });
}

/// Stores prepared meals encrypted with the household key [_cipher].
class FirestorePreparedMealStore implements PreparedMealStore {
  /// The firestore prepared meal store.
  const new({required this._firestore, required this._cipher});

  final FirebaseFirestore _firestore;
  final PayloadCipher _cipher;

  FirestoreAtomicReplaceService get _atomicReplaceService {
    return FirestoreAtomicReplaceService(firestore: _firestore);
  }

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
  Future<bool> replaceAll({
    required String householdId,
    required Map<String, Map<String, dynamic>> documentsById,
    required void Function(String id, Map<String, dynamic> data) parse,
  }) async {
    try {
      final collection = _collection(householdId);
      await collection.ensureAllSealed();
      await _atomicReplaceService.replaceAll(
        collection: collection.reference,
        documentsById: await collection.sealAll(documentsById),
        canDelete: (candidate) => collection.canDeleteStale(candidate, parse),
      );
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to replace prepared meals for household $householdId.',
        name: _storeLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
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
