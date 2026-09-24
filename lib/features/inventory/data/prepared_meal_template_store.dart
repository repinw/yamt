import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_atomic_replace_service.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';

const String _storeLogName = 'FirestorePreparedMealTemplateStore';
const String _usersCollection = 'users';
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
  Future<List<PreparedMealTemplateDocument>> readAll({required String userId});

  /// Watch all.
  Stream<List<PreparedMealTemplateDocument>> watchAll({required String userId});

  /// Replace all.
  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  });
}

/// Stores prepared meal templates encrypted with the household key [_cipher].
class FirestorePreparedMealTemplateStore implements PreparedMealTemplateStore {
  /// The firestore prepared meal template store.
  const new({required this._firestore, required this._cipher});

  final FirebaseFirestore _firestore;
  final PayloadCipher _cipher;

  FirestoreAtomicReplaceService get _atomicReplaceService {
    return FirestoreAtomicReplaceService(firestore: _firestore);
  }

  @override
  Future<List<PreparedMealTemplateDocument>> readAll({
    required String userId,
  }) async {
    final collection = _collection(userId);
    return _mapDocuments(
      await collection.openAll(await collection.reference.get()),
    );
  }

  @override
  Stream<List<PreparedMealTemplateDocument>> watchAll({
    required String userId,
  }) {
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
      final collection = _collection(userId);
      await collection.ensureAllSealed();
      await _atomicReplaceService.replaceAll(
        collection: collection.reference,
        documentsById: await collection.sealAll(documentsById),
      );
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to replace prepared meal templates for user $userId.',
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
