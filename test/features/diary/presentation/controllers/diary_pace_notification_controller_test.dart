import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';
import 'package:yamt/features/diary/domain/diary_meal_times.dart';
import 'package:yamt/features/diary/domain/diary_pace_notices.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_notification_controller.dart';

import '../../../../helpers/fake_local_notifications.dart';
import '../../../../helpers/memory_app_preferences.dart';

const _onKey = 'diary_pace_notification_on_v1';
const _markerKey = 'diary_pace_marker_v1';
const _spentKey = 'diary_pace_notification_spent_v1';
const _idBase = 300000000;
final _today = DateTime(2026, 11, 12);

int _id(MealType meal) => _idBase + MealType.sectionOrder.indexOf(meal);

class _AskingNotifications extends FakeLocalNotifications {
  final answer = Completer<bool>();

  @override
  Future<bool> requestPermission() {
    permissionRequests++;
    return answer.future;
  }
}

class _FailingNotifications extends FakeLocalNotifications {
  new({
    this.failRequest = false,
    this.failScheduleFor,
    this.failPending = false,
  });

  final bool failRequest;
  final int? failScheduleFor;
  final bool failPending;

  @override
  Future<List<int>> pendingIds() async =>
      failPending ? throw StateError('no list') : await super.pendingIds();

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required NotificationChannel channel,
    required String title,
    required String body,
    required String payload,
    bool exact = false,
    AlarmStyle? alarm,
  }) async => id == failScheduleFor
      ? throw StateError('no schedule')
      : await super.schedule(
          id: id,
          at: at,
          channel: channel,
          title: title,
          body: body,
          payload: payload,
          exact: exact,
          alarm: alarm,
        );

  @override
  Future<bool> requestPermission() async => failRequest
      ? throw StateError('no dialog')
      : await super.requestPermission();
}

void main() {
  // The allowed check listens for the app returning to the foreground.
  TestWidgetsFlutterBinding.ensureInitialized();

  // What the clock shows; a test moves it on.
  late DateTime now;
  setUp(() => now = DateTime(2026, 11, 12, 19, 30));

  const lateTimes = DiaryMealTimes(
    start: 19 * 60,
    ends: [19 * 60 + 55, 20 * 60 + 10, 20 * 60 + 30, 21 * 60],
  );
  final texts = (
    channelName: 'Frei',
    title: (int kcal) => 'free $kcal',
    body: (DiaryPaceMacro? macro) => macro?.name ?? '',
  );

  DiaryPaceDay pace({double eaten = 0, DateTime? day, DiaryPaceMacro? macro}) =>
      (
        day: day ?? _today,
        targetKcal: 1588,
        eatenKcal: eaten,
        times: lateTimes,
        shares: DiaryMealShares.standard,
        macro: macro,
      );

  ProviderContainer containerWith({
    MemoryAppPreferences? preferences,
    FakeLocalNotifications? notifications,
    bool markerOn = true,
    bool noticesOn = true,
  }) {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(
          preferences ??
              MemoryAppPreferences(
                initialInts: {if (markerOn) _markerKey: 1},
                initialStrings: {if (noticesOn) _onKey: 'set'},
              ),
        ),
        clockProvider.overrideWithValue(() => now),
        localNotificationsProvider.overrideWithValue(
          notifications ?? FakeLocalNotifications(),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  DiaryPaceNotificationController controllerOf(ProviderContainer container) =>
      container.read(diaryPaceNotificationControllerProvider.notifier);

  group('setEnabled', () {
    test('is off by default and keeps the choice on the device', () async {
      final preferences = MemoryAppPreferences();
      final notifications = FakeLocalNotifications();
      final container = containerWith(
        preferences: preferences,
        notifications: notifications,
      );
      final states = <bool>[];
      container.listen(
        diaryPaceNotificationControllerProvider,
        (_, next) => states.add(next),
      );
      expect(container.read(diaryPaceNotificationControllerProvider), isFalse);

      await controllerOf(container).setEnabled(enabled: true);

      expect(states, [true]);
      expect(notifications.permissionRequests, 1);
      expect(preferences.getStringSync(_onKey), 'set');
      expect(
        containerWith(preferences: preferences)
            .read(diaryPaceNotificationControllerProvider),
        isTrue,
      );

      await controllerOf(container).setEnabled(enabled: false);

      expect(states, [true, false]);
      expect(preferences.getStringSync(_onKey), isNull);
      // Turning off asks for nothing.
      expect(notifications.permissionRequests, 1);
    });

    test('turns on only after the permission answer, asks once', () async {
      final notifications = _AskingNotifications();
      final preferences = MemoryAppPreferences();
      final container = containerWith(
        preferences: preferences,
        notifications: notifications,
      );
      final subscription = container.listen(
        diaryPaceNotificationControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      final controller = controllerOf(container);

      final first = controller.setEnabled(enabled: true);
      await controller.setEnabled(enabled: true);

      expect(notifications.permissionRequests, 1);
      expect(container.read(diaryPaceNotificationControllerProvider), isFalse);
      expect(preferences.getStringSync(_onKey), isNull);

      notifications.answer.complete(true);
      await first;

      expect(container.read(diaryPaceNotificationControllerProvider), isTrue);
      expect(preferences.getStringSync(_onKey), 'set');

      // The guard opens again after the answer.
      await controller.setEnabled(enabled: false);
      notifications.permissionRequests = 0;
      final again = controller.setEnabled(enabled: true);
      expect(notifications.permissionRequests, 1);
      await again;
    });

    test('turns on when the permission request fails', () async {
      final container = containerWith(
        notifications: _FailingNotifications(failRequest: true),
      );
      final subscription = container.listen(
        diaryPaceNotificationControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      await controllerOf(container).setEnabled(enabled: true);

      expect(container.read(diaryPaceNotificationControllerProvider), isTrue);
    });
  });

  group('sync', () {
    test('a null pace cancels pending pace notices and nothing else', () async {
      final notifications = FakeLocalNotifications();
      notifications.scheduled[7] = (at: now, title: 'other', payload: 'x');
      final container = containerWith(notifications: notifications);
      final controller = controllerOf(container);
      await controller.sync(pace(), texts);
      expect(notifications.scheduled.length, greaterThan(1));

      await controller.sync(null, texts);

      expect(notifications.scheduled.keys, [7]);
    });

    test('turned off, also cancels a passed notice still pending', () async {
      now = DateTime(2026, 11, 12, 20, 5);
      final notifications = FakeLocalNotifications();
      final container = containerWith(notifications: notifications);
      final controller = controllerOf(container);
      await controller.sync(pace(), texts);
      notifications.scheduled[_id(MealType.lunch)] = (
        at: DateTime(2026, 11, 12, 20),
        title: 'held',
        payload: diaryPaceChannelId,
      );
      await controller.setEnabled(enabled: false);

      await controller.sync(null, texts);

      expect(notifications.scheduled, isEmpty);
    });

    test('never cancels the debug notice', () async {
      now = DateTime(2026, 11, 12, 20, 5);
      final notifications = FakeLocalNotifications();
      final container = containerWith(notifications: notifications);
      final controller = controllerOf(container);
      await controller.debugShowSoon(pace(), texts);

      await controller.sync(null, texts);

      expect(notifications.scheduled.containsKey(_idBase + 99), isTrue);
    });

    test('does not touch pending ids of other features', () async {
      final notifications = FakeLocalNotifications();
      notifications.scheduled[_idBase - 1] = (
        at: now,
        title: 'other',
        payload: 'x',
      );
      notifications.scheduled[_idBase + 4] = (
        at: now,
        title: 'other',
        payload: 'x',
      );
      final container = containerWith(notifications: notifications);

      await controllerOf(container).sync(null, texts);

      expect(notifications.scheduled.length, 2);
    });

    test('a pace of another day schedules nothing and cancels', () async {
      final notifications = FakeLocalNotifications();
      final container = containerWith(notifications: notifications);
      final controller = controllerOf(container);
      await controller.sync(pace(), texts);

      await controller.sync(pace(day: DateTime(2026, 11, 11)), texts);

      expect(notifications.scheduled, isEmpty);
    });

    test('ignores a spent record of another day', () async {
      now = DateTime(2026, 11, 12, 20, 5);
      final notifications = FakeLocalNotifications();
      final container = containerWith(
        notifications: notifications,
        preferences: MemoryAppPreferences(
          initialInts: {_markerKey: 1},
          initialStrings: {_onKey: 'set', _spentKey: '2026-11-11|dinner=100'},
        ),
      );

      await controllerOf(container).sync(pace(eaten: 300), texts);

      expect(notifications.scheduled.containsKey(_id(MealType.dinner)), isTrue);
    });

    test('a failing call leaves the others in place', () async {
      now = DateTime(2026, 11, 12, 18, 30);
      final notifications = _FailingNotifications(
        failScheduleFor: _id(MealType.lunch),
        failPending: true,
      );
      final container = containerWith(notifications: notifications);

      await controllerOf(container).sync(pace(), texts);

      expect(
        notifications.scheduled.keys,
        unorderedEquals([_id(MealType.breakfast), _id(MealType.dinner)]),
      );
    });

    test('runs calls one after the other, the last pace wins', () async {
      final notifications = FakeLocalNotifications();
      final container = containerWith(notifications: notifications);
      final controller = controllerOf(container);

      final first = controller.sync(pace(), texts);
      final second = controller.sync(null, texts);
      await Future.wait([first, second]);

      expect(notifications.scheduled, isEmpty);
    });

    test('does nothing once the container is disposed', () async {
      final notifications = FakeLocalNotifications();
      final container = containerWith(notifications: notifications);
      final controller = controllerOf(container);
      container.dispose();

      await controller.sync(pace(), texts);

      expect(notifications.scheduled, isEmpty);
    });
  });

  group('diaryPaceNotificationBlocked', () {
    test('is false while the notices are off', () async {
      final notifications = FakeLocalNotifications()..allowed = false;
      final container = containerWith(notifications: notifications);

      expect(container.read(diaryPaceNotificationBlockedProvider), isFalse);
    });

    test('is true while on and the system blocks the channel', () async {
      final notifications = FakeLocalNotifications()..allowed = false;
      final container = containerWith(
        notifications: notifications,
        preferences: MemoryAppPreferences(initialStrings: {_onKey: 'set'}),
      );
      final subscription = container.listen(
        diaryPaceNotificationBlockedProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      // False while the check runs.
      expect(subscription.read(), isFalse);

      await container.read(
        localNotificationsAllowedProvider(diaryPaceChannelId).future,
      );

      expect(subscription.read(), isTrue);
    });

    test('is false while on and the system allows it', () async {
      final container = containerWith(
        preferences: MemoryAppPreferences(initialStrings: {_onKey: 'set'}),
      );
      final subscription = container.listen(
        diaryPaceNotificationBlockedProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(
        localNotificationsAllowedProvider(diaryPaceChannelId).future,
      );

      expect(container.read(diaryPaceNotificationBlockedProvider), isFalse);
    });
  });
}
