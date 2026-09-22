import 'dart:math' as math;

import 'package:yamt/features/calories/application/burn_week_live_window_logic.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/domain/burn_week_mock_logic.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Resolves live Burn Week metrics from real diary data.
BurnWeekMockMetrics resolveBurnWeekLiveMetrics({
  required DateTime now,
  required CalorieWeekOverview weekOverview,
  required CalorieWeekDayOverview todayOverview,
  required DateTime currentWeekStartDate,
  required double previousWeekOverflowKcal,
  required double plannedLaterTodayKcal,
  required double safeZoneMultiplier,
}) {
  final dayProgress = todayOverview.isPauseDay
      ? 1.0
      : resolveBurnWeekCurrentDayProgress(now);
  final fallbackDailyGoalKcal = resolveBurnWeekMockGoalKcal(
    todayOverview.baseGoalKcal,
  );
  final visibleCurrentWeekBaseGoalKcal = weekOverview.days.fold<double>(0, (
    sum,
    day,
  ) {
    if (isBeforeBurnWeekDay(day.date, currentWeekStartDate)) {
      return sum;
    }
    return sum + day.baseGoalKcal;
  });
  final baseWeeklyGoalKcal = math.max<double>(
    fallbackDailyGoalKcal * burnWeekDaysPerWeek,
    visibleCurrentWeekBaseGoalKcal,
  );

  final currentWeekActivityBonus = weekOverview.days.fold<double>(0, (
    sum,
    day,
  ) {
    if (isBeforeBurnWeekDay(day.date, currentWeekStartDate)) {
      return sum;
    }
    return sum + day.activityBonusKcal;
  });
  final rawWeeklyGoalKcal = baseWeeklyGoalKcal + currentWeekActivityBonus;
  final adjustedWeeklyGoalKcal = math.max<double>(
    fallbackDailyGoalKcal,
    rawWeeklyGoalKcal + previousWeekOverflowKcal,
  );
  final dailyGoalKcal = adjustedWeeklyGoalKcal / burnWeekDaysPerWeek;
  final completedDaysCount = weekOverview.days
      .where(
        (day) =>
            !isBeforeBurnWeekDay(day.date, currentWeekStartDate) &&
            isBeforeBurnWeekDay(day.date, todayOverview.date),
      )
      .length;
  final elapsedWeekDays = completedDaysCount + dayProgress;
  final targetKcal = dailyGoalKcal * elapsedWeekDays;
  final actualConsumedKcal = weekOverview.days.fold<double>(0, (sum, day) {
    if (isBeforeBurnWeekDay(day.date, currentWeekStartDate)) {
      return sum;
    }
    if (isSameDiaryDay(day.date, todayOverview.date)) {
      if (day.isPauseDay) {
        return sum + day.goalKcal;
      }
      return sum + math.max<double>(0, day.totalKcal - plannedLaterTodayKcal);
    }
    return sum + day.countedTotalKcal;
  });
  final consumedKcal = actualConsumedKcal;

  return BurnWeekMockMetrics(
    dailyGoalKcal: dailyGoalKcal,
    weeklyGoalKcal: adjustedWeeklyGoalKcal,
    usesFallbackGoal: todayOverview.baseGoalKcal <= 0,
    paceRatio: (targetKcal / adjustedWeeklyGoalKcal).clamp(0.0, 1.0),
    targetKcal: targetKcal,
    consumedKcal: consumedKcal,
    actualConsumedKcal: actualConsumedKcal,
    safeZoneMinKcal: targetKcal - (dailyGoalKcal * safeZoneMultiplier),
    safeZoneMaxKcal: targetKcal + (dailyGoalKcal * safeZoneMultiplier),
    barMinKcal: 0,
    barMaxKcal: adjustedWeeklyGoalKcal,
    plannedLaterKcal: plannedLaterTodayKcal,
  );
}

/// Resolves future same-day logged kcal that should stay in shadow state.
double resolveBurnWeekPlannedLaterTodayKcal({
  required List<CalorieEntry> todayEntries,
  required DateTime now,
}) {
  return todayEntries.fold<double>(0, (sum, entry) {
    if (!entry.loggedAt.isAfter(now)) {
      return sum;
    }
    return sum + entry.totalKcal;
  });
}

/// Resolves current day progress from wall clock.
double resolveBurnWeekCurrentDayProgress(DateTime now) {
  final startOfDay = DateTime(now.year, now.month, now.day);
  final elapsedSeconds = now.difference(startOfDay).inSeconds;
  return (elapsedSeconds / (24 * 60 * 60)).clamp(0.0, 1.0);
}

/// Resolves carryover inside current Burn Week before today.
double resolveBurnWeekCarryoverBeforeTodayKcal({
  required CalorieWeekOverview weekOverview,
  required DateTime currentWeekStartDate,
  required DateTime today,
}) {
  return CalorieBudgetCalculator.calculateCarryover(
    weekOverview.days
        .where(
          (day) =>
              !isBeforeBurnWeekDay(day.date, currentWeekStartDate) &&
              isBeforeBurnWeekDay(day.date, today),
        )
        .map(
          (day) => CalorieCarryoverDay(
            goalKcal: day.baseGoalKcal,
            consumedKcal: day.countedBaseTotalKcal,
          ),
        ),
  );
}

/// Resolves overflow that should affect the current Burn Week only.
double resolveBurnWeekPreviousOverflowKcal({
  required double cycleCarryoverBeforeTodayKcal,
  required double currentWeekCarryoverBeforeTodayKcal,
  required int runWeekNumber,
}) {
  if (runWeekNumber <= burnWeekLearningRunWeekNumber) {
    return 0;
  }
  return cycleCarryoverBeforeTodayKcal - currentWeekCarryoverBeforeTodayKcal;
}

/// Formats live Burn Week label from run week and current day.
String formatBurnWeekLiveWeekDayLabel({
  required DateTime currentDay,
  required DateTime currentWeekStartDate,
  required int runWeekNumber,
  required AppLocalizations l10n,
}) {
  final dayNumber =
      normalizeDiaryDay(currentDay)
          .difference(normalizeDiaryDay(currentWeekStartDate))
          .inDays +
      1;
  return l10n.burnWeekWeekDayLabel(runWeekNumber, dayNumber);
}
