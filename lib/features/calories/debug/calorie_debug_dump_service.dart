import 'package:yamt/features/calories/application/calorie_health_activity_kcal_reader.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/debug/calorie_debug_dump_formatting.dart';
import 'package:yamt/features/calories/debug/calorie_debug_weekly_checkin_rows.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart'
    show CalorieCalculatorProfile;
import 'package:yamt/features/calories/domain/calorie_domain_math.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
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
  final rows = <CalorieDebugDumpRow>[
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
        CalorieDebugDumpRow(
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
  final weeklyCheckInResult = await buildCalorieDebugWeeklyCheckInRows(
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

  final sortedRows = List<CalorieDebugDumpRow>.of(rows)..sort(_compareRows);
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

Future<List<CalorieDebugDumpRow>> _loadHealthRows({
  required DateTime startInclusive,
  required DateTime endExclusive,
  required CalorieGoalSettings settings,
  required DiaryHealthService diaryHealthService,
  required HealthWeightService healthWeightService,
  required List<ManualHealthWeightEntry> manualWeightEntries,
  required double? userHeightCm,
}) async {
  final rows = <CalorieDebugDumpRow>[];
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
  for (final day in activityDays) {
    final data = await diaryHealthService.loadDayData(
      day: day,
      userHeightCm: userHeightCm,
    );
    rows.addAll(_activityRows(day: day, data: data));
  }
  return rows;
}

List<CalorieDebugDumpRow> _activityRows({
  required DateTime day,
  required DiaryHealthDayData data,
}) {
  if (data.totalSteps <= 0 &&
      data.workouts.isEmpty &&
      data.unassignedActiveEnergySegments.isEmpty) {
    return const <CalorieDebugDumpRow>[];
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
    CalorieDebugDumpRow(
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

CalorieDebugDumpRow _summaryRow({
  required DateTime startInclusive,
  required DateTime endExclusive,
  required HealthConnectionStatus healthStatus,
}) {
  final endDay = _formatDay(endExclusive);
  final healthState = healthStatus.accessState.name;

  return CalorieDebugDumpRow(
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

List<CalorieDebugDumpRow> _dailyEatenRows({
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

  final rows = <CalorieDebugDumpRow>[];
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
      CalorieDebugDumpRow(
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

List<CalorieDebugDumpRow> _dailyWeightRows({
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

CalorieDebugDumpRow _weightRow({
  required DateTime sortAt,
  required String source,
  required double weightKg,
}) {
  return CalorieDebugDumpRow(
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

CalorieDebugDumpRow _dailyWeightRow({
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

List<CalorieDebugDumpRow> _goalWeekRows({
  required CalorieGoalSettings settings,
  required List<CalorieDebugDumpRow> rows,
  required DateTime startInclusive,
  required DateTime endExclusive,
  required Map<String, CalorieDebugWeekTdeeData> learnedTdeeByWeekStart,
}) {
  final goalEntries = _debugGoalEntries(settings);
  if (goalEntries.isEmpty) {
    return const <CalorieDebugDumpRow>[];
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
  final weekRows = <CalorieDebugDumpRow>[];

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

  return List<CalorieDebugDumpRow>.unmodifiable(weekRows);
}

Set<String> _goalWeekSeparatorDays({
  required CalorieGoalSettings settings,
  required DateTime startInclusive,
  required DateTime endExclusive,
}) {
  final goalEntries = _debugGoalEntries(settings);
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

CalorieDebugDumpRow _weekStartRow({
  required CalorieGoalSettings settings,
  required CalorieGoalHistoryEntry goalEntry,
  required DateTime weekStart,
  required DateTime weekEndExclusive,
  required int weekNumber,
  required Map<String, CalorieDebugWeekTdeeData> learnedTdeeByWeekStart,
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
  return CalorieDebugDumpRow(
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

CalorieDebugDumpRow _weekSummaryRow({
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

  return CalorieDebugDumpRow(
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

CalorieDebugWeekTdeeData _weekTdeeData({
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
    return CalorieDebugWeekTdeeData(
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
      goalEntry.dailyKcalGoal ??
      settings.goalKcalForDay(
        weekStart,
      );
  return CalorieDebugWeekTdeeData(
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
  required List<CalorieDebugDumpRow> rows,
  required String type,
  required String name,
}) {
  return <String, double>{
    for (final row in rows)
      if (row.cells[2] == type && row.cells[3] == name)
        diaryDayKey(row.sortAt): _parseDebugNumber(row.cells[4]) ?? 0,
  };
}

Map<String, double> _dailyRowWeightByDay(List<CalorieDebugDumpRow> rows) {
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

String _buildMarkdownTable(
  List<CalorieDebugDumpRow> rows, {
  required Set<String> separatorDays,
}) {
  return buildCalorieDebugMarkdownTable(
    rows,
    separatorDays: separatorDays,
  );
}

String _formatNumber(num? value) {
  return formatCalorieDebugNumber(value);
}

String _formatDay(DateTime dateTime) {
  return formatCalorieDebugDay(dateTime);
}

String _formatTime(DateTime dateTime) {
  return formatCalorieDebugTime(dateTime);
}

int _compareRows(CalorieDebugDumpRow left, CalorieDebugDumpRow right) {
  return compareCalorieDebugRows(left, right);
}
