import 'dart:math' as math;

import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/daily_tdee_estimator.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// How far the goal of each day from [startDate] through the end of the
/// running week moves with the daily TDEE, by diary day key.
///
/// A day gets the change of the daily TDEE since its goal was set: the TDEE
/// known when the day starts (that of the day before, and of yesterday for
/// today and later days) minus the TDEE the goal rests on. A check-in goal
/// rests on the TDEE of its check-in; any other goal with a profile rests on
/// the TDEE of the day before it took effect, or on the calculator TDEE when
/// the daily TDEE does not reach back that far. A goal without either moves
/// nothing. Days of finished weeks keep their offset, so a budget stays what
/// it was during its week.
Map<String, double> goalTdeeOffsets({
  required CalorieGoalSettings settings,
  required DateTime startDate,
  required DateTime today,
  required Map<String, DailyTdeeEstimate> tdeeByDay,
}) {
  final normalizedToday = normalizeDiaryDay(today);
  // Without a counting goal today, no running week reaches into the future.
  final endDate = settings.countingGoalEntryForDay(normalizedToday) == null
      ? normalizedToday
      : resolveCalorieGoalRunEndDate(settings: settings, day: normalizedToday);
  final offsets = <String, double>{};
  for (
    var day = normalizeDiaryDay(startDate);
    !day.isAfter(endDate);
    day = nextDiaryDay(day)
  ) {
    if (settings.countingGoalEntryForDay(day) == null) continue;
    // Each day moves against the goal it has, also after a change mid-run.
    final entry = settings.baseGoalEntryForDay(day);
    final referenceKcal = entry == null
        ? null
        : _referenceTdeeKcal(entry, tdeeByDay);
    // A day's own intake must not raise its own goal.
    final known = previousDiaryDay(
      day.isBefore(normalizedToday) ? day : normalizedToday,
    );
    final tdeeKcal = tdeeByDay[diaryDayKey(known)]?.tdeeKcal;
    if (referenceKcal != null && tdeeKcal != null) {
      // A falling TDEE never pushes a goal under the minimum budget.
      final floorKcal = math.min<double>(
        0,
        minimumDailyCalorieBudgetKcal - (entry!.dailyKcalGoal ?? 0),
      );
      offsets[diaryDayKey(day)] = math.max(tdeeKcal - referenceKcal, floorKcal);
    }
  }
  return offsets;
}

double? _referenceTdeeKcal(
  CalorieGoalHistoryEntry entry,
  Map<String, DailyTdeeEstimate> tdeeByDay,
) {
  final checkInTdee = entry.weeklyCheckInSnapshot?.calculatedTdeeKcal ?? 0;
  if (checkInTdee > 0) return checkInTdee;
  final profile = entry.calculatorProfile;
  if (profile == null) return null;
  return tdeeByDay[diaryDayKey(previousDiaryDay(entry.effectiveDate))]
          ?.tdeeKcal ??
      CalorieGoalCalculator.calculate(profile).tdeeKcal;
}
