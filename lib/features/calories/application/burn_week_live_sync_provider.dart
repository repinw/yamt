import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/app_version_config_repository.dart';
import 'package:yamt/core/domain/app_update_status.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/'
    'burn_week_live_mutation_coordinator.dart';
import 'package:yamt/features/calories/application/'
    'burn_week_live_window_logic.dart';
import 'package:yamt/features/calories/application/burn_week_run_controller.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/calorie_week_consumption_snapshot_provider.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_provider.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';

part 'burn_week_live_sync_provider.g.dart';

/// How often Burn Week live sync should re-check the current day.
@riverpod
Duration? burnWeekLiveSyncTickerPeriod(Ref ref) {
  ref.keepAlive();
  return const Duration(minutes: 1);
}

/// Keeps Burn Week sync active outside the widget tree.
@riverpod
Object? burnWeekLiveSync(Ref ref) {
  // Keep the mutation coordinator alive for as long as live sync is active.
  ref.watch(burnWeekLiveMutationCoordinatorProvider);
  final tickerPeriod = ref.watch(burnWeekLiveSyncTickerPeriodProvider);
  if (tickerPeriod != null) {
    final ticker = Timer.periodic(tickerPeriod, (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(ticker.cancel);
  }

  final today = normalizeLocalDay(ref.watch(clockProvider)());
  final weekOverview = ref.watch(calorieWeekOverviewForWindowProvider(today));
  final todayOverview = ref.watch(calorieWeekDayOverviewForDateProvider(today));
  final settings = ref.watch(calorieGoalControllerProvider).asData?.value;
  final runState =
      ref.watch(burnWeekRunControllerProvider).asData?.value ??
      const BurnWeekRunState.initial();

  final weekOverviewValue = weekOverview.value;
  final todayOverviewValue = todayOverview.value;
  if (weekOverviewValue == null ||
      todayOverviewValue == null ||
      settings == null) {
    return null;
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
      final normalizedGoalStartDate = normalizeLocalDay(nextGoalStartDate);
      if (!isScheduledFutureFreshBurnWeekRun(
        runState: runState,
        storedWeekStartDate: storedWeekStartDate,
        expectedWeekStartDate: normalizedGoalStartDate,
      )) {
        _queueRunRestart(
          ref,
          weekStartDate: normalizedGoalStartDate,
          runWeekNumber: burnWeekLearningRunWeekNumber,
        );
      }
      return null;
    }
    if (!isInitialBurnWeekRunState(runState)) {
      _queueRunReset(ref);
    }
    return null;
  }

  final alignedWeekStartDate = storedWeekStartDate == null
      ? null
      : alignBurnWeekStartDate(
          storedWeekStartDate: storedWeekStartDate,
          balanceStartDate: weekOverviewValue.balanceStartDate,
        );
  if (alignedWeekStartDate != null &&
      !isSameLocalDay(alignedWeekStartDate, storedWeekStartDate!)) {
    // An app below the minimum version must not rewrite the run; until the
    // status is known the sync keeps the shifted weeks as they are.
    final updateStatus = ref.watch(appUpdateStatusProvider).value;
    if (updateStatus != null && updateStatus is! AppUpdateRequired) {
      _queueRunWeekMove(ref, weekStartDate: alignedWeekStartDate);
      return null;
    }
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
    return null;
  }

  final hasStoredWeekStartOutsideCycle =
      storedWeekStartDate != null &&
      storedWeekStartDate.isBefore(weekOverviewValue.balanceStartDate);
  if (hasStoredWeekStartOutsideCycle) {
    _queueRunRestart(
      ref,
      weekStartDate: syncWeekStartDate,
      runWeekNumber: burnWeekLearningRunWeekNumber,
    );
    return null;
  }

  final missedTrackingThisWeek = resolveBurnWeekLiveMissedTrackingThisWeek(
    weekOverview: weekOverviewValue,
    currentWeekStartDate: currentWeekStartDate,
    today: todayOverviewValue.date,
    settings: settings,
  );
  final closedWeekStartDates = resolveBurnWeekClosedWeekStartDates(
    runState: runState,
    storedWeekStartDate: storedWeekStartDate,
    balanceStartDate: weekOverviewValue.balanceStartDate,
    today: todayOverviewValue.date,
    syncWeekStartDate: syncWeekStartDate,
  );
  final expectedWeekStartDayKey = localDayKey(syncWeekStartDate);
  final expectedCurrentDayKey = localDayKey(todayOverviewValue.date);
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
              addLocalDays(closedWeekStartDate, burnWeekDaysPerWeek - 1),
            ),
          )
          .value,
  ];
  if (closedWeekSnapshots.any((snapshot) => snapshot == null)) {
    return null;
  }

  final missedTrackingForClosedWeeks = [
    for (var index = 0; index < closedWeekStartDates.length; index += 1)
      resolveBurnWeekLiveMissedTrackingForStoredWeek(
        storedWeekSnapshot: closedWeekSnapshots[index]!,
        storedWeekStartDate: closedWeekStartDates[index],
        today: nextLocalDay(
          addLocalDays(closedWeekStartDates[index], burnWeekDaysPerWeek - 1),
        ),
        settings: settings,
      ),
  ];
  _queueRunSync(
    ref,
    currentDay: today,
    weekStartDate: syncWeekStartDate,
    missedTrackingThisWeek: missedTrackingThisWeek,
    missedTrackingForClosedWeeks: missedTrackingForClosedWeeks,
  );
  return null;
}

void _queueRunSync(
  Ref ref, {
  required DateTime currentDay,
  required DateTime weekStartDate,
  required bool missedTrackingThisWeek,
  List<bool>? missedTrackingForClosedWeeks,
}) {
  final controller = ref.read(burnWeekRunControllerProvider.notifier);
  final closedWeeksKey = (missedTrackingForClosedWeeks ?? const <bool>[])
      .map((value) => value ? '1' : '0')
      .join();
  final mutationKey =
      'sync:${localDayKey(normalizeLocalDay(weekStartDate))}'
      ':${missedTrackingThisWeek ? '1' : '0'}:$closedWeeksKey';

  ref
      .read(burnWeekLiveMutationCoordinatorProvider)
      .queueMutation(
        key: mutationKey,
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
  final mutationKey = [
    'restart',
    localDayKey(normalizeLocalDay(weekStartDate)),
    if (runWeekNumber != null) runWeekNumber.toString(),
  ].join(':');

  ref
      .read(burnWeekLiveMutationCoordinatorProvider)
      .queueMutation(
        key: mutationKey,
        action: () {
          return controller.restartRunFrom(
            weekStartDate: weekStartDate,
            runWeekNumber: runWeekNumber,
          );
        },
      );
}

void _queueRunWeekMove(Ref ref, {required DateTime weekStartDate}) {
  final controller = ref.read(burnWeekRunControllerProvider.notifier);
  ref
      .read(burnWeekLiveMutationCoordinatorProvider)
      .queueMutation(
        key: 'move:${localDayKey(normalizeLocalDay(weekStartDate))}',
        action: () => controller.moveWeekStartTo(weekStartDate),
      );
}

void _queueRunReset(Ref ref) {
  final controller = ref.read(burnWeekRunControllerProvider.notifier);
  ref
      .read(burnWeekLiveMutationCoordinatorProvider)
      .queueMutation(key: 'reset', action: controller.resetRun);
}
