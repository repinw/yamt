import 'package:yamt/features/calories/application/calorie_health_activity_kcal_reader.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart'
    show CalorieCalculatorProfile, CalorieGoalMode;
import 'package:yamt/features/calories/domain/calorie_domain_math.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_window_resolver.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository.dart';
import 'package:yamt/features/health/domain/diary_activity_summary.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

const _debugActivityFallbackDays = 30;

/// Result for debug calorie dump.
class CalorieDebugDumpResult {
  /// Creates result.
  const CalorieDebugDumpResult({
    required this.table,
    required this.rowCount,
    required this.startInclusive,
    required this.endExclusive,
  });

  /// Markdown table exported as debug text.
  final String table;

  /// Number of data rows in the table.
  final int rowCount;

  /// Export start.
  final DateTime startInclusive;

  /// Export end.
  final DateTime endExclusive;
}

/// Builds one debug table with food, activity, and weight data.
Future<CalorieDebugDumpResult> buildCalorieDebugDump({
  required CalorieLogRepositoryContract calorieLogRepository,
  required DiaryHealthService diaryHealthService,
  required HealthWeightService healthWeightService,
  required ManualHealthWeightRepository manualWeightRepository,
  required Future<HealthConnectionStatus> healthStatusFuture,
  required Future<CalorieGoalSettings> settingsFuture,
  required DateTime now,
}) async {
  final today = normalizeDiaryDay(now.toLocal());
  final endExclusive = nextDiaryDay(today);
  final firstEntryDate = await calorieLogRepository.readFirstEntryDate();
  final manualWeightEntries = await manualWeightRepository.readEntries();
  final settings = await settingsFuture;
  final activityStartInclusive = _resolveActivityStart(
    today: today,
    firstEntryDate: firstEntryDate,
  );
  final startInclusive = _resolveDebugDumpStart(
    settings: settings,
    fallbackStartInclusive: activityStartInclusive,
    today: today,
  );
  final calorieEntries = await calorieLogRepository.readEntriesInRange(
    startInclusive: startInclusive,
    endExclusive: endExclusive,
  );
  final healthStatus = await healthStatusFuture;
  final rows = <_DebugDumpRow>[
    _summaryRow(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
      healthStatus: healthStatus,
    ),
    ..._dailyEatenRows(
      entries: calorieEntries,
      settings: settings,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    ),
  ];

  if (healthStatus.accessState == HealthDataAccessState.ready) {
    rows.addAll(
      await _loadHealthRows(
        startInclusive: startInclusive,
        endExclusive: endExclusive,
        settings: settings,
        diaryHealthService: diaryHealthService,
        healthWeightService: healthWeightService,
        manualWeightEntries: manualWeightEntries,
        userHeightCm: settings.calculatorProfile?.heightCm,
      ),
    );
  } else {
    rows
      ..addAll(
        _dailyWeightRows(
          healthWeightSamples: const <HealthWeightSample>[],
          manualWeightEntries: manualWeightEntries,
          settings: settings,
          startInclusive: startInclusive,
          endExclusive: endExclusive,
        ),
      )
      ..add(
        _DebugDumpRow(
          sortAt: startInclusive,
          typeOrder: 0,
          cells: [
            _formatDay(startInclusive),
            '',
            'health_access',
            'not_ready',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            healthStatus.platform.name,
            'access_state=${healthStatus.accessState.name}',
          ],
        ),
      );
  }
  final weeklyCheckInResult = await _weeklyCheckInRows(
    settings: settings,
    calorieEntries: calorieEntries,
    manualWeightEntries: manualWeightEntries,
    healthStatus: healthStatus,
    diaryHealthService: diaryHealthService,
    healthWeightService: healthWeightService,
    today: today,
  );
  rows
    ..addAll(
      _goalWeekRows(
        settings: settings,
        rows: rows,
        startInclusive: startInclusive,
        endExclusive: endExclusive,
        learnedTdeeByWeekStart: weeklyCheckInResult.learnedTdeeByWeekStart,
      ),
    )
    ..addAll(weeklyCheckInResult.rows);

  final sortedRows = List<_DebugDumpRow>.of(rows)..sort(_compareRows);
  final table = _buildMarkdownTable(
    sortedRows,
    separatorDays: _goalWeekSeparatorDays(
      settings: settings,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    ),
  );
  return CalorieDebugDumpResult(
    table: table,
    rowCount: sortedRows.length,
    startInclusive: startInclusive,
    endExclusive: endExclusive,
  );
}

DateTime _resolveActivityStart({
  required DateTime today,
  required DateTime? firstEntryDate,
}) {
  if (firstEntryDate != null) {
    return normalizeDiaryDay(firstEntryDate.toLocal());
  }
  return today.subtract(const Duration(days: _debugActivityFallbackDays - 1));
}

DateTime _resolveDebugDumpStart({
  required CalorieGoalSettings settings,
  required DateTime fallbackStartInclusive,
  required DateTime today,
}) {
  final goalStart = _earliestDebugGoalStart(settings);
  if (goalStart == null) {
    return fallbackStartInclusive;
  }
  if (goalStart.isAfter(today)) {
    return today;
  }
  return goalStart;
}

DateTime? _earliestDebugGoalStart(CalorieGoalSettings settings) {
  DateTime? earliest;
  for (final entry in settings.sortedGoalHistory) {
    if (!entry.hasGoal || entry.isWeeklyCheckIn) {
      continue;
    }
    final start = normalizeDiaryDay(entry.effectiveCountingStartDate);
    if (earliest == null || start.isBefore(earliest)) {
      earliest = start;
    }
  }
  return earliest;
}

bool _hasDebugGoalWindows(CalorieGoalSettings settings) {
  return settings.sortedGoalHistory.any(
    (entry) => entry.hasGoal && !entry.isWeeklyCheckIn,
  );
}

bool _isDebugGoalWindowDay({
  required CalorieGoalSettings settings,
  required DateTime day,
}) {
  if (!_hasDebugGoalWindows(settings)) {
    return true;
  }
  return settings.countingGoalEntryForDay(day)?.hasGoal == true;
}

Future<List<_DebugDumpRow>> _loadHealthRows({
  required DateTime startInclusive,
  required DateTime endExclusive,
  required CalorieGoalSettings settings,
  required DiaryHealthService diaryHealthService,
  required HealthWeightService healthWeightService,
  required List<ManualHealthWeightEntry> manualWeightEntries,
  required double? userHeightCm,
}) async {
  final rows = <_DebugDumpRow>[];
  final weightSamples = await healthWeightService.loadWeightSamples(
    startInclusive: startInclusive,
    endExclusive: endExclusive,
  );
  rows.addAll(
    _dailyWeightRows(
      healthWeightSamples: weightSamples,
      manualWeightEntries: manualWeightEntries,
      settings: settings,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    ),
  );

  final activityDays = <DateTime>[];
  for (
    var day = normalizeDiaryDay(startInclusive);
    day.isBefore(endExclusive);
    day = nextDiaryDay(day)
  ) {
    if (!_isDebugGoalWindowDay(settings: settings, day: day)) {
      continue;
    }
    activityDays.add(day);
  }
  final activityRows = await Future.wait([
    for (final day in activityDays)
      () async {
        final data = await diaryHealthService.loadDayData(
          day: day,
          userHeightCm: userHeightCm,
        );
        return _activityRows(day: day, data: data);
      }(),
  ]);
  activityRows.forEach(rows.addAll);
  return rows;
}

Future<_DebugWeeklyRowsResult> _weeklyCheckInRows({
  required CalorieGoalSettings settings,
  required List<CalorieEntry> calorieEntries,
  required List<ManualHealthWeightEntry> manualWeightEntries,
  required HealthConnectionStatus healthStatus,
  required DiaryHealthService diaryHealthService,
  required HealthWeightService healthWeightService,
  required DateTime today,
}) async {
  final windows = _resolveDebugWeeklyCheckInWindows(
    settings: settings,
    today: today,
  );
  if (windows.isEmpty) {
    return const _DebugWeeklyRowsResult.empty();
  }

  final datesByWindow = <PendingCalorieGoalWeeklyCheckIn, _DebugWeeklyDates>{};
  for (final window in windows) {
    datesByWindow[window] = _resolveDebugWeeklyDates(
      settings: settings,
      pendingWeeklyCheckIn: window,
    );
  }
  final entriesByDay = _calorieEntriesByDay(calorieEntries);
  final manualWeightByDay = _manualWeightByDay(manualWeightEntries);
  final healthData = await _loadDebugWeeklyHealthData(
    settings: settings,
    datesByWindow: datesByWindow.values,
    windows: windows,
    healthStatus: healthStatus,
    diaryHealthService: diaryHealthService,
    healthWeightService: healthWeightService,
  );
  final usesHealthActivity =
      healthStatus.accessState == HealthDataAccessState.ready;

  var previousGoalKcal = settings.goalKcalForDay(windows.first.windowEndDate);
  var previousLearnedTdeeKcal = _previousLearnedTdeeKcalBeforeDay(
    settings: settings,
    day: windows.first.windowStartDate,
    fallbackDay: windows.first.windowEndDate,
  );
  final rows = <_DebugDumpRow>[];
  final learnedTdeeByWeekStart = <String, _DebugWeekTdeeData>{};
  for (final window in windows) {
    final result = _weeklyCheckInRow(
      settings: settings,
      window: window,
      dates: datesByWindow[window]!,
      entriesByDay: entriesByDay,
      manualWeightByDay: manualWeightByDay,
      healthData: healthData,
      previousGoalKcal: previousGoalKcal,
      previousLearnedTdeeKcal: previousLearnedTdeeKcal,
      usesHealthActivity: usesHealthActivity,
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
        usesHealthActivity: usesHealthActivity,
      );
      previousGoalKcal = calculation.newBaseGoalKcal;
      previousLearnedTdeeKcal = calculation.calculatedBaseTdeeKcal;
    }
  }
  return _DebugWeeklyRowsResult(
    rows: List<_DebugDumpRow>.unmodifiable(rows),
    learnedTdeeByWeekStart: Map<String, _DebugWeekTdeeData>.unmodifiable(
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
  required _DebugWeeklyDates dates,
  required Map<String, List<CalorieEntry>> entriesByDay,
  required Map<String, double> manualWeightByDay,
  required _DebugWeeklyHealthData healthData,
  required double previousGoalKcal,
  required double previousLearnedTdeeKcal,
  required bool usesHealthActivity,
}) {
  final weightData = _mergeDebugWeeklyWeights(
    settings: settings,
    dates: dates,
    manualWeightByDay: manualWeightByDay,
    representativeWeightByDay: healthData.representativeWeightByDay,
  );
  final windowIntake = _resolveDebugWindowIntakeData(
    days: dates.windowDays,
    entriesByDay: entriesByDay,
    settings: settings,
    activeKcalByDay: healthData.activeKcalByDay,
    weightByDay: weightData.weightByDay,
  );
  final blockedWindowReason = windowIntake.blockedReason;
  if (blockedWindowReason != null) {
    return _DebugWeeklyRowResult(
      rows: [
        _blockedWeeklyCheckInRow(
          window: window,
          dates: dates,
          reason: blockedWindowReason,
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

  final learningIntake = _resolveDebugLearningIntakeData(
    days: dates.learningDays,
    entriesByDay: entriesByDay,
    settings: settings,
  );
  final blockedLearningReason = learningIntake.blockedReason;
  if (blockedLearningReason != null) {
    return _DebugWeeklyRowResult(
      rows: [
        _blockedWeeklyCheckInRow(
          window: window,
          dates: dates,
          reason: blockedLearningReason,
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
    lastWeekActiveKcalByDay: windowIntake.days
        .map((day) => day.activeKcal)
        .toList(growable: false),
    todayActiveKcal:
        healthData.activeKcalByDay[diaryDayKey(window.dueDate)] ?? 0,
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
      usesHealthActivity: usesHealthActivity,
    ),
    calculation: calculation,
    windowDays: windowIntake.days,
    intakeKcalByDay: learningIntake.intakeKcalByDay,
    weightPoints: weightData.weightPoints,
  );
}

List<_DebugDumpRow> _readyWeeklyCheckInRows({
  required PendingCalorieGoalWeeklyCheckIn window,
  required _DebugWeeklyDates dates,
  required double previousGoalKcal,
  required double previousLearnedTdeeKcal,
  required CalorieWeeklyCheckInCalculation calculation,
  required List<_DebugWeeklyWindowDay> windowDays,
  required List<double> intakeKcalByDay,
  required List<CalorieWeeklyCheckInWeightPoint> weightPoints,
  required bool usesHealthActivity,
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
      usesHealthActivity: usesHealthActivity,
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
    if (usesHealthActivity)
      _measuredBaseTdeeWeeklyRow(
        window: window,
        dates: dates,
        calculation: calculation,
        windowDays: windowDays,
        order: 4,
      ),
    _newTargetWeeklyRow(
      window: window,
      dates: dates,
      previousLearnedTdeeKcal: previousLearnedTdeeKcal,
      calculation: calculation,
      usesHealthActivity: usesHealthActivity,
      order: 5,
    ),
  ];
}

_DebugWeekTdeeData _learnedWeekStartTdeeData({
  required PendingCalorieGoalWeeklyCheckIn window,
  required _DebugWeeklyDates dates,
  required double previousGoalKcal,
  required double previousLearnedTdeeKcal,
  required CalorieWeeklyCheckInCalculation calculation,
  required List<_DebugWeeklyWindowDay> windowDays,
  required List<double> intakeKcalByDay,
  required List<CalorieWeeklyCheckInWeightPoint> weightPoints,
  required bool usesHealthActivity,
}) {
  final activeTotal = windowDays.fold<int>(
    0,
    (sum, day) => sum + day.activeKcal,
  );
  final weightTrend = _weightTrend(weightPoints: weightPoints);
  final calculatedWindow =
      '${diaryDayKey(window.windowStartDate)}'
      '..${diaryDayKey(window.windowEndDate)}';
  final learningWindow =
      '${diaryDayKey(dates.learningStartDate)}'
      '..${diaryDayKey(window.windowEndDate)}';
  final trendPerDay = calculation.trendWeightChangePerDay.toStringAsFixed(5);

  return _DebugWeekTdeeData(
    source: 'learned_tdee',
    tdeeKcal: calculation.calculatedBaseTdeeKcal,
    used: [
      'calculated_from_window=$calculatedWindow',
      'learning_window=$learningWindow',
      'previous_goal=${_formatNumber(previousGoalKcal)}',
      'previous_learned_base_tdee=${_formatNumber(previousLearnedTdeeKcal)}',
      'average_eaten=${_formatNumber(calculation.averageIntakeKcal)}',
      'measured_total_tdee=${_formatNumber(calculation.measuredTotalTdeeKcal)}',
      if (usesHealthActivity) ...[
        'activity_total=$activeTotal',
        'credited_activity_average=${_formatNumber(
          calculation.averageCreditedActivityKcal,
        )}',
        'activity_subtracted_from_total_tdee=${_formatNumber(
          calculation.averageCreditedActivityKcal,
        )}',
        'measured_base_tdee=${_formatNumber(calculation.measuredBaseTdeeKcal)}',
      ],
      'smoothed_base_tdee=${_formatNumber(calculation.calculatedBaseTdeeKcal)}',
      'new_target=${_formatNumber(calculation.newBaseGoalKcal)}',
      'start_weight=${_formatNumber(weightTrend.startWeightKg)}',
      'end_weight=${_formatNumber(weightTrend.endWeightKg)}',
      'weight_change=${_formatNumber(weightTrend.weightChangeKg)}',
      'trend_kg_per_day=$trendPerDay',
      'intake=[${_formatDoubleList(intakeKcalByDay)}]',
      'active=[${windowDays.map((day) => day.activeKcal).join(',')}]',
    ].join(','),
  );
}

_DebugDumpRow _readyWeeklyCheckInSummaryRow({
  required PendingCalorieGoalWeeklyCheckIn window,
  required _DebugWeeklyDates dates,
  required double previousGoalKcal,
  required double previousLearnedTdeeKcal,
  required CalorieWeeklyCheckInCalculation calculation,
  required List<_DebugWeeklyWindowDay> windowDays,
  required List<double> intakeKcalByDay,
  required List<CalorieWeeklyCheckInWeightPoint> weightPoints,
  required bool usesHealthActivity,
  required int order,
}) {
  final trendWeightChangePerDay = calculation.trendWeightChangePerDay
      .toStringAsFixed(5);
  return _weeklyRow(
    window: window,
    name: 'learned_base_tdee',
    kcal: calculation.calculatedBaseTdeeKcal,
    order: order,
    extra: [
      _windowExtra(window, dates),
      'previous_goal=${_formatNumber(previousGoalKcal)}',
      'previous_learned_base_tdee=${_formatNumber(previousLearnedTdeeKcal)}',
      'trend_kg_per_day=$trendWeightChangePerDay',
      'average_intake=${_formatNumber(calculation.averageIntakeKcal)}',
      'measured_total_tdee=${_formatNumber(calculation.measuredTotalTdeeKcal)}',
      if (usesHealthActivity)
        'measured_base_tdee=${_formatNumber(calculation.measuredBaseTdeeKcal)}',
      'learned_base_tdee=${_formatNumber(calculation.calculatedBaseTdeeKcal)}',
      'new_target=${_formatNumber(calculation.newBaseGoalKcal)}',
      if (usesHealthActivity) ...[
        'credited_activity_average=${_formatNumber(
          calculation.averageCreditedActivityKcal,
        )}',
        'activity_subtracted_from_total_tdee=${_formatNumber(
          calculation.averageCreditedActivityKcal,
        )}',
        'due_active=${calculation.todayActiveKcal}',
        'activity_delta=${_formatNumber(calculation.activityDeltaKcal)}',
        'dynamic_target_today=${_formatNumber(
          calculation.dynamicGoalTodayKcal,
        )}',
      ],
      'low_confidence=${weightPoints.length <= 2}',
      'intake=[${_formatDoubleList(intakeKcalByDay)}]',
      'active=[${windowDays.map((day) => day.activeKcal).join(',')}]',
      'weight_points=[${_formatWeightPoints(weightPoints)}]',
      'days=[${_formatWindowDays(windowDays)}]',
    ].join('; '),
  );
}

_DebugDumpRow _plannedVsEatenWeeklyRow({
  required PendingCalorieGoalWeeklyCheckIn window,
  required _DebugWeeklyDates dates,
  required double previousGoalKcal,
  required List<_DebugWeeklyWindowDay> windowDays,
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
      'planned_daily=${_formatNumber(previousGoalKcal)}',
      'planned_total=${_formatNumber(plannedTotalKcal)}',
      'eaten_total=${_formatNumber(eatenTotalKcal)}',
      'eaten_daily_avg=${_formatNumber(eatenTotalKcal / windowDays.length)}',
      'eaten_minus_planned=${_formatNumber(
        eatenTotalKcal - plannedTotalKcal,
      )}',
      'days=[${_formatWindowDays(windowDays)}]',
    ].join('; '),
  );
}

_DebugDumpRow _weightTrendWeeklyRow({
  required PendingCalorieGoalWeeklyCheckIn window,
  required _DebugWeeklyDates dates,
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
      'start_weight=${_formatNumber(weightTrend.startWeightKg)}',
      'end_weight=${_formatNumber(weightTrend.endWeightKg)}',
      'weight_change=${_formatNumber(weightTrend.weightChangeKg)}',
      'trend_kg_per_day=$trendPerDay',
      'trend_kg_per_week=${_formatNumber(
        calculation.trendWeightChangePerDay * 7,
      )}',
      'low_confidence=${weightPoints.length <= 2}',
      'weight_points=[${_formatWeightPoints(weightPoints)}]',
    ].join('; '),
  );
}

_DebugDumpRow _measuredTotalTdeeWeeklyRow({
  required PendingCalorieGoalWeeklyCheckIn window,
  required _DebugWeeklyDates dates,
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
      'average_eaten=${_formatNumber(calculation.averageIntakeKcal)}',
      'weight_storage_per_day=${_formatNumber(weightStorageKcalPerDay)}',
      'measured_total_tdee=${_formatNumber(
        calculation.measuredTotalTdeeKcal,
      )}',
      'learning_intake=[${_formatDoubleList(intakeKcalByDay)}]',
    ].join('; '),
  );
}

_DebugDumpRow _measuredBaseTdeeWeeklyRow({
  required PendingCalorieGoalWeeklyCheckIn window,
  required _DebugWeeklyDates dates,
  required CalorieWeeklyCheckInCalculation calculation,
  required List<_DebugWeeklyWindowDay> windowDays,
  required int order,
}) {
  return _weeklyRow(
    window: window,
    name: 'measured_base_tdee',
    kcal: calculation.measuredBaseTdeeKcal,
    order: order,
    extra: [
      _windowExtra(window, dates),
      'formula=measured_total_tdee - credited_activity_average',
      'measured_total_tdee=${_formatNumber(
        calculation.measuredTotalTdeeKcal,
      )}',
      'credited_activity_average=${_formatNumber(
        calculation.averageCreditedActivityKcal,
      )}',
      'activity_subtracted_from_total_tdee=${_formatNumber(
        calculation.averageCreditedActivityKcal,
      )}',
      'measured_base_tdee=${_formatNumber(calculation.measuredBaseTdeeKcal)}',
      'raw_active=[${windowDays.map((day) => day.activeKcal).join(',')}]',
    ].join('; '),
  );
}

_DebugDumpRow _newTargetWeeklyRow({
  required PendingCalorieGoalWeeklyCheckIn window,
  required _DebugWeeklyDates dates,
  required double previousLearnedTdeeKcal,
  required CalorieWeeklyCheckInCalculation calculation,
  required bool usesHealthActivity,
  required int order,
}) {
  return _weeklyRow(
    window: window,
    name: 'new_target',
    kcal: calculation.newBaseGoalKcal,
    order: order,
    extra: [
      _windowExtra(window, dates),
      'previous_learned_base_tdee=${_formatNumber(previousLearnedTdeeKcal)}',
      if (usesHealthActivity)
        'measured_base_tdee=${_formatNumber(calculation.measuredBaseTdeeKcal)}',
      'smoothed_base_tdee=${_formatNumber(
        calculation.calculatedBaseTdeeKcal,
      )}',
      'new_target=${_formatNumber(calculation.newBaseGoalKcal)}',
      if (usesHealthActivity) ...[
        'due_active=${calculation.todayActiveKcal}',
        'activity_delta=${_formatNumber(calculation.activityDeltaKcal)}',
        'dynamic_target_today=${_formatNumber(
          calculation.dynamicGoalTodayKcal,
        )}',
      ],
    ].join('; '),
  );
}

_DebugDumpRow _blockedWeeklyCheckInRow({
  required PendingCalorieGoalWeeklyCheckIn window,
  required _DebugWeeklyDates dates,
  required String reason,
  required List<_DebugWeeklyWindowDay> windowDays,
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
      'missing_intake=[${_formatDayKeys(missingIntakeDays)}]',
      'missing_weight=[${_formatDayKeys(missingWeightDays)}]',
      'days=[${_formatWindowDays(windowDays)}]',
    ].join('; '),
  );
}

_DebugDumpRow _weeklyRow({
  required PendingCalorieGoalWeeklyCheckIn window,
  required String name,
  required double? kcal,
  required String extra,
  int order = 0,
}) {
  final sortAt = window.windowEndDate.add(
    const Duration(hours: 23, minutes: 59, seconds: 59),
  );
  return _DebugDumpRow(
    sortAt: sortAt,
    typeOrder: 90 + order,
    cells: [
      _formatDay(sortAt),
      _formatTime(sortAt),
      'weekly_checkin',
      name,
      _formatNumber(kcal),
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
  required Iterable<_DebugWeeklyDates> datesByWindow,
  required List<PendingCalorieGoalWeeklyCheckIn> windows,
  required HealthConnectionStatus healthStatus,
  required DiaryHealthService diaryHealthService,
  required HealthWeightService healthWeightService,
}) async {
  if (healthStatus.accessState != HealthDataAccessState.ready) {
    return const _DebugWeeklyHealthData(
      activeKcalByDay: <String, int>{},
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
  final activeDays = <String, DateTime>{
    for (final date in dates)
      for (final day in date.windowDays) diaryDayKey(day): day,
    for (final window in windows) diaryDayKey(window.dueDate): window.dueDate,
  };
  final activeDayData = await Future.wait([
    for (final day in activeDays.values)
      () async {
        final dayData = await diaryHealthService.loadDayData(
          day: day,
          userHeightCm: settings.calculatorProfile?.heightCm,
        );
        return (day: day, dayData: dayData);
      }(),
  ]);
  final activeKcalByDay = <String, int>{
    for (final result in activeDayData)
      diaryDayKey(result.day): _resolveActiveKcal(
        day: result.day,
        dayData: result.dayData,
      ),
  };

  return _DebugWeeklyHealthData(
    activeKcalByDay: Map<String, int>.unmodifiable(activeKcalByDay),
    representativeWeightByDay: _representativeWeightByDay(
      healthWeightSamples,
    ),
  );
}

_DebugWeeklyDates _resolveDebugWeeklyDates({
  required CalorieGoalSettings settings,
  required PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
}) {
  final windowLengthDays = _windowLengthDays(pendingWeeklyCheckIn);
  final learningStartDate = _learningStartDateForCheckIn(
    settings: settings,
    pendingWeeklyCheckIn: pendingWeeklyCheckIn,
  );
  final windowDays = <DateTime>[
    for (var index = 0; index < windowLengthDays; index += 1)
      addDiaryDays(pendingWeeklyCheckIn.windowStartDate, index),
  ];
  final learningDays = _buildInclusiveDays(
    startDate: learningStartDate,
    endDate: pendingWeeklyCheckIn.windowEndDate,
  );
  final anchorEntry = settings.cycleAnchorEntryForDay(
    pendingWeeklyCheckIn.windowEndDate,
  );
  final anchorWeightSourceDay = anchorEntry == null
      ? null
      : CalorieWeeklyWindowResolver.anchorWeightSourceDayForWindow(
          anchorEntry: anchorEntry,
          windowStartDate: pendingWeeklyCheckIn.windowStartDate,
        );
  final learningPreviousBoundaryDay = previousDiaryDay(learningStartDate);
  final shouldUseLearningPreviousBoundary =
      learningPreviousBoundaryDay.isAfter(
        normalizeDiaryDay(
          anchorEntry?.effectiveCountingStartDate ?? learningStartDate,
        ),
      ) ||
      learningStartDate.isAfter(pendingWeeklyCheckIn.windowStartDate);
  final isFirstWindow =
      anchorEntry != null &&
      CalorieWeeklyWindowResolver.isFirstWindowStart(
        anchorEntry: anchorEntry,
        windowStartDate: pendingWeeklyCheckIn.windowStartDate,
      );
  return _DebugWeeklyDates(
    pendingWeeklyCheckIn: pendingWeeklyCheckIn,
    anchorEntry: anchorEntry,
    anchorWeightSourceDay: anchorWeightSourceDay,
    learningStartDate: learningStartDate,
    learningDays: learningDays,
    windowDays: windowDays,
    learningPreviousBoundaryDay: learningPreviousBoundaryDay,
    shouldUseLearningPreviousBoundary: shouldUseLearningPreviousBoundary,
    isFirstWindow: isFirstWindow,
    previousBoundaryDay: isFirstWindow
        ? null
        : previousDiaryDay(pendingWeeklyCheckIn.windowStartDate),
    nextBoundaryDay: nextDiaryDay(pendingWeeklyCheckIn.windowEndDate),
  );
}

_DebugWeeklyWeightData _mergeDebugWeeklyWeights({
  required CalorieGoalSettings settings,
  required _DebugWeeklyDates dates,
  required Map<String, double> manualWeightByDay,
  required Map<String, double> representativeWeightByDay,
}) {
  final weightByDay = <String, double>{};
  final weightPointByDay = <String, CalorieWeeklyCheckInWeightPoint>{};
  for (final day in dates.learningDays) {
    _putWeightIfAbsent(
      weightByDay: weightByDay,
      weightPointByDay: weightPointByDay,
      displayDay: day,
      weightKg: manualWeightByDay[diaryDayKey(day)],
      dayIndex: dates.dayIndexFor(day),
    );
    _putWeightIfAbsent(
      weightByDay: weightByDay,
      weightPointByDay: weightPointByDay,
      displayDay: day,
      weightKg: representativeWeightByDay[diaryDayKey(day)],
      dayIndex: dates.dayIndexFor(day),
    );
  }

  _putDebugBoundaryWeights(
    dates: dates,
    weightByDay: weightByDay,
    weightPointByDay: weightPointByDay,
    manualWeightByDay: manualWeightByDay,
    representativeWeightByDay: representativeWeightByDay,
  );
  if (dates.isFirstWindow && dates.anchorEntry != null) {
    _putWeightIfAbsent(
      weightByDay: weightByDay,
      weightPointByDay: weightPointByDay,
      displayDay: dates.pendingWeeklyCheckIn.windowStartDate,
      weightKg:
          dates.anchorEntry?.calculatorProfile?.weightKg ??
          settings.calculatorProfile?.weightKg,
      dayIndex: dates.dayIndexFor(dates.pendingWeeklyCheckIn.windowStartDate),
    );
  }

  final weightPoints = weightPointByDay.values.toList(growable: false)
    ..sort((left, right) => left.dayIndex.compareTo(right.dayIndex));
  return _DebugWeeklyWeightData(
    weightByDay: Map<String, double>.unmodifiable(weightByDay),
    weightPoints: List<CalorieWeeklyCheckInWeightPoint>.unmodifiable(
      weightPoints,
    ),
  );
}

void _putDebugBoundaryWeights({
  required _DebugWeeklyDates dates,
  required Map<String, double> weightByDay,
  required Map<String, CalorieWeeklyCheckInWeightPoint> weightPointByDay,
  required Map<String, double> manualWeightByDay,
  required Map<String, double> representativeWeightByDay,
}) {
  final anchorWeightSourceDay = dates.anchorWeightSourceDay;
  if (anchorWeightSourceDay != null) {
    _putBoundaryWeightIfAbsent(
      weightByDay: weightByDay,
      weightPointByDay: weightPointByDay,
      displayDay: dates.pendingWeeklyCheckIn.windowStartDate,
      dayIndex: dates.dayIndexFor(dates.pendingWeeklyCheckIn.windowStartDate),
      dayKey: diaryDayKey(anchorWeightSourceDay),
      manualWeightByDay: manualWeightByDay,
      representativeWeightByDay: representativeWeightByDay,
    );
  }
  if (dates.shouldUseLearningPreviousBoundary) {
    _putBoundaryWeightIfAbsent(
      weightByDay: weightByDay,
      weightPointByDay: weightPointByDay,
      displayDay: dates.learningStartDate,
      dayIndex: 0,
      dayKey: diaryDayKey(dates.learningPreviousBoundaryDay),
      manualWeightByDay: manualWeightByDay,
      representativeWeightByDay: representativeWeightByDay,
    );
  }
  final previousBoundaryDay = dates.previousBoundaryDay;
  if (previousBoundaryDay != null) {
    _putBoundaryWeightIfAbsent(
      weightByDay: weightByDay,
      weightPointByDay: weightPointByDay,
      displayDay: dates.pendingWeeklyCheckIn.windowStartDate,
      dayIndex: dates.dayIndexFor(dates.pendingWeeklyCheckIn.windowStartDate),
      dayKey: diaryDayKey(previousBoundaryDay),
      manualWeightByDay: manualWeightByDay,
      representativeWeightByDay: representativeWeightByDay,
    );
  }
  _putBoundaryWeightIfAbsent(
    weightByDay: weightByDay,
    weightPointByDay: weightPointByDay,
    displayDay: dates.pendingWeeklyCheckIn.windowEndDate,
    dayIndex: dates.dayIndexFor(dates.nextBoundaryDay),
    dayKey: diaryDayKey(dates.nextBoundaryDay),
    manualWeightByDay: manualWeightByDay,
    representativeWeightByDay: representativeWeightByDay,
  );
}

_DebugWeeklyWindowIntakeData _resolveDebugWindowIntakeData({
  required List<DateTime> days,
  required Map<String, List<CalorieEntry>> entriesByDay,
  required CalorieGoalSettings settings,
  required Map<String, int> activeKcalByDay,
  required Map<String, double> weightByDay,
}) {
  final missingIntakeDays = <DateTime>[];
  final windowDays = <_DebugWeeklyWindowDay>[];
  for (final day in days) {
    final dayEntries = entriesByDay[diaryDayKey(day)] ?? const <CalorieEntry>[];
    if (dayEntries.isEmpty) {
      missingIntakeDays.add(day);
    }
    windowDays.add(
      _DebugWeeklyWindowDay(
        day: day,
        hasEntries: dayEntries.isNotEmpty,
        loggedIntakeKcal: _sumCalories(dayEntries),
        resolvedIntakeKcal: null,
        isSkippedIntakeDay: settings.isSkippedIntakeDay(day),
        activeKcal: activeKcalByDay[diaryDayKey(day)] ?? 0,
        weightKg: weightByDay[diaryDayKey(day)],
      ),
    );
  }
  if (missingIntakeDays.length >= weeklyCheckInMissingIntakeBlockThreshold) {
    return _DebugWeeklyWindowIntakeData.blocked(
      days: windowDays,
      blockedReason: 'too_many_missing_intake_days',
      missingIntakeDays: missingIntakeDays,
    );
  }
  return _resolveDebugSkippedWindowIntake(
    windowDays: windowDays,
    missingIntakeDays: missingIntakeDays,
  );
}

_DebugWeeklyWindowIntakeData _resolveDebugSkippedWindowIntake({
  required List<_DebugWeeklyWindowDay> windowDays,
  required List<DateTime> missingIntakeDays,
}) {
  final resolvedWindowIntake = <double>[];
  for (var index = 0; index < windowDays.length; index += 1) {
    final day = windowDays[index];
    if (day.hasEntries) {
      resolvedWindowIntake.add(day.loggedIntakeKcal);
      windowDays[index] = day.copyWith(
        loggedIntakeKcal: day.loggedIntakeKcal,
        resolvedIntakeKcal: day.loggedIntakeKcal,
      );
      continue;
    }
    if (!day.isSkippedIntakeDay) {
      return _DebugWeeklyWindowIntakeData.blocked(
        days: windowDays,
        blockedReason: 'missing_intake_days',
        missingIntakeDays: missingIntakeDays,
      );
    }
    if (resolvedWindowIntake.isEmpty) {
      return _DebugWeeklyWindowIntakeData.blocked(
        days: windowDays,
        blockedReason: 'skipped_day_without_prior_average',
        missingIntakeDays: missingIntakeDays,
      );
    }
    final interpolatedIntakeKcal = CalorieDomainMath.average(
      resolvedWindowIntake,
    );
    resolvedWindowIntake.add(interpolatedIntakeKcal);
    windowDays[index] = day.copyWith(
      loggedIntakeKcal: 0,
      resolvedIntakeKcal: interpolatedIntakeKcal,
    );
  }
  return _DebugWeeklyWindowIntakeData.ready(
    days: windowDays,
    missingIntakeDays: missingIntakeDays,
  );
}

_DebugWeeklyLearningIntakeData _resolveDebugLearningIntakeData({
  required List<DateTime> days,
  required Map<String, List<CalorieEntry>> entriesByDay,
  required CalorieGoalSettings settings,
}) {
  final missingIntakeDays = <DateTime>[];
  final intakeKcalByDay = <double>[];
  for (final day in days) {
    final dayEntries = entriesByDay[diaryDayKey(day)] ?? const <CalorieEntry>[];
    if (dayEntries.isNotEmpty) {
      intakeKcalByDay.add(_sumCalories(dayEntries));
      continue;
    }
    missingIntakeDays.add(day);
    if (!settings.isSkippedIntakeDay(day)) {
      return _DebugWeeklyLearningIntakeData.blocked(
        blockedReason:
            missingIntakeDays.length >= weeklyCheckInMissingIntakeBlockThreshold
            ? 'too_many_missing_intake_days'
            : 'missing_intake_days',
        missingIntakeDays: missingIntakeDays,
      );
    }
    if (intakeKcalByDay.isEmpty) {
      return _DebugWeeklyLearningIntakeData.blocked(
        blockedReason: 'skipped_day_without_prior_average',
        missingIntakeDays: missingIntakeDays,
      );
    }
    intakeKcalByDay.add(CalorieDomainMath.average(intakeKcalByDay));
  }
  return _DebugWeeklyLearningIntakeData.ready(
    intakeKcalByDay: intakeKcalByDay,
    missingIntakeDays: missingIntakeDays,
  );
}

_DebugMissingWeightData? _validateDebugWeeklyWeightData({
  required _DebugWeeklyDates dates,
  required _DebugWeeklyWeightData weightData,
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

DateTime _learningStartDateForCheckIn({
  required CalorieGoalSettings settings,
  required PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
}) {
  final anchorEntry = settings.cycleAnchorEntryForDay(
    pendingWeeklyCheckIn.windowEndDate,
  );
  final anchorStartDate = anchorEntry == null
      ? pendingWeeklyCheckIn.windowStartDate
      : CalorieWeeklyWindowResolver.firstWindowStartDate(anchorEntry);
  final oldestAllowedStartDate = pendingWeeklyCheckIn.windowEndDate.subtract(
    const Duration(days: dailyLearnedTdeeMaximumLookbackDays - 1),
  );
  if (anchorStartDate.isBefore(oldestAllowedStartDate)) {
    return normalizeDiaryDay(oldestAllowedStartDate);
  }
  return normalizeDiaryDay(anchorStartDate);
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
    return CalorieGoalCalculator.calculate(calculatorProfile).tdeeKcal;
  }
  return settings.goalKcalForDay(fallbackDay);
}

int _resolveActiveKcal({
  required DateTime day,
  required DiaryHealthDayData dayData,
}) {
  final summary = buildDiaryActivitySummary(day: day, dayData: dayData);
  return calculateImportedHealthActivityKcal(
    stepsOutsideWorkouts: summary.stepsOutsideWorkouts,
    workoutCalories: summary.workouts.map(
      (workout) => workout.totalCalories,
    ),
    unassignedActiveEnergySegments: summary.unassignedActiveEnergySegments,
  );
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

Map<String, double> _manualWeightByDay(
  List<ManualHealthWeightEntry> manualEntries,
) {
  return <String, double>{
    for (final entry in manualEntries) diaryDayKey(entry.day): entry.weightKg,
  };
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

void _putBoundaryWeightIfAbsent({
  required Map<String, double> weightByDay,
  required Map<String, CalorieWeeklyCheckInWeightPoint> weightPointByDay,
  required DateTime displayDay,
  required int dayIndex,
  required String dayKey,
  required Map<String, double> manualWeightByDay,
  required Map<String, double> representativeWeightByDay,
}) {
  _putWeightIfAbsent(
    weightByDay: weightByDay,
    weightPointByDay: weightPointByDay,
    displayDay: displayDay,
    weightKg: manualWeightByDay[dayKey],
    dayIndex: dayIndex,
  );
  _putWeightIfAbsent(
    weightByDay: weightByDay,
    weightPointByDay: weightPointByDay,
    displayDay: displayDay,
    weightKg: representativeWeightByDay[dayKey],
    dayIndex: dayIndex,
  );
}

void _putWeightIfAbsent({
  required Map<String, double> weightByDay,
  required Map<String, CalorieWeeklyCheckInWeightPoint> weightPointByDay,
  required DateTime displayDay,
  required double? weightKg,
  required int dayIndex,
}) {
  if (weightKg == null) {
    return;
  }
  final displayDayKey = diaryDayKey(displayDay);
  if (weightByDay.containsKey(displayDayKey)) {
    return;
  }
  weightByDay[displayDayKey] = weightKg;
  weightPointByDay[displayDayKey] = CalorieWeeklyCheckInWeightPoint(
    dayIndex: dayIndex,
    weightKg: weightKg,
  );
}

double _sumCalories(List<CalorieEntry> entries) {
  return entries.fold<double>(0, (sum, entry) => sum + entry.totalKcal);
}

List<DateTime> _buildInclusiveDays({
  required DateTime startDate,
  required DateTime endDate,
}) {
  final normalizedStartDate = normalizeDiaryDay(startDate);
  final normalizedEndDate = normalizeDiaryDay(endDate);
  return <DateTime>[
    for (
      var day = normalizedStartDate;
      !day.isAfter(normalizedEndDate);
      day = nextDiaryDay(day)
    )
      day,
  ];
}

int _windowLengthDays(PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn) {
  return pendingWeeklyCheckIn.windowEndDate
          .difference(pendingWeeklyCheckIn.windowStartDate)
          .inDays +
      1;
}

double _windowEatenTotalKcal(List<_DebugWeeklyWindowDay> days) {
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

List<_DebugDumpRow> _activityRows({
  required DateTime day,
  required DiaryHealthDayData data,
}) {
  if (data.totalSteps <= 0 &&
      data.workouts.isEmpty &&
      data.unassignedActiveEnergySegments.isEmpty) {
    return const <_DebugDumpRow>[];
  }
  final summary = buildDiaryActivitySummary(day: day, dayData: data);
  final activityKcal = calculateImportedHealthActivityKcal(
    stepsOutsideWorkouts: summary.stepsOutsideWorkouts,
    workoutCalories: summary.workouts.map(
      (workout) => workout.totalCalories,
    ),
    unassignedActiveEnergySegments: summary.unassignedActiveEnergySegments,
  );
  final workoutKcal = summary.workouts.fold<int>(
    0,
    (sum, workout) {
      final totalCalories = workout.totalCalories;
      return totalCalories == null ? sum : sum + totalCalories;
    },
  );
  final unassignedActiveEnergyKcal = summary.unassignedActiveEnergySegments
      .fold<int>(0, (sum, segment) => sum + segment.totalCalories);

  return [
    _DebugDumpRow(
      sortAt: day,
      typeOrder: 2,
      cells: [
        _formatDay(day),
        '',
        'activity_day',
        'activity_total',
        _formatNumber(activityKcal),
        '',
        '',
        '',
        '',
        data.totalSteps.toString(),
        '',
        'health',
        [
          'steps_outside_workouts=${summary.stepsOutsideWorkouts}',
          'workouts=${summary.workouts.length}',
          'workout_kcal=$workoutKcal',
          'unassigned_active_energy_kcal=$unassignedActiveEnergyKcal',
        ].join('; '),
      ],
    ),
  ];
}

_DebugDumpRow _summaryRow({
  required DateTime startInclusive,
  required DateTime endExclusive,
  required HealthConnectionStatus healthStatus,
}) {
  final endDay = _formatDay(endExclusive);
  final healthState = healthStatus.accessState.name;

  return _DebugDumpRow(
    sortAt: startInclusive,
    typeOrder: -1,
    cells: [
      _formatDay(startInclusive),
      '',
      'summary',
      'calorie_debug_dump',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      'app',
      'end=$endDay; health=$healthState',
    ],
  );
}

List<_DebugDumpRow> _dailyEatenRows({
  required List<CalorieEntry> entries,
  required CalorieGoalSettings settings,
  required DateTime startInclusive,
  required DateTime endExclusive,
}) {
  final kcalByDay = <DateTime, double>{};
  final entryCountByDay = <DateTime, int>{};
  for (final entry in entries) {
    final day = normalizeDiaryDay(entry.loggedAt.toLocal());
    kcalByDay[day] = (kcalByDay[day] ?? 0) + entry.totalKcal;
    entryCountByDay[day] = (entryCountByDay[day] ?? 0) + 1;
  }

  final rows = <_DebugDumpRow>[];
  for (
    var day = normalizeDiaryDay(startInclusive);
    day.isBefore(endExclusive);
    day = nextDiaryDay(day)
  ) {
    if (!_isDebugGoalWindowDay(settings: settings, day: day)) {
      continue;
    }
    final entryCount = entryCountByDay[day] ?? 0;
    rows.add(
      _DebugDumpRow(
        sortAt: day,
        typeOrder: 1,
        cells: [
          _formatDay(day),
          '',
          'eaten_day',
          'eaten_total',
          _formatNumber(kcalByDay[day] ?? 0),
          '',
          '',
          '',
          '',
          '',
          '',
          'app',
          'entries=$entryCount',
        ],
      ),
    );
  }
  return rows;
}

List<_DebugDumpRow> _dailyWeightRows({
  required List<HealthWeightSample> healthWeightSamples,
  required List<ManualHealthWeightEntry> manualWeightEntries,
  required CalorieGoalSettings settings,
  required DateTime startInclusive,
  required DateTime endExclusive,
}) {
  final healthWeightsByDay = <String, List<double>>{};
  final manualWeightByDay = <String, double>{};
  final daysByKey = <String, DateTime>{};
  for (final sample in healthWeightSamples) {
    final day = normalizeDiaryDay(sample.recordedAt);
    final key = diaryDayKey(day);
    daysByKey[key] = day;
    healthWeightsByDay.putIfAbsent(key, () => <double>[]).add(sample.weightKg);
  }
  for (final entry in manualWeightEntries) {
    final day = normalizeDiaryDay(entry.day);
    final key = diaryDayKey(day);
    daysByKey[key] = day;
    manualWeightByDay[key] = entry.weightKg;
  }

  final days = daysByKey.values.toList(growable: false)..sort();
  return [
    for (final day in days)
      if (!day.isBefore(startInclusive) &&
          day.isBefore(endExclusive) &&
          _isDebugGoalWindowDay(settings: settings, day: day))
        _dailyWeightRow(
          day: day,
          manualWeightKg: manualWeightByDay[diaryDayKey(day)],
          healthWeightsKg:
              healthWeightsByDay[diaryDayKey(day)] ?? const <double>[],
        ),
  ];
}

_DebugDumpRow _weightRow({
  required DateTime sortAt,
  required String source,
  required double weightKg,
}) {
  return _DebugDumpRow(
    sortAt: sortAt,
    typeOrder: 4,
    cells: [
      _formatDay(sortAt),
      _formatTime(sortAt),
      'weight',
      'body_weight',
      '',
      '',
      '',
      '',
      '',
      '',
      _formatNumber(weightKg),
      source,
      '',
    ],
  );
}

_DebugDumpRow _dailyWeightRow({
  required DateTime day,
  required double? manualWeightKg,
  required List<double> healthWeightsKg,
}) {
  final weightKg = manualWeightKg ?? CalorieDomainMath.median(healthWeightsKg);
  final source = manualWeightKg == null ? 'health' : 'manual_fallback';
  return _weightRow(
    sortAt: day,
    source: source,
    weightKg: weightKg,
  );
}

List<_DebugDumpRow> _goalWeekRows({
  required CalorieGoalSettings settings,
  required List<_DebugDumpRow> rows,
  required DateTime startInclusive,
  required DateTime endExclusive,
  required Map<String, _DebugWeekTdeeData> learnedTdeeByWeekStart,
}) {
  final goalEntries = _debugGoalEntries(settings);
  if (goalEntries.isEmpty) {
    return const <_DebugDumpRow>[];
  }

  final eatenKcalByDay = _dailyRowKcalByDay(
    rows: rows,
    type: 'eaten_day',
    name: 'eaten_total',
  );
  final activityKcalByDay = _dailyRowKcalByDay(
    rows: rows,
    type: 'activity_day',
    name: 'activity_total',
  );
  final weightByDay = _dailyRowWeightByDay(rows);
  final weekRows = <_DebugDumpRow>[];

  for (var index = 0; index < goalEntries.length; index += 1) {
    final goalEntry = goalEntries[index];
    final goalStart = normalizeDiaryDay(goalEntry.effectiveCountingStartDate);
    final nextGoalStart = index + 1 < goalEntries.length
        ? normalizeDiaryDay(goalEntries[index + 1].effectiveCountingStartDate)
        : endExclusive;
    final goalEndExclusive = nextGoalStart.isBefore(endExclusive)
        ? nextGoalStart
        : endExclusive;

    var weekStart = goalStart;
    var weekNumber = 1;
    while (weekStart.isBefore(goalEndExclusive)) {
      final nextWeekStart = addDiaryDays(weekStart, 7);
      final weekEndExclusive = nextWeekStart.isBefore(goalEndExclusive)
          ? nextWeekStart
          : goalEndExclusive;
      if (!weekEndExclusive.isAfter(startInclusive)) {
        weekStart = nextWeekStart;
        weekNumber += 1;
        continue;
      }

      weekRows
        ..add(
          _weekStartRow(
            settings: settings,
            goalEntry: goalEntry,
            weekStart: weekStart,
            weekEndExclusive: weekEndExclusive,
            weekNumber: weekNumber,
            learnedTdeeByWeekStart: learnedTdeeByWeekStart,
          ),
        )
        ..add(
          _weekSummaryRow(
            settings: settings,
            weekStart: weekStart,
            weekEndExclusive: weekEndExclusive,
            weekNumber: weekNumber,
            eatenKcalByDay: eatenKcalByDay,
            activityKcalByDay: activityKcalByDay,
            weightByDay: weightByDay,
          ),
        );

      weekStart = nextWeekStart;
      weekNumber += 1;
    }
  }

  return List<_DebugDumpRow>.unmodifiable(weekRows);
}

List<CalorieGoalHistoryEntry> _debugGoalEntries(CalorieGoalSettings settings) {
  final entries =
      settings.sortedGoalHistory
          .where((entry) => entry.hasGoal && !entry.isWeeklyCheckIn)
          .toList(growable: false)
        ..sort((left, right) {
          final byStart = left.effectiveCountingStartDate.compareTo(
            right.effectiveCountingStartDate,
          );
          if (byStart != 0) {
            return byStart;
          }
          return left.effectiveChangedAt.compareTo(right.effectiveChangedAt);
        });
  return List<CalorieGoalHistoryEntry>.unmodifiable(entries);
}

_DebugDumpRow _weekStartRow({
  required CalorieGoalSettings settings,
  required CalorieGoalHistoryEntry goalEntry,
  required DateTime weekStart,
  required DateTime weekEndExclusive,
  required int weekNumber,
  required Map<String, _DebugWeekTdeeData> learnedTdeeByWeekStart,
}) {
  final tdeeData = _weekTdeeData(
    settings: settings,
    goalEntry: goalEntry,
    weekStart: weekStart,
    learnedTdeeByWeekStart: learnedTdeeByWeekStart,
  );
  final range =
      '${diaryDayKey(weekStart)}'
      '..${diaryDayKey(previousDiaryDay(weekEndExclusive))}';
  return _DebugDumpRow(
    sortAt: weekStart,
    typeOrder: 0,
    cells: [
      _formatDay(weekStart),
      '',
      'week',
      'week_${weekNumber}_start',
      _formatNumber(tdeeData.tdeeKcal),
      '',
      '',
      '',
      '',
      '',
      '',
      'app',
      [
        'week=$weekNumber',
        'range=$range',
        'tdee_source=${tdeeData.source}',
        'tdee=${_formatNumber(tdeeData.tdeeKcal)}',
        'used=${tdeeData.used}',
      ].join('; '),
    ],
  );
}

_DebugDumpRow _weekSummaryRow({
  required CalorieGoalSettings settings,
  required DateTime weekStart,
  required DateTime weekEndExclusive,
  required int weekNumber,
  required Map<String, double> eatenKcalByDay,
  required Map<String, double> activityKcalByDay,
  required Map<String, double> weightByDay,
}) {
  final days = _buildExclusiveDays(
    startDate: weekStart,
    endExclusive: weekEndExclusive,
  );
  final calculatedGoalTotal = days.fold<double>(
    0,
    (sum, day) => sum + settings.goalKcalForDay(day),
  );
  final eatenTotal = _sumDailyValues(days, eatenKcalByDay);
  final activityTotal = _sumDailyValues(days, activityKcalByDay);
  final weights = [
    for (final day in days)
      if (weightByDay[diaryDayKey(day)] != null)
        (day: day, weightKg: weightByDay[diaryDayKey(day)]!),
  ];
  final startWeight = weights.isEmpty ? null : weights.first.weightKg;
  final endWeight = weights.isEmpty ? null : weights.last.weightKg;
  final weightChange = startWeight == null || endWeight == null
      ? null
      : endWeight - startWeight;
  final summaryDay = previousDiaryDay(weekEndExclusive);
  final range =
      '${diaryDayKey(weekStart)}'
      '..${diaryDayKey(summaryDay)}';
  final sortAt = summaryDay.add(
    const Duration(hours: 23, minutes: 59, seconds: 58),
  );

  return _DebugDumpRow(
    sortAt: sortAt,
    typeOrder: 80,
    cells: [
      _formatDay(sortAt),
      _formatTime(sortAt),
      'week',
      'week_${weekNumber}_summary',
      _formatNumber(calculatedGoalTotal),
      '',
      '',
      '',
      '',
      '',
      _formatNumber(endWeight),
      'app',
      [
        'week=$weekNumber',
        'range=$range',
        'days=${days.length}',
        'calculated_goal_total=${_formatNumber(calculatedGoalTotal)}',
        'eaten_total=${_formatNumber(eatenTotal)}',
        'eaten_minus_goal=${_formatNumber(eatenTotal - calculatedGoalTotal)}',
        'activity_total=${_formatNumber(activityTotal)}',
        'start_weight=${_formatNumber(startWeight)}',
        'end_weight=${_formatNumber(endWeight)}',
        'weight_change=${_formatNumber(weightChange)}',
      ].join('; '),
    ],
  );
}

_DebugWeekTdeeData _weekTdeeData({
  required CalorieGoalSettings settings,
  required CalorieGoalHistoryEntry goalEntry,
  required DateTime weekStart,
  required Map<String, _DebugWeekTdeeData> learnedTdeeByWeekStart,
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
    final measuredTotalTdee = _formatNumber(
      learnedSnapshot.measuredTotalTdeeKcal,
    );
    final measuredBaseTdee = _formatNumber(
      learnedSnapshot.measuredBaseTdeeKcal,
    );
    final creditedActivityAverage = _formatNumber(
      learnedSnapshot.averageCreditedActivityKcal,
    );
    final newTarget = _formatNumber(learnedSnapshot.baseGoalKcal);
    final trendPerDay = learnedSnapshot.trendWeightChangePerDay.toStringAsFixed(
      5,
    );
    final usesHealthActivity = settings.isActivityTrackingActiveForDay(
      learnedSnapshot.windowEndDate,
    );
    return _DebugWeekTdeeData(
      source: 'learned_tdee',
      tdeeKcal: learnedSnapshot.calculatedBaseTdeeKcal,
      used: [
        'snapshot_window=$snapshotWindow',
        'measured_total_tdee=$measuredTotalTdee',
        if (usesHealthActivity) ...[
          'measured_base_tdee=$measuredBaseTdee',
          'credited_activity_average=$creditedActivityAverage',
          'activity_subtracted_from_total_tdee=$creditedActivityAverage',
        ],
        'new_target=$newTarget',
        'trend_kg_per_day=$trendPerDay',
      ].join(','),
    );
  }

  final profile = goalEntry.calculatorProfile ?? settings.calculatorProfile;
  if (profile != null) {
    final calculation = CalorieGoalCalculator.calculate(profile);
    return _DebugWeekTdeeData(
      source: 'calculator_profile',
      tdeeKcal: calculation.tdeeKcal,
      used: _calculatorProfileUsedText(
        profile: profile,
        calculation: calculation,
      ),
    );
  }

  final dailyGoal =
      goalEntry.dailyKcalGoal ??
      settings.goalKcalForDay(
        weekStart,
      );
  return _DebugWeekTdeeData(
    source: 'manual_goal',
    tdeeKcal: dailyGoal,
    used: 'daily_goal=${_formatNumber(dailyGoal)}',
  );
}

String _calculatorProfileUsedText({
  required CalorieCalculatorProfile profile,
  required CalorieGoalCalculationResult calculation,
}) {
  return [
    'sex=${profile.sex.name}',
    'weight_kg=${_formatNumber(profile.weightKg)}',
    'height_cm=${_formatNumber(profile.heightCm)}',
    'age_years=${profile.ageYears}',
    'activity_level=${_formatNumber(profile.activityLevel)}',
    'goal_mode=${profile.goalMode.name}',
    'goal_speed_kg_per_week=${_formatNumber(profile.goalSpeedKgPerWeek)}',
    'bmr=${_formatNumber(calculation.bmrKcal)}',
    'expected_activity=${_formatNumber(calculation.expectedActivityKcal)}',
    'daily_adjustment=${_formatNumber(calculation.dailyAdjustmentKcal)}',
    'final_goal=${_formatNumber(calculation.finalGoalKcal)}',
  ].join(',');
}

Map<String, double> _dailyRowKcalByDay({
  required List<_DebugDumpRow> rows,
  required String type,
  required String name,
}) {
  return <String, double>{
    for (final row in rows)
      if (row.cells[2] == type && row.cells[3] == name)
        diaryDayKey(row.sortAt): _parseDebugNumber(row.cells[4]) ?? 0,
  };
}

Map<String, double> _dailyRowWeightByDay(List<_DebugDumpRow> rows) {
  final weightByDay = <String, double>{};
  for (final row in rows) {
    if (row.cells[2] != 'weight' || row.cells[3] != 'body_weight') {
      continue;
    }
    final weightKg = _parseDebugNumber(row.cells[10]);
    if (weightKg != null) {
      weightByDay[diaryDayKey(row.sortAt)] = weightKg;
    }
  }
  return weightByDay;
}

double _sumDailyValues(
  List<DateTime> days,
  Map<String, double> valuesByDay,
) {
  return days.fold<double>(
    0,
    (sum, day) => sum + (valuesByDay[diaryDayKey(day)] ?? 0),
  );
}

List<DateTime> _buildExclusiveDays({
  required DateTime startDate,
  required DateTime endExclusive,
}) {
  final normalizedStartDate = normalizeDiaryDay(startDate);
  final normalizedEndExclusive = normalizeDiaryDay(endExclusive);
  return <DateTime>[
    for (
      var day = normalizedStartDate;
      day.isBefore(normalizedEndExclusive);
      day = nextDiaryDay(day)
    )
      day,
  ];
}

double? _parseDebugNumber(String value) {
  if (value.isEmpty) {
    return null;
  }
  return double.tryParse(value);
}

String _windowExtra(
  PendingCalorieGoalWeeklyCheckIn window,
  _DebugWeeklyDates dates,
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

String _formatWeightPoints(List<CalorieWeeklyCheckInWeightPoint> points) {
  return points
      .map((point) {
        return '${point.dayIndex}:${point.weightKg.toStringAsFixed(2)}';
      })
      .join(',');
}

String _formatWindowDays(List<_DebugWeeklyWindowDay> days) {
  return days
      .map((day) {
        return '${diaryDayKey(day.day)}'
            ':logged=${day.loggedIntakeKcal.toStringAsFixed(2)}'
            ',resolved=${day.resolvedIntakeKcal?.toStringAsFixed(2) ?? 'null'}'
            ',active=${day.activeKcal}'
            ',weight=${day.weightKg?.toStringAsFixed(2) ?? 'null'}'
            ',skipped=${day.isSkippedIntakeDay}';
      })
      .join(' | ');
}

String _formatDayKeys(List<DateTime> days) {
  return days.map(diaryDayKey).join(',');
}

Set<String> _goalWeekSeparatorDays({
  required CalorieGoalSettings settings,
  required DateTime startInclusive,
  required DateTime endExclusive,
}) {
  final goalEntries = settings.sortedGoalHistory
      .where((entry) => entry.hasGoal && !entry.isWeeklyCheckIn)
      .toList(growable: false);
  final separatorDays = <String>{};
  for (var index = 0; index < goalEntries.length; index += 1) {
    final goalStart = normalizeDiaryDay(
      goalEntries[index].effectiveCountingStartDate,
    );
    final nextGoalStart = index + 1 < goalEntries.length
        ? normalizeDiaryDay(goalEntries[index + 1].effectiveCountingStartDate)
        : endExclusive;
    final goalEndExclusive = nextGoalStart.isBefore(endExclusive)
        ? nextGoalStart
        : endExclusive;

    for (
      var day = addDiaryDays(goalStart, 7);
      day.isBefore(goalEndExclusive);
      day = addDiaryDays(day, 7)
    ) {
      if (!day.isBefore(startInclusive)) {
        separatorDays.add(diaryDayKey(day));
      }
    }
  }
  return separatorDays;
}

String _buildMarkdownTable(
  List<_DebugDumpRow> rows, {
  required Set<String> separatorDays,
}) {
  const headers = [
    'date',
    'time',
    'type',
    'name',
    'kcal',
    'protein_g',
    'carbs_g',
    'fat_g',
    'amount',
    'steps',
    'weight_kg',
    'source',
    'extra',
  ];
  final buffer = StringBuffer()
    ..writeln(_tableLine(headers))
    ..writeln(_tableLine(List<String>.filled(headers.length, '---')));
  final separatedDays = <String>{};
  for (final row in rows) {
    final dayKey = diaryDayKey(row.sortAt);
    if (separatorDays.contains(dayKey) && separatedDays.add(dayKey)) {
      buffer.writeln();
    }
    buffer.writeln(_tableLine(row.cells));
  }
  return buffer.toString();
}

String _tableLine(List<String> cells) {
  return '| ${cells.map(_escapeCell).join(' | ')} |';
}

String _escapeCell(String value) {
  return value
      .replaceAll('\n', ' ')
      .replaceAll('\r', ' ')
      .replaceAll('|', r'\|');
}

String _formatNumber(num? value) {
  if (value == null) {
    return '';
  }
  final asDouble = value.toDouble();
  if (!asDouble.isFinite) {
    return '';
  }
  if (asDouble == asDouble.roundToDouble()) {
    return asDouble.round().toString();
  }
  final rounded = (asDouble * 100).roundToDouble() / 100;
  if (rounded == rounded.roundToDouble()) {
    return rounded.round().toString();
  }
  return rounded.toStringAsFixed(2);
}

String _formatDay(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

String _formatTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  if (local.hour == 0 &&
      local.minute == 0 &&
      local.second == 0 &&
      local.millisecond == 0 &&
      local.microsecond == 0) {
    return '';
  }
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}:'
      '${local.second.toString().padLeft(2, '0')}';
}

int _compareRows(_DebugDumpRow left, _DebugDumpRow right) {
  final timeCompare = left.sortAt.compareTo(right.sortAt);
  if (timeCompare != 0) {
    return timeCompare;
  }
  return left.typeOrder.compareTo(right.typeOrder);
}

DateTime _earliestDate(List<DateTime> dates) {
  return dates.reduce((left, right) => left.isBefore(right) ? left : right);
}

class _DebugWeeklyDates {
  const _DebugWeeklyDates({
    required this.pendingWeeklyCheckIn,
    required this.anchorEntry,
    required this.anchorWeightSourceDay,
    required this.learningStartDate,
    required this.learningDays,
    required this.windowDays,
    required this.learningPreviousBoundaryDay,
    required this.shouldUseLearningPreviousBoundary,
    required this.isFirstWindow,
    required this.previousBoundaryDay,
    required this.nextBoundaryDay,
  });

  final PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn;
  final CalorieGoalHistoryEntry? anchorEntry;
  final DateTime? anchorWeightSourceDay;
  final DateTime learningStartDate;
  final List<DateTime> learningDays;
  final List<DateTime> windowDays;
  final DateTime learningPreviousBoundaryDay;
  final bool shouldUseLearningPreviousBoundary;
  final bool isFirstWindow;
  final DateTime? previousBoundaryDay;
  final DateTime nextBoundaryDay;

  List<DateTime> get healthWeightStartCandidates {
    return <DateTime>[
      learningStartDate,
      ?anchorWeightSourceDay,
      if (shouldUseLearningPreviousBoundary) learningPreviousBoundaryDay,
      ?previousBoundaryDay,
    ];
  }

  int dayIndexFor(DateTime day) {
    return normalizeDiaryDay(day).difference(learningStartDate).inDays;
  }
}

class _DebugWeeklyHealthData {
  const _DebugWeeklyHealthData({
    required this.activeKcalByDay,
    required this.representativeWeightByDay,
  });

  final Map<String, int> activeKcalByDay;
  final Map<String, double> representativeWeightByDay;
}

class _DebugWeeklyWeightData {
  const _DebugWeeklyWeightData({
    required this.weightByDay,
    required this.weightPoints,
  });

  final Map<String, double> weightByDay;
  final List<CalorieWeeklyCheckInWeightPoint> weightPoints;
}

class _DebugWeeklyRowResult {
  const _DebugWeeklyRowResult({
    required this.rows,
    required this.calculation,
    required this.windowDays,
    required this.intakeKcalByDay,
    required this.weightPoints,
  });

  final List<_DebugDumpRow> rows;
  final CalorieWeeklyCheckInCalculation? calculation;
  final List<_DebugWeeklyWindowDay> windowDays;
  final List<double> intakeKcalByDay;
  final List<CalorieWeeklyCheckInWeightPoint> weightPoints;
}

class _DebugWeeklyRowsResult {
  const _DebugWeeklyRowsResult({
    required this.rows,
    required this.learnedTdeeByWeekStart,
  });

  const _DebugWeeklyRowsResult.empty()
    : rows = const <_DebugDumpRow>[],
      learnedTdeeByWeekStart = const <String, _DebugWeekTdeeData>{};

  final List<_DebugDumpRow> rows;
  final Map<String, _DebugWeekTdeeData> learnedTdeeByWeekStart;
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

class _DebugWeekTdeeData {
  const _DebugWeekTdeeData({
    required this.source,
    required this.tdeeKcal,
    required this.used,
  });

  final String source;
  final double tdeeKcal;
  final String used;
}

class _DebugWeeklyWindowDay {
  const _DebugWeeklyWindowDay({
    required this.day,
    required this.hasEntries,
    required this.loggedIntakeKcal,
    required this.resolvedIntakeKcal,
    required this.isSkippedIntakeDay,
    required this.activeKcal,
    required this.weightKg,
  });

  final DateTime day;
  final bool hasEntries;
  final double loggedIntakeKcal;
  final double? resolvedIntakeKcal;
  final bool isSkippedIntakeDay;
  final int activeKcal;
  final double? weightKg;

  _DebugWeeklyWindowDay copyWith({
    required double loggedIntakeKcal,
    required double resolvedIntakeKcal,
  }) {
    return _DebugWeeklyWindowDay(
      day: day,
      hasEntries: hasEntries,
      loggedIntakeKcal: loggedIntakeKcal,
      resolvedIntakeKcal: resolvedIntakeKcal,
      isSkippedIntakeDay: isSkippedIntakeDay,
      activeKcal: activeKcal,
      weightKg: weightKg,
    );
  }
}

class _DebugWeeklyWindowIntakeData {
  const _DebugWeeklyWindowIntakeData._({
    required this.days,
    required this.missingIntakeDays,
    required this.blockedReason,
  });

  factory _DebugWeeklyWindowIntakeData.ready({
    required List<_DebugWeeklyWindowDay> days,
    required List<DateTime> missingIntakeDays,
  }) {
    return _DebugWeeklyWindowIntakeData._(
      days: List<_DebugWeeklyWindowDay>.unmodifiable(days),
      missingIntakeDays: List<DateTime>.unmodifiable(missingIntakeDays),
      blockedReason: null,
    );
  }

  factory _DebugWeeklyWindowIntakeData.blocked({
    required List<_DebugWeeklyWindowDay> days,
    required String blockedReason,
    required List<DateTime> missingIntakeDays,
  }) {
    return _DebugWeeklyWindowIntakeData._(
      days: List<_DebugWeeklyWindowDay>.unmodifiable(days),
      missingIntakeDays: List<DateTime>.unmodifiable(missingIntakeDays),
      blockedReason: blockedReason,
    );
  }

  final List<_DebugWeeklyWindowDay> days;
  final List<DateTime> missingIntakeDays;
  final String? blockedReason;
}

class _DebugWeeklyLearningIntakeData {
  const _DebugWeeklyLearningIntakeData._({
    required this.intakeKcalByDay,
    required this.missingIntakeDays,
    required this.blockedReason,
  });

  factory _DebugWeeklyLearningIntakeData.ready({
    required List<double> intakeKcalByDay,
    required List<DateTime> missingIntakeDays,
  }) {
    return _DebugWeeklyLearningIntakeData._(
      intakeKcalByDay: List<double>.unmodifiable(intakeKcalByDay),
      missingIntakeDays: List<DateTime>.unmodifiable(missingIntakeDays),
      blockedReason: null,
    );
  }

  factory _DebugWeeklyLearningIntakeData.blocked({
    required String blockedReason,
    required List<DateTime> missingIntakeDays,
  }) {
    return _DebugWeeklyLearningIntakeData._(
      intakeKcalByDay: const <double>[],
      missingIntakeDays: List<DateTime>.unmodifiable(missingIntakeDays),
      blockedReason: blockedReason,
    );
  }

  final List<double> intakeKcalByDay;
  final List<DateTime> missingIntakeDays;
  final String? blockedReason;
}

class _DebugMissingWeightData {
  const _DebugMissingWeightData({
    required this.reason,
    required this.missingWeightDays,
  });

  final String reason;
  final List<DateTime> missingWeightDays;
}

class _DebugDumpRow {
  const _DebugDumpRow({
    required this.sortAt,
    required this.typeOrder,
    required this.cells,
  }) : assert(cells.length == 13, 'Debug dump rows must have 13 cells.');

  final DateTime sortAt;
  final int typeOrder;
  final List<String> cells;
}
