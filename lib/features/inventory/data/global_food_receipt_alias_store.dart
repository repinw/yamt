import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';

const String _storeLogName = 'FirestoreGlobalFoodReceiptAliasStore';
const String _globalFoodReceiptAliasesCollection =
    'global_food_item_receipt_aliases';

class GlobalFoodReceiptAliasDocument {
  const GlobalFoodReceiptAliasDocument({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}

abstract interface class GlobalFoodReceiptAliasStore {
  Future<List<GlobalFoodReceiptAliasDocument>> searchCandidates({
    required String lookupKey,
    int limit = 5,
  });

  Future<bool> upsertAll({
    required Map<String, Map<String, dynamic>> documentsById,
  });
}

class FirestoreGlobalFoodReceiptAliasStore
    implements GlobalFoodReceiptAliasStore {
  const FirestoreGlobalFoodReceiptAliasStore({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<List<GlobalFoodReceiptAliasDocument>> searchCandidates({
    required String lookupKey,
    int limit = 5,
  }) async {
    final safeLookupKey = lookupKey.trim();
    if (safeLookupKey.isEmpty) {
      return const <GlobalFoodReceiptAliasDocument>[];
    }

    final safeLimit = limit < 1 ? 1 : limit;
    final snapshot = await _collection()
        .where('lookup_key', isEqualTo: safeLookupKey)
        .limit(safeLimit)
        .get();
    return _mapSnapshot(snapshot);
  }

  @override
  Future<bool> upsertAll({
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    try {
      await _createMissingDocuments(documentsById);
      return true;
    } catch (error, stackTrace) {
      log(
        'Failed to upsert global food receipt aliases.',
        name: _storeLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  CollectionReference<Map<String, dynamic>> _collection() {
    return _firestore.collection(_globalFoodReceiptAliasesCollection);
  }

  Future<void> _createMissingDocuments(
    Map<String, Map<String, dynamic>> documentsById,
  ) async {
    for (final entry in documentsById.entries) {
      await _firestore.runTransaction((transaction) async {
        final reference = _collection().doc(entry.key);
        final snapshot = await transaction.get(reference);
        if (!snapshot.exists) {
          transaction.set(reference, entry.value);
          return;
        }
        final currentData = snapshot.data() ?? const <String, dynamic>{};
        final currentCount = _readSelectionCount(
          currentData['selection_count'],
        );
        final nextCount = _readSelectionCount(entry.value['selection_count']);
        final merged = Map<String, dynamic>.from(entry.value)
          ..['created_at'] =
              currentData['created_at'] ?? entry.value['created_at']
          ..['selection_count'] = currentCount + nextCount;
        transaction.set(reference, merged);
      });
    }
  }

  List<GlobalFoodReceiptAliasDocument> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(
          (document) => GlobalFoodReceiptAliasDocument(
            id: document.id,
            data: Map<String, dynamic>.from(document.data()),
          ),
        )
        .toList(growable: false);
  }

  int _readSelectionCount(Object? value) {
    if (value is int) {
      return value < 1 ? 1 : value;
    }
    if (value is num) {
      final safeValue = value.toInt();
      return safeValue < 1 ? 1 : safeValue;
    }
    return 1;
  }
}
