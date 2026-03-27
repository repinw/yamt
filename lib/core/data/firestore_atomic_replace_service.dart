import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';

const int defaultMaxFirestoreBatchOperations = 500;
const int defaultMaxFirestoreTransactionWrites = 500;
const int defaultMaxStaleDeleteCandidatesPerTransaction = 100;
const String _atomicReplaceLogName = 'FirestoreAtomicReplaceService';

/// Stores the original document state for stale-delete safety checks.
class FirestoreStaleDeleteCandidate {
  const FirestoreStaleDeleteCandidate({
    required this.reference,
    required this.expectedData,
  });

  final DocumentReference<Map<String, dynamic>> reference;
  final Map<String, dynamic> expectedData;
}

/// Provides atomic/fallback replace-all behavior for Firestore collections.
class FirestoreAtomicReplaceService {
  const FirestoreAtomicReplaceService({
    required FirebaseFirestore firestore,
    this.maxFirestoreBatchOperations = defaultMaxFirestoreBatchOperations,
    this.maxFirestoreTransactionWrites = defaultMaxFirestoreTransactionWrites,
    this.maxStaleDeleteCandidatesPerTransaction =
        defaultMaxStaleDeleteCandidatesPerTransaction,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;
  final int maxFirestoreBatchOperations;
  final int maxFirestoreTransactionWrites;
  final int maxStaleDeleteCandidatesPerTransaction;

  Future<void> replaceAll({
    required CollectionReference<Map<String, dynamic>> collection,
    required Map<String, Map<String, dynamic>> documentsById,
    Future<void> Function()? onBeforeDeleteStaleDocuments,
  }) async {
    final stopwatch = Stopwatch()..start();
    log(
      'replaceAll started path=${collection.path} '
      'documents=${documentsById.length}.',
      name: _atomicReplaceLogName,
    );
    final existingSnapshot = await collection.get();
    log(
      'replaceAll fetched existing snapshot path=${collection.path} '
      'existing=${existingSnapshot.docs.length} '
      'elapsedMs=${stopwatch.elapsedMilliseconds}.',
      name: _atomicReplaceLogName,
    );
    final staleDeleteCandidates = buildStaleDeleteCandidates(
      existingSnapshot: existingSnapshot,
      documentsById: documentsById,
    );
    final canRunAtomic = canRunAtomicReplaceAll(
      upsertCount: documentsById.length,
      staleDeleteCount: staleDeleteCandidates.length,
    );
    log(
      'replaceAll computed stale deletes path=${collection.path} '
      'staleDeletes=${staleDeleteCandidates.length} '
      'canRunAtomic=$canRunAtomic '
      'elapsedMs=${stopwatch.elapsedMilliseconds}.',
      name: _atomicReplaceLogName,
    );

    if (canRunAtomic) {
      await onBeforeDeleteStaleDocuments?.call();
      await replaceAllAtomically(
        collection: collection,
        documentsById: documentsById,
        staleDeleteCandidates: staleDeleteCandidates,
      );
      log(
        'replaceAll completed atomically path=${collection.path} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}.',
        name: _atomicReplaceLogName,
      );
      return;
    }

    await upsertAll(collection: collection, documentsById: documentsById);
    log(
      'replaceAll upserts completed path=${collection.path} '
      'elapsedMs=${stopwatch.elapsedMilliseconds}.',
      name: _atomicReplaceLogName,
    );
    await onBeforeDeleteStaleDocuments?.call();
    await deleteStaleDocumentsIfUnchanged(
      staleDeleteCandidates: staleDeleteCandidates,
    );
    log(
      'replaceAll completed with fallback path=${collection.path} '
      'elapsedMs=${stopwatch.elapsedMilliseconds}.',
      name: _atomicReplaceLogName,
    );
  }

  Future<void> upsertAll({
    required CollectionReference<Map<String, dynamic>> collection,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    await commitInChunks(
      operations: buildUpsertOperations(
        collection: collection,
        documentsById: documentsById,
      ),
    );
  }

  bool canRunAtomicReplaceAll({
    required int upsertCount,
    required int staleDeleteCount,
  }) {
    return upsertCount + staleDeleteCount <= maxFirestoreTransactionWrites;
  }

  List<FirestoreBatchWriteOperation> buildUpsertOperations({
    required CollectionReference<Map<String, dynamic>> collection,
    required Map<String, Map<String, dynamic>> documentsById,
  }) {
    return documentsById.entries
        .map(
          (entry) => FirestoreBatchWriteOperation.set(
            collection.doc(entry.key),
            entry.value,
          ),
        )
        .toList(growable: false);
  }

  List<FirestoreStaleDeleteCandidate> buildStaleDeleteCandidates({
    required QuerySnapshot<Map<String, dynamic>> existingSnapshot,
    required Map<String, Map<String, dynamic>> documentsById,
  }) {
    return existingSnapshot.docs
        .where((document) => !documentsById.containsKey(document.id))
        .map(
          (document) => FirestoreStaleDeleteCandidate(
            reference: document.reference,
            expectedData: Map<String, dynamic>.from(document.data()),
          ),
        )
        .toList(growable: false);
  }

  Future<void> replaceAllAtomically({
    required CollectionReference<Map<String, dynamic>> collection,
    required Map<String, Map<String, dynamic>> documentsById,
    required List<FirestoreStaleDeleteCandidate> staleDeleteCandidates,
  }) async {
    log(
      'replaceAllAtomically started path=${collection.path} '
      'upserts=${documentsById.length} '
      'staleDeletes=${staleDeleteCandidates.length}.',
      name: _atomicReplaceLogName,
    );
    await _firestore.runTransaction((transaction) async {
      final deleteReferences = await _unchangedDeleteReferences(
        transaction: transaction,
        staleDeleteCandidates: staleDeleteCandidates,
      );

      for (final entry in documentsById.entries) {
        transaction.set(collection.doc(entry.key), entry.value);
      }

      for (final reference in deleteReferences) {
        transaction.delete(reference);
      }
    });
    log(
      'replaceAllAtomically finished path=${collection.path} '
      'upserts=${documentsById.length} '
      'staleDeletes=${staleDeleteCandidates.length}.',
      name: _atomicReplaceLogName,
    );
  }

  Future<void> deleteStaleDocumentsIfUnchanged({
    required List<FirestoreStaleDeleteCandidate> staleDeleteCandidates,
  }) async {
    log(
      'deleteStaleDocumentsIfUnchanged started '
      'staleDeletes=${staleDeleteCandidates.length}.',
      name: _atomicReplaceLogName,
    );
    for (final chunk in FirestoreBatchChunker.chunk(
      operations: staleDeleteCandidates,
      maxChunkSize: maxStaleDeleteCandidatesPerTransaction,
    )) {
      await _firestore.runTransaction((transaction) async {
        final deleteReferences = await _unchangedDeleteReferences(
          transaction: transaction,
          staleDeleteCandidates: chunk,
        );

        for (final reference in deleteReferences) {
          transaction.delete(reference);
        }
      });
    }
    log(
      'deleteStaleDocumentsIfUnchanged finished '
      'staleDeletes=${staleDeleteCandidates.length}.',
      name: _atomicReplaceLogName,
    );
  }

  Future<void> commitInChunks({
    required List<FirestoreBatchWriteOperation> operations,
    int? maxChunkSize,
  }) async {
    final chunkSize = maxChunkSize ?? maxFirestoreBatchOperations;
    log(
      'commitInChunks started operations=${operations.length} '
      'chunkSize=$chunkSize.',
      name: _atomicReplaceLogName,
    );
    for (final chunk in FirestoreBatchChunker.chunk(
      operations: operations,
      maxChunkSize: chunkSize,
    )) {
      final batch = _firestore.batch();
      for (final operation in chunk) {
        operation.apply(batch);
      }
      await batch.commit();
    }
    log(
      'commitInChunks finished operations=${operations.length} '
      'chunkSize=$chunkSize.',
      name: _atomicReplaceLogName,
    );
  }

  Future<List<DocumentReference<Map<String, dynamic>>>>
  _unchangedDeleteReferences({
    required Transaction transaction,
    required List<FirestoreStaleDeleteCandidate> staleDeleteCandidates,
  }) async {
    final deleteReferences = <DocumentReference<Map<String, dynamic>>>[];
    for (final candidate in staleDeleteCandidates) {
      final latestSnapshot = await transaction.get(candidate.reference);
      if (!latestSnapshot.exists) {
        continue;
      }
      final latestData = latestSnapshot.data();
      if (!_deepEquals(latestData, candidate.expectedData)) {
        continue;
      }
      deleteReferences.add(candidate.reference);
    }
    return deleteReferences;
  }

  bool _deepEquals(Object? left, Object? right) {
    return const DeepCollectionEquality().equals(left, right);
  }
}
