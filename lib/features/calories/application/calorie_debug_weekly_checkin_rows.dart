import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/application/calorie_debug_dump_formatting.dart';
import 'package:yamt/features/calories/application/calorie_debug_week_tdee.dart';
import 'package:yamt/features/calories/application/calorie_debug_weekly_checkin_inputs.dart';
import 'package:yamt/features/calories/application/calorie_debug_weekly_checkin_row_cells.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_window_evaluator.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_window_resolver.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';

/// Recomputes every completed weekly check-in of the active goal and
/// returns its debug rows.
Future<CalorieDebugWeeklyRowsResult> buildCalorieDebugWeeklyCheckInRows({
  required CalorieGoalSettings settings,
  required List<CalorieEntry> calorieEntries,
  required List<ManualHealthWeightEntry> manualWeightEntries,
  required List<HealthWeightSample> healthWeightSamples,
  required DateTime today,
}) async {
  final windows = resolveCalorieDebugWeeklyCheckInWindows(
    settings: settings,
    today: today,
  );
  if (windows.isEmpty) {
    return const CalorieDebugWeeklyRowsResult.empty();
  }

  final weightSeries = WeightTrendCalculator.fromSources(
    manualEntries: manualWeightEntries,
    healthSamples: healthWeightSamples,
  );
  final entriesByDay = calorieDebugEntriesByDay(calorieEntries);
  final rows = <CalorieDebugDumpRow>[];
  final learnedTdeeByWeekStart = <String, CalorieDebugWeekTdeeData>{};
  for (final window in windows) {
    final dates = resolveCalorieWeeklyCheckInWindowDates(
      settings: settings,
      pendingWeeklyCheckIn: window,
    );
    final evaluation = evaluateWeeklyCheckInWindow(
      settings: settings,
      dates: dates,
      entriesByDay: entriesByDay,
      weights: weightSeries,
    );
    final dayData = evaluation.dayData;
    final calculation = dayData.calculation;
    if (calculation == null) {
      rows.add(
        calorieDebugBlockedWeeklyCheckInRow(
          window: window,
          dates: dates,
          reason: calorieDebugBlockedReasonName(dayData.blockedReason!),
          windowDays: dayData.days,
          missingIntakeDays: dayData.missingIntakeDays,
          missingWeightDays: dayData.missingWeightDays,
        ),
      );
      continue;
    }
    final intakeKcalByDay = [
      for (final day in dayData.days) ?day.resolvedIntakeKcal,
    ];
    final weightPoints = evaluation.weightData.weightPoints;
    rows.addAll(
      calorieDebugReadyWeeklyCheckInRows(
        window: window,
        dates: dates,
        previousGoalKcal: calculation.previousGoalKcal,
        previousLearnedTdeeKcal: calculation.previousTdeeKcal,
        calculation: calculation,
        windowDays: dayData.days,
        intakeKcalByDay: intakeKcalByDay,
        weightPoints: weightPoints,
        lowConfidence: dayData.lowConfidence,
      ),
    );
    learnedTdeeByWeekStart[localDayKey(
      window.dueDate,
    )] = calorieDebugLearnedWeekTdeeData(
      window: window,
      dates: dates,
      previousGoalKcal: calculation.previousGoalKcal,
      previousLearnedTdeeKcal: calculation.previousTdeeKcal,
      calculation: calculation,
      windowDays: dayData.days,
      intakeKcalByDay: intakeKcalByDay,
      weightPoints: weightPoints,
    );
  }
  return CalorieDebugWeeklyRowsResult(
    rows: List<CalorieDebugDumpRow>.unmodifiable(rows),
    learnedTdeeByWeekStart: Map<String, CalorieDebugWeekTdeeData>.unmodifiable(
      learnedTdeeByWeekStart,
    ),
  );
}

/// The weekly check-in rows and the learned TDEE per week start.
class CalorieDebugWeeklyRowsResult {
  /// Creates a result.
  const new({required this.rows, required this.learnedTdeeByWeekStart});

  /// A result without check-ins.
  const new empty()
    : rows = const <CalorieDebugDumpRow>[],
      learnedTdeeByWeekStart = const <String, CalorieDebugWeekTdeeData>{};

  /// The weekly check-in rows.
  final List<CalorieDebugDumpRow> rows;

  /// The learned TDEE by diary day key of the week start.
  final Map<String, CalorieDebugWeekTdeeData> learnedTdeeByWeekStart;
}
