import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';

void main() {
  test('chunker returns no chunks for empty operations', () {
    final chunks = FirestoreBatchChunker.chunk<int>(
      operations: const <int>[],
      maxChunkSize: 500,
    ).toList(growable: false);

    expect(chunks, isEmpty);
  });

  test('chunker keeps chunk size below max limit', () {
    final input = List<int>.generate(1201, (index) => index);

    final chunks = FirestoreBatchChunker.chunk<int>(
      operations: input,
      maxChunkSize: 500,
    ).toList(growable: false);

    expect(chunks, hasLength(3));
    expect(chunks[0], hasLength(500));
    expect(chunks[1], hasLength(500));
    expect(chunks[2], hasLength(201));
    expect(chunks.expand((chunk) => chunk), orderedEquals(input));
  });

  test('chunker throws when maxChunkSize is zero', () {
    expect(
      () => FirestoreBatchChunker.chunk<int>(
        operations: const <int>[1, 2, 3],
        maxChunkSize: 0,
      ).toList(growable: false),
      throwsArgumentError,
    );
  });
}
