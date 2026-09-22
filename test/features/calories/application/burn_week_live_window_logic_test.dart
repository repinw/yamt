import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/'
    'burn_week_live_window_logic.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';

void main() {
  group('burn_week_live_window_logic', () {
    test('isBeforeBurnWeekDay compares diary days normalized', () {
      expect(
        isBeforeBurnWeekDay(
          DateTime(2026, 4, 20, 23, 59),
          DateTime(2026, 4, 21, 0, 1),
        ),
        isTrue,
      );
      expect(
        isBeforeBurnWeekDay(
          DateTime(2026, 4, 21, 1),
          DateTime(2026, 4, 21, 23),
        ),
        isFalse,
      );
    });

    test('tryParseBurnWeekDayKey parses valid day key or returns null', () {
      expect(tryParseBurnWeekDayKey('2026-04-20'), DateTime(2026, 4, 20));
      expect(tryParseBurnWeekDayKey('2026-4-8'), DateTime(2026, 4, 8));
      expect(tryParseBurnWeekDayKey(null), isNull);
      expect(tryParseBurnWeekDayKey(''), isNull);
      expect(tryParseBurnWeekDayKey('invalid-key'), isNull);
      expect(tryParseBurnWeekDayKey('2026-04'), isNull);
    });

    test('live week start ignores a stored future anchor', () {
      final currentWeekStartDate = resolveBurnWeekLiveWeekStartDate(
        currentDay: DateTime(2026, 4, 21, 12),
        balanceStartDate: DateTime(2026, 4, 21),
        storedWeekStartDayKey: '2026-4-22',
      );

      expect(currentWeekStartDate, DateTime(2026, 4, 21));
    });

    test('live week start ignores a stored anchor before the active cycle', () {
      final currentWeekStartDate = resolveBurnWeekLiveWeekStartDate(
        currentDay: DateTime(2026, 4, 21, 12),
        balanceStartDate: DateTime(2026, 4, 21),
        storedWeekStartDayKey: '2026-4-14',
      );

      expect(currentWeekStartDate, DateTime(2026, 4, 21));
    });

    test('live week start ignores an expired stored anchor', () {
      final currentWeekStartDate = resolveBurnWeekLiveWeekStartDate(
        currentDay: DateTime(2026, 4, 15, 12),
        balanceStartDate: DateTime(2026, 4, 8),
        storedWeekStartDayKey: '2026-4-8',
      );

      expect(currentWeekStartDate, DateTime(2026, 4, 15));
    });

    test(
      'live week start keeps a valid stored anchor within cycle and week',
      () {
        final currentWeekStartDate = resolveBurnWeekLiveWeekStartDate(
          currentDay: DateTime(2026, 4, 12, 12),
          balanceStartDate: DateTime(2026, 4, 8),
          storedWeekStartDayKey: '2026-4-8',
        );

        expect(currentWeekStartDate, DateTime(2026, 4, 8));
      },
    );

    test('sync week start date advances in 7-day increments', () {
      final syncStart = resolveBurnWeekLiveSyncWeekStartDate(
        currentDay: DateTime(2026, 4, 23),
        currentWeekStartDate: DateTime(2026, 4, 8),
      );

      expect(syncStart, DateTime(2026, 4, 22));
    });

    test('elapsed days calculates difference clamped to non-negative', () {
      expect(
        resolveBurnWeekLiveElapsedDays(
          currentDay: DateTime(2026, 4, 21),
          balanceStartDate: DateTime(2026, 4, 14),
        ),
        7,
      );
      expect(
        resolveBurnWeekLiveElapsedDays(
          currentDay: DateTime(2026, 4, 14),
          balanceStartDate: DateTime(2026, 4, 21),
        ),
        0,
      );
    });

    test('missed tracking detects untracked past days in current week', () {
      final weekOverview = CalorieWeekOverview(
        days: <CalorieWeekDayOverview>[
          CalorieWeekDayOverview(
            date: DateTime(2026, 4, 20),
            totalKcal: 0,
            goalKcal: 2000,
            entryCount: 0,
          ),
          CalorieWeekDayOverview(
            date: DateTime(2026, 4, 21),
            totalKcal: 0,
            goalKcal: 2000,
            entryCount: 0,
          ),
        ],
        totalConsumedKcal: 0,
        totalGoalKcal: 4000,
        remainingKcal: 4000,
        balanceStartDate: DateTime(2026, 4, 20),
        carryoverBeforeTodayKcal: 0,
        todayFlexibleGoalKcal: 2000,
        goalStartsInFuture: false,
        nextGoalStartDate: null,
        futureGoalKcal: null,
      );

      final hasMissed = resolveBurnWeekLiveMissedTrackingThisWeek(
        weekOverview: weekOverview,
        currentWeekStartDate: DateTime(2026, 4, 20),
        today: DateTime(2026, 4, 21),
        settings: const CalorieGoalSettings.empty(),
      );

      expect(hasMissed, isTrue);
    });

    test('isInitialBurnWeekRunState detects initial state', () {
      expect(
        isInitialBurnWeekRunState(const BurnWeekRunState.initial()),
        isTrue,
      );
      expect(
        isInitialBurnWeekRunState(
          const BurnWeekRunState(
            currentWeekStartDayKey: '2026-04-20',
            lastActiveDayKey: '2026-04-20',
            runWeekNumber: 1,
            starCount: 0,
            heartCount: 3,
            heartCreditKcal: 0,
            starBrokeThisWeek: false,
            missedTrackingThisWeek: false,
          ),
        ),
        isFalse,
      );
    });

    test('isFreshBurnWeekRunState verifies fresh learning run metrics', () {
      expect(isFreshBurnWeekRunState(const BurnWeekRunState.initial()), isTrue);
      expect(
        isFreshBurnWeekRunState(
          const BurnWeekRunState.initial().copyWith(starCount: 1),
        ),
        isFalse,
      );
      expect(
        isFreshBurnWeekRunState(
          const BurnWeekRunState.initial().copyWith(starBrokeThisWeek: true),
        ),
        isFalse,
      );
    });

    test('isScheduledFutureFreshBurnWeekRun checks future scheduled start', () {
      expect(
        isScheduledFutureFreshBurnWeekRun(
          runState: const BurnWeekRunState.initial(),
          storedWeekStartDate: DateTime(2026, 5, 10),
          expectedWeekStartDate: DateTime(2026, 5, 10),
        ),
        isTrue,
      );
      expect(
        isScheduledFutureFreshBurnWeekRun(
          runState: const BurnWeekRunState.initial(),
          storedWeekStartDate: DateTime(2026, 5, 10),
          expectedWeekStartDate: DateTime(2026, 5, 11),
        ),
        isFalse,
      );
      expect(
        isScheduledFutureFreshBurnWeekRun(
          runState: const BurnWeekRunState.initial(),
          storedWeekStartDate: null,
          expectedWeekStartDate: DateTime(2026, 5, 10),
        ),
        isFalse,
      );
    });

    test('resolveBurnWeekClosedWeekStartDates builds 7-day increments', () {
      final closedWeeks = resolveBurnWeekClosedWeekStartDates(
        runState: const BurnWeekRunState(
          currentWeekStartDayKey: '2026-04-06',
          lastActiveDayKey: '2026-04-06',
          runWeekNumber: 2,
          starCount: 1,
          heartCount: 3,
          heartCreditKcal: 0,
          starBrokeThisWeek: false,
          missedTrackingThisWeek: false,
        ),
        storedWeekStartDate: DateTime(2026, 4, 6),
        balanceStartDate: DateTime(2026, 4, 6),
        today: DateTime(2026, 4, 20),
        syncWeekStartDate: DateTime(2026, 4, 20),
      );

      expect(closedWeeks, <DateTime>[
        DateTime(2026, 4, 6),
        DateTime(2026, 4, 13),
      ]);
    });
  });
}
