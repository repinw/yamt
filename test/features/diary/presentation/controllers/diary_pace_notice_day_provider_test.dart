import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_balance_loaded_metrics.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';
import 'package:yamt/features/diary/domain/diary_meal_times.dart';
import 'package:yamt/features/diary/domain/diary_pace_notices.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_card_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_notice_day_provider.dart';

import '../../../../helpers/auth_user_data_key_session.dart';
import '../../../../helpers/fake_local_notifications.dart';
import '../../../../helpers/memory_app_preferences.dart';
import '../../support/diary_dashboard_test_support.dart';

const _onKey = 'diary_pace_notification_on_v1';
const _markerKey = 'diary_pace_marker_v1';
final _today = DateTime(2026, 11, 12);

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
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerWith({
    DiaryBalanceCardData? card,
    bool markerOn = true,
    bool noticesOn = true,
    Map<String, String> strings = const {},
    UserDataKeySession Function()? session,
  }) {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(
          MemoryAppPreferences(
            initialInts: {if (markerOn) _markerKey: 1},
            initialStrings: {if (noticesOn) _onKey: 'set', ...strings},
          ),
        ),
        if (session == null)
          userDataCipherProvider.overrideWithValue(testUserDataCipher)
        else
          userDataKeySessionProvider.overrideWith(session),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 12, 12)),
        localNotificationsProvider.overrideWithValue(FakeLocalNotifications()),
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

  AsyncValue<DiaryPaceDay?> read(ProviderContainer container) {
    final subscription = container.listen(
      diaryPaceNoticeDayProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    return subscription.read();
  }

  group('diaryPaceNoticeDay', () {
    test('has no day while the notices are off', () {
      final value = read(containerWith(card: _loaded(), noticesOn: false));

      expect(value, isA<AsyncData<DiaryPaceDay?>>());
      expect(value.value, isNull);
    });

    test('has no day while the pace marker is off', () {
      final value = read(containerWith(card: _loaded(), markerOn: false));

      expect(value, isA<AsyncData<DiaryPaceDay?>>());
      expect(value.value, isNull);
    });

    test('has no day while the notices are off, even while today loads', () {
      final value = read(containerWith(noticesOn: false));

      expect(value, isA<AsyncData<DiaryPaceDay?>>());
      expect(value.value, isNull);
    });

    test('has no day when nobody is signed in', () async {
      final container = containerWith(
        card: _loaded(),
        session: SignedOutUserDataKeySession.new,
      );
      await container.read(userDataKeySessionProvider.future);

      final value = read(container);

      expect(value, isA<AsyncData<DiaryPaceDay?>>());
      expect(value.value, isNull);
    });

    test('is an error when the data key failed to load', () async {
      final container = containerWith(
        card: _loaded(),
        session: FailingUserDataKeySession.new,
      );
      await expectLater(
        container.read(userDataKeySessionProvider.future),
        throwsStateError,
      );

      final value = read(container);

      expect(value, isA<AsyncError<DiaryPaceDay?>>());
      expect(value.hasValue, isFalse);
    });

    test('is loading while the data key loads', () {
      final value = read(
        containerWith(card: _loaded(), session: LoadingUserDataKeySession.new),
      );

      expect(value, isA<AsyncLoading<DiaryPaceDay?>>());
    });

    test('is loading while the balance card of today is null', () {
      final value = read(containerWith());

      expect(value, isA<AsyncLoading<DiaryPaceDay?>>());
      expect(value.hasValue, isFalse);
    });

    test('is data without a day on a pause day, not loading', () {
      final value = read(containerWith(card: _loaded(isPauseDay: true)));

      expect(value, isA<AsyncData<DiaryPaceDay?>>());
      expect(value.value, isNull);
    });

    test("is data with the day's target, eaten kcal, times and shares", () {
      final value = read(
        containerWith(
          card: _loaded(eaten: 250),
          strings: {'diary_meal_shares_v1': '30,30,30,10'},
        ),
      );

      expect(value, isA<AsyncData<DiaryPaceDay?>>());
      final day = value.value!;
      expect(day.day, _today);
      expect(day.targetKcal, 1588);
      expect(day.eatenKcal, 250);
      expect(day.times, DiaryMealTimes.standard);
      expect(day.shares, const DiaryMealShares([30, 30, 30, 10]));
      // The dashboard has no nutrition data yet.
      expect(day.macro, isNull);
    });

    test('falls back to the daily numbers of a practice day', () {
      final value = read(
        containerWith(
          card: DiaryBalanceCardData.practiceDay(practiceDay: _notCounting()),
        ),
      );

      expect(value.value!.targetKcal, 1588);
      expect(value.value!.eatenKcal, 100);
    });

    test('falls back to the daily numbers before a scheduled restart', () {
      final value = read(
        containerWith(
          card: DiaryBalanceCardData.scheduledRestart(
            scheduledRestart: _notCounting(),
          ),
        ),
      );

      expect(value.value!.targetKcal, 1588);
      expect(value.value!.eatenKcal, 100);
    });
  });
}
