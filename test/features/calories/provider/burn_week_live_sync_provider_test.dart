import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';

class _FakeCalorieGoalController extends CalorieGoalController {
  _FakeCalorieGoalController(this.settings);

  final CalorieGoalSettings settings;

  @override
  FutureOr<CalorieGoalSettings> build() {
    return settings;
  }
}

class _RecordingBurnWeekRunController extends BurnWeekRunController {
  _RecordingBurnWeekRunController(
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
  int _resetCallCount = 0;

  int resetCallCount() => _resetCallCount;

  @override
  Future<BurnWeekRunState> build() async {
    return initialState;
  }

  @override
  Future<void> restartRunFrom({required DateTime weekStartDate}) async {
    restartCalls.add(normalizeDiaryDay(weekStartDate));
    await restartBlocker?.future;
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
        currentDay: normalizeDiaryDay(currentDay),
        weekStartDate: normalizeDiaryDay(weekStartDate),
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
  const _SyncCall({
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
      calorieWeekOverviewForWindowProvider(today).overrideWith(
        (ref) => weekOverview,
      ),
      calorieWeekDayOverviewForDateProvider(today).overrideWith(
        (ref) => todayOverview,
      ),
      for (final entry in snapshotsByWindowEnd.entries)
        calorieWeekConsumptionSnapshotForWindowProvider(
          entry.key,
        ).overrideWith((ref) => entry.value),
      calorieGoalControllerProvider.overrideWith(
        () => _FakeCalorieGoalController(settings),
      ),
      burnWeekRunControllerProvider.overrideWith(
        () {
          final controller =
              controllerFactory?.call(initialRunState) ??
              _RecordingBurnWeekRunController(initialRunState);
          captureController(controller);
          return controller;
        },
      ),
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
  final normalizedToday = normalizeDiaryDay(today);
  final days = [
    for (var offset = 6; offset >= 0; offset -= 1)
      CalorieWeekDayOverview(
        date: normalizedToday.subtract(Duration(days: offset)),
        totalKcal:
            missingDays.contains(
              normalizedToday.subtract(Duration(days: offset)),
            )
            ? 0
            : 1000,
        goalKcal: 2000,
        entryCount:
            missingDays.contains(
              normalizedToday.subtract(Duration(days: offset)),
            )
            ? 0
            : 1,
      ),
  ];
  return CalorieWeekOverview(
    days: days,
    totalConsumedKcal: days.fold<double>(0, (sum, day) => sum + day.totalKcal),
    totalGoalKcal: 2000 * 7,
    remainingKcal: 0,
    balanceStartDate: normalizeDiaryDay(balanceStartDate),
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
  final normalizedWeekStartDate = normalizeDiaryDay(weekStartDate);
  final days = [
    for (var offset = 0; offset < 7; offset += 1)
      CalorieWeekConsumptionDaySnapshot(
        date: normalizedWeekStartDate.add(Duration(days: offset)),
        totalKcal:
            missingDays.contains(
              normalizedWeekStartDate.add(Duration(days: offset)),
            )
            ? 0
            : 1000,
        entryCount:
            missingDays.contains(
              normalizedWeekStartDate.add(Duration(days: offset)),
            )
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

void main() {
  group('burnWeekLiveSyncProvider', () {
    test('does nothing when the run state is already synchronized', () async {
      final today = normalizeDiaryDay(DateTime.now());
      late _RecordingBurnWeekRunController controller;
      final container = _buildContainer(
        today: today,
        weekOverview: _weekOverview(
          today: today,
          balanceStartDate: today.subtract(const Duration(days: 6)),
        ),
        todayOverview: _defaultTodayOverview(today),
        settings: _activeGoalSettings(today.subtract(const Duration(days: 6))),
        initialRunState: BurnWeekRunState(
          currentWeekStartDayKey: diaryDayKey(
            today.subtract(const Duration(days: 6)),
          ),
          lastActiveDayKey: diaryDayKey(today),
          runWeekNumber: 1,
          starCount: 0,
          heartCount: 3,
          heartCreditKcal: 0,
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
      final today = normalizeDiaryDay(DateTime.now());
      final tomorrow = nextDiaryDay(today);
      late _RecordingBurnWeekRunController controller;
      final container = _buildContainer(
        today: today,
        weekOverview: _weekOverview(
          today: today,
          balanceStartDate: today.subtract(const Duration(days: 6)),
        ),
        todayOverview: _defaultTodayOverview(today),
        settings: _activeGoalSettings(today.subtract(const Duration(days: 6))),
        initialRunState: BurnWeekRunState(
          currentWeekStartDayKey: diaryDayKey(tomorrow),
          lastActiveDayKey: diaryDayKey(today),
          runWeekNumber: 1,
          starCount: 0,
          heartCount: 3,
          heartCreditKcal: 0,
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
      final today = normalizeDiaryDay(DateTime.now());
      final cycleStart = today.subtract(const Duration(days: 18));
      final currentWeekStart = today.subtract(const Duration(days: 4));
      late _RecordingBurnWeekRunController controller;
      final container = _buildContainer(
        today: today,
        weekOverview: _weekOverview(
          today: today,
          balanceStartDate: cycleStart,
        ),
        todayOverview: _defaultTodayOverview(today),
        settings: _activeGoalSettings(cycleStart),
        initialRunState: const BurnWeekRunState.initial(),
        snapshotsByWindowEnd: <DateTime, CalorieWeekConsumptionSnapshot>{
          cycleStart.add(const Duration(days: 6)): _snapshotForWeek(
            weekStartDate: cycleStart,
          ),
          cycleStart.add(const Duration(days: 13)): _snapshotForWeek(
            weekStartDate: cycleStart.add(const Duration(days: 7)),
          ),
        },
        captureController: (value) => controller = value,
      );
      addTearDown(container.dispose);

      await _activateSync(container);

      expect(controller.restartCalls, isEmpty);
      expect(controller.syncCalls, hasLength(1));
      expect(controller.syncCalls.single.weekStartDate, currentWeekStart);
      expect(
        controller.syncCalls.single.missedTrackingForClosedWeeks,
        <bool>[false, false],
      );
    });

    test(
      'repairs fresh current-week state that skipped backfilled weeks',
      () async {
        final today = normalizeDiaryDay(DateTime.now());
        final cycleStart = today.subtract(const Duration(days: 18));
        final currentWeekStart = today.subtract(const Duration(days: 4));
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
            currentWeekStartDayKey: diaryDayKey(currentWeekStart),
            lastActiveDayKey: diaryDayKey(today),
            runWeekNumber: 1,
            starCount: 0,
            heartCount: 3,
            heartCreditKcal: 0,
            starBrokeThisWeek: false,
            missedTrackingThisWeek: false,
          ),
          snapshotsByWindowEnd: <DateTime, CalorieWeekConsumptionSnapshot>{
            cycleStart.add(const Duration(days: 6)): _snapshotForWeek(
              weekStartDate: cycleStart,
            ),
            cycleStart.add(const Duration(days: 13)): _snapshotForWeek(
              weekStartDate: cycleStart.add(const Duration(days: 7)),
            ),
          },
          captureController: (value) => controller = value,
        );
        addTearDown(container.dispose);

        await _activateSync(container);

        expect(controller.restartCalls, isEmpty);
        expect(controller.syncCalls, hasLength(1));
        expect(controller.syncCalls.single.weekStartDate, currentWeekStart);
        expect(
          controller.syncCalls.single.missedTrackingForClosedWeeks,
          <bool>[false, false],
        );
      },
    );

    test('does nothing while the goal starts in the future', () async {
      final today = normalizeDiaryDay(DateTime.now());
      final tomorrow = nextDiaryDay(today);
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
      'restarts when stored week start is outside the active cycle',
      () async {
        final today = normalizeDiaryDay(DateTime.now());
        late _RecordingBurnWeekRunController controller;
        final container = _buildContainer(
          today: today,
          weekOverview: _weekOverview(
            today: today,
            balanceStartDate: today,
          ),
          todayOverview: _defaultTodayOverview(today),
          settings: _activeGoalSettings(today),
          initialRunState: BurnWeekRunState(
            currentWeekStartDayKey: diaryDayKey(
              today.subtract(const Duration(days: 8)),
            ),
            lastActiveDayKey: diaryDayKey(today),
            runWeekNumber: 2,
            starCount: 1,
            heartCount: 3,
            heartCreditKcal: 0,
            starBrokeThisWeek: false,
            missedTrackingThisWeek: false,
          ),
          captureController: (value) => controller = value,
        );
        addTearDown(container.dispose);

        await _activateSync(container);

        expect(controller.syncCalls, isEmpty);
        expect(controller.restartCalls, <DateTime>[today]);
      },
    );

    test(
      'syncs current week with missed tracking for an earlier empty day',
      () async {
        final today = normalizeDiaryDay(DateTime.now());
        final missingDay = today.subtract(const Duration(days: 2));
        late _RecordingBurnWeekRunController controller;
        final container = _buildContainer(
          today: today,
          weekOverview: _weekOverview(
            today: today,
            balanceStartDate: today.subtract(const Duration(days: 6)),
            missingDays: <DateTime>{missingDay},
          ),
          todayOverview: _defaultTodayOverview(today),
          settings: _activeGoalSettings(
            today.subtract(const Duration(days: 6)),
          ),
          initialRunState: BurnWeekRunState(
            currentWeekStartDayKey: diaryDayKey(
              today.subtract(const Duration(days: 6)),
            ),
            lastActiveDayKey: diaryDayKey(today),
            runWeekNumber: 1,
            starCount: 0,
            heartCount: 3,
            heartCreditKcal: 0,
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
          today.subtract(const Duration(days: 6)),
        );
        expect(controller.syncCalls.single.missedTrackingThisWeek, isTrue);
        expect(
          controller.syncCalls.single.missedTrackingForClosedWeeks,
          isEmpty,
        );
      },
    );

    test('syncs closed weeks with missed tracking flags', () async {
      final today = normalizeDiaryDay(DateTime.now());
      final closedWeekStart = today.subtract(const Duration(days: 7));
      final missingClosedWeekDay = closedWeekStart.add(const Duration(days: 3));
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
          currentWeekStartDayKey: diaryDayKey(closedWeekStart),
          lastActiveDayKey: diaryDayKey(
            today.subtract(const Duration(days: 1)),
          ),
          runWeekNumber: 1,
          starCount: 0,
          heartCount: 3,
          heartCreditKcal: 0,
          starBrokeThisWeek: false,
          missedTrackingThisWeek: false,
        ),
        snapshotsByWindowEnd: <DateTime, CalorieWeekConsumptionSnapshot>{
          closedWeekStart.add(const Duration(days: 6)): _snapshotForWeek(
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
      expect(
        controller.syncCalls.single.missedTrackingForClosedWeeks,
        <bool>[true],
      );
    });

    test(
      'dedupes identical queued sync work while sync is in flight',
      () async {
        final today = normalizeDiaryDay(DateTime.now());
        final syncBlocker = Completer<void>();
        late _RecordingBurnWeekRunController controller;
        final container = _buildContainer(
          today: today,
          weekOverview: _weekOverview(
            today: today,
            balanceStartDate: today.subtract(const Duration(days: 6)),
            missingDays: <DateTime>{today.subtract(const Duration(days: 2))},
          ),
          todayOverview: _defaultTodayOverview(today),
          settings: _activeGoalSettings(
            today.subtract(const Duration(days: 6)),
          ),
          initialRunState: BurnWeekRunState(
            currentWeekStartDayKey: diaryDayKey(
              today.subtract(const Duration(days: 6)),
            ),
            lastActiveDayKey: diaryDayKey(today),
            runWeekNumber: 1,
            starCount: 0,
            heartCount: 3,
            heartCreditKcal: 0,
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
        final today = normalizeDiaryDay(DateTime.now());
        final restartBlocker = Completer<void>();
        late _RecordingBurnWeekRunController controller;
        final container = _buildContainer(
          today: today,
          weekOverview: _weekOverview(
            today: today,
            balanceStartDate: today,
          ),
          todayOverview: _defaultTodayOverview(today),
          settings: _activeGoalSettings(today),
          initialRunState: BurnWeekRunState(
            currentWeekStartDayKey: diaryDayKey(
              today.subtract(const Duration(days: 8)),
            ),
            lastActiveDayKey: diaryDayKey(today),
            runWeekNumber: 2,
            starCount: 1,
            heartCount: 3,
            heartCreditKcal: 0,
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
        final today = normalizeDiaryDay(DateTime.now());
        final tomorrow = nextDiaryDay(today);
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
            currentWeekStartDayKey: diaryDayKey(
              today.subtract(const Duration(days: 6)),
            ),
            lastActiveDayKey: diaryDayKey(today),
            runWeekNumber: 2,
            starCount: 1,
            heartCount: 2,
            heartCreditKcal: 600,
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
