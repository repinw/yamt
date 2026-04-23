import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_live_overview_logic.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';

/// How often Burn Week live sync should re-check the current day.
final burnWeekLiveSyncTickerPeriodProvider = Provider<Duration?>(
  (ref) => const Duration(minutes: 1),
);

/// Keeps Burn Week sync active outside the widget tree.
final Provider<Object?> burnWeekLiveSyncProvider =
    Provider.autoDispose<Object?>((ref) {
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

      if (weekOverviewValue.goalStartsInFuture) {
        if (!_isInitialBurnWeekRunState(runState)) {
          _queueRunReset(ref);
        }
        return null;
      }

      final storedWeekStartDate = tryParseBurnWeekDayKey(
        runState.currentWeekStartDayKey,
      );
      final currentWeekStartDate = resolveBurnWeekLiveWeekStartDate(
        currentDay: todayOverviewValue.date,
        balanceStartDate: weekOverviewValue.balanceStartDate,
        storedWeekStartDayKey: runState.currentWeekStartDayKey,
      );
      final syncWeekStartDate = resolveBurnWeekLiveSyncWeekStartDate(
        currentDay: todayOverviewValue.date,
        currentWeekStartDate: currentWeekStartDate,
      );
      final hasFutureStoredWeekStart =
          storedWeekStartDate != null &&
          storedWeekStartDate.isAfter(todayOverviewValue.date);
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
      if (storedWeekStartDate != null) {
        var closedWeekStartDate = storedWeekStartDate;
        while (closedWeekStartDate.isBefore(syncWeekStartDate)) {
          closedWeekStartDates.add(closedWeekStartDate);
          closedWeekStartDate = closedWeekStartDate.add(
            const Duration(days: burnWeekDaysPerWeek),
          );
        }
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
  scheduleMicrotask(() {
    if (!ref.mounted) {
      return;
    }
    unawaited(
      ref
          .read(burnWeekRunControllerProvider.notifier)
          .syncForWeek(
            currentDay: normalizeDiaryDay(DateTime.now()),
            weekStartDate: weekStartDate,
            missedTrackingThisWeek: missedTrackingThisWeek,
            missedTrackingForClosedWeeks: missedTrackingForClosedWeeks,
          ),
    );
  });
}

void _queueRunRestart(Ref ref, {required DateTime weekStartDate}) {
  scheduleMicrotask(() {
    if (!ref.mounted) {
      return;
    }
    unawaited(
      ref
          .read(burnWeekRunControllerProvider.notifier)
          .restartRunFrom(
            weekStartDate: weekStartDate,
          ),
    );
  });
}

void _queueRunReset(Ref ref) {
  scheduleMicrotask(() {
    if (!ref.mounted) {
      return;
    }
    unawaited(ref.read(burnWeekRunControllerProvider.notifier).resetRun());
  });
}

bool _isInitialBurnWeekRunState(BurnWeekRunState state) {
  return state.currentWeekStartDayKey == null &&
      state.lastActiveDayKey == null &&
      state.runWeekNumber == 1 &&
      state.starCount == 0 &&
      state.heartCount == 3 &&
      state.heartCreditKcal == 0 &&
      !state.starBrokeThisWeek &&
      !state.missedTrackingThisWeek;
}
