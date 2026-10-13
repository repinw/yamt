import 'dart:math' as math;

import 'package:yamt/features/calories/domain/calorie_carryover_history.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_window_resolver.dart';
import 'package:yamt/features/calories/domain/daily_tdee_estimator.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';

/// Runs the [DailyTdeeEstimator] over loaded diary entries and weights.
abstract final class DailyTdeeSeries {
  /// First day of the daily TDEE: the earliest first-window day of a goal
  /// that is set and counting on or before [day], or `null` without one.
  static DateTime? startDay(CalorieGoalSettings settings, DateTime day) {
    final normalizedDay = normalizeDiaryDay(day);
    DateTime? earliest;
    for (final entry in settings.sortedGoalHistory) {
      if (entry.effectiveDate.isAfter(normalizedDay)) break;
      if (!entry.hasGoal || entry.isWeeklyCheckIn) continue;
      final start = CalorieWeeklyWindowResolver.firstWindowStartDate(entry);
      if (start.isAfter(normalizedDay)) continue;
      if (earliest == null || start.isBefore(earliest)) earliest = start;
    }
    return earliest;
  }

  /// Runs the daily TDEE estimator from [startDate] through [endDate].
  ///
  /// Pause days count as days without intake. Today and later days keep
  /// yesterday's estimate, because today's diary is not complete yet. It
  /// starts from the calculator TDEE of [startDate].
  static Map<String, DailyTdeeEstimate> estimate({
    required DateTime startDate,
    required DateTime endDate,
    required DateTime today,
    required CalorieGoalSettings settings,
    required Map<String, List<CalorieEntry>> entriesByDay,
    required DailyWeightSeries weights,
  }) {
    final days = buildCalorieCarryoverDateRange(
      startInclusive: startDate,
      endExclusive: nextDiaryDay(endDate),
    );
    final start = _seedAndFloor(settings, startDate);
    final estimates = DailyTdeeEstimator.estimate(
      seedKcal: start.seedKcal,
      floorKcal: start.floorKcal,
      days: [
        for (final day in days.where((day) => day.isBefore(today)))
          (
            intakeKcal: settings.isPauseDay(day)
                ? null
                : entriesByDay[diaryDayKey(day)]?.fold<double>(
                    0,
                    (sum, entry) => sum + entry.totalKcal,
                  ),
            weightKg: weights.rawByDay[diaryDayKey(day)],
          ),
      ],
    );
    return {
      for (final (index, day) in days.indexed)
        if (estimates.isNotEmpty)
          diaryDayKey(day): index < estimates.length
              ? estimates[index]
              : DailyTdeeEstimate(
                  tdeeKcal: estimates.last.tdeeKcal,
                  measuredTdeeKcal: null,
                  trendKgPerDay: estimates.last.trendKgPerDay,
                  isHolding: estimates.last.isHolding,
                ),
    };
  }

  /// The TDEE the daily estimate starts from on [day]: the calculator TDEE,
  /// or the goal without a profile, never below the floor.
  static double startTdeeKcal(CalorieGoalSettings settings, DateTime day) {
    final start = _seedAndFloor(settings, day);
    return math.max(start.seedKcal, start.floorKcal);
  }

  /// The seed is the calculator TDEE of [day], or the goal without a
  /// profile; the floor is max(750, 0.85 x BMR).
  static ({double seedKcal, double floorKcal}) _seedAndFloor(
    CalorieGoalSettings settings,
    DateTime day,
  ) {
    final profile = CalorieWeeklyWindowResolver.calculatorProfileForDay(
      settings: settings,
      day: day,
    );
    if (profile == null) {
      return (seedKcal: settings.goalKcalForDay(day), floorKcal: 750);
    }
    final calculation = CalorieGoalCalculator.calculate(profile);
    return (
      seedKcal: calculation.tdeeKcal,
      floorKcal: math.max(750, 0.85 * calculation.bmrKcal),
    );
  }
}
