import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_atomic_replace_service.dart';

const String _storeLogName = 'FirestorePreparedMealTemplateStore';
const String _usersCollection = 'users';
const String _preparedMealTemplatesCollection = 'prepared_meal_templates';

/// Defines prepared meal template document.
class PreparedMealTemplateDocument {
  /// The prepared meal template document.
  const PreparedMealTemplateDocument({required this.id, required this.data});

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

/// Defines firestore prepared meal template store.
class FirestorePreparedMealTemplateStore implements PreparedMealTemplateStore {
  /// The firestore prepared meal template store.
  const FirestorePreparedMealTemplateStore({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  FirestoreAtomicReplaceService get _atomicReplaceService {
    return FirestoreAtomicReplaceService(firestore: _firestore);
  }

  @override
  Future<List<PreparedMealTemplateDocument>> readAll({
    required String userId,
  }) async {
    final snapshot = await _collection(userId).get();
    return _mapSnapshot(snapshot);
  }

  @override
  Stream<List<PreparedMealTemplateDocument>> watchAll({
    required String userId,
  }) {
    return _collection(userId).snapshots().map(_mapSnapshot);
  }

  @override
  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    try {
      await _atomicReplaceService.replaceAll(
        collection: _collection(userId),
        documentsById: documentsById,
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

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_preparedMealTemplatesCollection);
  }

  List<PreparedMealTemplateDocument> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(
          (document) => PreparedMealTemplateDocument(
            id: document.id,
            data: Map<String, dynamic>.from(document.data()),
          ),
        )
        .toList(growable: false);
  }
}
