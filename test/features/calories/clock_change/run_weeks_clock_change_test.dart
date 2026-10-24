// These tests check the autumn clock change on 2026-10-25. CI runs them once
// more with TZ=Europe/Berlin; in UTC they pass without a clock change.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/app_version_config_repository.dart';
import 'package:yamt/core/domain/app_update_status.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/application/burn_week_live_window_logic.dart';
import 'package:yamt/features/calories/application/burn_week_run_controller.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_provider.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

class _MemoryRunStateRepository implements BurnWeekRunStateRepository {
  new(this.state);

  BurnWeekRunState state;

  @override
  Future<BurnWeekRunState> readState() async => state;

  @override
  Future<bool> saveState(BurnWeekRunState next) async {
    state = next;
    return true;
  }
}

class _FakeGoalController extends CalorieGoalController {
  new(this.settings);

  final CalorieGoalSettings settings;

  @override
  FutureOr<CalorieGoalSettings> build() => settings;
}

/// True where the clock changes between 2026-10-05 and 2026-10-26.
final _hasClockChange =
    DateTime(2026, 10, 5).timeZoneOffset !=
    DateTime(2026, 10, 26).timeZoneOffset;
const _needsClockChange = 'needs a time zone with a clock change, as on CI';

/// Runs the live sync on 2026-10-27 over a week start that 3.8.1 stored a
/// day early, and returns the stored run.
Future<BurnWeekRunState> _syncEarlyWeekStart(AppUpdateStatus status) async {
  final today = DateTime(2026, 10, 27);
  final balanceStart = DateTime(2026, 10, 5);
  final repository = _MemoryRunStateRepository(
    const BurnWeekRunState(
      currentWeekStartDayKey: '2026-10-25',
      lastActiveDayKey: '2026-10-26',
      runWeekNumber: 4,
      starCount: 3,
      starBrokeThisWeek: false,
      missedTrackingThisWeek: false,
    ),
  );
  final days = [
    for (var offset = -6; offset <= 0; offset++)
      CalorieWeekDayOverview(
        date: addDiaryDays(today, offset),
        totalKcal: 1000,
        goalKcal: 2000,
        entryCount: 1,
      ),
  ];
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(
        () => today.add(const Duration(hours: 9)),
      ),
      appUpdateStatusProvider.overrideWith((ref) => Stream.value(status)),
      burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
      burnWeekRunStateRepositoryProvider.overrideWithValue(repository),
      calorieGoalControllerProvider.overrideWith(
        () => _FakeGoalController(
          CalorieGoalSettings.single(
            dailyKcalGoal: 2000,
            calculatorProfile: null,
            effectiveDate: balanceStart,
          ),
        ),
      ),
      calorieWeekOverviewForWindowProvider(today).overrideWith(
        (ref) => CalorieWeekOverview(
          days: days,
          totalConsumedKcal: 7000,
          totalGoalKcal: 14000,
          remainingKcal: 0,
          balanceStartDate: balanceStart,
          carryoverBeforeTodayKcal: 0,
          todayFlexibleGoalKcal: 2000,
          goalStartsInFuture: false,
          nextGoalStartDate: null,
          futureGoalKcal: null,
          isPreviousDayClosed: false,
        ),
      ),
      calorieWeekDayOverviewForDateProvider(today)
          .overrideWith((ref) => days.last),
    ],
  );
  addTearDown(container.dispose);
  await container.read(calorieGoalControllerProvider.future);
  await container.read(burnWeekRunControllerProvider.future);
  final sync = container.listen<Object?>(burnWeekLiveSyncProvider, (_, _) {});
  addTearDown(sync.close);
  await pumpEventQueue();
  return repository.state;
}

void main() {
  final settings = CalorieGoalSettings.single(
    dailyKcalGoal: 2000,
    calculatorProfile: null,
    effectiveDate: DateTime(2026, 10, 6),
  );

  test('a run that spans the clock change starts at midnight of its day', () {
    final day = DateTime(2026, 10, 26);

    expect(
      resolveCalorieGoalRunStartDate(settings: settings, day: day),
      DateTime(2026, 10, 20),
    );
    expect(resolveCalorieGoalRunNumber(settings: settings, day: day), 3);
    expect(resolveRemainingCalorieGoalRunDays(settings: settings, day: day), 1);
  });

  test('the Burn Week moves on by calendar days across the clock change', () {
    expect(
      resolveBurnWeekLiveSyncWeekStartDate(
        currentDay: DateTime(2026, 10, 26),
        currentWeekStartDate: DateTime(2026, 10, 19),
      ),
      DateTime(2026, 10, 26),
    );
    expect(
      resolveBurnWeekClosedWeekStartDates(
        runState: const BurnWeekRunState(
          currentWeekStartDayKey: '2026-10-19',
          lastActiveDayKey: '2026-10-25',
          runWeekNumber: 3,
          starCount: 2,
          starBrokeThisWeek: false,
          missedTrackingThisWeek: false,
        ),
        storedWeekStartDate: DateTime(2026, 10, 19),
        balanceStartDate: DateTime(2026, 10, 5),
        today: DateTime(2026, 11, 2),
        syncWeekStartDate: DateTime(2026, 11, 2),
      ),
      [DateTime(2026, 10, 19), DateTime(2026, 10, 26)],
    );
  });

  test('a week start stored one or two days early moves onto the grid', () {
    final balanceStart = DateTime(2026, 10, 5);
    DateTime align(DateTime stored) => alignBurnWeekStartDate(
      storedWeekStartDate: stored,
      balanceStartDate: balanceStart,
    );

    expect(align(DateTime(2026, 10, 25)), DateTime(2026, 10, 26));
    expect(align(DateTime(2026, 10, 31)), DateTime(2026, 11, 2));
    expect(align(DateTime(2026, 10, 26)), DateTime(2026, 10, 26));
    // A cycle from winter time passes the spring change too.
    expect(
      alignBurnWeekStartDate(
        storedWeekStartDate: DateTime(2026, 10, 25),
        balanceStartDate: DateTime(2026, 1, 5),
      ),
      DateTime(2026, 10, 26),
    );
    // A start before the cycle stays, so the sync restarts the run.
    expect(align(DateTime(2026, 10, 4)), DateTime(2026, 10, 4));
  }, skip: _hasClockChange ? false : _needsClockChange);

  test('an off-grid week start without a clock change stays', () {
    expect(
      alignBurnWeekStartDate(
        storedWeekStartDate: DateTime(2026, 11, 15),
        balanceStartDate: DateTime(2026, 11, 2),
      ),
      DateTime(2026, 11, 15),
    );
  });

  test(
    'the live sync moves an early week start without closing a week',
    () async {
      final state = await _syncEarlyWeekStart(const AppUpToDate());

      expect(state.currentWeekStartDayKey, '2026-10-26');
      expect(state.runWeekNumber, 4);
      expect(state.starCount, 3);
    },
    skip: _hasClockChange ? false : _needsClockChange,
  );

  test(
    'the live sync leaves the run alone while the app is below the minimum',
    () async {
      final state = await _syncEarlyWeekStart(const AppUpdateRequired());

      expect(state.currentWeekStartDayKey, '2026-10-25');
      expect(state.runWeekNumber, 4);
      expect(state.starCount, 3);
    },
    skip: _hasClockChange ? false : _needsClockChange,
  );

  test('moveWeekStartTo changes only the week start', () async {
    final repository = _MemoryRunStateRepository(
      const BurnWeekRunState(
        currentWeekStartDayKey: '2026-10-25',
        lastActiveDayKey: '2026-10-26',
        runWeekNumber: 4,
        starCount: 3,
        starBrokeThisWeek: true,
        missedTrackingThisWeek: true,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        burnWeekRunStateRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(burnWeekRunControllerProvider.future);

    final moved = await container
        .read(burnWeekRunControllerProvider.notifier)
        .moveWeekStartTo(DateTime(2026, 10, 26));

    expect(moved, isTrue);
    final state = repository.state;
    expect(state.currentWeekStartDayKey, '2026-10-26');
    expect(state.lastActiveDayKey, '2026-10-26');
    expect(state.runWeekNumber, 4);
    expect(state.starCount, 3);
    expect(state.starBrokeThisWeek, isTrue);
    expect(state.missedTrackingThisWeek, isTrue);
  });

  test('closing the week before the clock change starts the next on '
      'Monday and counts it once', () async {
    final repository = _MemoryRunStateRepository(
      const BurnWeekRunState(
        currentWeekStartDayKey: '2026-10-19',
        lastActiveDayKey: '2026-10-25',
        runWeekNumber: 3,
        starCount: 2,
        starBrokeThisWeek: false,
        missedTrackingThisWeek: false,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        burnWeekRunStateRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(burnWeekRunControllerProvider.future);

    await container
        .read(burnWeekRunControllerProvider.notifier)
        .syncForWeek(
          currentDay: DateTime(2026, 10, 26),
          weekStartDate: DateTime(2026, 10, 26),
          missedTrackingThisWeek: false,
          missedTrackingForClosedWeeks: const [false],
        );

    expect(repository.state.currentWeekStartDayKey, '2026-10-26');
    expect(repository.state.runWeekNumber, 4);
    expect(repository.state.starCount, 3);
  });
}
