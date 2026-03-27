import 'dart:convert';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_atomic_replace_service.dart';

const String _storeLogName = 'FirestorePreparedMealStore';
const String _usersCollection = 'users';
const String _preparedMealsCollection = 'prepared_meals';

class PreparedMealDocument {
  const PreparedMealDocument({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}

abstract interface class PreparedMealStore {
  Future<List<PreparedMealDocument>> readAll({required String userId});

  Stream<List<PreparedMealDocument>> watchAll({required String userId});

  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  });
}

class FirestorePreparedMealStore implements PreparedMealStore {
  const FirestorePreparedMealStore({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  FirestoreAtomicReplaceService get _atomicReplaceService {
    return FirestoreAtomicReplaceService(firestore: _firestore);
  }

  @override
  Future<List<PreparedMealDocument>> readAll({required String userId}) async {
    final snapshot = await _collection(userId).get();
    return _mapSnapshot(snapshot);
  }

  @override
  Stream<List<PreparedMealDocument>> watchAll({required String userId}) {
    return _collection(userId).snapshots().map(_mapSnapshot);
  }

  @override
  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    final stopwatch = Stopwatch()..start();
    final approximatePayloadBytes = _estimatePayloadBytes(documentsById);
    log(
      'Starting prepared meal replaceAll user=$userId '
      'documents=${documentsById.length} '
      'approxPayloadBytes=$approximatePayloadBytes.',
      name: _storeLogName,
    );
    try {
      await _atomicReplaceService.replaceAll(
        collection: _collection(userId),
        documentsById: documentsById,
      );
      log(
        'Prepared meal replaceAll completed user=$userId '
        'documents=${documentsById.length} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}.',
        name: _storeLogName,
      );
      return true;
    } catch (error, stackTrace) {
      log(
        'Failed to replace prepared meals for user $userId.',
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
        .collection(_preparedMealsCollection);
  }

  List<PreparedMealDocument> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(
          (document) => PreparedMealDocument(
            id: document.id,
            data: Map<String, dynamic>.from(document.data()),
          ),
        )
        .toList(growable: false);
  }

  int _estimatePayloadBytes(Map<String, Map<String, dynamic>> documentsById) {
    var total = 0;
    for (final entry in documentsById.entries) {
      try {
        total += utf8.encode(jsonEncode(entry.value)).length;
      } catch (_) {
        total += entry.key.length;
      }
    }
    return total;
  }
}
