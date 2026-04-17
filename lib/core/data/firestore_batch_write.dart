import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Single write operation that can be applied to a Firestore batch.
class FirestoreBatchWriteOperation {
  /// Creates set operation for given document reference.
  const FirestoreBatchWriteOperation.set(this.reference, this.data);

  /// Document reference affected by this operation.
  final DocumentReference<Map<String, dynamic>> reference;

  /// Data written by this operation.
  final Map<String, dynamic> data;

  /// Applies this operation to provided batch.
  void apply(WriteBatch batch) {
    batch.set(reference, data);
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
