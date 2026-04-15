import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Single write operation that can be applied to a Firestore batch.
class FirestoreBatchWriteOperation {
  /// Creates set operation for given document reference.
  const FirestoreBatchWriteOperation.set(this.reference, this.data)
    : _isDelete = false;

  /// Creates delete operation for given document reference.
  const FirestoreBatchWriteOperation.delete(this.reference)
    : data = null,
      _isDelete = true;

  /// Document reference affected by this operation.
  final DocumentReference<Map<String, dynamic>> reference;

  /// Data written by set operations, or `null` for deletes.
  final Map<String, dynamic>? data;
  final bool _isDelete;

  /// Applies this operation to provided batch.
  void apply(WriteBatch batch) {
    if (_isDelete) {
      batch.delete(reference);
      return;
    }
    batch.set(reference, data!);
  }
}

/// Splits Firestore operations into chunks that fit batch limits.
class FirestoreBatchChunker {
  const FirestoreBatchChunker._();

  /// Yields chunks with at most `maxChunkSize` items each.
  static Iterable<List<T>> chunk<T>({
    required List<T> operations,
    required int maxChunkSize,
  }) sync* {
    if (maxChunkSize < 1) {
      throw ArgumentError.value(
        maxChunkSize,
        'maxChunkSize',
        'Must be greater than zero.',
      );
    }
    if (operations.isEmpty) {
      return;
    }

    for (var start = 0; start < operations.length; start += maxChunkSize) {
      final end = math.min(start + maxChunkSize, operations.length);
      yield operations.sublist(start, end);
    }
  }
}
