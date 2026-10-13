import 'package:yamt/features/calories/application/calorie_debug_dump_formatting.dart';
import 'package:yamt/features/calories/application/calorie_debug_week_tdee.dart';
import 'package:yamt/features/calories/application/calorie_debug_weekly_checkin_inputs.dart';
import 'package:yamt/features/calories/application/calorie_debug_weekly_checkin_row_cells.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_daily_tdee.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_intake_resolver.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_weight_resolver.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_window_resolver.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin_weight_point.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';

/// Recomputes every completed weekly check-in of the active goal and
/// returns its debug rows.
Future<CalorieDebugWeeklyRowsResult> buildCalorieDebugWeeklyCheckInRows({
  required CalorieGoalSettings settings,
  required List<CalorieEntry> calorieEntries,
  required List<ManualHealthWeightEntry> manualWeightEntries,
  required HealthConnectionStatus healthStatus,
  required HealthWeightService healthWeightService,
  required DateTime today,
}) async {
  final windows = resolveCalorieDebugWeeklyCheckInWindows(
    settings: settings,
    today: today,
  );
  if (windows.isEmpty) {
    return const CalorieDebugWeeklyRowsResult.empty();
  }

  final datesByWindow =
      <PendingCalorieGoalWeeklyCheckIn, CalorieWeeklyCheckInWindowDates>{};
  for (final window in windows) {
    datesByWindow[window] = resolveCalorieWeeklyCheckInWindowDates(
      settings: settings,
      pendingWeeklyCheckIn: window,
    );
  }
  final entriesByDay = calorieDebugEntriesByDay(calorieEntries);
  final healthWeightSamples = await loadCalorieDebugWeeklyHealthWeights(
    settings: settings,
    datesByWindow: datesByWindow.values,
    windows: windows,
    healthStatus: healthStatus,
    healthWeightService: healthWeightService,
  );
  final weightSeries = WeightTrendCalculator.fromSources(
    manualEntries: manualWeightEntries,
    healthSamples: healthWeightSamples,
  );

  // One daily TDEE run serves every window.
  final dailyTdee = weeklyCheckInDailyTdee(
    settings: settings,
    learningStartDate: datesByWindow.values
        .map((dates) => dates.learningStartDate)
        .reduce((a, b) => a.isBefore(b) ? a : b),
    endDate: windows.last.windowEndDate,
    entriesByDay: entriesByDay,
    weights: weightSeries,
  );
  final rows = <CalorieDebugDumpRow>[];
  final learnedTdeeByWeekStart = <String, CalorieDebugWeekTdeeData>{};
  for (final window in windows) {
    final result = _weeklyCheckInRow(
      settings: settings,
      window: window,
      dates: datesByWindow[window]!,
      entriesByDay: entriesByDay,
      weights: weightSeries,
      dailyTdee: dailyTdee,
    );
    rows.addAll(result.rows);
    final calculation = result.calculation;
    if (calculation != null) {
      learnedTdeeByWeekStart[diaryDayKey(
        window.dueDate,
      )] = calorieDebugLearnedWeekTdeeData(
        window: window,
        dates: datesByWindow[window]!,
        previousGoalKcal: calculation.previousGoalKcal,
        previousLearnedTdeeKcal: calculation.previousTdeeKcal,
        calculation: calculation,
        windowDays: result.windowDays,
        intakeKcalByDay: result.intakeKcalByDay,
        weightPoints: result.weightPoints,
      );
    }
  }
  return CalorieDebugWeeklyRowsResult(
    rows: List<CalorieDebugDumpRow>.unmodifiable(rows),
    learnedTdeeByWeekStart: Map<String, CalorieDebugWeekTdeeData>.unmodifiable(
      learnedTdeeByWeekStart,
    ),
  );
}

_DebugWeeklyRowResult _weeklyCheckInRow({
  required CalorieGoalSettings settings,
  required PendingCalorieGoalWeeklyCheckIn window,
  required CalorieWeeklyCheckInWindowDates dates,
  required Map<String, List<CalorieEntry>> entriesByDay,
  required DailyWeightSeries weights,
  required WeeklyCheckInDailyTdee dailyTdee,
}) {
  final weightData = mergeWeeklyCheckInWeights(
    dates: dates,
    anchorEntry: dates.anchorEntry,
    dailyWeightByDay: weights.rawByDay,
  );
  final windowIntake = resolveWeeklyWindowIntakeData(
    days: dates.windowDays,
    calorieEntriesByDay: entriesByDay,
    settings: settings,
    weightByDay: weightData.weightByDay,
  );
  final blockedWindowReason = windowIntake.blockedReason;
  if (blockedWindowReason != null) {
    return _DebugWeeklyRowResult(
      rows: [
        calorieDebugBlockedWeeklyCheckInRow(
          window: window,
          dates: dates,
          reason: calorieDebugBlockedReasonName(blockedWindowReason),
          windowDays: windowIntake.days,
          missingIntakeDays: windowIntake.missingIntakeDays,
          missingWeightDays: const <DateTime>[],
        ),
      ],
      calculation: null,
      windowDays: windowIntake.days,
      intakeKcalByDay: const <double>[],
      weightPoints: const <CalorieWeeklyCheckInWeightPoint>[],
    );
  }

  final intakeKcalByDay = [
    for (final day in windowIntake.days) ?day.resolvedIntakeKcal,
  ];
  final missingWeight = validateCalorieDebugWeeklyWeightData(
    dates: dates,
    weightData: weightData,
  );
  if (missingWeight != null) {
    return _DebugWeeklyRowResult(
      rows: [
        calorieDebugBlockedWeeklyCheckInRow(
          window: window,
          dates: dates,
          reason: missingWeight.reason,
          windowDays: windowIntake.days,
          missingIntakeDays: windowIntake.missingIntakeDays,
          missingWeightDays: missingWeight.missingWeightDays,
        ),
      ],
      calculation: null,
      windowDays: windowIntake.days,
      intakeKcalByDay: intakeKcalByDay,
      weightPoints: weightData.weightPoints,
    );
  }

  final calculation = calculateWeeklyCheckInFromDailyTdee(
    settings: settings,
    window: window,
    dailyTdee: dailyTdee,
    windowDays: windowIntake.days,
  );
  return _DebugWeeklyRowResult(
    rows: calorieDebugReadyWeeklyCheckInRows(
      window: window,
      dates: dates,
      previousGoalKcal: calculation.previousGoalKcal,
      previousLearnedTdeeKcal: calculation.previousTdeeKcal,
      calculation: calculation,
      windowDays: windowIntake.days,
      intakeKcalByDay: intakeKcalByDay,
      weightPoints: weightData.weightPoints,
    ),
    calculation: calculation,
    windowDays: windowIntake.days,
    intakeKcalByDay: intakeKcalByDay,
    weightPoints: weightData.weightPoints,
  );
}

class _DebugWeeklyRowResult {
  const new({
    required this.rows,
    required this.calculation,
    required this.windowDays,
    required this.intakeKcalByDay,
    required this.weightPoints,
  });

  final List<CalorieDebugDumpRow> rows;
  final CalorieWeeklyCheckInCalculation? calculation;
  final List<CalorieWeeklyCheckInWindowDay> windowDays;
  final List<double> intakeKcalByDay;
  final List<CalorieWeeklyCheckInWeightPoint> weightPoints;
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
