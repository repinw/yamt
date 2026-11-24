// Technical tests of the free kcal notice (#971): tomorrow's target provider,
// sync while tomorrow loads, and the debug notice.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_balance_loaded_metrics.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';
import 'package:yamt/features/diary/domain/diary_meal_times.dart';
import 'package:yamt/features/diary/domain/diary_pace_notices.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_card_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_notice_day_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_notification_controller.dart';

import '../../../../helpers/fake_local_notifications.dart';
import '../../../../helpers/memory_app_preferences.dart';

const _onKey = 'diary_pace_notification_on_v1';
const _markerKey = 'diary_pace_marker_v1';
const _tomorrowId = 300000050;
const _debugId = 300000099;
final _today = DateTime(2026, 11, 12);
final _tomorrow = DateTime(2026, 11, 13);

DiaryDailyBalanceMetrics _daily(double target) => DiaryDailyBalanceMetrics(
  bufferAdjustmentKcal: 0,
  realEatenKcal: 0,
  eatenKcal: 0,
  realDayLeftKcal: target,
  dayLeftKcal: target,
  targetKcal: target,
);

DiaryBalanceCardData _loaded(double target, {bool isPauseDay = false}) =>
    DiaryBalanceCardData.loaded(
      loadedMetrics: DiaryBalanceLoadedMetrics(
        selectedDay: _tomorrow,
        daily: _daily(target),
        state: DiaryBalanceLoadedState(
          isPauseDay: isPauseDay,
          showGameControls: false,
          runWeekNumber: 1,
        ),
        runWeekStart: _tomorrow,
      ),
    );

class _RecordingNotifications extends FakeLocalNotifications {
  final bodies = <int, String>{};

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
  }) {
    bodies[id] = body;
    return super.schedule(
      id: id,
      at: at,
      channel: channel,
      title: title,
      body: body,
      payload: payload,
      exact: exact,
      alarm: alarm,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 11, 12, 12);
  final texts = (
    channelName: 'Frei',
    title: (int kcal) => 'free $kcal',
    body: (DiaryPaceMacro? macro) => macro?.name ?? '',
  );

  DiaryPaceDay pace({
    double target = 2000,
    double eaten = 0,
    DiaryPaceMacro? macro,
  }) => (
    day: _today,
    targetKcal: target,
    eatenKcal: eaten,
    times: DiaryMealTimes.standard,
    shares: DiaryMealShares.standard,
    macro: macro,
  );

  ProviderContainer containerWith({
    FakeLocalNotifications? notifications,
    DiaryBalanceCardData? tomorrowCard,
    bool markerOn = true,
    bool noticesOn = true,
  }) {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(
          MemoryAppPreferences(
            initialInts: {if (markerOn) _markerKey: 1},
            initialStrings: {if (noticesOn) _onKey: 'set'},
          ),
        ),
        clockProvider.overrideWithValue(() => now),
        localNotificationsProvider.overrideWithValue(
          notifications ?? FakeLocalNotifications(),
        ),
        diaryBalanceCardProvider(_tomorrow).overrideWith((ref) => tomorrowCard),
      ],
    );
    addTearDown(container.dispose);
    // The switch's state lives in the controller; keep it alive.
    container.listen(diaryPaceNotificationControllerProvider, (_, _) {});
    return container;
  }

  AsyncValue<double?> readTomorrow(ProviderContainer container) {
    final subscription = container.listen(
      diaryPaceTomorrowTargetProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    return subscription.read();
  }

  group('diaryPaceTomorrowTarget', () {
    test("is loading while tomorrow's balance card is null", () {
      final value = readTomorrow(containerWith());

      expect(value, isA<AsyncLoading<double?>>());
      expect(value.value, isNull);
    });

    test("is tomorrow's target of the budget card, carryover included", () {
      // A target that differs from a plain daily goal: the carryover moved it.
      final value = readTomorrow(containerWith(tomorrowCard: _loaded(1743)));

      expect(value, isA<AsyncData<double?>>());
      expect(value.value, 1743);
    });

    test('is data without a value on a pause day, not loading', () {
      final value = readTomorrow(
        containerWith(tomorrowCard: _loaded(1743, isPauseDay: true)),
      );

      expect(value, isA<AsyncData<double?>>());
      expect(value.value, isNull);
    });

    test('is data without a value while the notices are off, even while '
        'tomorrow loads', () {
      final value = readTomorrow(containerWith(noticesOn: false));

      expect(value, isA<AsyncData<double?>>());
      expect(value.value, isNull);
    });

    test('is data without a value while the pace marker is off, even while '
        'tomorrow loads', () {
      final value = readTomorrow(containerWith(markerOn: false));

      expect(value, isA<AsyncData<double?>>());
      expect(value.value, isNull);
    });
  });

  group('sync while tomorrow loads', () {
    test(
      'a pending tomorrow notice stays pending and is not planned again',
      () async {
        final notifications = FakeLocalNotifications();
        final container = containerWith(notifications: notifications);
        final controller = container.read(
          diaryPaceNotificationControllerProvider.notifier,
        );
        await controller.sync(pace(), texts, tomorrowTargetKcal: 2000);
        final planned = notifications.scheduled[_tomorrowId]!;
        expect(planned.at, DateTime(2026, 11, 13, 6));
        // A mark that a second planning would overwrite.
        notifications.scheduled[_tomorrowId] = (
          at: planned.at,
          title: 'marked',
          payload: planned.payload,
        );

        await controller.sync(pace(), texts, tomorrowLoading: true);

        expect(notifications.scheduled[_tomorrowId]!.title, 'marked');
      },
    );

    test(
      'plans no tomorrow notice while it loads and none is pending',
      () async {
        final notifications = FakeLocalNotifications();
        final container = containerWith(notifications: notifications);

        await container
            .read(diaryPaceNotificationControllerProvider.notifier)
            .sync(pace(), texts, tomorrowLoading: true);

        expect(notifications.scheduled.containsKey(_tomorrowId), isFalse);
      },
    );

    test('the loading flag still cancels the stale notices of today', () async {
      final notifications = FakeLocalNotifications();
      final container = containerWith(notifications: notifications);
      final controller = container.read(
        diaryPaceNotificationControllerProvider.notifier,
      );
      await controller.sync(pace(), texts, tomorrowTargetKcal: 2000);
      expect(notifications.scheduled.length, greaterThan(1));

      await controller.sync(null, texts, tomorrowLoading: true);

      expect(notifications.scheduled.keys, [_tomorrowId]);
    });

    test(
      'cancels the pending tomorrow notice when the notices are off',
      () async {
        final notifications = FakeLocalNotifications();
        final container = containerWith(
          notifications: notifications,
          noticesOn: false,
        );
        notifications.scheduled[_tomorrowId] = (
          at: DateTime(2026, 11, 13, 6),
          title: 'pending',
          payload: diaryPaceChannelId,
        );

        await container
            .read(diaryPaceNotificationControllerProvider.notifier)
            .sync(null, texts, tomorrowLoading: true);

        expect(notifications.scheduled, isEmpty);
      },
    );

    test(
      'cancels the pending tomorrow notice when the pace marker is off',
      () async {
        final notifications = FakeLocalNotifications();
        final container = containerWith(
          notifications: notifications,
          markerOn: false,
        );
        notifications.scheduled[_tomorrowId] = (
          at: DateTime(2026, 11, 13, 6),
          title: 'pending',
          payload: diaryPaceChannelId,
        );

        await container
            .read(diaryPaceNotificationControllerProvider.notifier)
            .sync(null, texts, tomorrowLoading: true);

        expect(notifications.scheduled, isEmpty);
      },
    );

    test('cancels the pending tomorrow notice for a pause day once it is '
        'known', () async {
      final notifications = FakeLocalNotifications();
      final container = containerWith(notifications: notifications);
      notifications.scheduled[_tomorrowId] = (
        at: DateTime(2026, 11, 13, 6),
        title: 'pending',
        payload: diaryPaceChannelId,
      );

      await container
          .read(diaryPaceNotificationControllerProvider.notifier)
          .sync(pace(), texts);

      expect(notifications.scheduled.containsKey(_tomorrowId), isFalse);
    });
  });

  group('debugShowSoon', () {
    Future<_RecordingNotifications> show(
      DiaryPaceDay day, {
      DateTime? at,
    }) async {
      final notifications = _RecordingNotifications();
      final clock = at ?? now;
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
          clockProvider.overrideWithValue(() => clock),
          localNotificationsProvider.overrideWithValue(notifications),
        ],
      );
      addTearDown(container.dispose);
      container.listen(diaryPaceNotificationControllerProvider, (_, _) {});
      await container
          .read(diaryPaceNotificationControllerProvider.notifier)
          .debugShowSoon(day, texts);
      return notifications;
    }

    test('shows in five seconds on its own id and channel, and asks for the '
        'permission', () async {
      final notifications = await show(pace());

      final notice = notifications.scheduled[_debugId]!;
      expect(notice.at, now.add(const Duration(seconds: 5)));
      expect(notice.payload, diaryPaceChannelId);
      expect(notifications.channelIds[_debugId], diaryPaceChannelId);
      expect(notifications.permissionRequests, 1);
      expect(notifications.scheduled.length, 1);
    });

    test('names what the marker stands ahead of the kcal eaten', () async {
      // 12:00 is in lunch's part: 60 % of 2000 are due.
      final nothingEaten = await show(pace());
      final someEaten = await show(pace(eaten: 500));

      expect(nothingEaten.scheduled[_debugId]!.title, 'free 1200');
      expect(someEaten.scheduled[_debugId]!.title, 'free 700');
    });

    test('rounds the kcal', () async {
      final notifications = await show(pace(target: 1999, eaten: 0.4));

      // 0.6 * 1999 - 0.4 = 1199.0
      expect(notifications.scheduled[_debugId]!.title, 'free 1199');
    });

    test('never goes below 0 kcal', () async {
      final notifications = await show(pace(eaten: 1500));

      expect(notifications.scheduled[_debugId]!.title, 'free 0');
    });

    test('is 0 kcal before the day starts', () async {
      final notifications = await show(pace(), at: DateTime(2026, 11, 12, 5));

      expect(notifications.scheduled[_debugId]!.title, 'free 0');
    });

    test('points at the macro only once something is eaten', () async {
      final eaten = await show(pace(eaten: 100, macro: DiaryPaceMacro.fat));
      final nothing = await show(pace(macro: DiaryPaceMacro.fat));

      expect(eaten.bodies[_debugId], 'fat');
      expect(nothing.bodies[_debugId], '');
    });
  });
}
