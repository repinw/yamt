import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';

/// Default Firestore batch size used for chunked writes.
const int defaultMaxFirestoreBatchOperations = 500;

/// Default transaction write limit for atomic replace operations.
const int defaultMaxFirestoreTransactionWrites = 500;

/// Default stale-delete checks performed per transaction.
const int defaultMaxStaleDeleteCandidatesPerTransaction = 100;

/// Stores the original document state for stale-delete safety checks.
class FirestoreStaleDeleteCandidate {
  /// Creates stale-delete candidate with expected document contents.
  const FirestoreStaleDeleteCandidate({
    required this.reference,
    required this.expectedData,
  });

  /// Reference considered for deletion.
  final DocumentReference<Map<String, dynamic>> reference;

  /// Snapshot data expected before deletion is allowed.
  final Map<String, dynamic> expectedData;
}

/// Provides atomic/fallback replace-all behavior for Firestore collections.
class FirestoreAtomicReplaceService {
  /// Creates service with configurable Firestore safety limits.
  const FirestoreAtomicReplaceService({
    required FirebaseFirestore firestore,
    this.maxFirestoreBatchOperations = defaultMaxFirestoreBatchOperations,
    this.maxFirestoreTransactionWrites = defaultMaxFirestoreTransactionWrites,
    this.maxStaleDeleteCandidatesPerTransaction =
        defaultMaxStaleDeleteCandidatesPerTransaction,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// Max operations per batch write chunk.
  final int maxFirestoreBatchOperations;

  /// Max writes allowed in one atomic transaction path.
  final int maxFirestoreTransactionWrites;

  /// Max stale-delete candidates checked in one transaction.
  final int maxStaleDeleteCandidatesPerTransaction;

  /// Replaces collection contents with provided documents.
  Future<void> replaceAll({
    required CollectionReference<Map<String, dynamic>> collection,
    required Map<String, Map<String, dynamic>> documentsById,
    Future<void> Function()? onBeforeDeleteStaleDocuments,
  }) async {
    final existingSnapshot = await collection.get();
    final staleDeleteCandidates = buildStaleDeleteCandidates(
      existingSnapshot: existingSnapshot,
      documentsById: documentsById,
    );
    final canRunAtomic = canRunAtomicReplaceAll(
      upsertCount: documentsById.length,
      staleDeleteCount: staleDeleteCandidates.length,
    );

    if (canRunAtomic) {
      await onBeforeDeleteStaleDocuments?.call();
      await replaceAllAtomically(
        collection: collection,
        documentsById: documentsById,
        staleDeleteCandidates: staleDeleteCandidates,
      );
      return;
    }

    await upsertAll(collection: collection, documentsById: documentsById);
    await onBeforeDeleteStaleDocuments?.call();
    await deleteStaleDocumentsIfUnchanged(
      staleDeleteCandidates: staleDeleteCandidates,
    );
  }

  /// Writes all documents in chunks without deleting stale documents.
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

  /// Returns whether replace-all can run fully inside one transaction.
  bool canRunAtomicReplaceAll({
    required int upsertCount,
    required int staleDeleteCount,
  }) {
    return upsertCount + staleDeleteCount <= maxFirestoreTransactionWrites;
  }

  /// Builds batch write operations for all upserts.
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

  /// Builds delete candidates for docs absent from target contents.
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

  /// Replaces documents and deletes unchanged stale docs atomically.
  Future<void> replaceAllAtomically({
    required CollectionReference<Map<String, dynamic>> collection,
    required Map<String, Map<String, dynamic>> documentsById,
    required List<FirestoreStaleDeleteCandidate> staleDeleteCandidates,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final deleteReferences = await _unchangedDeleteReferences(
        transaction: transaction,
        staleDeleteCandidates: staleDeleteCandidates,
      );

      documentsById.entries.forEach(
        _transactionSetter(
          transaction: transaction,
          collection: collection,
        ),
      );

      deleteReferences.forEach(transaction.delete);
    });
  }

  /// Deletes stale docs only when their contents still match expectation.
  Future<void> deleteStaleDocumentsIfUnchanged({
    required List<FirestoreStaleDeleteCandidate> staleDeleteCandidates,
  }) async {
    for (final chunk in FirestoreBatchChunker.chunk(
      operations: staleDeleteCandidates,
      maxChunkSize: maxStaleDeleteCandidatesPerTransaction,
    )) {
      await _firestore.runTransaction((transaction) async {
        final deleteReferences = await _unchangedDeleteReferences(
          transaction: transaction,
          staleDeleteCandidates: chunk,
        );

        deleteReferences.forEach(transaction.delete);
      });
    }
  }

  /// Commits operations in chunks to respect Firestore batch limits.
  Future<void> commitInChunks({
    required List<FirestoreBatchWriteOperation> operations,
    int? maxChunkSize,
  }) async {
    final chunkSize = maxChunkSize ?? maxFirestoreBatchOperations;
    for (final chunk in FirestoreBatchChunker.chunk(
      operations: operations,
      maxChunkSize: chunkSize,
    )) {
      final batch = _firestore.batch();
      chunk.forEach(batch.applyOperation);
      await batch.commit();
    }
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

  void Function(MapEntry<String, Map<String, dynamic>>) _transactionSetter({
    required Transaction transaction,
    required CollectionReference<Map<String, dynamic>> collection,
  }) {
    return (entry) => transaction.set(collection.doc(entry.key), entry.value);
  }
}

extension on WriteBatch {
  void applyOperation(FirestoreBatchWriteOperation operation) {
    operation.apply(this);
  }
}
