import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kochmodus/application/cook_timer_alarms.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../recipes/cook_run_fixtures.dart';

final _now = DateTime.utc(2026, 11, 7, 12);

CookTimer _timer(String id, {int minutes = 5, String device = 'dev-1'}) =>
    CookTimer(
      id: id,
      label: 'Label $id',
      endsAt: _now.add(Duration(minutes: minutes)),
      deviceId: device,
    );

CookRun _run(List<CookTimer> timers, {String id = 'recipe-t1'}) =>
    buildCookRun(id: id, timers: timers);

CookTimerAlarmChanges _reconcile(
  List<CookRun> runs, {
  Iterable<int> pending = const [],
  Iterable<int> active = const [],
  Map<int, DateTime> scheduled = const {},
  String deviceId = 'dev-1',
}) => reconcileCookTimerAlarms(
  runs: runs,
  deviceId: deviceId,
  pendingIds: pending,
  activeIds: active,
  scheduled: scheduled,
  now: _now,
);

void main() {
  group('notification ids', () {
    test('are stable and inside the range of cook timers', () {
      final id = cookTimerNotificationId('t-1');

      expect(cookTimerNotificationId('t-1'), id);
      expect(isCookTimerNotificationId(id), isTrue);
      expect(id, greaterThanOrEqualTo(200000000));
      expect(id, lessThan(300000000));
    });

    test('differ between timers, and other ids are not cook ids', () {
      expect(
        cookTimerNotificationId('t-1'),
        isNot(cookTimerNotificationId('t-2')),
      );
      expect(isCookTimerNotificationId(199999999), isFalse);
      expect(isCookTimerNotificationId(300000000), isFalse);
      expect(isCookTimerNotificationId(42), isFalse);
    });
  });

  test('the payload names the run and reads back', () {
    expect(cookTimerPayload('recipe-t1'), 'cook-run:recipe-t1');
    expect(cookRunIdOfPayload('cook-run:recipe-t1'), 'recipe-t1');
    expect(cookRunIdOfPayload('meal-plan:1'), isNull);
  });

  group('reconcileCookTimerAlarms', () {
    test('schedules a running timer that is not pending', () {
      final changes = _reconcile([
        _run([_timer('a')]),
      ]);

      expect(changes.cancel, isEmpty);
      expect(changes.schedule, hasLength(1));
      final alarm = changes.schedule.single;
      expect(alarm.id, cookTimerNotificationId('a'));
      expect(alarm.at, _now.add(const Duration(minutes: 5)));
      expect(alarm.label, 'Label a');
      expect(alarm.runName, 'Eintopf');
      expect(alarm.payload, 'cook-run:recipe-t1');
    });

    test('leaves a pending timer with the same time alone', () {
      final id = cookTimerNotificationId('a');

      final changes = _reconcile(
        [
          _run([_timer('a')]),
        ],
        pending: [id],
        scheduled: {id: _now.add(const Duration(minutes: 5))},
      );

      expect(changes.schedule, isEmpty);
      expect(changes.cancel, isEmpty);
    });

    test('schedules again when "+1 Min" moved the time', () {
      final id = cookTimerNotificationId('a');

      final changes = _reconcile(
        [
          _run([_timer('a', minutes: 6)]),
        ],
        pending: [id],
        scheduled: {id: _now.add(const Duration(minutes: 5))},
      );

      expect(changes.schedule.map((alarm) => alarm.id), [id]);
      expect(changes.cancel, isEmpty);
    });

    test('cancels a pending timer that was stopped', () {
      final id = cookTimerNotificationId('a');

      final changes = _reconcile([_run(const [])], pending: [id]);

      expect(changes.cancel, [id]);
      expect(changes.schedule, isEmpty);
    });

    test('cancels the timers of a run that is gone', () {
      final id = cookTimerNotificationId('a');

      expect(_reconcile(const [], pending: [id]).cancel, [id]);
    });

    test('rings only the timers this device started', () {
      final other = cookTimerNotificationId('b');

      final changes = _reconcile(
        [
          _run([_timer('a'), _timer('b', device: 'dev-2')]),
        ],
        pending: [other],
      );

      expect(changes.schedule.map((alarm) => alarm.id), [
        cookTimerNotificationId('a'),
      ]);
      // The other device's notification is not wanted here either.
      expect(changes.cancel, [other]);
    });

    test('does not schedule a timer that is over, nor cancel its ring', () {
      final over = _timer('a', minutes: -1);
      final id = cookTimerNotificationId('a');

      final changes = _reconcile(
        [
          _run([over]),
        ],
        pending: [id],
        scheduled: {id: over.endsAt},
      );

      expect(changes.schedule, isEmpty);
      expect(changes.cancel, isEmpty);
    });

    test('does not schedule an over timer that was never scheduled', () {
      expect(
        _reconcile([
          _run([_timer('a', minutes: -1)]),
        ]).schedule,
        isEmpty,
      );
    });

    test('cancels a scheduled notification that is no longer pending', () {
      final id = cookTimerNotificationId('a');

      final changes = _reconcile(
        const [],
        scheduled: {id: _now.subtract(const Duration(minutes: 1))},
      );

      expect(changes.cancel, [id]);
    });

    test('lists an id once when it is pending and scheduled', () {
      final id = cookTimerNotificationId('a');

      final changes = _reconcile(
        const [],
        pending: [id],
        scheduled: {id: _now},
      );

      expect(changes.cancel, [id]);
    });

    test('does not cancel a scheduled id that is not a cook timer', () {
      expect(_reconcile(const [], scheduled: {7: _now}).cancel, isEmpty);
    });

    test('ignores pending notifications that are not cook timers', () {
      final changes = _reconcile(const [], pending: [7, 99999999, 300000001]);

      expect(changes.cancel, isEmpty);
    });

    test('cancels and schedules a rung timer that got "+1 Min"', () {
      final id = cookTimerNotificationId('a');

      final changes = _reconcile(
        [
          _run([_timer('a', minutes: 1)]),
        ],
        active: [id],
        scheduled: {id: _now.subtract(const Duration(minutes: 1))},
      );

      expect(changes.cancel, [id]);
      expect(changes.schedule.map((alarm) => alarm.id), [id]);
    });

    test('cancels an active notification without a timer', () {
      final id = cookTimerNotificationId('a');

      final changes = _reconcile(const [], active: [id]);

      expect(changes.cancel, [id]);
      expect(changes.schedule, isEmpty);
    });

    test('ignores active notifications that are not cook timers', () {
      expect(
        _reconcile(const [], active: [7, 99999999, 300000001]).cancel,
        isEmpty,
      );
    });

    test('keeps an active timer that already passed ringing', () {
      final over = _timer('a', minutes: -1);
      final id = cookTimerNotificationId('a');

      final changes = _reconcile(
        [
          _run([over]),
        ],
        active: [id],
        scheduled: {id: over.endsAt},
      );

      expect(changes.cancel, isEmpty);
      expect(changes.schedule, isEmpty);
    });

    test('timers of several runs get their own payloads', () {
      final changes = _reconcile([
        _run([_timer('a')]),
        _run([_timer('b')], id: 'free-1'),
      ]);

      expect(changes.schedule.map((alarm) => alarm.payload).toSet(), {
        'cook-run:recipe-t1',
        'cook-run:free-1',
      });
    });
  });
}
