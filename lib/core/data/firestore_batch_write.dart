import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreBatchWriteOperation {
  const FirestoreBatchWriteOperation.set(this.reference, this.data)
    : _isDelete = false;

  const FirestoreBatchWriteOperation.delete(this.reference)
    : data = null,
      _isDelete = true;

  final DocumentReference<Map<String, dynamic>> reference;
  final Map<String, dynamic>? data;
  final bool _isDelete;

  void apply(WriteBatch batch) {
    if (_isDelete) {
      batch.delete(reference);
      return;
    }
    batch.set(reference, data!);
  }
}

class FirestoreBatchChunker {
  const FirestoreBatchChunker._();

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
