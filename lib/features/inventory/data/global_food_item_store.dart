import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'package:yamt/core/data/firestore_atomic_replace_service.dart';

const String _storeLogName = 'FirestoreGlobalFoodItemStore';
const String _globalFoodItemsCollection = 'global_food_items';

class GlobalFoodItemDocument {
  const GlobalFoodItemDocument({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}

abstract interface class GlobalFoodItemStore {
  Future<List<GlobalFoodItemDocument>> readAll();

  Stream<List<GlobalFoodItemDocument>> watchAll();

  Future<bool> replaceAll({
    required Map<String, Map<String, dynamic>> documentsById,
  });

  Future<bool> upsertAll({
    required Map<String, Map<String, dynamic>> documentsById,
  });
}

class FirestoreGlobalFoodItemStore implements GlobalFoodItemStore {
  const FirestoreGlobalFoodItemStore({required FirebaseFirestore firestore})
    : _firestore = firestore,
      _onBeforeDeleteStaleDocuments = null;

  @visibleForTesting
  const FirestoreGlobalFoodItemStore.testing({
    required FirebaseFirestore firestore,
    Future<void> Function()? onBeforeDeleteStaleDocuments,
  }) : _firestore = firestore,
       _onBeforeDeleteStaleDocuments = onBeforeDeleteStaleDocuments;

  final FirebaseFirestore _firestore;
  final Future<void> Function()? _onBeforeDeleteStaleDocuments;

  FirestoreAtomicReplaceService get _atomicReplaceService {
    return FirestoreAtomicReplaceService(firestore: _firestore);
  }

  @override
  Future<List<GlobalFoodItemDocument>> readAll() async {
    final snapshot = await _collection().get();
    return _mapSnapshot(snapshot);
  }

  @override
  Stream<List<GlobalFoodItemDocument>> watchAll() {
    return _collection().snapshots().map(_mapSnapshot);
  }

  @override
  Future<bool> replaceAll({
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    try {
      await _atomicReplaceService.replaceAll(
        collection: _collection(),
        documentsById: documentsById,
        onBeforeDeleteStaleDocuments: _onBeforeDeleteStaleDocuments,
      );
      return true;
    } catch (error, stackTrace) {
      log(
        'Failed to replace global food items.',
        name: _storeLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<bool> upsertAll({
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    try {
      await _atomicReplaceService.upsertAll(
        collection: _collection(),
        documentsById: documentsById,
      );
      return true;
    } catch (error, stackTrace) {
      log(
        'Failed to upsert global food items.',
        name: _storeLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  CollectionReference<Map<String, dynamic>> _collection() {
    return _firestore.collection(_globalFoodItemsCollection);
  }

  List<GlobalFoodItemDocument> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(
          (document) => GlobalFoodItemDocument(
            id: document.id,
            data: Map<String, dynamic>.from(document.data()),
          ),
        )
        .toList(growable: false);
  }
}
