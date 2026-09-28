import 'package:yamt/features/calories/application/calorie_debug_dump_formatting.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart'
    show CalorieCalculatorProfile;
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';

/// The TDEE of a goal week, its source, and the inputs it used.
class CalorieDebugWeekTdeeData {
  /// Creates week TDEE data.
  const new({required this.source, required this.tdeeKcal, required this.used});

  /// Where the TDEE comes from.
  final String source;

  /// The TDEE in kcal.
  final double tdeeKcal;

  /// The inputs that produced it.
  final String used;
}

/// The TDEE a goal week starts with and where it comes from.
CalorieDebugWeekTdeeData resolveCalorieDebugWeekTdeeData({
  required CalorieGoalSettings settings,
  required CalorieGoalHistoryEntry goalEntry,
  required DateTime weekStart,
  required Map<String, CalorieDebugWeekTdeeData> learnedTdeeByWeekStart,
}) {
  final calculatedLearnedTdee = learnedTdeeByWeekStart[diaryDayKey(weekStart)];
  if (calculatedLearnedTdee != null) {
    return calculatedLearnedTdee;
  }

  final learnedEntry = settings.learnedTdeeEntryForDay(weekStart);
  final learnedSnapshot = learnedEntry?.learnedTdeeSnapshot;
  if (learnedEntry != null &&
      learnedSnapshot != null &&
      !learnedEntry.effectiveDate.isBefore(
        normalizeDiaryDay(goalEntry.effectiveCountingStartDate),
      )) {
    final snapshotWindow =
        '${diaryDayKey(learnedSnapshot.windowStartDate)}'
        '..${diaryDayKey(learnedSnapshot.windowEndDate)}';
    final measuredTotalTdee = formatCalorieDebugNumber(
      learnedSnapshot.measuredTdeeKcal,
    );
    final newTarget = formatCalorieDebugNumber(learnedSnapshot.baseGoalKcal);
    final trendPerDay = learnedSnapshot.trendWeightChangePerDay.toStringAsFixed(
      5,
    );
    return CalorieDebugWeekTdeeData(
      source: 'learned_tdee',
      tdeeKcal: learnedSnapshot.calculatedTdeeKcal,
      used: [
        'snapshot_window=$snapshotWindow',
        'measured_total_tdee=$measuredTotalTdee',
        'new_target=$newTarget',
        'trend_kg_per_day=$trendPerDay',
      ].join(','),
    );
  }

  final profile = goalEntry.calculatorProfile ?? settings.calculatorProfile;
  if (profile != null) {
    final calculation = CalorieGoalCalculator.calculate(profile);
    return CalorieDebugWeekTdeeData(
      source: 'calculator_profile',
      tdeeKcal: calculation.tdeeKcal,
      used: _calculatorProfileUsedText(
        profile: profile,
        calculation: calculation,
      ),
    );
  }

  final dailyGoal =
      goalEntry.dailyKcalGoal ?? settings.goalKcalForDay(weekStart);
  return CalorieDebugWeekTdeeData(
    source: 'manual_goal',
    tdeeKcal: dailyGoal,
    used: 'daily_goal=${formatCalorieDebugNumber(dailyGoal)}',
  );
}

String _calculatorProfileUsedText({
  required CalorieCalculatorProfile profile,
  required CalorieGoalCalculationResult calculation,
}) {
  return [
    'sex=${profile.sex.name}',
    'weight_kg=${formatCalorieDebugNumber(profile.weightKg)}',
    'height_cm=${formatCalorieDebugNumber(profile.heightCm)}',
    'age_years=${profile.ageYears}',
    'activity_level=${formatCalorieDebugNumber(profile.activityLevel)}',
    'goal_mode=${profile.goalMode.name}',
    calorieDebugNamedNumber(
      'goal_speed_kg_per_week',
      profile.goalSpeedKgPerWeek,
    ),
    'bmr=${formatCalorieDebugNumber(calculation.bmrKcal)}',
    calorieDebugNamedNumber(
      'daily_adjustment',
      calculation.dailyAdjustmentKcal,
    ),
    'final_goal=${formatCalorieDebugNumber(calculation.finalGoalKcal)}',
  ].join(',');
}

/// The learned TDEE a check-in window hands to the next week.
CalorieDebugWeekTdeeData calorieDebugLearnedWeekTdeeData({
  required PendingCalorieGoalWeeklyCheckIn window,
  required CalorieWeeklyCheckInWindowDates dates,
  required double previousGoalKcal,
  required double previousLearnedTdeeKcal,
  required CalorieWeeklyCheckInCalculation calculation,
  required List<CalorieWeeklyCheckInWindowDay> windowDays,
  required List<double> intakeKcalByDay,
  required List<CalorieWeeklyCheckInWeightPoint> weightPoints,
}) {
  final weightTrend = calorieDebugWeightTrend(weightPoints: weightPoints);
  final calculatedWindow =
      '${diaryDayKey(window.windowStartDate)}'
      '..${diaryDayKey(window.windowEndDate)}';
  final learningWindow =
      '${diaryDayKey(dates.learningStartDate)}'
      '..${diaryDayKey(window.windowEndDate)}';
  final trendPerDay = calculation.trendWeightChangePerDay.toStringAsFixed(5);

  return CalorieDebugWeekTdeeData(
    source: 'learned_tdee',
    tdeeKcal: calculation.calculatedTdeeKcal,
    used: [
      'calculated_from_window=$calculatedWindow',
      'learning_window=$learningWindow',
      calorieDebugNamedNumber('previous_goal', previousGoalKcal),
      calorieDebugNamedNumber('previous_learned_tdee', previousLearnedTdeeKcal),
      calorieDebugNamedNumber('average_eaten', calculation.averageIntakeKcal),
      calorieDebugNamedNumber('measured_tdee', calculation.measuredTdeeKcal),
      calorieDebugNamedNumber('smoothed_tdee', calculation.calculatedTdeeKcal),
      calorieDebugNamedNumber('new_target', calculation.newGoalKcal),
      calorieDebugNamedNumber('start_weight', weightTrend.startWeightKg),
      calorieDebugNamedNumber('end_weight', weightTrend.endWeightKg),
      calorieDebugNamedNumber('weight_change', weightTrend.weightChangeKg),
      'trend_kg_per_day=$trendPerDay',
      'intake=[${formatCalorieDebugDoubleList(intakeKcalByDay)}]',
    ].join(','),
  );
}
