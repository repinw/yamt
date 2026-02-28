import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';

const int defaultMaxFirestoreBatchOperations = 500;
const int defaultMaxFirestoreTransactionWrites = 500;
const int defaultMaxStaleDeleteCandidatesPerTransaction = 100;

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
    final existingSnapshot = await collection.get();
    final staleDeleteCandidates = buildStaleDeleteCandidates(
      existingSnapshot: existingSnapshot,
      documentsById: documentsById,
    );

    if (canRunAtomicReplaceAll(
      upsertCount: documentsById.length,
      staleDeleteCount: staleDeleteCandidates.length,
    )) {
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
    await _firestore.runTransaction((transaction) async {
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

      for (final entry in documentsById.entries) {
        transaction.set(collection.doc(entry.key), entry.value);
      }

      for (final reference in deleteReferences) {
        transaction.delete(reference);
      }
    });
  }

  Future<void> deleteStaleDocumentsIfUnchanged({
    required List<FirestoreStaleDeleteCandidate> staleDeleteCandidates,
  }) async {
    for (final chunk in FirestoreBatchChunker.chunk(
      operations: staleDeleteCandidates,
      maxChunkSize: maxStaleDeleteCandidatesPerTransaction,
    )) {
      await _firestore.runTransaction((transaction) async {
        final deleteReferences = <DocumentReference<Map<String, dynamic>>>[];

        for (final candidate in chunk) {
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

        for (final reference in deleteReferences) {
          transaction.delete(reference);
        }
      });
    }
  }

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
      for (final operation in chunk) {
        operation.apply(batch);
      }
      await batch.commit();
    }
  }

  bool _deepEquals(Object? left, Object? right) {
    return const DeepCollectionEquality().equals(left, right);
  }
}
