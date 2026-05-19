import 'dart:math' as math;

import 'package:yamt/features/calories/application/burn_week_live_overview_logic.dart';
import 'package:yamt/features/calories/domain/burn_week_mock_logic.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/'
    'diary_daily_balance_metrics.dart';

/// Derived values for the weekly Burn Week pacing card.
class DiaryWeeklyBalanceMetrics {
  /// Creates weekly balance metrics.
  const DiaryWeeklyBalanceMetrics({
    required this.pacing,
    required this.targetKcal,
    required this.goalKcal,
    required this.progressDay,
    this.totalDays = burnWeekDaysPerWeek,
  });

  /// Burn Week progress-bar metrics.
  final BurnWeekMockMetrics pacing;

  /// Stable pacing target used for the visual marker.
  final double targetKcal;

  /// Stable weekly maximum used for the visual scale.
  final double goalKcal;

  /// Current day number within the displayed week.
  final int progressDay;

  /// Total days in a Burn Week.
  final int totalDays;
}

/// Resolves weekly pacing metrics for the diary balance card.
DiaryWeeklyBalanceMetrics resolveDiaryWeeklyBalanceMetrics({
  required CalorieWeekOverview weekOverview,
  required CalorieWeekDayOverview selectedDayOverview,
  required List<CalorieEntry> selectedDayEntries,
  required DateTime currentWeekStartDate,
  required BurnWeekRunState runState,
  required DateTime now,
}) {
  final pacing = _resolveBurnWeekMetrics(
    weekOverview: weekOverview,
    selectedDayOverview: selectedDayOverview,
    selectedDayEntries: selectedDayEntries,
    currentWeekStartDate: currentWeekStartDate,
    runState: runState,
    now: now,
  );
  final weeklyGoalKcal = _resolveProgressWeeklyGoalKcal(
    weekOverview: weekOverview,
    selectedDayOverview: selectedDayOverview,
    currentWeekStartDate: currentWeekStartDate,
  );
  final displayWeeklyGoalKcal = _resolveDisplayWeeklyGoalKcal(
    baseWeeklyGoalKcal: weeklyGoalKcal,
    actualConsumedKcal: pacing.actualConsumedKcal,
    selectedDayTargetKcal: resolveDiaryDailyTargetKcal(
      flexibleGoalKcal: weekOverview.todayFlexibleGoalKcal,
      goalKcal: selectedDayOverview.goalKcal,
      baseGoalKcal: selectedDayOverview.baseGoalKcal,
      activitySegmentKcal: selectedDayOverview.activityBonusKcal,
    ),
    selectedDayTotalKcal: selectedDayOverview.totalKcal,
  );

  return DiaryWeeklyBalanceMetrics(
    pacing: pacing,
    targetKcal: displayWeeklyGoalKcal * pacing.paceRatio,
    goalKcal: displayWeeklyGoalKcal,
    progressDay: resolveDiaryWeeklyProgressDay(
      selectedDay: selectedDayOverview.date,
      currentWeekStartDate: currentWeekStartDate,
    ),
  );
}

double _resolveDisplayWeeklyGoalKcal({
  required double baseWeeklyGoalKcal,
  required double actualConsumedKcal,
  required double selectedDayTargetKcal,
  required double selectedDayTotalKcal,
}) {
  final selectedDayLeftKcal = selectedDayTargetKcal - selectedDayTotalKcal;
  if (selectedDayLeftKcal <= 0) {
    return baseWeeklyGoalKcal;
  }

  return math.max<double>(
    baseWeeklyGoalKcal,
    actualConsumedKcal + selectedDayLeftKcal,
  );
}

/// Resolves the clamped day number for the weekly pacing label.
int resolveDiaryWeeklyProgressDay({
  required DateTime selectedDay,
  required DateTime currentWeekStartDate,
}) {
  final currentWeekDay =
      selectedDay.difference(currentWeekStartDate).inDays + 1;
  if (currentWeekDay < 1) {
    return 1;
  }
  if (currentWeekDay > burnWeekDaysPerWeek) {
    return burnWeekDaysPerWeek;
  }
  return currentWeekDay;
}

double _resolveProgressWeeklyGoalKcal({
  required CalorieWeekOverview weekOverview,
  required CalorieWeekDayOverview selectedDayOverview,
  required DateTime currentWeekStartDate,
}) {
  final fallbackDailyGoalKcal = resolveBurnWeekMockGoalKcal(
    selectedDayOverview.baseGoalKcal,
  );
  final visibleCurrentWeekBaseGoalKcal = weekOverview.days.fold<double>(
    0,
    (sum, day) {
      if (isBeforeBurnWeekDay(day.date, currentWeekStartDate)) {
        return sum;
      }
      return sum + day.baseGoalKcal;
    },
  );

  return math.max<double>(
    fallbackDailyGoalKcal * burnWeekDaysPerWeek,
    visibleCurrentWeekBaseGoalKcal,
  );
}

BurnWeekMockMetrics _resolveBurnWeekMetrics({
  required CalorieWeekOverview weekOverview,
  required CalorieWeekDayOverview selectedDayOverview,
  required List<CalorieEntry> selectedDayEntries,
  required DateTime currentWeekStartDate,
  required BurnWeekRunState runState,
  required DateTime now,
}) {
  final weekCarryoverBeforeTodayKcal = resolveBurnWeekCarryoverBeforeTodayKcal(
    weekOverview: weekOverview,
    currentWeekStartDate: currentWeekStartDate,
    today: selectedDayOverview.date,
  );
  final previousWeekOverflowKcal = resolveBurnWeekPreviousOverflowKcal(
    cycleCarryoverBeforeTodayKcal: weekOverview.carryoverBeforeTodayKcal,
    currentWeekCarryoverBeforeTodayKcal: weekCarryoverBeforeTodayKcal,
    runWeekNumber: runState.runWeekNumber,
  );
  final difficulty = resolveBurnWeekMockDifficulty(runState.starCount);
  final plannedLaterTodayKcal = isSameDiaryDay(selectedDayOverview.date, now)
      ? resolveBurnWeekPlannedLaterTodayKcal(
          todayEntries: selectedDayEntries,
          now: now,
        )
      : 0.0;

  return resolveBurnWeekLiveMetrics(
    now: _referenceNowForDay(selectedDayOverview.date, now),
    weekOverview: weekOverview,
    todayOverview: selectedDayOverview,
    currentWeekStartDate: currentWeekStartDate,
    previousWeekOverflowKcal: previousWeekOverflowKcal,
    heartCreditKcal: runState.heartCreditKcal,
    plannedLaterTodayKcal: plannedLaterTodayKcal,
    safeZoneMultiplier: difficulty.safeZoneMultiplier,
  );
}

DateTime _referenceNowForDay(DateTime day, DateTime now) {
  final today = normalizeDiaryDay(now);
  final normalizedSelectedDay = normalizeDiaryDay(day);
  if (normalizedSelectedDay.isBefore(today)) {
    return DateTime(day.year, day.month, day.day, 23, 59, 59);
  }
  if (normalizedSelectedDay.isAfter(today)) {
    return normalizeDiaryDay(day);
  }

  return now;
}
