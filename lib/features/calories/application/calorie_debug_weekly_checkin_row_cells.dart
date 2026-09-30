import 'package:yamt/features/calories/application/calorie_debug_dump_formatting.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin_weight_point.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';

/// The five rows of a ready weekly check-in.
List<CalorieDebugDumpRow> calorieDebugReadyWeeklyCheckInRows({
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
  return [
    _readyWeeklyCheckInSummaryRow(
      window: window,
      dates: dates,
      previousGoalKcal: previousGoalKcal,
      previousLearnedTdeeKcal: previousLearnedTdeeKcal,
      calculation: calculation,
      windowDays: windowDays,
      intakeKcalByDay: intakeKcalByDay,
      weightPoints: weightPoints,
      order: 0,
    ),
    _plannedVsEatenWeeklyRow(
      window: window,
      dates: dates,
      previousGoalKcal: previousGoalKcal,
      windowDays: windowDays,
      order: 1,
    ),
    _weightTrendWeeklyRow(
      window: window,
      dates: dates,
      calculation: calculation,
      weightTrend: weightTrend,
      weightPoints: weightPoints,
      order: 2,
    ),
    _measuredTotalTdeeWeeklyRow(
      window: window,
      dates: dates,
      calculation: calculation,
      intakeKcalByDay: intakeKcalByDay,
      order: 3,
    ),
    _newTargetWeeklyRow(
      window: window,
      dates: dates,
      previousLearnedTdeeKcal: previousLearnedTdeeKcal,
      calculation: calculation,
      order: 4,
    ),
  ];
}

CalorieDebugDumpRow _readyWeeklyCheckInSummaryRow({
  required PendingCalorieGoalWeeklyCheckIn window,
  required CalorieWeeklyCheckInWindowDates dates,
  required double previousGoalKcal,
  required double previousLearnedTdeeKcal,
  required CalorieWeeklyCheckInCalculation calculation,
  required List<CalorieWeeklyCheckInWindowDay> windowDays,
  required List<double> intakeKcalByDay,
  required List<CalorieWeeklyCheckInWeightPoint> weightPoints,
  required int order,
}) {
  final trendWeightChangePerDay = calculation.trendWeightChangePerDay
      .toStringAsFixed(5);
  return _weeklyRow(
    window: window,
    name: 'learned_tdee',
    kcal: calculation.calculatedTdeeKcal,
    order: order,
    extra: [
      calorieDebugWindowExtra(window, dates),
      calorieDebugNamedNumber('previous_goal', previousGoalKcal),
      calorieDebugNamedNumber('previous_learned_tdee', previousLearnedTdeeKcal),
      'trend_kg_per_day=$trendWeightChangePerDay',
      calorieDebugNamedNumber('average_intake', calculation.averageIntakeKcal),
      calorieDebugNamedNumber('measured_tdee', calculation.measuredTdeeKcal),
      calorieDebugNamedNumber('learned_tdee', calculation.calculatedTdeeKcal),
      calorieDebugNamedNumber('new_target', calculation.newGoalKcal),
      'low_confidence=${weightPoints.length <= 2}',
      'intake=[${formatCalorieDebugDoubleList(intakeKcalByDay)}]',
      'weight_points=[${formatCalorieDebugWeightPoints(weightPoints)}]',
      'days=[${formatCalorieDebugWindowDays(windowDays)}]',
    ].join('; '),
  );
}

CalorieDebugDumpRow _plannedVsEatenWeeklyRow({
  required PendingCalorieGoalWeeklyCheckIn window,
  required CalorieWeeklyCheckInWindowDates dates,
  required double previousGoalKcal,
  required List<CalorieWeeklyCheckInWindowDay> windowDays,
  required int order,
}) {
  final plannedTotalKcal = previousGoalKcal * windowDays.length;
  final eatenTotalKcal = _windowEatenTotalKcal(windowDays);

  return _weeklyRow(
    window: window,
    name: 'planned_vs_eaten',
    kcal: eatenTotalKcal,
    order: order,
    extra: [
      calorieDebugWindowExtra(window, dates),
      calorieDebugNamedNumber('planned_daily', previousGoalKcal),
      calorieDebugNamedNumber('planned_total', plannedTotalKcal),
      calorieDebugNamedNumber('eaten_total', eatenTotalKcal),
      calorieDebugNamedNumber(
        'eaten_daily_avg',
        eatenTotalKcal / windowDays.length,
      ),
      calorieDebugNamedNumber(
        'eaten_minus_planned',
        eatenTotalKcal - plannedTotalKcal,
      ),
      'days=[${formatCalorieDebugWindowDays(windowDays)}]',
    ].join('; '),
  );
}

CalorieDebugDumpRow _weightTrendWeeklyRow({
  required PendingCalorieGoalWeeklyCheckIn window,
  required CalorieWeeklyCheckInWindowDates dates,
  required CalorieWeeklyCheckInCalculation calculation,
  required CalorieDebugWeightTrend weightTrend,
  required List<CalorieWeeklyCheckInWeightPoint> weightPoints,
  required int order,
}) {
  final trendPerDay = calculation.trendWeightChangePerDay.toStringAsFixed(5);
  return _weeklyRow(
    window: window,
    name: 'weight_trend',
    kcal: null,
    order: order,
    extra: [
      calorieDebugWindowExtra(window, dates),
      calorieDebugNamedNumber('start_weight', weightTrend.startWeightKg),
      calorieDebugNamedNumber('end_weight', weightTrend.endWeightKg),
      calorieDebugNamedNumber('weight_change', weightTrend.weightChangeKg),
      'trend_kg_per_day=$trendPerDay',
      calorieDebugNamedNumber(
        'trend_kg_per_week',
        calculation.trendWeightChangePerDay * 7,
      ),
      'low_confidence=${weightPoints.length <= 2}',
      'weight_points=[${formatCalorieDebugWeightPoints(weightPoints)}]',
    ].join('; '),
  );
}

CalorieDebugDumpRow _measuredTotalTdeeWeeklyRow({
  required PendingCalorieGoalWeeklyCheckIn window,
  required CalorieWeeklyCheckInWindowDates dates,
  required CalorieWeeklyCheckInCalculation calculation,
  required List<double> intakeKcalByDay,
  required int order,
}) {
  final weightStorageKcalPerDay =
      calculation.averageIntakeKcal - calculation.measuredTdeeKcal;

  return _weeklyRow(
    window: window,
    name: 'measured_total_tdee',
    kcal: calculation.measuredTdeeKcal,
    order: order,
    extra: [
      calorieDebugWindowExtra(window, dates),
      'formula=average_eaten - weight_storage_per_day',
      calorieDebugNamedNumber('average_eaten', calculation.averageIntakeKcal),
      calorieDebugNamedNumber(
        'weight_storage_per_day',
        weightStorageKcalPerDay,
      ),
      calorieDebugNamedNumber(
        'measured_total_tdee',
        calculation.measuredTdeeKcal,
      ),
      'learning_intake=[${formatCalorieDebugDoubleList(intakeKcalByDay)}]',
    ].join('; '),
  );
}

CalorieDebugDumpRow _newTargetWeeklyRow({
  required PendingCalorieGoalWeeklyCheckIn window,
  required CalorieWeeklyCheckInWindowDates dates,
  required double previousLearnedTdeeKcal,
  required CalorieWeeklyCheckInCalculation calculation,
  required int order,
}) {
  return _weeklyRow(
    window: window,
    name: 'new_target',
    kcal: calculation.newGoalKcal,
    order: order,
    extra: [
      calorieDebugWindowExtra(window, dates),
      calorieDebugNamedNumber('previous_learned_tdee', previousLearnedTdeeKcal),
      calorieDebugNamedNumber('smoothed_tdee', calculation.calculatedTdeeKcal),
      calorieDebugNamedNumber('new_target', calculation.newGoalKcal),
    ].join('; '),
  );
}

/// The row of a blocked weekly check-in.
CalorieDebugDumpRow calorieDebugBlockedWeeklyCheckInRow({
  required PendingCalorieGoalWeeklyCheckIn window,
  required CalorieWeeklyCheckInWindowDates dates,
  required String reason,
  required List<CalorieWeeklyCheckInWindowDay> windowDays,
  required List<DateTime> missingIntakeDays,
  required List<DateTime> missingWeightDays,
}) {
  return _weeklyRow(
    window: window,
    name: 'blocked',
    kcal: null,
    extra: [
      calorieDebugWindowExtra(window, dates),
      'blocked=$reason',
      'missing_intake=[${formatCalorieDebugDayKeys(missingIntakeDays)}]',
      'missing_weight=[${formatCalorieDebugDayKeys(missingWeightDays)}]',
      'days=[${formatCalorieDebugWindowDays(windowDays)}]',
    ].join('; '),
  );
}

CalorieDebugDumpRow _weeklyRow({
  required PendingCalorieGoalWeeklyCheckIn window,
  required String name,
  required double? kcal,
  required String extra,
  int order = 0,
}) {
  final sortAt = window.windowEndDate.add(
    const Duration(hours: 23, minutes: 59, seconds: 59),
  );
  return CalorieDebugDumpRow(
    sortAt: sortAt,
    typeOrder: 90 + order,
    cells: [
      formatCalorieDebugDay(sortAt),
      formatCalorieDebugTime(sortAt),
      'weekly_checkin',
      name,
      formatCalorieDebugNumber(kcal),
      '',
      '',
      '',
      '',
      '',
      '',
      'app',
      extra,
    ],
  );
}

double _windowEatenTotalKcal(List<CalorieWeeklyCheckInWindowDay> days) {
  return days.fold<double>(
    0,
    (sum, day) => sum + (day.resolvedIntakeKcal ?? day.loggedIntakeKcal),
  );
}
