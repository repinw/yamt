import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/kochmodus/application/cook_timer_alarms.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/cook_timer_alarm_controller.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../../../helpers/fake_local_notifications.dart';
import '../../../../helpers/fake_signed_in_user.dart';
import '../../../../helpers/memory_app_preferences.dart';
import '../../../recipes/cook_run_fixtures.dart';

void main() {
  _blockedTests();
  _exactAlarmCriteriaTests();
  _syncTests();
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    // Keeps the controller alive between the reads of one test.
    container.listen(cookTimerAlarmControllerProvider, (_, _) {});
  });

  CookTimerAlarmController controller() =>
      container.read(cookTimerAlarmControllerProvider.notifier);

  test('a page is open from opening until closing', () {
    expect(controller().isPageOpen('recipe-t1'), isFalse);

    controller().pageOpened('recipe-t1');
    expect(controller().isPageOpen('recipe-t1'), isTrue);
    expect(controller().isPageOpen('free-1'), isFalse);

    controller().pageClosed('recipe-t1');
    expect(controller().isPageOpen('recipe-t1'), isFalse);
  });

  test('opening the same run twice and closing once leaves it closed', () {
    controller()
      ..pageOpened('recipe-t1')
      ..pageOpened('recipe-t1')
      ..pageClosed('recipe-t1');

    expect(controller().isPageOpen('recipe-t1'), isFalse);
  });
}

const _askedKey = 'cook_timer_permissions_asked_v2';

class _FailingNotifications extends FakeLocalNotifications {
  @override
  Future<bool> areAllowed(String channelId) async =>
      throw StateError('The system has no answer.');
}

void _blockedTests() {
  group('cookTimerNotificationsBlocked', () {
    late MemoryAppPreferences preferences;
    late FakeLocalNotifications notifications;

    setUp(() {
      // The check of the system listens to the app lifecycle.
      TestWidgetsFlutterBinding.ensureInitialized();
      preferences = MemoryAppPreferences();
      notifications = FakeLocalNotifications();
    });

    Future<ProviderContainer> open({LocalNotifications? system}) async {
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(preferences),
          localNotificationsProvider.overrideWithValue(system ?? notifications),
        ],
      );
      addTearDown(container.dispose);
      container.listen(cookTimerNotificationsBlockedProvider, (_, _) {});
      // Lets the check of the system answer.
      await container
          .read(localNotificationsAllowedProvider(cookTimerChannelId).future)
          .then<void>((_) {}, onError: (Object _) {});
      await pumpEventQueue();
      return container;
    }

    test(
      'is false before this device asked, though notifications are off',
      () async {
        notifications.allowed = false;

        final container = await open();

        expect(container.read(cookTimerNotificationsBlockedProvider), isFalse);
      },
    );

    test('is false when asked and notifications are allowed', () async {
      await preferences.setString(_askedKey, 'set');

      final container = await open();

      expect(container.read(cookTimerNotificationsBlockedProvider), isFalse);
    });

    test('is false when the check fails', () async {
      await preferences.setString(_askedKey, 'set');

      final container = await open(system: _FailingNotifications());

      expect(container.read(cookTimerNotificationsBlockedProvider), isFalse);
    });

    test('is true when asked and the system says no', () async {
      await preferences.setString(_askedKey, 'set');
      notifications.allowed = false;

      final container = await open();

      expect(container.read(cookTimerNotificationsBlockedProvider), isTrue);
    });
  });

  test('openNotificationSettings opens the system settings', () async {
    final notifications = FakeLocalNotifications();
    final container = ProviderContainer(
      overrides: [localNotificationsProvider.overrideWithValue(notifications)],
    );
    addTearDown(container.dispose);
    container.listen(cookTimerAlarmControllerProvider, (_, _) {});

    await container
        .read(cookTimerAlarmControllerProvider.notifier)
        .openNotificationSettings();

    expect(notifications.settingsOpened, 1);
  });

  test('openNotificationSettings logs a failure and does not throw', () async {
    final notifications = FakeLocalNotifications()..canOpenSettings = false;
    final container = ProviderContainer(
      overrides: [localNotificationsProvider.overrideWithValue(notifications)],
    );
    addTearDown(container.dispose);
    container.listen(cookTimerAlarmControllerProvider, (_, _) {});

    await container
        .read(cookTimerAlarmControllerProvider.notifier)
        .openNotificationSettings();

    expect(notifications.settingsOpened, 0);
  });
}

final _now = DateTime.utc(2026, 11, 7, 12);

const CookTimerAlarmTexts _texts = (
  channelName: 'Timer',
  countdownChannelName: 'Laufende Timer',
  title: _title,
  body: _body,
  stopLabel: 'Stopp',
  countdownTitle: _countdownTitle,
);

String _countdownTitle(String label) => 'Läuft: $label';

String _title(String label) => 'Fertig: $label';

String _body(String runName) => runName;

CookRun _runWith(String timerId, {int minutes = 5}) => buildCookRun(
  timers: [
    CookTimer(
      id: timerId,
      label: 'Nudeln',
      endsAt: _now.add(Duration(minutes: minutes)),
      deviceId: 'dev-1',
    ),
  ],
);

void _syncTests() {
  group('sync', () {
    late FakeLocalNotifications notifications;
    late ProviderContainer container;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      notifications = FakeLocalNotifications();
      container = ProviderContainer(
        overrides: [
          localNotificationsProvider.overrideWithValue(notifications),
          appPreferencesProvider.overrideWithValue(
            MemoryAppPreferences(
              initialStrings: const {'app_install_id_v1': 'dev-1'},
            ),
          ),
          firebaseAuthProvider.overrideWithValue(FakeSignedInAuth(null)),
          clockProvider.overrideWithValue(() => _now),
        ],
      );
      addTearDown(container.dispose);
      container.listen(cookTimerAlarmControllerProvider, (_, _) {});
    });

    CookTimerAlarmController controller() =>
        container.read(cookTimerAlarmControllerProvider.notifier);

    test('schedules a timer as an alarm on the alarm channel', () async {
      await controller().sync([_runWith('a')], _texts);

      final id = cookTimerNotificationId('a');
      expect(cookTimerChannelId, 'cook_timer_alarm');
      expect(notifications.scheduled.keys, [id]);
      expect(notifications.alarmIds, {id});
      expect(notifications.channelIds[id], 'cook_timer_alarm');
      expect(notifications.scheduled[id]?.title, 'Fertig: Nudeln');
      expect(notifications.alarmStyles[id], (
        stopLabel: 'Stopp',
        countdown: (id: 'cook_timer_countdown', name: 'Laufende Timer'),
        countdownTitle: 'Läuft: Nudeln',
      ));
    });

    test('W1: the first timer never asks for exact alarms mid-step', () async {
      notifications
        ..exactAllowed = false
        ..grantsExact = false;

      await controller().sync([_runWith('a')], _texts);

      expect(notifications.scheduled.keys, [cookTimerNotificationId('a')]);
      expect(notifications.exactRequests, 0);
    });

    test('a failing tray read still schedules the timer', () async {
      notifications.activeFails = true;

      await controller().sync([_runWith('a')], _texts);

      expect(notifications.scheduled.keys, [cookTimerNotificationId('a')]);
    });

    test('after a restart a ringing notification of a stopped timer is '
        'cancelled', () async {
      final id = cookTimerNotificationId('a');
      notifications.active.add(id);

      await controller().sync(const [], _texts);

      expect(notifications.active, isEmpty);
    });

    test('Stopp cancels the scheduled notification', () async {
      await controller().sync([_runWith('a')], _texts);

      await controller().sync([buildCookRun()], _texts);

      expect(notifications.scheduled, isEmpty);
    });

    test('a discarded run cancels its notification', () async {
      await controller().sync([_runWith('a')], _texts);

      await controller().sync(const [], _texts);

      expect(notifications.scheduled, isEmpty);
    });

    test('"+1 Min" on a ringing timer stops the ring and schedules the new '
        'time', () async {
      final id = cookTimerNotificationId('a');
      await controller().sync([_runWith('a', minutes: 1)], _texts);
      notifications.active.add(id);

      await controller().sync([_runWith('a', minutes: 2)], _texts);

      expect(notifications.active, isEmpty);
      expect(
        notifications.scheduled[id]?.at,
        _now.add(const Duration(minutes: 2)),
      );
      expect(notifications.alarmIds, {id});
    });

    test('a timer that still rings is left alone', () async {
      final id = cookTimerNotificationId('a');
      notifications.active.add(id);

      await controller().sync([_runWith('a', minutes: -1)], _texts);

      expect(notifications.active, {id});
      expect(notifications.scheduled, isEmpty);
    });
  });
}

/// The first request for exact alarms does not reach the system.
class _FlakyExactNotifications extends FakeLocalNotifications {
  var _failed = false;

  @override
  Future<bool> requestExactAlarms() async {
    if (!_failed) {
      _failed = true;
      throw StateError('The system screen did not open.');
    }
    return await super.requestExactAlarms();
  }
}

// Acceptance tests of "Erlaubnis für genaue Wecker beim Kochstart" (W1-W6) in
// lib/features/kochmodus/CRITERIA.md. A start of cooking is askPermissions().
void _exactAlarmCriteriaTests() {
  group('Erlaubnis für genaue Wecker beim Kochstart', () {
    setUp(TestWidgetsFlutterBinding.ensureInitialized);

    // One start of cooking on a device with [preferences], a fresh app run.
    Future<void> startCooking(
      LocalNotifications notifications,
      MemoryAppPreferences preferences,
    ) async {
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(preferences),
          localNotificationsProvider.overrideWithValue(notifications),
        ],
      );
      addTearDown(container.dispose);
      container.listen(cookTimerAlarmControllerProvider, (_, _) {});
      await container
          .read(cookTimerAlarmControllerProvider.notifier)
          .askPermissions();
    }

    test('W1: starting to cook opens the exact alarm screen', () async {
      final notifications = FakeLocalNotifications()..exactAllowed = false;

      await startCooking(notifications, MemoryAppPreferences());

      expect(notifications.exactRequests, 1);
    });

    test('W1: every start asks again as long as exact alarms are not allowed '
        'and the cook has not declined', () async {
      final notifications = _FlakyExactNotifications()..exactAllowed = false;
      final preferences = MemoryAppPreferences();

      await startCooking(notifications, preferences);
      // The first screen never opened, so nothing was declined.
      expect(notifications.exactRequests, 0);
      await startCooking(notifications, preferences);

      expect(notifications.exactRequests, 1);
    });

    test('W2: after one decline the start never asks again', () async {
      final notifications = FakeLocalNotifications()
        ..exactAllowed = false
        ..grantsExact = false;
      final preferences = MemoryAppPreferences();

      await startCooking(notifications, preferences);
      expect(notifications.exactRequests, 1);
      // Also after the app was closed and opened again.
      await startCooking(notifications, preferences);
      await startCooking(notifications, preferences);

      expect(notifications.exactRequests, 1);
    });

    test('W3: allowed exact alarms are not asked', () async {
      final notifications = FakeLocalNotifications()..exactAllowed = true;

      await startCooking(notifications, MemoryAppPreferences());
      await startCooking(notifications, MemoryAppPreferences());

      expect(notifications.exactRequests, 0);
    });

    test('W4: an older app version asked for notifications; exact alarms are '
        'still asked', () async {
      final notifications = FakeLocalNotifications()
        ..exactAllowed = false
        ..grantsExact = false;
      final preferences = MemoryAppPreferences(
        initialStrings: const {_askedKey: 'set'},
      );

      await startCooking(notifications, preferences);

      expect(notifications.exactRequests, 1);
    });

    test('W4: notifications asked earlier and denied; exact alarms are still '
        'asked', () async {
      final notifications = FakeLocalNotifications()
        ..allowed = false
        ..grants = false
        ..exactAllowed = false
        ..grantsExact = false;
      final preferences = MemoryAppPreferences(
        initialStrings: const {_askedKey: 'set'},
      );

      await startCooking(notifications, preferences);

      expect(notifications.exactRequests, 1);
    });

    test(
      'W4: denying notifications does not count as declining exact alarms',
      () async {
        final notifications = FakeLocalNotifications()
          ..grants = false
          ..exactAllowed = false
          ..grantsExact = false;
        final preferences = MemoryAppPreferences();

        await startCooking(notifications, preferences);

        // The exact alarm screen opens at this start although notifications
        // were denied, and the denial is not remembered as a decline of it.
        expect(notifications.permissionRequests, 1);
        expect(notifications.exactRequests, 1);
      },
    );

    test('W5: the notification permission is asked only once', () async {
      final notifications = FakeLocalNotifications();
      final preferences = MemoryAppPreferences();

      await startCooking(notifications, preferences);
      await startCooking(notifications, preferences);
      await startCooking(notifications, preferences);

      expect(notifications.permissionRequests, 1);
    });

    test('W5: not asked again after an older app version asked', () async {
      final notifications = FakeLocalNotifications();

      await startCooking(
        notifications,
        MemoryAppPreferences(initialStrings: const {_askedKey: 'set'}),
      );

      expect(notifications.permissionRequests, 0);
    });

    test('W6: iOS, where exact alarms are always allowed, asks nothing '
        'about them', () async {
      // iOS reports exact alarms as allowed.
      final notifications = FakeLocalNotifications()..exactAllowed = true;

      await startCooking(notifications, MemoryAppPreferences());

      expect(notifications.exactRequests, 0);
    });
  });
}
