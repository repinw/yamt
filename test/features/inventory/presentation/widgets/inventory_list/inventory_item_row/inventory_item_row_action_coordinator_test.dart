import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_action_coordinator.dart';

void main() {
  test('runAction sets loading state and shows success feedback', () async {
    final harness = _CoordinatorHarness();
    final coordinator = harness.buildCoordinator();

    await coordinator.runAction(() async {
      harness.events.add('action');
      return true;
    }, successMessage: 'done');

    expect(
      harness.events,
      orderedEquals(<String>[
        'setWorking:true',
        'action',
        'setWorking:false',
        'snack:done:success',
      ]),
    );
  });

  test('runAction passes undo only to the success snack bar', () async {
    final harness = _CoordinatorHarness();
    final coordinator = harness.buildCoordinator();
    var undone = false;

    await coordinator.runAction(
      () async => true,
      successMessage: 'done',
      undo: () async => undone = true,
    );
    await harness.lastUndo!();

    expect(undone, isTrue);

    await coordinator.runAction(() async => false, undo: () async => true);

    expect(harness.lastUndo, isNull);
  });

  test('runAction shows provided failure message when action fails', () async {
    final harness = _CoordinatorHarness();
    final coordinator = harness.buildCoordinator();

    await coordinator.runAction(() async {
      harness.events.add('action');
      return false;
    }, failureMessage: 'failed');

    expect(
      harness.events,
      orderedEquals(<String>[
        'setWorking:true',
        'action',
        'setWorking:false',
        'snack:failed:error',
      ]),
    );
  });

  test(
    'runAction uses default failure message when none is provided',
    () async {
      final harness = _CoordinatorHarness();
      final coordinator = harness.buildCoordinator();

      await coordinator.runAction(() async => false);

      expect(harness.lastSnackBarMessage, 'fallback-failure');
    },
  );

  test('runAction does nothing when already working', () async {
    final harness = _CoordinatorHarness(working: true);
    final coordinator = harness.buildCoordinator();
    var actionCalls = 0;

    await coordinator.runAction(() async {
      actionCalls++;
      return true;
    });

    expect(actionCalls, 0);
    expect(harness.events, isEmpty);
  });

  test(
    'runAction skips reset and feedback when unmounted after action',
    () async {
      final harness = _CoordinatorHarness();
      final coordinator = harness.buildCoordinator();

      await coordinator.runAction(() async {
        harness.events.add('action');
        harness.mounted = false;
        return false;
      });

      expect(
        harness.events,
        orderedEquals(<String>['setWorking:true', 'action']),
      );
    },
  );

  test(
    'runAction resets loading state and shows failure when action throws',
    () async {
      final harness = _CoordinatorHarness();
      final coordinator = harness.buildCoordinator();

      await coordinator.runAction(() async {
        harness.events.add('action');
        throw StateError('boom');
      });

      expect(
        harness.events,
        orderedEquals(<String>[
          'setWorking:true',
          'action',
          'setWorking:false',
          'snack:fallback-failure:error',
        ]),
      );
    },
  );
}

class _CoordinatorHarness {
  new({this.working = false});

  final events = <String>[];
  bool working = false;
  bool mounted = true;
  String? lastSnackBarMessage;
  Future<bool> Function()? lastUndo;

  InventoryItemRowActionCoordinator buildCoordinator() {
    return InventoryItemRowActionCoordinator(
      isWorking: () => working,
      setWorking: (isWorking) {
        events.add('setWorking:$isWorking');
        working = isWorking;
      },
      isMounted: () => mounted,
      showSnackBar: (message, tone, undo) {
        events.add('snack:$message:${tone.name}');
        lastSnackBarMessage = message;
        lastUndo = undo;
      },
      defaultFailureMessage: 'fallback-failure',
    );
  }
}
