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
        'snack:done',
      ]),
    );
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
        'snack:failed',
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

  test('runAction resets loading state when action throws', () async {
    final harness = _CoordinatorHarness();
    final coordinator = harness.buildCoordinator();

    await expectLater(
      coordinator.runAction(() async {
        harness.events.add('action');
        throw StateError('boom');
      }),
      throwsA(isA<StateError>()),
    );

    expect(
      harness.events,
      orderedEquals(<String>['setWorking:true', 'action', 'setWorking:false']),
    );
  });
}

class _CoordinatorHarness {
  _CoordinatorHarness({this.working = false});

  final events = <String>[];
  var working = false;
  var mounted = true;
  String? lastSnackBarMessage;

  InventoryItemRowActionCoordinator buildCoordinator() {
    return InventoryItemRowActionCoordinator(
      isWorking: () => working,
      setWorking: (isWorking) {
        events.add('setWorking:$isWorking');
        working = isWorking;
      },
      isMounted: () => mounted,
      showSnackBar: (message) {
        events.add('snack:$message');
        lastSnackBarMessage = message;
      },
      defaultFailureMessage: 'fallback-failure',
    );
  }
}
