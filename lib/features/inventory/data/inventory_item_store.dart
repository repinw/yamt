import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_atomic_replace_service.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';
import 'package:yamt/core/data/firestore_offline_writes.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';

const String _storeLogName = 'FirestoreInventoryItemStore';
const String _usersCollection = 'users';
const String _inventoryItemsCollection = 'inventory_items';

/// Defines inventory item document.
class InventoryItemDocument {
  /// The inventory item document.
  const new({required this.id, required this.data});

  /// The id.
  final String id;

  /// The data.
  final Map<String, dynamic> data;
}

/// Defines inventory item store.
abstract interface class InventoryItemStore {
  /// Read all.
  Future<List<InventoryItemDocument>> readAll({required String userId});

  /// Watch all.
  Stream<List<InventoryItemDocument>> watchAll({required String userId});

  /// Replace all.
  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  });

  /// Upsert all.
  Future<bool> upsertAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  });
}

/// Reads limited inventory item projections.
abstract interface class InventoryItemRecentManualStore {
  /// Whether recent manual reads are query-limited by the store.
  bool get supportsLimitedRecentManualQuery;

  /// Reads recent manual item documents, newest first.
  Future<List<InventoryItemDocument>> readRecentManual({
    required String userId,
    required int limit,
  });
}

/// Stores inventory items encrypted with the household key [_cipher].
class FirestoreInventoryItemStore
    implements InventoryItemStore, InventoryItemRecentManualStore {
  /// The firestore inventory item store.
  const new({required this._firestore, required this._cipher});

  final FirebaseFirestore _firestore;
  final PayloadCipher _cipher;

  FirestoreAtomicReplaceService get _atomicReplaceService {
    return FirestoreAtomicReplaceService(firestore: _firestore);
  }

  @override
  bool get supportsLimitedRecentManualQuery => true;

  @override
  Future<List<InventoryItemDocument>> readAll({required String userId}) async {
    final collection = _collection(userId);
    return _mapDocuments(
      await collection.openAll(await collection.reference.get()),
    );
  }

  @override
  Future<List<InventoryItemDocument>> readRecentManual({
    required String userId,
    required int limit,
  }) async {
    if (limit <= 0) {
      return const <InventoryItemDocument>[];
    }

    final collection = _collection(userId);
    final snapshot = await collection.reference
        .where('origin', isEqualTo: 'manualAdd')
        .where('is_deposit', isEqualTo: false)
        .where('is_discount', isEqualTo: false)
        .orderBy('entry_date', descending: true)
        .limit(limit)
        .get();
    return _mapDocuments(await collection.openAll(snapshot));
  }

  @override
  Stream<List<InventoryItemDocument>> watchAll({required String userId}) {
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
        'Failed to replace inventory items for user $userId.',
        name: _storeLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<bool> upsertAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    try {
      final collection = _collection(userId);
      final operations = _atomicReplaceService.buildUpsertOperations(
        collection: collection.reference,
        documentsById: await collection.sealAll(documentsById),
      );
      for (final chunk in FirestoreBatchChunker.chunk(
        operations: operations,
        maxChunkSize: defaultMaxFirestoreBatchOperations,
      )) {
        final batch = _firestore.batch();
        for (final operation in chunk) {
          operation.apply(batch);
        }
        commitBatchInBackground(
          batch,
          failureMessage:
              'Server rejected inventory item upsert for user $userId.',
          logName: _storeLogName,
        );
      }
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to upsert inventory items for user $userId.',
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
          .collection(_inventoryItemsCollection),
      cipher: _cipher,
      plaintextFields: inventoryItemPlaintextFields,
    );
  }

  List<InventoryItemDocument> _mapDocuments(List<OpenedDocument> documents) {
    return documents
        .map(
          (document) =>
              InventoryItemDocument(id: document.id, data: document.data),
        )
        .toList(growable: false);
  }
}
