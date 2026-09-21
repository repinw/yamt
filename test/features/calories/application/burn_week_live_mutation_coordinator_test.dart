import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/'
    'burn_week_live_mutation_coordinator.dart';

void main() {
  group('BurnWeekLiveMutationCoordinator', () {
    late BurnWeekLiveMutationCoordinator coordinator;

    setUp(() {
      coordinator = BurnWeekLiveMutationCoordinator();
    });

    test('queues and executes mutation in microtask', () async {
      var executed = false;
      coordinator.queueMutation(
        key: 'sync:week1',
        action: () async {
          executed = true;
        },
      );

      expect(coordinator.hasPendingMutation('sync:week1'), isTrue);
      expect(executed, isFalse);

      await Future<void>.delayed(Duration.zero);
      expect(executed, isTrue);
      expect(coordinator.hasPendingMutation('sync:week1'), isFalse);
    });

    test('deduplicates identical queued mutations', () async {
      var callCount = 0;
      coordinator
        ..queueMutation(
          key: 'sync:week1',
          action: () async {
            callCount += 1;
          },
        )
        ..queueMutation(
          key: 'sync:week1',
          action: () async {
            callCount += 1;
          },
        );

      await Future<void>.delayed(Duration.zero);
      expect(callCount, 1);
    });

    test('deduplicates identical mutations while in flight', () async {
      final blocker = Completer<void>();
      var callCount = 0;

      coordinator.queueMutation(
        key: 'sync:week1',
        action: () async {
          callCount += 1;
          await blocker.future;
        },
      );

      await Future<void>.delayed(Duration.zero);
      expect(callCount, 1);
      expect(coordinator.hasPendingMutation('sync:week1'), isTrue);

      coordinator.queueMutation(
        key: 'sync:week1',
        action: () async {
          callCount += 1;
        },
      );

      await Future<void>.delayed(Duration.zero);
      expect(callCount, 1);

      blocker.complete();
      await Future<void>.delayed(Duration.zero);
      expect(coordinator.hasPendingMutation('sync:week1'), isFalse);
    });

    test('clears pending state if mutation action fails', () async {
      final errors = <Object>[];
      runZonedGuarded(
        () {
          coordinator.queueMutation(
            key: 'failing',
            action: () async {
              throw Exception('network error');
            },
          );
        },
        (error, stack) {
          errors.add(error);
        },
      );

      await Future<void>.delayed(Duration.zero);
      expect(coordinator.hasPendingMutation('failing'), isFalse);
      expect(errors, hasLength(1));
    });
  });
}
