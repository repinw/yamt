import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_live_overview_logic.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';

final Provider<_BurnWeekMutationCoordinator>
_burnWeekMutationCoordinatorProvider =
    Provider.autoDispose<_BurnWeekMutationCoordinator>(
      (ref) => _BurnWeekMutationCoordinator(),
    );

/// How often Burn Week live sync should re-check the current day.
final burnWeekLiveSyncTickerPeriodProvider = Provider<Duration?>(
  (ref) => const Duration(minutes: 1),
);

/// Keeps Burn Week sync active outside the widget tree.
final Provider<Object?> burnWeekLiveSyncProvider =
    Provider.autoDispose<Object?>((ref) {
      // Keep the mutation coordinator alive for as long as live sync is active.
      ref.watch(_burnWeekMutationCoordinatorProvider);
      final tickerPeriod = ref.watch(burnWeekLiveSyncTickerPeriodProvider);
      if (tickerPeriod != null) {
        final ticker = Timer.periodic(tickerPeriod, (_) {
          ref.invalidateSelf();
        });
        ref.onDispose(ticker.cancel);
      }

      final today = normalizeDiaryDay(DateTime.now());
      final weekOverview = ref.watch(
        calorieWeekOverviewForWindowProvider(today),
      );
      final todayOverview = ref.watch(
        calorieWeekDayOverviewForDateProvider(today),
      );
      final settings = ref.watch(calorieGoalControllerProvider).asData?.value;
      final runState =
          ref.watch(burnWeekRunControllerProvider).asData?.value ??
          const BurnWeekRunState.initial();

      final weekOverviewValue = weekOverview.value;
      final todayOverviewValue = todayOverview.value;
      if (weekOverviewValue == null ||
          todayOverviewValue == null ||
          settings == null) {
        return;
      }

      final storedWeekStartDate = tryParseBurnWeekDayKey(
        runState.currentWeekStartDayKey,
      );
      final hasFutureStoredWeekStart =
          storedWeekStartDate != null &&
          storedWeekStartDate.isAfter(todayOverviewValue.date);
      if (weekOverviewValue.goalStartsInFuture) {
        final nextGoalStartDate = weekOverviewValue.nextGoalStartDate;
        if (settings.hasLearnedTdee && nextGoalStartDate != null) {
          final normalizedGoalStartDate = normalizeDiaryDay(
            nextGoalStartDate,
          );
          if (!_isScheduledFutureGameRun(
            runState: runState,
            storedWeekStartDate: storedWeekStartDate,
            expectedWeekStartDate: normalizedGoalStartDate,
          )) {
            _queueRunRestart(
              ref,
              weekStartDate: normalizedGoalStartDate,
              runWeekNumber: burnWeekFirstGameRunWeekNumber,
            );
          }
          return null;
        }
        if (!_isInitialBurnWeekRunState(runState)) {
          _queueRunReset(ref);
        }
        return null;
      }

      final currentWeekStartDate = resolveBurnWeekLiveWeekStartDate(
        currentDay: todayOverviewValue.date,
        balanceStartDate: weekOverviewValue.balanceStartDate,
        storedWeekStartDayKey: runState.currentWeekStartDayKey,
      );
      final syncWeekStartDate = resolveBurnWeekLiveSyncWeekStartDate(
        currentDay: todayOverviewValue.date,
        currentWeekStartDate: currentWeekStartDate,
      );
      if (hasFutureStoredWeekStart) {
        return;
      }

      final hasStoredWeekStartOutsideCycle =
          storedWeekStartDate != null &&
          storedWeekStartDate.isBefore(weekOverviewValue.balanceStartDate);
      if (hasStoredWeekStartOutsideCycle) {
        _queueRunRestart(ref, weekStartDate: syncWeekStartDate);
        return;
      }

      final missedTrackingThisWeek = resolveBurnWeekLiveMissedTrackingThisWeek(
        weekOverview: weekOverviewValue,
        currentWeekStartDate: currentWeekStartDate,
        today: todayOverviewValue.date,
        settings: settings,
      );
      final closedWeekStartDates = <DateTime>[];
      var closedWeekStartDate =
          _shouldRepairBackfilledInitialRun(
            runState: runState,
            storedWeekStartDate: storedWeekStartDate,
            balanceStartDate: weekOverviewValue.balanceStartDate,
            today: todayOverviewValue.date,
            syncWeekStartDate: syncWeekStartDate,
          )
          ? weekOverviewValue.balanceStartDate
          : storedWeekStartDate ?? weekOverviewValue.balanceStartDate;
      while (closedWeekStartDate.isBefore(syncWeekStartDate)) {
        closedWeekStartDates.add(closedWeekStartDate);
        closedWeekStartDate = closedWeekStartDate.add(
          const Duration(days: burnWeekDaysPerWeek),
        );
      }
      final expectedWeekStartDayKey = diaryDayKey(syncWeekStartDate);
      final expectedCurrentDayKey = diaryDayKey(todayOverviewValue.date);
      final isAlreadySynced =
          closedWeekStartDates.isEmpty &&
          runState.currentWeekStartDayKey == expectedWeekStartDayKey &&
          runState.lastActiveDayKey == expectedCurrentDayKey &&
          runState.missedTrackingThisWeek == missedTrackingThisWeek;
      if (isAlreadySynced) {
        return null;
      }

      final closedWeekSnapshots = [
        for (final closedWeekStartDate in closedWeekStartDates)
          ref
              .watch(
                calorieWeekConsumptionSnapshotForWindowProvider(
                  closedWeekStartDate.add(
                    const Duration(days: burnWeekDaysPerWeek - 1),
                  ),
                ),
              )
              .value,
      ];
      if (closedWeekSnapshots.any((snapshot) => snapshot == null)) {
        return;
      }

      final missedTrackingForClosedWeeks = [
        for (var index = 0; index < closedWeekStartDates.length; index += 1)
          resolveBurnWeekLiveMissedTrackingForStoredWeek(
            storedWeekSnapshot: closedWeekSnapshots[index]!,
            storedWeekStartDate: closedWeekStartDates[index],
            today: nextDiaryDay(
              closedWeekStartDates[index].add(
                const Duration(days: burnWeekDaysPerWeek - 1),
              ),
            ),
            settings: settings,
          ),
      ];
      _queueRunSync(
        ref,
        weekStartDate: syncWeekStartDate,
        missedTrackingThisWeek: missedTrackingThisWeek,
        missedTrackingForClosedWeeks: missedTrackingForClosedWeeks,
      );
      return null;
    });

void _queueRunSync(
  Ref ref, {
  required DateTime weekStartDate,
  required bool missedTrackingThisWeek,
  List<bool>? missedTrackingForClosedWeeks,
}) {
  final controller = ref.read(burnWeekRunControllerProvider.notifier);
  final currentDay = normalizeDiaryDay(DateTime.now());
  _queuePendingBurnWeekMutation(
    ref,
    mutation: _PendingBurnWeekMutation.sync(
      weekStartDate: weekStartDate,
      missedTrackingThisWeek: missedTrackingThisWeek,
      missedTrackingForClosedWeeks: missedTrackingForClosedWeeks,
    ),
    action: () {
      return controller.syncForWeek(
        currentDay: currentDay,
        weekStartDate: weekStartDate,
        missedTrackingThisWeek: missedTrackingThisWeek,
        missedTrackingForClosedWeeks: missedTrackingForClosedWeeks,
      );
    },
  );
}

void _queueRunRestart(
  Ref ref, {
  required DateTime weekStartDate,
  int? runWeekNumber,
}) {
  final controller = ref.read(burnWeekRunControllerProvider.notifier);
  _queuePendingBurnWeekMutation(
    ref,
    mutation: _PendingBurnWeekMutation.restart(
      weekStartDate: weekStartDate,
      runWeekNumber: runWeekNumber,
    ),
    action: () {
      return controller.restartRunFrom(
        weekStartDate: weekStartDate,
        runWeekNumber: runWeekNumber,
      );
    },
  );
}

void _queueRunReset(Ref ref) {
  final controller = ref.read(burnWeekRunControllerProvider.notifier);
  _queuePendingBurnWeekMutation(
    ref,
    mutation: const _PendingBurnWeekMutation.reset(),
    action: controller.resetRun,
  );
}

void _queuePendingBurnWeekMutation(
  Ref ref, {
  required _PendingBurnWeekMutation mutation,
  required Future<void> Function() action,
}) {
  final mutationCoordinator = ref.read(_burnWeekMutationCoordinatorProvider);
  if (mutationCoordinator.hasPendingMutation(mutation)) {
    return;
  }
  mutationCoordinator.queue(mutation);
  scheduleMicrotask(() {
    if (!mutationCoordinator.startIfQueued(mutation)) {
      return;
    }
    unawaited(
      _runPendingBurnWeekMutation(mutationCoordinator, mutation, action),
    );
  });
}

bool _isInitialBurnWeekRunState(BurnWeekRunState state) {
  return state.currentWeekStartDayKey == null &&
      state.lastActiveDayKey == null &&
      state.runWeekNumber == burnWeekLearningRunWeekNumber &&
      state.starCount == 0 &&
      state.heartCount == 3 &&
      state.heartCreditKcal == 0 &&
      !state.starBrokeThisWeek &&
      !state.missedTrackingThisWeek;
}

bool _shouldRepairBackfilledInitialRun({
  required BurnWeekRunState runState,
  required DateTime? storedWeekStartDate,
  required DateTime balanceStartDate,
  required DateTime today,
  required DateTime syncWeekStartDate,
}) {
  if (storedWeekStartDate == null || !_looksLikeFreshRun(runState)) {
    return false;
  }

  final normalizedBalanceStartDate = normalizeDiaryDay(balanceStartDate);
  final normalizedStoredWeekStartDate = normalizeDiaryDay(storedWeekStartDate);
  final normalizedSyncWeekStartDate = normalizeDiaryDay(syncWeekStartDate);
  if (!normalizedBalanceStartDate.isBefore(normalizedStoredWeekStartDate) ||
      !_isSameDiaryDay(
        normalizedStoredWeekStartDate,
        normalizedSyncWeekStartDate,
      )) {
    return false;
  }

  final cycleWeekStartDate = resolveBurnWeekLiveSyncWeekStartDate(
    currentDay: today,
    currentWeekStartDate: resolveBurnWeekLiveWeekStartDate(
      currentDay: today,
      balanceStartDate: normalizedBalanceStartDate,
      storedWeekStartDayKey: null,
    ),
  );
  return _isSameDiaryDay(cycleWeekStartDate, normalizedStoredWeekStartDate);
}

bool _looksLikeFreshRun(BurnWeekRunState state) {
  return state.runWeekNumber == burnWeekLearningRunWeekNumber &&
      state.starCount == 0 &&
      state.heartCount == 3 &&
      state.heartCreditKcal == 0 &&
      !state.starBrokeThisWeek;
}

bool _isScheduledFutureGameRun({
  required BurnWeekRunState runState,
  required DateTime? storedWeekStartDate,
  required DateTime expectedWeekStartDate,
}) {
  return storedWeekStartDate != null &&
      _isSameDiaryDay(storedWeekStartDate, expectedWeekStartDate) &&
      runState.runWeekNumber == burnWeekFirstGameRunWeekNumber &&
      runState.starCount == 0 &&
      runState.heartCount == 3 &&
      runState.heartCreditKcal == 0 &&
      !runState.starBrokeThisWeek &&
      !runState.missedTrackingThisWeek;
}

bool _isSameDiaryDay(DateTime left, DateTime right) {
  return diaryDayKey(left) == diaryDayKey(right);
}

Future<void> _runPendingBurnWeekMutation(
  _BurnWeekMutationCoordinator mutationCoordinator,
  _PendingBurnWeekMutation mutation,
  Future<void> Function() action,
) async {
  try {
    await action();
  } finally {
    mutationCoordinator.clearIfRunning(mutation);
  }
}

class _BurnWeekMutationCoordinator {
  _PendingBurnWeekMutationState? _pendingMutation;

  bool hasPendingMutation(_PendingBurnWeekMutation mutation) {
    return _pendingMutation?.mutation == mutation;
  }

  void queue(_PendingBurnWeekMutation mutation) {
    _pendingMutation = _QueuedBurnWeekMutationState(mutation);
  }

  bool startIfQueued(_PendingBurnWeekMutation mutation) {
    final pendingMutation = _pendingMutation;
    if (pendingMutation is! _QueuedBurnWeekMutationState ||
        pendingMutation.mutation != mutation) {
      return false;
    }
    _pendingMutation = _RunningBurnWeekMutationState(mutation);
    return true;
  }

  void clearIfRunning(_PendingBurnWeekMutation mutation) {
    final pendingMutation = _pendingMutation;
    if (pendingMutation is _RunningBurnWeekMutationState &&
        pendingMutation.mutation == mutation) {
      _pendingMutation = null;
    }
  }
}

sealed class _PendingBurnWeekMutationState {
  const _PendingBurnWeekMutationState(this.mutation);

  final _PendingBurnWeekMutation mutation;
}

class _QueuedBurnWeekMutationState extends _PendingBurnWeekMutationState {
  const _QueuedBurnWeekMutationState(super.mutation);
}

class _RunningBurnWeekMutationState extends _PendingBurnWeekMutationState {
  const _RunningBurnWeekMutationState(super.mutation);
}

@immutable
class _PendingBurnWeekMutation {
  const _PendingBurnWeekMutation._(this.key);

  const _PendingBurnWeekMutation.reset() : this._('reset');

  factory _PendingBurnWeekMutation.restart({
    required DateTime weekStartDate,
    int? runWeekNumber,
  }) {
    final runWeekKey = runWeekNumber == null ? '' : ':$runWeekNumber';
    return _PendingBurnWeekMutation._(
      'restart:${diaryDayKey(normalizeDiaryDay(weekStartDate))}$runWeekKey',
    );
  }

  factory _PendingBurnWeekMutation.sync({
    required DateTime weekStartDate,
    required bool missedTrackingThisWeek,
    List<bool>? missedTrackingForClosedWeeks,
  }) {
    final closedWeeksKey = (missedTrackingForClosedWeeks ?? const <bool>[])
        .map((value) => value ? '1' : '0')
        .join();
    return _PendingBurnWeekMutation._(
      'sync:${diaryDayKey(normalizeDiaryDay(weekStartDate))}'
      ':${missedTrackingThisWeek ? '1' : '0'}:$closedWeeksKey',
    );
  }

  final String key;

  @override
  bool operator ==(Object other) {
    return other is _PendingBurnWeekMutation && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}
