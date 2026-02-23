import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/inventory_fridge_item_store.dart';

void main() {
  test('chunker returns no chunks for empty input', () {
    final chunks = InventoryWriteOperationChunker.chunk<int>(
      operations: const <int>[],
      maxChunkSize: 500,
    ).toList(growable: false);

    expect(chunks, isEmpty);
  });

  test('chunker keeps chunk size at or below max limit', () {
    final input = List<int>.generate(1201, (index) => index);

    final chunks = InventoryWriteOperationChunker.chunk<int>(
      operations: input,
      maxChunkSize: 500,
    ).toList(growable: false);

    expect(chunks, hasLength(3));
    expect(chunks[0], hasLength(500));
    expect(chunks[1], hasLength(500));
    expect(chunks[2], hasLength(201));
    expect(chunks.expand((chunk) => chunk), orderedEquals(input));
  });

  test('chunker creates one chunk for exact batch-size input', () {
    final input = List<int>.generate(500, (index) => index);

    final chunks = InventoryWriteOperationChunker.chunk<int>(
      operations: input,
      maxChunkSize: 500,
    ).toList(growable: false);

    expect(chunks, hasLength(1));
    expect(chunks.single, orderedEquals(input));
  });

  test('chunker throws when maxChunkSize is zero', () {
    expect(
      () => InventoryWriteOperationChunker.chunk<int>(
        operations: const <int>[1, 2, 3],
        maxChunkSize: 0,
      ).toList(growable: false),
      throwsArgumentError,
    );
  });
}
