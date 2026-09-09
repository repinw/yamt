// Debug weekly helpers are public only for file splitting.
// ignore_for_file: public_member_api_docs

import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_intake_resolver.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_weight_resolver.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_window_resolver.dart';
import 'package:yamt/features/calories/debug/calorie_debug_dump_formatting.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart'
    show CalorieGoalMode;
import 'package:yamt/features/calories/domain/calorie_domain_math.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_window_resolver.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

Future<CalorieDebugWeeklyRowsResult> buildCalorieDebugWeeklyCheckInRows({
  required CalorieGoalSettings settings,
  required List<CalorieEntry> calorieEntries,
  required List<ManualHealthWeightEntry> manualWeightEntries,
  required HealthConnectionStatus healthStatus,
  required HealthWeightService healthWeightService,
  required DateTime today,
}) async {
  final windows = _resolveDebugWeeklyCheckInWindows(
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
  final entriesByDay = _calorieEntriesByDay(calorieEntries);
  final manualWeightsByDay = manualWeightByDay(manualWeightEntries);
  final healthData = await _loadDebugWeeklyHealthData(
    settings: settings,
    datesByWindow: datesByWindow.values,
    windows: windows,
    healthStatus: healthStatus,
    healthWeightService: healthWeightService,
  );

  var previousGoalKcal = settings.baseGoalKcalForDay(
    windows.first.windowEndDate,
  );
  var previousLearnedTdeeKcal = _previousLearnedTdeeKcalBeforeDay(
    settings: settings,
    day: windows.first.windowStartDate,
    fallbackDay: windows.first.windowEndDate,
  );
  final rows = <CalorieDebugDumpRow>[];
  final learnedTdeeByWeekStart = <String, CalorieDebugWeekTdeeData>{};
  for (final window in windows) {
    final result = _weeklyCheckInRow(
      settings: settings,
      window: window,
      dates: datesByWindow[window]!,
      entriesByDay: entriesByDay,
      manualWeightByDay: manualWeightsByDay,
      healthData: healthData,
      previousGoalKcal: previousGoalKcal,
      previousLearnedTdeeKcal: previousLearnedTdeeKcal,
    );
    rows.addAll(result.rows);
    final calculation = result.calculation;
    if (calculation != null) {
      learnedTdeeByWeekStart[diaryDayKey(
        window.dueDate,
      )] = _learnedWeekStartTdeeData(
        window: window,
        dates: datesByWindow[window]!,
        previousGoalKcal: previousGoalKcal,
        previousLearnedTdeeKcal: previousLearnedTdeeKcal,
        calculation: calculation,
        windowDays: result.windowDays,
        intakeKcalByDay: result.intakeKcalByDay,
        weightPoints: result.weightPoints,
      );
      previousGoalKcal = calculation.newGoalKcal;
      previousLearnedTdeeKcal = calculation.calculatedTdeeKcal;
    }
  }
  return CalorieDebugWeeklyRowsResult(
    rows: List<CalorieDebugDumpRow>.unmodifiable(rows),
    learnedTdeeByWeekStart: Map<String, CalorieDebugWeekTdeeData>.unmodifiable(
      learnedTdeeByWeekStart,
    ),
  );
}

List<PendingCalorieGoalWeeklyCheckIn> _resolveDebugWeeklyCheckInWindows({
  required CalorieGoalSettings settings,
  required DateTime today,
}) {
  final countingGoalEntry = settings.countingGoalEntryForDay(today);
  if (countingGoalEntry == null) {
    return const <PendingCalorieGoalWeeklyCheckIn>[];
  }
  final anchorEntry =
      settings.cycleAnchorEntryForDay(today) ?? countingGoalEntry;
  if (!anchorEntry.hasGoal) {
    return const <PendingCalorieGoalWeeklyCheckIn>[];
  }

  final windows = <PendingCalorieGoalWeeklyCheckIn>[];
  var windowStartDate = CalorieWeeklyWindowResolver.firstWindowStartDate(
    anchorEntry,
  );
  while (true) {
    final windowLengthDays =
        CalorieWeeklyWindowResolver.windowLengthDaysForStart(
          anchorEntry: anchorEntry,
          windowStartDate: windowStartDate,
        );
    final dueDate = addDiaryDays(windowStartDate, windowLengthDays);
    if (dueDate.isAfter(today)) {
      break;
    }
    final windowEndDate = addDiaryDays(windowStartDate, windowLengthDays - 1);
    windows.add(
      PendingCalorieGoalWeeklyCheckIn(
        windowStartDate: windowStartDate,
        windowEndDate: windowEndDate,
        dueDate: dueDate,
      ),
    );
    windowStartDate = nextDiaryDay(windowEndDate);
  }
  return List<PendingCalorieGoalWeeklyCheckIn>.unmodifiable(windows);
}

_DebugWeeklyRowResult _weeklyCheckInRow({
  required CalorieGoalSettings settings,
  required PendingCalorieGoalWeeklyCheckIn window,
  required CalorieWeeklyCheckInWindowDates dates,
  required Map<String, List<CalorieEntry>> entriesByDay,
  required Map<String, double> manualWeightByDay,
  required _DebugWeeklyHealthData healthData,
  required double previousGoalKcal,
  required double previousLearnedTdeeKcal,
}) {
  final weightData = mergeWeeklyCheckInWeights(
    dates: dates,
    anchorEntry: dates.anchorEntry,
    manualWeightByDay: manualWeightByDay,
    representativeWeightByDay: healthData.representativeWeightByDay,
  );
  final windowIntake = resolveWeeklyWindowIntakeData(
    days: dates.windowDays,
    calorieEntriesByDay: entriesByDay,
    settings: settings,
    activeKcalByDay: const <String, int>{},
    weightByDay: weightData.weightByDay,
  );
  final blockedWindowReason = windowIntake.blockedReason;
  if (blockedWindowReason != null) {
    return _DebugWeeklyRowResult(
      rows: [
        _blockedWeeklyCheckInRow(
          window: window,
          dates: dates,
          reason: _debugBlockedReasonName(blockedWindowReason),
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

  final learningIntake = resolveWeeklyLearningIntakeData(
    days: dates.learningDays,
    calorieEntriesByDay: entriesByDay,
    settings: settings,
  );
  final blockedLearningReason = learningIntake.blockedReason;
  if (blockedLearningReason != null) {
    return _DebugWeeklyRowResult(
      rows: [
        _blockedWeeklyCheckInRow(
          window: window,
          dates: dates,
          reason: _debugBlockedReasonName(blockedLearningReason),
          windowDays: windowIntake.days,
          missingIntakeDays: learningIntake.missingIntakeDays,
          missingWeightDays: const <DateTime>[],
        ),
      ],
      calculation: null,
      windowDays: windowIntake.days,
      intakeKcalByDay: const <double>[],
      weightPoints: const <CalorieWeeklyCheckInWeightPoint>[],
    );
  }

  final missingWeight = _validateDebugWeeklyWeightData(
    dates: dates,
    weightData: weightData,
  );
  if (missingWeight != null) {
    return _DebugWeeklyRowResult(
      rows: [
        _blockedWeeklyCheckInRow(
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
      intakeKcalByDay: learningIntake.intakeKcalByDay,
      weightPoints: weightData.weightPoints,
    );
  }

  final calculatorProfile = CalorieWeeklyWindowResolver.calculatorProfileForDay(
    settings: settings,
    day: window.windowEndDate,
  );
  final calculation = CalorieWeeklyCheckInCalculator.calculate(
    previousGoalKcal: previousGoalKcal,
    previousLearnedTdeeKcal: previousLearnedTdeeKcal,
    goalMode: calculatorProfile?.goalMode ?? CalorieGoalMode.maintain,
    goalSpeedKgPerWeek: calculatorProfile?.goalSpeedKgPerWeek ?? 0,
    intakeKcalByDay: learningIntake.intakeKcalByDay,
    weightPoints: weightData.weightPoints,
  );
  return _DebugWeeklyRowResult(
    rows: _readyWeeklyCheckInRows(
      window: window,
      dates: dates,
      previousGoalKcal: previousGoalKcal,
      previousLearnedTdeeKcal: previousLearnedTdeeKcal,
      calculation: calculation,
      windowDays: windowIntake.days,
      intakeKcalByDay: learningIntake.intakeKcalByDay,
      weightPoints: weightData.weightPoints,
    ),
    calculation: calculation,
    windowDays: windowIntake.days,
    intakeKcalByDay: learningIntake.intakeKcalByDay,
    weightPoints: weightData.weightPoints,
  );
}

List<CalorieDebugDumpRow> _readyWeeklyCheckInRows({
  required PendingCalorieGoalWeeklyCheckIn window,
  required CalorieWeeklyCheckInWindowDates dates,
  required double previousGoalKcal,
  required double previousLearnedTdeeKcal,
  required CalorieWeeklyCheckInCalculation calculation,
  required List<CalorieWeeklyCheckInWindowDay> windowDays,
  required List<double> intakeKcalByDay,
  required List<CalorieWeeklyCheckInWeightPoint> weightPoints,
}) {
  final weightTrend = _weightTrend(
    weightPoints: weightPoints,
  );
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

CalorieDebugWeekTdeeData _learnedWeekStartTdeeData({
  required PendingCalorieGoalWeeklyCheckIn window,
  required CalorieWeeklyCheckInWindowDates dates,
  required double previousGoalKcal,
  required double previousLearnedTdeeKcal,
  required CalorieWeeklyCheckInCalculation calculation,
  required List<CalorieWeeklyCheckInWindowDay> windowDays,
  required List<double> intakeKcalByDay,
  required List<CalorieWeeklyCheckInWeightPoint> weightPoints,
}) {
  final weightTrend = _weightTrend(weightPoints: weightPoints);
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
      _debugNumber('previous_goal', previousGoalKcal),
      _debugNumber('previous_learned_tdee', previousLearnedTdeeKcal),
      _debugNumber('average_eaten', calculation.averageIntakeKcal),
      _debugNumber('measured_tdee', calculation.measuredTdeeKcal),
      _debugNumber('smoothed_tdee', calculation.calculatedTdeeKcal),
      _debugNumber('new_target', calculation.newGoalKcal),
      _debugNumber('start_weight', weightTrend.startWeightKg),
      _debugNumber('end_weight', weightTrend.endWeightKg),
      _debugNumber('weight_change', weightTrend.weightChangeKg),
      'trend_kg_per_day=$trendPerDay',
      'intake=[${_formatDoubleList(intakeKcalByDay)}]',
    ].join(','),
  );
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
      _windowExtra(window, dates),
      _debugNumber('previous_goal', previousGoalKcal),
      _debugNumber('previous_learned_tdee', previousLearnedTdeeKcal),
      'trend_kg_per_day=$trendWeightChangePerDay',
      _debugNumber('average_intake', calculation.averageIntakeKcal),
      _debugNumber('measured_tdee', calculation.measuredTdeeKcal),
      _debugNumber('learned_tdee', calculation.calculatedTdeeKcal),
      _debugNumber('new_target', calculation.newGoalKcal),
      'low_confidence=${weightPoints.length <= 2}',
      'intake=[${_formatDoubleList(intakeKcalByDay)}]',
      'weight_points=[${_formatWeightPoints(weightPoints)}]',
      'days=[${_formatWindowDays(windowDays)}]',
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
      _windowExtra(window, dates),
      _debugNumber('planned_daily', previousGoalKcal),
      _debugNumber('planned_total', plannedTotalKcal),
      _debugNumber('eaten_total', eatenTotalKcal),
      _debugNumber('eaten_daily_avg', eatenTotalKcal / windowDays.length),
      'eaten_minus_planned=${formatCalorieDebugNumber(
        eatenTotalKcal - plannedTotalKcal,
      )}',
      'days=[${_formatWindowDays(windowDays)}]',
    ].join('; '),
  );
}

CalorieDebugDumpRow _weightTrendWeeklyRow({
  required PendingCalorieGoalWeeklyCheckIn window,
  required CalorieWeeklyCheckInWindowDates dates,
  required CalorieWeeklyCheckInCalculation calculation,
  required _DebugWeightTrend weightTrend,
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
      _windowExtra(window, dates),
      _debugNumber('start_weight', weightTrend.startWeightKg),
      _debugNumber('end_weight', weightTrend.endWeightKg),
      _debugNumber('weight_change', weightTrend.weightChangeKg),
      'trend_kg_per_day=$trendPerDay',
      'trend_kg_per_week=${formatCalorieDebugNumber(
        calculation.trendWeightChangePerDay * 7,
      )}',
      'low_confidence=${weightPoints.length <= 2}',
      'weight_points=[${_formatWeightPoints(weightPoints)}]',
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
      calculation.averageIntakeKcal - calculation.measuredTotalTdeeKcal;

  return _weeklyRow(
    window: window,
    name: 'measured_total_tdee',
    kcal: calculation.measuredTotalTdeeKcal,
    order: order,
    extra: [
      _windowExtra(window, dates),
      'formula=average_eaten - weight_storage_per_day',
      _debugNumber('average_eaten', calculation.averageIntakeKcal),
      _debugNumber('weight_storage_per_day', weightStorageKcalPerDay),
      'measured_total_tdee=${formatCalorieDebugNumber(
        calculation.measuredTotalTdeeKcal,
      )}',
      'learning_intake=[${_formatDoubleList(intakeKcalByDay)}]',
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
      _windowExtra(window, dates),
      _debugNumber('previous_learned_tdee', previousLearnedTdeeKcal),
      _debugNumber('smoothed_tdee', calculation.calculatedTdeeKcal),
      _debugNumber('new_target', calculation.newGoalKcal),
    ].join('; '),
  );
}

CalorieDebugDumpRow _blockedWeeklyCheckInRow({
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
      _windowExtra(window, dates),
      'blocked=$reason',
      'missing_intake=[${formatCalorieDebugDayKeys(missingIntakeDays)}]',
      'missing_weight=[${formatCalorieDebugDayKeys(missingWeightDays)}]',
      'days=[${_formatWindowDays(windowDays)}]',
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

Future<_DebugWeeklyHealthData> _loadDebugWeeklyHealthData({
  required CalorieGoalSettings settings,
  required Iterable<CalorieWeeklyCheckInWindowDates> datesByWindow,
  required List<PendingCalorieGoalWeeklyCheckIn> windows,
  required HealthConnectionStatus healthStatus,
  required HealthWeightService healthWeightService,
}) async {
  if (healthStatus.accessState != HealthDataAccessState.ready) {
    return const _DebugWeeklyHealthData(
      representativeWeightByDay: <String, double>{},
    );
  }

  final dates = datesByWindow.toList(growable: false);
  final weightStartCandidates = [
    for (final date in dates) ...date.healthWeightStartCandidates,
  ];
  final weightEndDay = _latestDay([
    for (final date in dates) date.nextBoundaryDay,
  ]);
  final healthWeightSamples = await healthWeightService.loadWeightSamples(
    startInclusive: _earliestDate(weightStartCandidates),
    endExclusive: nextDiaryDay(weightEndDay),
  );
  return _DebugWeeklyHealthData(
    representativeWeightByDay: _representativeWeightByDay(
      healthWeightSamples,
    ),
  );
}

_DebugMissingWeightData? _validateDebugWeeklyWeightData({
  required CalorieWeeklyCheckInWindowDates dates,
  required CalorieWeeklyCheckInWeightData weightData,
}) {
  final hasLearningStartWeight =
      weightData.weightByDay[diaryDayKey(dates.learningStartDate)] != null;
  final hasWindowEndWeight =
      weightData.weightByDay[diaryDayKey(
        dates.pendingWeeklyCheckIn.windowEndDate,
      )] !=
      null;
  if (weightData.weightPoints.length < 2 && !hasLearningStartWeight) {
    return _DebugMissingWeightData(
      reason: 'missing_window_start_weight',
      missingWeightDays: [dates.learningStartDate],
    );
  }
  if (weightData.weightPoints.length < 2 && !hasWindowEndWeight) {
    return _DebugMissingWeightData(
      reason: 'missing_window_end_weight',
      missingWeightDays: [dates.pendingWeeklyCheckIn.windowEndDate],
    );
  }
  return null;
}

String _debugBlockedReasonName(CalorieWeeklyCheckInBlockedReason reason) {
  return switch (reason) {
    CalorieWeeklyCheckInBlockedReason.missingIntakeDays =>
      'missing_intake_days',
    CalorieWeeklyCheckInBlockedReason.tooManyMissingIntakeDays =>
      'too_many_missing_intake_days',
    CalorieWeeklyCheckInBlockedReason.skippedDayWithoutPriorAverage =>
      'skipped_day_without_prior_average',
    CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight =>
      'missing_window_start_weight',
    CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight =>
      'missing_window_end_weight',
    CalorieWeeklyCheckInBlockedReason.unstableWeightData =>
      'unstable_weight_data',
  };
}

double _previousLearnedTdeeKcalBeforeDay({
  required CalorieGoalSettings settings,
  required DateTime day,
  required DateTime fallbackDay,
}) {
  final normalizedDay = normalizeDiaryDay(day);
  CalorieGoalHistoryEntry? learnedEntry;
  for (final entry in settings.sortedGoalHistory) {
    if (!entry.effectiveDate.isBefore(normalizedDay)) {
      break;
    }
    if (entry.hasLearnedTdee) {
      learnedEntry = entry;
    }
  }
  final learnedTdeeKcal =
      learnedEntry?.weeklyCheckInSnapshot?.calculatedBaseTdeeKcal;
  if (learnedTdeeKcal != null) {
    return learnedTdeeKcal;
  }
  final calculatorProfile = CalorieWeeklyWindowResolver.calculatorProfileForDay(
    settings: settings,
    day: fallbackDay,
  );
  if (calculatorProfile != null) {
    final result = CalorieGoalCalculator.calculate(calculatorProfile);
    return result.tdeeKcal;
  }
  return settings.baseGoalKcalForDay(fallbackDay);
}

Map<String, List<CalorieEntry>> _calorieEntriesByDay(
  List<CalorieEntry> entries,
) {
  final entriesByDay = <String, List<CalorieEntry>>{};
  for (final entry in entries) {
    final key = diaryDayKey(entry.loggedAt);
    entriesByDay.putIfAbsent(key, () => <CalorieEntry>[]).add(entry);
  }
  return entriesByDay;
}

Map<String, double> _representativeWeightByDay(
  List<HealthWeightSample> samples,
) {
  final samplesByDay = <String, List<double>>{};
  for (final sample in samples) {
    final key = diaryDayKey(sample.recordedAt);
    samplesByDay.putIfAbsent(key, () => <double>[]).add(sample.weightKg);
  }
  return {
    for (final entry in samplesByDay.entries)
      entry.key: CalorieDomainMath.median(entry.value),
  };
}

double _windowEatenTotalKcal(List<CalorieWeeklyCheckInWindowDay> days) {
  return days.fold<double>(
    0,
    (sum, day) => sum + (day.resolvedIntakeKcal ?? day.loggedIntakeKcal),
  );
}

_DebugWeightTrend _weightTrend({
  required List<CalorieWeeklyCheckInWeightPoint> weightPoints,
}) {
  final firstPoint = weightPoints.first;
  final lastPoint = weightPoints.last;
  return _DebugWeightTrend(
    startWeightKg: firstPoint.weightKg,
    endWeightKg: lastPoint.weightKg,
    weightChangeKg: lastPoint.weightKg - firstPoint.weightKg,
  );
}

DateTime _latestDay(List<DateTime> days) {
  assert(days.isNotEmpty, 'At least one day is required.');
  var latest = normalizeDiaryDay(days.first);
  for (final day in days.skip(1)) {
    final normalizedDay = normalizeDiaryDay(day);
    if (normalizedDay.isAfter(latest)) {
      latest = normalizedDay;
    }
  }
  return latest;
}

String _windowExtra(
  PendingCalorieGoalWeeklyCheckIn window,
  CalorieWeeklyCheckInWindowDates dates,
) {
  return 'window=${diaryDayKey(window.windowStartDate)}'
      '..${diaryDayKey(window.windowEndDate)}; '
      'learning_window=${diaryDayKey(dates.learningStartDate)}'
      '..${diaryDayKey(window.windowEndDate)}; '
      'due=${diaryDayKey(window.dueDate)}';
}

String _formatDoubleList(List<double> values) {
  return values.map((value) => value.toStringAsFixed(2)).join(',');
}

String _debugNumber(String name, double value) {
  return '$name=${formatCalorieDebugNumber(value)}';
}

String _formatWeightPoints(List<CalorieWeeklyCheckInWeightPoint> points) {
  return points
      .map((point) {
        return '${point.dayIndex}:${point.weightKg.toStringAsFixed(2)}';
      })
      .join(',');
}

String _formatWindowDays(List<CalorieWeeklyCheckInWindowDay> days) {
  return days
      .map((day) {
        return '${diaryDayKey(day.day)}'
            ':logged=${day.loggedIntakeKcal.toStringAsFixed(2)}'
            ',resolved=${day.resolvedIntakeKcal?.toStringAsFixed(2) ?? 'null'}'
            ',weight=${day.weightKg?.toStringAsFixed(2) ?? 'null'}'
            ',skipped=${day.isSkippedIntakeDay}';
      })
      .join(' | ');
}

String formatCalorieDebugDayKeys(List<DateTime> days) {
  return days.map(diaryDayKey).join(',');
}

DateTime _earliestDate(List<DateTime> dates) {
  return dates.reduce((left, right) => left.isBefore(right) ? left : right);
}

class _DebugWeeklyHealthData {
  const _DebugWeeklyHealthData({
    required this.representativeWeightByDay,
  });

  final Map<String, double> representativeWeightByDay;
}


class _DebugWeeklyRowResult {
  const _DebugWeeklyRowResult({
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

class CalorieDebugWeeklyRowsResult {
  const CalorieDebugWeeklyRowsResult({
    required this.rows,
    required this.learnedTdeeByWeekStart,
  });

  const CalorieDebugWeeklyRowsResult.empty()
    : rows = const <CalorieDebugDumpRow>[],
      learnedTdeeByWeekStart = const <String, CalorieDebugWeekTdeeData>{};

  final List<CalorieDebugDumpRow> rows;
  final Map<String, CalorieDebugWeekTdeeData> learnedTdeeByWeekStart;
}

class _DebugWeightTrend {
  const _DebugWeightTrend({
    required this.startWeightKg,
    required this.endWeightKg,
    required this.weightChangeKg,
  });

  final double startWeightKg;
  final double endWeightKg;
  final double weightChangeKg;
}

class CalorieDebugWeekTdeeData {
  const CalorieDebugWeekTdeeData({
    required this.source,
    required this.tdeeKcal,
    required this.used,
  });

  final String source;
  final double tdeeKcal;
  final String used;
}

class _DebugMissingWeightData {
  const _DebugMissingWeightData({
    required this.reason,
    required this.missingWeightDays,
  });

  final String reason;
  final List<DateTime> missingWeightDays;
}
