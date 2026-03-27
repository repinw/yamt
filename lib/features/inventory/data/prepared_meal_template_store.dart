import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_atomic_replace_service.dart';

const String _storeLogName = 'FirestorePreparedMealTemplateStore';
const String _usersCollection = 'users';
const String _preparedMealTemplatesCollection = 'prepared_meal_templates';

class PreparedMealTemplateDocument {
  const PreparedMealTemplateDocument({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}

abstract interface class PreparedMealTemplateStore {
  Future<List<PreparedMealTemplateDocument>> readAll({required String userId});

  Stream<List<PreparedMealTemplateDocument>> watchAll({required String userId});

  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  });
}

class FirestorePreparedMealTemplateStore implements PreparedMealTemplateStore {
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
    } catch (error, stackTrace) {
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
