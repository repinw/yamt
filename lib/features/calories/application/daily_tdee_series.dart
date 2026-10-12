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
  /// Runs the daily TDEE estimator from [startDate] through [endDate].
  ///
  /// Pause days count as days without intake. Today and later days keep
  /// yesterday's estimate, because today's diary is not complete yet. The
  /// seed is the calculator TDEE of [startDate]; the floor is
  /// max(750, 0.85 x BMR).
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
    final profile = CalorieWeeklyWindowResolver.calculatorProfileForDay(
      settings: settings,
      day: startDate,
    );
    final bmrKcal = profile == null
        ? 0.0
        : CalorieGoalCalculator.calculate(profile).bmrKcal;
    final estimates = DailyTdeeEstimator.estimate(
      seedKcal: seedTdeeKcal(
        settings: settings,
        day: startDate,
        fallbackGoalKcal: settings.goalKcalForDay(startDate),
      ),
      floorKcal: math.max(750, 0.85 * bmrKcal),
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
                  isHolding: estimates.last.isHolding,
                ),
    };
  }

  /// The calculator TDEE of [day], or [fallbackGoalKcal] without a profile.
  static double seedTdeeKcal({
    required CalorieGoalSettings settings,
    required DateTime day,
    required double fallbackGoalKcal,
  }) {
    final calculatorProfile =
        CalorieWeeklyWindowResolver.calculatorProfileForDay(
          settings: settings,
          day: day,
        );
    if (calculatorProfile == null) {
      return fallbackGoalKcal;
    }
    return CalorieGoalCalculator.calculate(calculatorProfile).tdeeKcal;
  }
}
