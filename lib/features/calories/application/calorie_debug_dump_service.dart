import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

const _debugWeightLookbackYears = 10;
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

  /// Markdown table printed to debug console.
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
  final activityStartInclusive = _resolveActivityStart(
    today: today,
    firstEntryDate: firstEntryDate,
  );
  final weightStartInclusive = DateTime(
    today.year - _debugWeightLookbackYears,
    today.month,
    today.day,
  );
  final startInclusive = _earliestDate([
    activityStartInclusive,
    weightStartInclusive,
    for (final entry in manualWeightEntries) normalizeDiaryDay(entry.day),
  ]);
  final calorieEntries = await calorieLogRepository.readEntriesInRange(
    startInclusive: activityStartInclusive,
    endExclusive: endExclusive,
  );
  final settings = await settingsFuture;
  final healthStatus = await healthStatusFuture;
  final rows = <_DebugDumpRow>[
    _summaryRow(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
      healthStatus: healthStatus,
    ),
    ..._dailyEatenRows(
      entries: calorieEntries,
      startInclusive: activityStartInclusive,
      endExclusive: endExclusive,
    ),
    ...manualWeightEntries.map(_manualWeightRow),
  ];

  if (healthStatus.accessState == HealthDataAccessState.ready) {
    rows.addAll(
      await _loadHealthRows(
        activityStartInclusive: activityStartInclusive,
        weightStartInclusive: weightStartInclusive,
        endExclusive: endExclusive,
        diaryHealthService: diaryHealthService,
        healthWeightService: healthWeightService,
        userHeightCm: settings.calculatorProfile?.heightCm,
      ),
    );
  } else {
    rows.add(
      _DebugDumpRow(
        sortAt: activityStartInclusive,
        typeOrder: 0,
        cells: [
          _formatDay(activityStartInclusive),
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
  rows.addAll(
    await _weeklyCheckInRows(
      settings: settings,
      calorieEntries: calorieEntries,
      manualWeightEntries: manualWeightEntries,
      healthStatus: healthStatus,
      diaryHealthService: diaryHealthService,
      healthWeightService: healthWeightService,
      today: today,
    ),
  );

  final sortedRows = List<_DebugDumpRow>.of(rows)..sort(_compareRows);
  final table = _buildMarkdownTable(sortedRows);
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

Future<List<_DebugDumpRow>> _loadHealthRows({
  required DateTime activityStartInclusive,
  required DateTime weightStartInclusive,
  required DateTime endExclusive,
  required DiaryHealthService diaryHealthService,
  required HealthWeightService healthWeightService,
  required double? userHeightCm,
}) async {
  final rows = <_DebugDumpRow>[];
  final weightSamples = await healthWeightService.loadWeightSamples(
    startInclusive: weightStartInclusive,
    endExclusive: endExclusive,
  );
  rows.addAll(weightSamples.map(_healthWeightRow));

  for (
    var day = normalizeDiaryDay(activityStartInclusive);
    day.isBefore(endExclusive);
    day = nextDiaryDay(day)
  ) {
    final data = await diaryHealthService.loadDayData(
      day: day,
      userHeightCm: userHeightCm,
    );
    rows.addAll(_activityRows(day: day, data: data));
  }
  return rows;
}

Future<List<_DebugDumpRow>> _weeklyCheckInRows({
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
    return const <_DebugDumpRow>[];
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

  var previousGoalKcal = settings.goalKcalForDay(windows.first.windowEndDate);
  var previousLearnedTdeeKcal = _previousLearnedTdeeKcalBeforeDay(
    settings: settings,
    day: windows.first.windowStartDate,
    fallbackDay: windows.first.windowEndDate,
  );
  final rows = <_DebugDumpRow>[];
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
    );
    rows.add(result.row);
    final calculation = result.calculation;
    if (calculation != null) {
      previousGoalKcal = calculation.newGoalKcal.roundToDouble();
      previousLearnedTdeeKcal = calculation.calculatedTrueTdeeKcal;
    }
  }
  return List<_DebugDumpRow>.unmodifiable(rows);
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
  var windowStartDate = _firstWeeklyCheckInWindowStartDate(anchorEntry);
  while (true) {
    final windowLengthDays = _weeklyCheckInWindowLengthDaysForStart(
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
      row: _blockedWeeklyCheckInRow(
        window: window,
        dates: dates,
        reason: blockedWindowReason,
        windowDays: windowIntake.days,
        missingIntakeDays: windowIntake.missingIntakeDays,
        missingWeightDays: const <DateTime>[],
      ),
      calculation: null,
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
      row: _blockedWeeklyCheckInRow(
        window: window,
        dates: dates,
        reason: blockedLearningReason,
        windowDays: windowIntake.days,
        missingIntakeDays: learningIntake.missingIntakeDays,
        missingWeightDays: const <DateTime>[],
      ),
      calculation: null,
    );
  }

  final missingWeight = _validateDebugWeeklyWeightData(
    dates: dates,
    weightData: weightData,
  );
  if (missingWeight != null) {
    return _DebugWeeklyRowResult(
      row: _blockedWeeklyCheckInRow(
        window: window,
        dates: dates,
        reason: missingWeight.reason,
        windowDays: windowIntake.days,
        missingIntakeDays: windowIntake.missingIntakeDays,
        missingWeightDays: missingWeight.missingWeightDays,
      ),
      calculation: null,
    );
  }

  final calculatorProfile = _calculatorProfileForDay(
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
    row: _readyWeeklyCheckInRow(
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
  );
}

_DebugDumpRow _readyWeeklyCheckInRow({
  required PendingCalorieGoalWeeklyCheckIn window,
  required _DebugWeeklyDates dates,
  required double previousGoalKcal,
  required double previousLearnedTdeeKcal,
  required CalorieWeeklyCheckInCalculation calculation,
  required List<_DebugWeeklyWindowDay> windowDays,
  required List<double> intakeKcalByDay,
  required List<CalorieWeeklyCheckInWeightPoint> weightPoints,
}) {
  final trendWeightChangePerDay = calculation.trendWeightChangePerDay
      .toStringAsFixed(5);
  return _weeklyRow(
    window: window,
    name: 'learned_tdee',
    kcal: calculation.calculatedTrueTdeeKcal,
    extra: [
      _windowExtra(window, dates),
      'previous_goal=${_formatNumber(previousGoalKcal)}',
      'previous_learned_tdee=${_formatNumber(previousLearnedTdeeKcal)}',
      'trend_kg_per_day=$trendWeightChangePerDay',
      'average_intake=${_formatNumber(calculation.averageIntakeKcal)}',
      'measured_tdee=${_formatNumber(calculation.measuredTrueTdeeKcal)}',
      'learned_tdee=${_formatNumber(calculation.calculatedTrueTdeeKcal)}',
      'new_goal=${_formatNumber(calculation.newGoalKcal)}',
      'active_average=${_formatNumber(calculation.lastWeekAverageActiveKcal)}',
      'due_active=${calculation.todayActiveKcal}',
      'activity_delta=${_formatNumber(calculation.activityDeltaKcal)}',
      'dynamic_goal=${_formatNumber(calculation.dynamicGoalTodayKcal)}',
      'low_confidence=${weightPoints.length <= 2}',
      'intake=[${_formatDoubleList(intakeKcalByDay)}]',
      'active=[${windowDays.map((day) => day.activeKcal).join(',')}]',
      'weight_points=[${_formatWeightPoints(weightPoints)}]',
      'days=[${_formatWindowDays(windowDays)}]',
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
}) {
  final sortAt = window.windowEndDate.add(
    const Duration(hours: 23, minutes: 59, seconds: 59),
  );
  return _DebugDumpRow(
    sortAt: sortAt,
    typeOrder: 9,
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
  final activeKcalByDay = <String, int>{};
  for (final day in activeDays.values) {
    final dayData = await diaryHealthService.loadDayData(
      day: day,
      userHeightCm: settings.calculatorProfile?.heightCm,
    );
    activeKcalByDay[diaryDayKey(day)] = _resolveActiveKcal(
      day: day,
      dayData: dayData,
    );
  }

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
      : _anchorWeightSourceDayForWindow(
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
      _isFirstWeeklyCheckInWindowStart(
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
    final interpolatedIntakeKcal = _averageDouble(resolvedWindowIntake);
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
    intakeKcalByDay.add(_averageDouble(intakeKcalByDay));
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
      : _firstWeeklyCheckInWindowStartDate(anchorEntry);
  final oldestAllowedStartDate = pendingWeeklyCheckIn.windowEndDate.subtract(
    const Duration(days: dailyLearnedTdeeMaximumLookbackDays - 1),
  );
  if (anchorStartDate.isBefore(oldestAllowedStartDate)) {
    return normalizeDiaryDay(oldestAllowedStartDate);
  }
  return normalizeDiaryDay(anchorStartDate);
}

CalorieCalculatorProfile? _calculatorProfileForDay({
  required CalorieGoalSettings settings,
  required DateTime day,
}) {
  return settings.activeGoalEntryForDay(day)?.calculatorProfile ??
      settings.calculatorProfile;
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
      learnedEntry?.weeklyCheckInSnapshot?.calculatedTrueTdeeKcal;
  if (learnedTdeeKcal != null) {
    return learnedTdeeKcal;
  }
  final calculatorProfile = _calculatorProfileForDay(
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
  return calculateDiaryBurnedCalories(
        stepsOutsideWorkouts: summary.stepsOutsideWorkouts,
        workoutCalories: summary.workouts.map(
          (workout) => workout.totalCalories,
        ),
      ) ??
      0;
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
      entry.key: _medianWeight(entry.value),
  };
}

double _medianWeight(List<double> values) {
  final sorted = List<double>.from(values)..sort();
  final middleIndex = sorted.length ~/ 2;
  if (sorted.length.isOdd) {
    return sorted[middleIndex];
  }
  return (sorted[middleIndex - 1] + sorted[middleIndex]) / 2;
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

double _averageDouble(List<double> values) {
  if (values.isEmpty) {
    return 0;
  }
  return values.fold<double>(0, (sum, value) => sum + value) / values.length;
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

DateTime _firstWeeklyCheckInWindowStartDate(
  CalorieGoalHistoryEntry anchorEntry,
) {
  final anchorStartDate = normalizeDiaryDay(
    anchorEntry.effectiveCountingStartDate,
  );
  if (!isSameDiaryDay(anchorEntry.effectiveDate, anchorStartDate)) {
    return anchorStartDate;
  }
  if (!_hasStarterDay(anchorEntry)) {
    return anchorStartDate;
  }
  return nextDiaryDay(anchorStartDate);
}

bool _hasStarterDay(CalorieGoalHistoryEntry anchorEntry) {
  return isSameDiaryDay(
        anchorEntry.effectiveDate,
        anchorEntry.effectiveCountingStartDate,
      ) &&
      _startsOnPartialDiaryDay(anchorEntry.effectiveChangedAt);
}

bool _startsOnPartialDiaryDay(DateTime changedAt) {
  return changedAt.hour != 0 ||
      changedAt.minute != 0 ||
      changedAt.second != 0 ||
      changedAt.millisecond != 0 ||
      changedAt.microsecond != 0;
}

int _weeklyCheckInWindowLengthDaysForStart({
  required CalorieGoalHistoryEntry anchorEntry,
  required DateTime windowStartDate,
}) {
  if (_hasStarterDay(anchorEntry) &&
      _isFirstWeeklyCheckInWindowStart(
        anchorEntry: anchorEntry,
        windowStartDate: windowStartDate,
      )) {
    return weeklyCheckInWindowLengthDays - 1;
  }
  return weeklyCheckInWindowLengthDays;
}

int _windowLengthDays(PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn) {
  return pendingWeeklyCheckIn.windowEndDate
          .difference(pendingWeeklyCheckIn.windowStartDate)
          .inDays +
      1;
}

bool _isFirstWeeklyCheckInWindowStart({
  required CalorieGoalHistoryEntry anchorEntry,
  required DateTime windowStartDate,
}) {
  return isSameDiaryDay(
    _firstWeeklyCheckInWindowStartDate(anchorEntry),
    windowStartDate,
  );
}

DateTime? _anchorWeightSourceDayForWindow({
  required CalorieGoalHistoryEntry anchorEntry,
  required DateTime windowStartDate,
}) {
  if (!_isFirstWeeklyCheckInWindowStart(
    anchorEntry: anchorEntry,
    windowStartDate: windowStartDate,
  )) {
    return null;
  }
  if (!_hasStarterDay(anchorEntry)) {
    return null;
  }
  return normalizeDiaryDay(anchorEntry.effectiveDate);
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
  if (data.totalSteps <= 0 && data.workouts.isEmpty) {
    return const <_DebugDumpRow>[];
  }

  final rows = <_DebugDumpRow>[
    _DebugDumpRow(
      sortAt: day,
      typeOrder: 2,
      cells: [
        _formatDay(day),
        '',
        'activity_day',
        'steps_total',
        '',
        '',
        '',
        '',
        '',
        data.totalSteps.toString(),
        '',
        'health',
        'workouts=${data.workouts.length}',
      ],
    ),
  ];
  for (final workout in data.workouts) {
    rows.add(
      _DebugDumpRow(
        sortAt: workout.start,
        typeOrder: 3,
        cells: [
          _formatDay(workout.start),
          _formatTime(workout.start),
          'workout',
          workout.activityLabel ?? '',
          _formatNumber(workout.totalCalories),
          '',
          '',
          '',
          '${_formatNumber(workout.durationMinutes)} min',
          workout.totalSteps?.toString() ?? '',
          '',
          workout.sourceName ?? 'health',
          'id=${workout.id}; end=${workout.endExclusive.toIso8601String()}',
        ],
      ),
    );
  }
  return rows;
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

_DebugDumpRow _healthWeightRow(HealthWeightSample sample) {
  return _weightRow(
    sortAt: sample.recordedAt,
    source: 'health',
    weightKg: sample.weightKg,
  );
}

_DebugDumpRow _manualWeightRow(ManualHealthWeightEntry entry) {
  return _weightRow(
    sortAt: entry.day,
    source: 'manual_fallback',
    weightKg: entry.weightKg,
  );
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

String _buildMarkdownTable(List<_DebugDumpRow> rows) {
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
  for (final row in rows) {
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
    required this.row,
    required this.calculation,
  });

  final _DebugDumpRow row;
  final CalorieWeeklyCheckInCalculation? calculation;
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
