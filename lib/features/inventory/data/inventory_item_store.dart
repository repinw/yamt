import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/firestore_atomic_replace_service.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';
import 'package:yamt/core/data/firestore_offline_writes.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/inventory/data/sealed_household_document_writes.dart';

const String _storeLogName = 'FirestoreInventoryItemStore';
const String _householdsCollection = 'households';
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
  Future<List<InventoryItemDocument>> readAll({required String householdId});

  /// Reads all from the local cache, and from the server only when the cache
  /// holds none.
  Future<List<InventoryItemDocument>> readAllLocal({
    required String householdId,
  });

  /// Watch all.
  Stream<List<InventoryItemDocument>> watchAll({required String householdId});

  /// Writes the item [id] alone; the other items stay untouched.
  Future<bool> save({
    required String householdId,
    required String id,
    required Map<String, dynamic> data,
  });

  /// Deletes the item [id] alone.
  Future<bool> delete({required String householdId, required String id});

  /// Upsert all.
  Future<bool> upsertAll({
    required String householdId,
    required Map<String, Map<String, dynamic>> documentsById,
  });
}

/// Reads limited inventory item projections.
abstract interface class InventoryItemRecentManualStore {
  /// Whether recent manual reads are query-limited by the store.
  bool get supportsLimitedRecentManualQuery;

  /// Reads recent manual item documents, newest first.
  Future<List<InventoryItemDocument>> readRecentManual({
    required String householdId,
    required int limit,
  });
}

/// Stores inventory items encrypted with the household key [_cipher].
class FirestoreInventoryItemStore
    with SealedHouseholdDocumentWrites
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
  Future<List<InventoryItemDocument>> readAll({
    required String householdId,
  }) async {
    final collection = householdCollection(householdId);
    return _mapDocuments(
      await collection.openAll(await collection.reference.get()),
    );
  }

  @override
  Future<List<InventoryItemDocument>> readAllLocal({
    required String householdId,
  }) async {
    final collection = householdCollection(householdId);
    return _mapDocuments(
      await collection.openAll(await readQueryLocalFirst(collection.reference)),
    );
  }

  @override
  Future<List<InventoryItemDocument>> readRecentManual({
    required String householdId,
    required int limit,
  }) async {
    if (limit <= 0) {
      return const <InventoryItemDocument>[];
    }

    final collection = householdCollection(householdId);
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
  Stream<List<InventoryItemDocument>> watchAll({required String householdId}) {
    final collection = householdCollection(householdId);
    return collection.reference.snapshots().asyncMap(
      (snapshot) async => _mapDocuments(await collection.openAll(snapshot)),
    );
  }

  @override
  String get writeLogName => _storeLogName;

  @override
  Future<bool> upsertAll({
    required String householdId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    try {
      final collection = householdCollection(householdId);
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
              'Server rejected inventory item upsert for '
              'household $householdId.',
          logName: _storeLogName,
        );
      }
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to upsert inventory items for household $householdId.',
        name: _storeLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  SealedCollection householdCollection(String householdId) {
    return SealedCollection(
      _firestore
          .collection(_householdsCollection)
          .doc(householdId)
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
