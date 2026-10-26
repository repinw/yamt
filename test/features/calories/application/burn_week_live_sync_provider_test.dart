import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/application/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/application/burn_week_run_controller.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/calorie_week_consumption_snapshot_provider.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_provider.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';

class _FakeCalorieGoalController extends CalorieGoalController {
  new(this.settings);

  final CalorieGoalSettings settings;

  @override
  FutureOr<CalorieGoalSettings> build() {
    return settings;
  }
}

class _RecordingBurnWeekRunController extends BurnWeekRunController {
  new(
    this.initialState, {
    this.syncBlocker,
    this.restartBlocker,
    this.resetBlocker,
  });

  final BurnWeekRunState initialState;
  final Completer<void>? syncBlocker;
  final Completer<void>? restartBlocker;
  final Completer<void>? resetBlocker;
  final List<_SyncCall> syncCalls = <_SyncCall>[];
  final List<DateTime> restartCalls = <DateTime>[];
  final List<int?> restartRunWeekNumbers = <int?>[];
  int _resetCallCount = 0;

  int resetCallCount() => _resetCallCount;

  @override
  Future<BurnWeekRunState> build() async {
    return initialState;
  }

  @override
  Future<bool> restartRunFrom({
    required DateTime weekStartDate,
    int? runWeekNumber,
  }) async {
    restartCalls.add(normalizeLocalDay(weekStartDate));
    restartRunWeekNumbers.add(runWeekNumber);
    await restartBlocker?.future;
    return true;
  }

  @override
  Future<void> resetRun() async {
    _resetCallCount += 1;
    await resetBlocker?.future;
  }

  @override
  Future<void> syncForWeek({
    required DateTime currentDay,
    required DateTime weekStartDate,
    required bool missedTrackingThisWeek,
    List<bool>? missedTrackingForClosedWeeks,
  }) async {
    syncCalls.add(
      _SyncCall(
        currentDay: normalizeLocalDay(currentDay),
        weekStartDate: normalizeLocalDay(weekStartDate),
        missedTrackingThisWeek: missedTrackingThisWeek,
        missedTrackingForClosedWeeks: missedTrackingForClosedWeeks == null
            ? null
            : List<bool>.from(missedTrackingForClosedWeeks),
      ),
    );
    await syncBlocker?.future;
  }
}

class _SyncCall {
  const new({
    required this.currentDay,
    required this.weekStartDate,
    required this.missedTrackingThisWeek,
    required this.missedTrackingForClosedWeeks,
  });

  final DateTime currentDay;
  final DateTime weekStartDate;
  final bool missedTrackingThisWeek;
  final List<bool>? missedTrackingForClosedWeeks;
}

ProviderContainer _buildContainer({
  required DateTime today,
  required CalorieWeekOverview weekOverview,
  required CalorieWeekDayOverview todayOverview,
  required CalorieGoalSettings settings,
  required BurnWeekRunState initialRunState,
  required void Function(_RecordingBurnWeekRunController controller)
  captureController,
  Map<DateTime, CalorieWeekConsumptionSnapshot> snapshotsByWindowEnd =
      const <DateTime, CalorieWeekConsumptionSnapshot>{},
  _RecordingBurnWeekRunController Function(BurnWeekRunState initialState)?
  controllerFactory,
}) {
  return ProviderContainer(
    overrides: [
      burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
      calorieWeekOverviewForWindowProvider(today)
          .overrideWith((ref) => weekOverview),
      calorieWeekDayOverviewForDateProvider(today)
          .overrideWith((ref) => todayOverview),
      for (final entry in snapshotsByWindowEnd.entries)
        calorieWeekConsumptionSnapshotForWindowProvider(entry.key)
            .overrideWith((ref) => entry.value),
      calorieGoalControllerProvider.overrideWith(
        () => _FakeCalorieGoalController(settings),
      ),
      burnWeekRunControllerProvider.overrideWith(() {
        final controller =
            controllerFactory?.call(initialRunState) ??
            _RecordingBurnWeekRunController(initialRunState);
        captureController(controller);
        return controller;
      }),
    ],
  );
}

CalorieWeekOverview _weekOverview({
  required DateTime today,
  required DateTime balanceStartDate,
  bool goalStartsInFuture = false,
  DateTime? nextGoalStartDate,
  double? futureGoalKcal,
  Set<DateTime> missingDays = const <DateTime>{},
}) {
  final normalizedToday = normalizeLocalDay(today);
  final days = [
    for (var offset = 6; offset >= 0; offset -= 1)
      CalorieWeekDayOverview(
        date: addLocalDays(normalizedToday, -offset),
        totalKcal: missingDays.contains(addLocalDays(normalizedToday, -offset))
            ? 0
            : 1000,
        goalKcal: 2000,
        entryCount: missingDays.contains(addLocalDays(normalizedToday, -offset))
            ? 0
            : 1,
      ),
  ];
  return CalorieWeekOverview(
    isPreviousDayClosed: false,
    days: days,
    totalConsumedKcal: days.fold<double>(0, (sum, day) => sum + day.totalKcal),
    totalGoalKcal: 2000 * 7,
    remainingKcal: 0,
    balanceStartDate: normalizeLocalDay(balanceStartDate),
    carryoverBeforeTodayKcal: 0,
    todayFlexibleGoalKcal: 2000,
    goalStartsInFuture: goalStartsInFuture,
    nextGoalStartDate: nextGoalStartDate,
    futureGoalKcal: futureGoalKcal,
  );
}

CalorieWeekConsumptionSnapshot _snapshotForWeek({
  required DateTime weekStartDate,
  Set<DateTime> missingDays = const <DateTime>{},
}) {
  final normalizedWeekStartDate = normalizeLocalDay(weekStartDate);
  final days = [
    for (var offset = 0; offset < 7; offset += 1)
      CalorieWeekConsumptionDaySnapshot(
        date: addLocalDays(normalizedWeekStartDate, offset),
        totalKcal:
            missingDays.contains(addLocalDays(normalizedWeekStartDate, offset))
            ? 0
            : 1000,
        entryCount:
            missingDays.contains(addLocalDays(normalizedWeekStartDate, offset))
            ? 0
            : 1,
      ),
  ];
  return CalorieWeekConsumptionSnapshot(
    days: days,
    totalConsumedKcal: days.fold<double>(0, (sum, day) => sum + day.totalKcal),
  );
}

Future<void> _activateSync(ProviderContainer container) async {
  await container.read(calorieGoalControllerProvider.future);
  await container.read(burnWeekRunControllerProvider.future);
  final subscription = container.listen<Object?>(
    burnWeekLiveSyncProvider,
    (_, _) {},
  );
  addTearDown(subscription.close);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Future<void> _primeSyncContainer(ProviderContainer container) async {
  await container.read(calorieGoalControllerProvider.future);
  await container.read(burnWeekRunControllerProvider.future);
}

void _queueLiveSyncRefresh(ProviderContainer container) {
  container
    ..invalidate(burnWeekLiveSyncProvider)
    ..read(burnWeekLiveSyncProvider)
    ..invalidate(burnWeekLiveSyncProvider)
    ..read(burnWeekLiveSyncProvider);
}

CalorieWeekDayOverview _defaultTodayOverview(
  DateTime today, {
  double totalKcal = 1000,
  double goalKcal = 2000,
  int entryCount = 1,
}) {
  return CalorieWeekDayOverview(
    date: today,
    totalKcal: totalKcal,
    goalKcal: goalKcal,
    entryCount: entryCount,
  );
}

CalorieGoalSettings _activeGoalSettings(DateTime effectiveDate) {
  return CalorieGoalSettings.single(
    dailyKcalGoal: 2000,
    calculatorProfile: null,
    effectiveDate: effectiveDate,
  );
}

CalorieGoalSettings _learnedGoalSettings(DateTime effectiveDate) {
  return CalorieGoalSettings.single(
    dailyKcalGoal: 2000,
    calculatorProfile: null,
    effectiveDate: effectiveDate,
    source: CalorieGoalSource.calculator,
    weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: addLocalDays(effectiveDate, -7),
      windowEndDate: addLocalDays(effectiveDate, -1),
      trendWeightChangePerDay: -0.05,
      calculatedTdeeKcal: 2300,
      lowConfidence: false,
    ),
  );
}

void main() {
  group('burnWeekLiveSyncProvider', () {
    test('does nothing when the run state is already synchronized', () async {
      final today = normalizeLocalDay(DateTime.now());
      late _RecordingBurnWeekRunController controller;
      final container = _buildContainer(
        today: today,
        weekOverview: _weekOverview(
          today: today,
          balanceStartDate: addLocalDays(today, -6),
        ),
        todayOverview: _defaultTodayOverview(today),
        settings: _activeGoalSettings(addLocalDays(today, -6)),
        initialRunState: BurnWeekRunState(
          currentWeekStartDayKey: localDayKey(addLocalDays(today, -6)),
          lastActiveDayKey: localDayKey(today),
          runWeekNumber: 1,
          starCount: 0,
          starBrokeThisWeek: false,
          missedTrackingThisWeek: false,
        ),
        captureController: (value) => controller = value,
      );
      addTearDown(container.dispose);

      await _activateSync(container);

      expect(controller.syncCalls, isEmpty);
      expect(controller.restartCalls, isEmpty);
    });

    test('returns early when stored week start is in the future', () async {
      final today = normalizeLocalDay(DateTime.now());
      final tomorrow = nextLocalDay(today);
      late _RecordingBurnWeekRunController controller;
      final container = _buildContainer(
        today: today,
        weekOverview: _weekOverview(
          today: today,
          balanceStartDate: addLocalDays(today, -6),
        ),
        todayOverview: _defaultTodayOverview(today),
        settings: _activeGoalSettings(addLocalDays(today, -6)),
        initialRunState: BurnWeekRunState(
          currentWeekStartDayKey: localDayKey(tomorrow),
          lastActiveDayKey: localDayKey(today),
          runWeekNumber: 1,
          starCount: 0,
          starBrokeThisWeek: false,
          missedTrackingThisWeek: false,
        ),
        captureController: (value) => controller = value,
      );
      addTearDown(container.dispose);

      await _activateSync(container);

      expect(controller.syncCalls, isEmpty);
      expect(controller.restartCalls, isEmpty);
    });

    test('catches up closed weeks when no run start is stored', () async {
      final today = normalizeLocalDay(DateTime.now());
      final cycleStart = addLocalDays(today, -18);
      final currentWeekStart = addLocalDays(today, -4);
      late _RecordingBurnWeekRunController controller;
      final container = _buildContainer(
        today: today,
        weekOverview: _weekOverview(today: today, balanceStartDate: cycleStart),
        todayOverview: _defaultTodayOverview(today),
        settings: _activeGoalSettings(cycleStart),
        initialRunState: const BurnWeekRunState.initial(),
        snapshotsByWindowEnd: <DateTime, CalorieWeekConsumptionSnapshot>{
          addLocalDays(cycleStart, 6): _snapshotForWeek(
            weekStartDate: cycleStart,
          ),
          addLocalDays(cycleStart, 13): _snapshotForWeek(
            weekStartDate: addLocalDays(cycleStart, 7),
          ),
        },
        captureController: (value) => controller = value,
      );
      addTearDown(container.dispose);

      await _activateSync(container);

      expect(controller.restartCalls, isEmpty);
      expect(controller.syncCalls, hasLength(1));
      expect(controller.syncCalls.single.weekStartDate, currentWeekStart);
      expect(controller.syncCalls.single.missedTrackingForClosedWeeks, <bool>[
        false,
        false,
      ]);
    });

    test(
      'repairs fresh current-week state that skipped backfilled weeks',
      () async {
        final today = normalizeLocalDay(DateTime.now());
        final cycleStart = addLocalDays(today, -18);
        final currentWeekStart = addLocalDays(today, -4);
        late _RecordingBurnWeekRunController controller;
        final container = _buildContainer(
          today: today,
          weekOverview: _weekOverview(
            today: today,
            balanceStartDate: cycleStart,
          ),
          todayOverview: _defaultTodayOverview(today),
          settings: _activeGoalSettings(cycleStart),
          initialRunState: BurnWeekRunState(
            currentWeekStartDayKey: localDayKey(currentWeekStart),
            lastActiveDayKey: localDayKey(today),
            runWeekNumber: 1,
            starCount: 0,
            starBrokeThisWeek: false,
            missedTrackingThisWeek: false,
          ),
          snapshotsByWindowEnd: <DateTime, CalorieWeekConsumptionSnapshot>{
            addLocalDays(cycleStart, 6): _snapshotForWeek(
              weekStartDate: cycleStart,
            ),
            addLocalDays(cycleStart, 13): _snapshotForWeek(
              weekStartDate: addLocalDays(cycleStart, 7),
            ),
          },
          captureController: (value) => controller = value,
        );
        addTearDown(container.dispose);

        await _activateSync(container);

        expect(controller.restartCalls, isEmpty);
        expect(controller.syncCalls, hasLength(1));
        expect(controller.syncCalls.single.weekStartDate, currentWeekStart);
        expect(controller.syncCalls.single.missedTrackingForClosedWeeks, <bool>[
          false,
          false,
        ]);
      },
    );

    test('does nothing while the goal starts in the future', () async {
      final today = normalizeLocalDay(DateTime.now());
      final tomorrow = nextLocalDay(today);
      late _RecordingBurnWeekRunController controller;
      final container = _buildContainer(
        today: today,
        weekOverview: _weekOverview(
          today: today,
          balanceStartDate: tomorrow,
          goalStartsInFuture: true,
          nextGoalStartDate: tomorrow,
        ),
        todayOverview: _defaultTodayOverview(
          today,
          totalKcal: 0,
          goalKcal: 0,
          entryCount: 0,
        ),
        settings: _activeGoalSettings(tomorrow),
        initialRunState: const BurnWeekRunState.initial(),
        captureController: (value) => controller = value,
      );
      addTearDown(container.dispose);

      await _activateSync(container);

      expect(controller.syncCalls, isEmpty);
      expect(controller.restartCalls, isEmpty);
      expect(controller.resetCallCount(), 0);
    });

    test(
      'keeps scheduled fresh week while the goal starts in the future',
      () async {
        final today = normalizeLocalDay(DateTime.now());
        final tomorrow = nextLocalDay(today);
        late _RecordingBurnWeekRunController controller;
        final container = _buildContainer(
          today: today,
          weekOverview: _weekOverview(
            today: today,
            balanceStartDate: tomorrow,
            goalStartsInFuture: true,
            nextGoalStartDate: tomorrow,
          ),
          todayOverview: _defaultTodayOverview(
            today,
            totalKcal: 0,
            goalKcal: 0,
            entryCount: 0,
          ),
          settings: _learnedGoalSettings(tomorrow),
          initialRunState: BurnWeekRunState(
            currentWeekStartDayKey: localDayKey(tomorrow),
            runWeekNumber: burnWeekLearningRunWeekNumber,
            starCount: 0,
            starBrokeThisWeek: false,
            missedTrackingThisWeek: false,
          ),
          captureController: (value) => controller = value,
        );
        addTearDown(container.dispose);

        await _activateSync(container);

        expect(controller.syncCalls, isEmpty);
        expect(controller.restartCalls, isEmpty);
        expect(controller.resetCallCount(), 0);
      },
    );

    test('schedules learned future goal start as first run week', () async {
      final today = normalizeLocalDay(DateTime.now());
      final tomorrow = nextLocalDay(today);
      late _RecordingBurnWeekRunController controller;
      final container = _buildContainer(
        today: today,
        weekOverview: _weekOverview(
          today: today,
          balanceStartDate: tomorrow,
          goalStartsInFuture: true,
          nextGoalStartDate: tomorrow,
        ),
        todayOverview: _defaultTodayOverview(
          today,
          totalKcal: 0,
          goalKcal: 0,
          entryCount: 0,
        ),
        settings: _learnedGoalSettings(tomorrow),
        initialRunState: BurnWeekRunState(
          currentWeekStartDayKey: localDayKey(addLocalDays(today, -6)),
          lastActiveDayKey: localDayKey(today),
          runWeekNumber: 3,
          starCount: 2,
          starBrokeThisWeek: true,
          missedTrackingThisWeek: true,
        ),
        captureController: (value) => controller = value,
      );
      addTearDown(container.dispose);

      await _activateSync(container);

      expect(controller.syncCalls, isEmpty);
      expect(controller.restartCalls, <DateTime>[tomorrow]);
      expect(controller.restartRunWeekNumbers, <int?>[
        burnWeekLearningRunWeekNumber,
      ]);
      expect(controller.resetCallCount(), 0);
    });

    test('reschedules stale learned future goal start', () async {
      final today = normalizeLocalDay(DateTime.now());
      final tomorrow = nextLocalDay(today);
      final staleStart = addLocalDays(tomorrow, 2);
      late _RecordingBurnWeekRunController controller;
      final container = _buildContainer(
        today: today,
        weekOverview: _weekOverview(
          today: today,
          balanceStartDate: tomorrow,
          goalStartsInFuture: true,
          nextGoalStartDate: tomorrow,
        ),
        todayOverview: _defaultTodayOverview(
          today,
          totalKcal: 0,
          goalKcal: 0,
          entryCount: 0,
        ),
        settings: _learnedGoalSettings(tomorrow),
        initialRunState: BurnWeekRunState(
          currentWeekStartDayKey: localDayKey(staleStart),
          runWeekNumber: burnWeekLearningRunWeekNumber,
          starCount: 0,
          starBrokeThisWeek: false,
          missedTrackingThisWeek: false,
        ),
        captureController: (value) => controller = value,
      );
      addTearDown(container.dispose);

      await _activateSync(container);

      expect(controller.syncCalls, isEmpty);
      expect(controller.restartCalls, <DateTime>[tomorrow]);
      expect(controller.restartRunWeekNumbers, <int?>[
        burnWeekLearningRunWeekNumber,
      ]);
      expect(controller.resetCallCount(), 0);
    });

    test(
      'restarts when stored week start is outside the active cycle',
      () async {
        final today = normalizeLocalDay(DateTime.now());
        late _RecordingBurnWeekRunController controller;
        final container = _buildContainer(
          today: today,
          weekOverview: _weekOverview(today: today, balanceStartDate: today),
          todayOverview: _defaultTodayOverview(today),
          settings: _activeGoalSettings(today),
          initialRunState: BurnWeekRunState(
            currentWeekStartDayKey: localDayKey(addLocalDays(today, -8)),
            lastActiveDayKey: localDayKey(today),
            runWeekNumber: 2,
            starCount: 1,
            starBrokeThisWeek: false,
            missedTrackingThisWeek: false,
          ),
          captureController: (value) => controller = value,
        );
        addTearDown(container.dispose);

        await _activateSync(container);

        expect(controller.syncCalls, isEmpty);
        expect(controller.restartCalls, <DateTime>[today]);
        expect(controller.restartRunWeekNumbers, <int?>[
          burnWeekLearningRunWeekNumber,
        ]);
      },
    );

    test('restarts learned stale cycle as first run week', () async {
      final today = normalizeLocalDay(DateTime.now());
      late _RecordingBurnWeekRunController controller;
      final container = _buildContainer(
        today: today,
        weekOverview: _weekOverview(today: today, balanceStartDate: today),
        todayOverview: _defaultTodayOverview(today),
        settings: _learnedGoalSettings(today),
        initialRunState: BurnWeekRunState(
          currentWeekStartDayKey: localDayKey(addLocalDays(today, -8)),
          lastActiveDayKey: localDayKey(today),
          runWeekNumber: 3,
          starCount: 2,
          starBrokeThisWeek: true,
          missedTrackingThisWeek: true,
        ),
        captureController: (value) => controller = value,
      );
      addTearDown(container.dispose);

      await _activateSync(container);

      expect(controller.syncCalls, isEmpty);
      expect(controller.restartCalls, <DateTime>[today]);
      expect(controller.restartRunWeekNumbers, <int?>[
        burnWeekLearningRunWeekNumber,
      ]);
    });

    test(
      'syncs current week with missed tracking for an earlier empty day',
      () async {
        final today = normalizeLocalDay(DateTime.now());
        final missingDay = addLocalDays(today, -2);
        late _RecordingBurnWeekRunController controller;
        final container = _buildContainer(
          today: today,
          weekOverview: _weekOverview(
            today: today,
            balanceStartDate: addLocalDays(today, -6),
            missingDays: <DateTime>{missingDay},
          ),
          todayOverview: _defaultTodayOverview(today),
          settings: _activeGoalSettings(addLocalDays(today, -6)),
          initialRunState: BurnWeekRunState(
            currentWeekStartDayKey: localDayKey(addLocalDays(today, -6)),
            lastActiveDayKey: localDayKey(today),
            runWeekNumber: 1,
            starCount: 0,
            starBrokeThisWeek: false,
            missedTrackingThisWeek: false,
          ),
          captureController: (value) => controller = value,
        );
        addTearDown(container.dispose);

        await _activateSync(container);

        expect(controller.restartCalls, isEmpty);
        expect(controller.syncCalls, hasLength(1));
        expect(controller.syncCalls.single.currentDay, today);
        expect(
          controller.syncCalls.single.weekStartDate,
          addLocalDays(today, -6),
        );
        expect(controller.syncCalls.single.missedTrackingThisWeek, isTrue);
        expect(
          controller.syncCalls.single.missedTrackingForClosedWeeks,
          isEmpty,
        );
      },
    );

    test('syncs closed weeks with missed tracking flags', () async {
      final today = normalizeLocalDay(DateTime.now());
      final closedWeekStart = addLocalDays(today, -7);
      final missingClosedWeekDay = addLocalDays(closedWeekStart, 3);
      late _RecordingBurnWeekRunController controller;
      final container = _buildContainer(
        today: today,
        weekOverview: _weekOverview(
          today: today,
          balanceStartDate: closedWeekStart,
        ),
        todayOverview: _defaultTodayOverview(today),
        settings: _activeGoalSettings(closedWeekStart),
        initialRunState: BurnWeekRunState(
          currentWeekStartDayKey: localDayKey(closedWeekStart),
          lastActiveDayKey: localDayKey(addLocalDays(today, -1)),
          runWeekNumber: 1,
          starCount: 0,
          starBrokeThisWeek: false,
          missedTrackingThisWeek: false,
        ),
        snapshotsByWindowEnd: <DateTime, CalorieWeekConsumptionSnapshot>{
          addLocalDays(closedWeekStart, 6): _snapshotForWeek(
            weekStartDate: closedWeekStart,
            missingDays: <DateTime>{missingClosedWeekDay},
          ),
        },
        captureController: (value) => controller = value,
      );
      addTearDown(container.dispose);

      await _activateSync(container);

      expect(controller.restartCalls, isEmpty);
      expect(controller.syncCalls, hasLength(1));
      expect(controller.syncCalls.single.currentDay, today);
      expect(controller.syncCalls.single.weekStartDate, today);
      expect(controller.syncCalls.single.missedTrackingThisWeek, isFalse);
      expect(controller.syncCalls.single.missedTrackingForClosedWeeks, <bool>[
        true,
      ]);
    });

    test(
      'dedupes identical queued sync work while sync is in flight',
      () async {
        final today = normalizeLocalDay(DateTime.now());
        final syncBlocker = Completer<void>();
        late _RecordingBurnWeekRunController controller;
        final container = _buildContainer(
          today: today,
          weekOverview: _weekOverview(
            today: today,
            balanceStartDate: addLocalDays(today, -6),
            missingDays: <DateTime>{addLocalDays(today, -2)},
          ),
          todayOverview: _defaultTodayOverview(today),
          settings: _activeGoalSettings(addLocalDays(today, -6)),
          initialRunState: BurnWeekRunState(
            currentWeekStartDayKey: localDayKey(addLocalDays(today, -6)),
            lastActiveDayKey: localDayKey(today),
            runWeekNumber: 1,
            starCount: 0,
            starBrokeThisWeek: false,
            missedTrackingThisWeek: false,
          ),
          controllerFactory: (initialState) => _RecordingBurnWeekRunController(
            initialState,
            syncBlocker: syncBlocker,
          ),
          captureController: (value) => controller = value,
        );
        addTearDown(container.dispose);
        await _primeSyncContainer(container);

        final subscription = container.listen<Object?>(
          burnWeekLiveSyncProvider,
          (_, _) {},
        );
        addTearDown(subscription.close);
        _queueLiveSyncRefresh(container);

        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(controller.syncCalls, hasLength(1));

        syncBlocker.complete();
        await Future<void>.delayed(Duration.zero);
      },
    );

    test(
      'dedupes identical queued restart work while restart is in flight',
      () async {
        final today = normalizeLocalDay(DateTime.now());
        final restartBlocker = Completer<void>();
        late _RecordingBurnWeekRunController controller;
        final container = _buildContainer(
          today: today,
          weekOverview: _weekOverview(today: today, balanceStartDate: today),
          todayOverview: _defaultTodayOverview(today),
          settings: _activeGoalSettings(today),
          initialRunState: BurnWeekRunState(
            currentWeekStartDayKey: localDayKey(addLocalDays(today, -8)),
            lastActiveDayKey: localDayKey(today),
            runWeekNumber: 2,
            starCount: 1,
            starBrokeThisWeek: false,
            missedTrackingThisWeek: false,
          ),
          controllerFactory: (initialState) => _RecordingBurnWeekRunController(
            initialState,
            restartBlocker: restartBlocker,
          ),
          captureController: (value) => controller = value,
        );
        addTearDown(container.dispose);
        await _primeSyncContainer(container);

        final subscription = container.listen<Object?>(
          burnWeekLiveSyncProvider,
          (_, _) {},
        );
        addTearDown(subscription.close);
        _queueLiveSyncRefresh(container);

        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(controller.restartCalls, <DateTime>[today]);

        restartBlocker.complete();
        await Future<void>.delayed(Duration.zero);
      },
    );

    test(
      'dedupes identical queued reset work while reset is in flight',
      () async {
        final today = normalizeLocalDay(DateTime.now());
        final tomorrow = nextLocalDay(today);
        final resetBlocker = Completer<void>();
        late _RecordingBurnWeekRunController controller;
        final container = _buildContainer(
          today: today,
          weekOverview: _weekOverview(
            today: today,
            balanceStartDate: tomorrow,
            goalStartsInFuture: true,
            nextGoalStartDate: tomorrow,
          ),
          todayOverview: _defaultTodayOverview(
            today,
            totalKcal: 0,
            goalKcal: 0,
            entryCount: 0,
          ),
          settings: _activeGoalSettings(tomorrow),
          initialRunState: BurnWeekRunState(
            currentWeekStartDayKey: localDayKey(addLocalDays(today, -6)),
            lastActiveDayKey: localDayKey(today),
            runWeekNumber: 2,
            starCount: 1,
            starBrokeThisWeek: false,
            missedTrackingThisWeek: false,
          ),
          controllerFactory: (initialState) => _RecordingBurnWeekRunController(
            initialState,
            resetBlocker: resetBlocker,
          ),
          captureController: (value) => controller = value,
        );
        addTearDown(container.dispose);
        await _primeSyncContainer(container);

        final subscription = container.listen<Object?>(
          burnWeekLiveSyncProvider,
          (_, _) {},
        );
        addTearDown(subscription.close);
        _queueLiveSyncRefresh(container);

        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(controller.resetCallCount(), 1);

        resetBlocker.complete();
        await Future<void>.delayed(Duration.zero);
      },
    );
  });
}
