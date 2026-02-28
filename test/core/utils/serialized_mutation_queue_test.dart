import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';

void main() {
  test('runs operation B only after longer operation A completed', () async {
    final queue = SerializedMutationQueue();
    final timeline = <String>[];

    final operationA = queue.run<String>(
      operation: () async {
        timeline.add('A-start');
        await Future<void>.delayed(const Duration(milliseconds: 200));
        timeline.add('A-end');
        return 'A-result';
      },
      fallbackValue: 'A-fallback',
      onError: (error, stackTrace) {
        fail('operation A should not fail');
      },
    );
    final operationB = queue.run<String>(
      operation: () async {
        timeline.add('B-start');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        timeline.add('B-end');
        return 'B-result';
      },
      fallbackValue: 'B-fallback',
      onError: (error, stackTrace) {
        fail('operation B should not fail');
      },
    );

    final results = await Future.wait(<Future<String>>[operationA, operationB]);

    expect(results, orderedEquals(<String>['A-result', 'B-result']));
    expect(
      timeline,
      orderedEquals(<String>['A-start', 'A-end', 'B-start', 'B-end']),
    );
  });

  test(
    'returns fallback and continues queue after failing operation',
    () async {
      final queue = SerializedMutationQueue();
      final timeline = <String>[];
      final handledErrors = <Object>[];

      final operationA = queue.run<int>(
        operation: () async {
          timeline.add('A-start');
          throw StateError('A failed');
        },
        fallbackValue: -1,
        onError: (error, stackTrace) {
          timeline.add('A-error');
          handledErrors.add(error);
        },
      );
      final operationB = queue.run<int>(
        operation: () async {
          timeline.add('B-start');
          await Future<void>.delayed(const Duration(milliseconds: 10));
          timeline.add('B-end');
          return 2;
        },
        fallbackValue: -2,
        onError: (error, stackTrace) {
          fail('operation B should not fail');
        },
      );

      final firstResult = await operationA;
      final secondResult = await operationB;

      expect(firstResult, -1);
      expect(secondResult, 2);
      expect(handledErrors, hasLength(1));
      expect(handledErrors.single, isA<StateError>());
      expect(
        timeline,
        orderedEquals(<String>['A-start', 'A-error', 'B-start', 'B-end']),
      );
    },
  );
}
