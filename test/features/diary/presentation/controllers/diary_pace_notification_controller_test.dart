import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_balance_loaded_metrics.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';
import 'package:yamt/features/diary/domain/diary_meal_times.dart';
import 'package:yamt/features/diary/domain/diary_pace_notices.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_card_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_notice_day_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_notification_controller.dart';

import '../../../../helpers/fake_local_notifications.dart';
import '../../../../helpers/memory_app_preferences.dart';
import '../../support/diary_dashboard_test_support.dart';

const _onKey = 'diary_pace_notification_on_v1';
const _markerKey = 'diary_pace_marker_v1';
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
  new({this.failRequest = false});

  final bool failRequest;

  @override
  Future<bool> requestPermission() async => failRequest
      ? throw StateError('no dialog')
      : await super.requestPermission();
}

DiaryDailyBalanceMetrics _daily(double target, {double eaten = 0}) =>
    DiaryDailyBalanceMetrics(
      bufferAdjustmentKcal: 0,
      realEatenKcal: eaten,
      eatenKcal: eaten,
      realDayLeftKcal: target - eaten,
      dayLeftKcal: target - eaten,
      targetKcal: target,
    );

DiaryBalanceCardData _loaded({bool isPauseDay = false, double eaten = 0}) =>
    DiaryBalanceCardData.loaded(
      loadedMetrics: DiaryBalanceLoadedMetrics(
        selectedDay: _today,
        daily: _daily(1588, eaten: eaten),
        state: DiaryBalanceLoadedState(
          isPauseDay: isPauseDay,
          showGameControls: false,
          runWeekNumber: 1,
        ),
        runWeekStart: _today,
      ),
    );

DiaryBalanceNotCountingDayData _notCounting() => DiaryBalanceNotCountingDayData(
  day: _today,
  startDate: DateTime(2026, 11, 14),
  daily: _daily(1588, eaten: 100),
);

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
    DiaryBalanceCardData? card,
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
        diaryBalanceCardProvider(_today).overrideWith((ref) => card),
        diaryDayDashboardControllerProvider(_today).overrideWith(
          () => FakeDiaryDayDashboardController(
            const DiaryDayDashboardState(
              data: null,
              isFromCache: false,
              isRefreshing: false,
              error: null,
            ),
          ),
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

  group('debugShowSoon', () {});

  group('diaryPaceNoticeDay', () {
    Future<DiaryPaceDay?> read(ProviderContainer container) async {
      final subscription = container.listen(
        diaryPaceNoticeDayProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      return subscription.read();
    }

    test('is null while the notices are off', () async {
      final container = containerWith(card: _loaded(), noticesOn: false);

      expect(await read(container), isNull);
    });

    test('is null while the pace marker is off', () async {
      final container = containerWith(
        card: _loaded(),
        markerOn: false,
        preferences: MemoryAppPreferences(initialStrings: {_onKey: 'set'}),
      );

      expect(await read(container), isNull);
    });

    test('is null while today has not loaded', () async {
      final container = containerWith(
        preferences: MemoryAppPreferences(
          initialInts: {_markerKey: 1},
          initialStrings: {_onKey: 'set'},
        ),
      );

      expect(await read(container), isNull);
    });

    test('is null on a pause day', () async {
      final container = containerWith(
        card: _loaded(isPauseDay: true),
        preferences: MemoryAppPreferences(
          initialInts: {_markerKey: 1},
          initialStrings: {_onKey: 'set'},
        ),
      );

      expect(await read(container), isNull);
    });

    test("has the day's target, eaten kcal, times and shares", () async {
      final container = containerWith(
        card: _loaded(eaten: 250),
        preferences: MemoryAppPreferences(
          initialInts: {_markerKey: 1},
          initialStrings: {
            _onKey: 'set',
            'diary_meal_shares_v1': '30,30,30,10',
          },
        ),
      );

      final day = await read(container);

      expect(day!.day, _today);
      expect(day.targetKcal, 1588);
      expect(day.eatenKcal, 250);
      expect(day.times, DiaryMealTimes.standard);
      expect(day.shares, const DiaryMealShares([30, 30, 30, 10]));
      // The dashboard has no nutrition data yet.
      expect(day.macro, isNull);
    });

    test('falls back to the daily numbers of a practice day', () async {
      final container = containerWith(
        card: DiaryBalanceCardData.practiceDay(practiceDay: _notCounting()),
        preferences: MemoryAppPreferences(
          initialInts: {_markerKey: 1},
          initialStrings: {_onKey: 'set'},
        ),
      );

      final day = await read(container);

      expect(day!.targetKcal, 1588);
      expect(day.eatenKcal, 100);
    });

    test(
      'falls back to the daily numbers before a scheduled restart',
      () async {
        final container = containerWith(
          card: DiaryBalanceCardData.scheduledRestart(
            scheduledRestart: _notCounting(),
          ),
          preferences: MemoryAppPreferences(
            initialInts: {_markerKey: 1},
            initialStrings: {_onKey: 'set'},
          ),
        );

        final day = await read(container);

        expect(day!.targetKcal, 1588);
        expect(day.eatenKcal, 100);
      },
    );
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
