import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart'
    show CalorieGoalMode;
import 'package:yamt/features/calories/domain/calorie_carryover_history.dart';
import 'package:yamt/features/calories/domain/calorie_domain_math.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_extensions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_window_resolver.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_entries_controller.dart';

part 'daily_learned_tdee_provider.g.dart';

/// Weekly learned TDEE target that is stable until the next boundary.
class DailyLearnedTdeeGoalData {
  /// Creates learned TDEE goal data.
  const DailyLearnedTdeeGoalData({
    required this.measured,
    required this.calculatedTrueTdeeKcal,
    required this.newGoalKcal,
    required this.averageActiveKcal,
  });

  /// The measured TDEE before EMA smoothing.
  final CalorieMeasuredTdeeCalculation measured;

  /// The smoothed learned maintenance TDEE.
  final double calculatedTrueTdeeKcal;

  /// The capped target goal.
  final double newGoalKcal;

  /// Average active kcal for the week that created the learned target.
  final double averageActiveKcal;
}

/// Resolve optional learned TDEE override for [day].
@riverpod
Future<DailyLearnedTdeeGoalData?> dailyLearnedTdeeGoalForDay(
  Ref ref, {
  required DateTime day,
  required DateTime today,
  required double storedGoalKcal,
}) async {
  ref.watch(calorieOverviewRevisionProvider);

  final normalizedDay = normalizeDiaryDay(day);
  final normalizedToday = normalizeDiaryDay(today);
  final learningReferenceDay = normalizedDay.isAfter(normalizedToday)
      ? normalizedToday
      : normalizedDay;

  final settings = await ref.watch(calorieGoalControllerProvider.future);
  if (!ref.mounted) {
    throw StateError('Weekly learned TDEE disposed.');
  }
  final anchorEntry = settings.cycleAnchorEntryForDay(normalizedDay);
  if (anchorEntry == null) {
    return null;
  }

  final windows = _weeklyLearnedWindowsForDay(
    anchorEntry: anchorEntry,
    day: learningReferenceDay,
  );
  if (windows.isEmpty) {
    return null;
  }

  final firstLearningStartDate = _learningStartDateForWindow(
    anchorEntry: anchorEntry,
    windowEndDate: windows.first.windowEndDate,
  );
  final lastWindow = windows.last;
  final entries = await ref
      .watch(calorieLogRepositoryProvider)
      .readEntriesInRange(
        startInclusive: firstLearningStartDate,
        endExclusive: nextDiaryDay(lastWindow.windowEndDate),
      );
  if (!ref.mounted) {
    throw StateError('Weekly learned TDEE disposed.');
  }
  final snapshotEntry = settings.learnedTdeeEntryForDay(normalizedDay);
  final snapshot = snapshotEntry?.weeklyCheckInSnapshot;
  final snapshotFallback = _snapshotLearnedGoalForEntry(
    learnedEntry: snapshotEntry,
    storedGoalKcal: storedGoalKcal,
  );
  if (entries.isEmpty) {
    return null;
  }

  final healthStatus = await ref.watch(
    healthConnectionControllerProvider.future,
  );
  if (!ref.mounted) {
    throw StateError('Weekly learned TDEE disposed.');
  }
  final manualEntries = await ref.watch(
    manualHealthWeightEntriesControllerProvider.future,
  );
  if (!ref.mounted) {
    throw StateError('Weekly learned TDEE disposed.');
  }
  final healthWeights = await _loadHealthWeights(
    ref,
    healthStatus: healthStatus,
    startDate: _weightStartDateForLearning(
      anchorEntry: anchorEntry,
      firstLearningStartDate: firstLearningStartDate,
    ),
    endDateExclusive: nextDiaryDay(lastWindow.nextBoundaryDay),
  );
  if (!ref.mounted) {
    throw StateError('Weekly learned TDEE disposed.');
  }
  final activeKcalByDay = await _loadActiveKcalByDay(
    ref,
    settings: settings,
    healthStatus: healthStatus,
    windows: windows,
  );
  if (!ref.mounted) {
    throw StateError('Weekly learned TDEE disposed.');
  }

  final entriesByDay = entries.groupByDiaryDayKey();
  final manualWeightByDay = _manualWeightByDay(manualEntries);
  final representativeWeightByDay = _representativeWeightByDay(healthWeights);
  var previousGoalKcal = settings.goalKcalForDay(
    previousDiaryDay(windows.first.windowStartDate),
  );
  if (previousGoalKcal <= 0) {
    previousGoalKcal = storedGoalKcal;
  }
  var previousLearnedTdeeKcal = _learnedTdeeSeed(
    settings: settings,
    day: windows.first.windowStartDate,
    fallbackGoalKcal: previousGoalKcal,
  );
  DailyLearnedTdeeGoalData? latest;

  for (final window in windows) {
    final learningDays = buildCalorieCarryoverDateRange(
      startInclusive: window.learningStartDate,
      endExclusive: nextDiaryDay(window.windowEndDate),
    );
    final intakeKcalByDay = _resolveLearningIntake(
      days: learningDays,
      entriesByDay: entriesByDay,
      settings: settings,
    );
    if (intakeKcalByDay == null) {
      return _latestOrLegacySnapshotBeforeWindow(
        latest: latest,
        settings: settings,
        snapshotFallback: snapshotFallback,
        snapshot: snapshot,
        learningDays: learningDays,
        entriesByDay: entriesByDay,
        window: window,
      );
    }

    final weightPoints = _weeklyWeightPoints(
      settings: settings,
      anchorEntry: anchorEntry,
      window: window,
      manualWeightByDay: manualWeightByDay,
      representativeWeightByDay: representativeWeightByDay,
    );
    if (weightPoints.length < 2) {
      return _latestOrSnapshotForMissingWeight(
        latest: latest,
        snapshotFallback: snapshotFallback,
      );
    }

    final goalMode = _goalModeForDay(
      settings: settings,
      day: window.windowEndDate,
    );
    final goalSpeedKgPerWeek = goalMode == CalorieGoalMode.maintain
        ? 0.0
        : _goalSpeedForDay(settings: settings, day: window.windowEndDate);
    final calculation = CalorieWeeklyCheckInCalculator.calculateLearnedGoal(
      previousGoalKcal: previousGoalKcal,
      previousLearnedTdeeKcal: previousLearnedTdeeKcal,
      goalSpeedKgPerWeek: goalSpeedKgPerWeek,
      isLosing: goalMode == CalorieGoalMode.lose,
      isGaining: goalMode == CalorieGoalMode.gain,
      intakeKcalByDay: intakeKcalByDay,
      weightPoints: weightPoints,
    );
    latest = DailyLearnedTdeeGoalData(
      measured: calculation.measured,
      calculatedTrueTdeeKcal: calculation.calculatedTrueTdeeKcal,
      newGoalKcal: calculation.newGoalKcal,
      averageActiveKcal: _averageActiveKcal(
        days: window.windowDays,
        activeKcalByDay: activeKcalByDay,
      ),
    );
    previousGoalKcal = calculation.newGoalKcal;
    previousLearnedTdeeKcal = calculation.calculatedTrueTdeeKcal;
  }

  return latest;
}

DailyLearnedTdeeGoalData? _latestOrSnapshotForMissingWeight({
  required DailyLearnedTdeeGoalData? latest,
  required DailyLearnedTdeeGoalData? snapshotFallback,
}) {
  return latest ?? snapshotFallback;
}

DailyLearnedTdeeGoalData? _latestOrLegacySnapshotBeforeWindow({
  required DailyLearnedTdeeGoalData? latest,
  required CalorieGoalSettings settings,
  required DailyLearnedTdeeGoalData? snapshotFallback,
  required CalorieGoalWeeklyCheckInSnapshot? snapshot,
  required List<DateTime> learningDays,
  required Map<String, List<CalorieEntry>> entriesByDay,
  required _WeeklyLearnedWindow window,
}) {
  if (latest != null) {
    return latest;
  }
  if (snapshot == null) {
    return null;
  }
  if (!window.windowEndDate.isBefore(
    normalizeDiaryDay(snapshot.windowStartDate),
  )) {
    return null;
  }
  if (_hasLearnedSnapshotForWindow(settings: settings, window: window)) {
    return null;
  }
  if (_hasEntriesForAnyDay(days: learningDays, entriesByDay: entriesByDay)) {
    return null;
  }
  return snapshotFallback;
}

bool _hasLearnedSnapshotForWindow({
  required CalorieGoalSettings settings,
  required _WeeklyLearnedWindow window,
}) {
  for (final entry in settings.sortedGoalHistory) {
    final snapshot = entry.weeklyCheckInSnapshot;
    if (snapshot == null) {
      continue;
    }
    if (isSameDiaryDay(snapshot.windowStartDate, window.windowStartDate) &&
        isSameDiaryDay(snapshot.windowEndDate, window.windowEndDate)) {
      return true;
    }
  }
  return false;
}

bool _hasEntriesForAnyDay({
  required List<DateTime> days,
  required Map<String, List<CalorieEntry>> entriesByDay,
}) {
  for (final day in days) {
    final entries = entriesByDay[diaryDayKey(day)];
    if (entries != null && entries.isNotEmpty) {
      return true;
    }
  }
  return false;
}

DailyLearnedTdeeGoalData? _snapshotLearnedGoalForEntry({
  required CalorieGoalHistoryEntry? learnedEntry,
  required double storedGoalKcal,
}) {
  final snapshot = learnedEntry?.weeklyCheckInSnapshot;
  if (snapshot == null) {
    return null;
  }
  return DailyLearnedTdeeGoalData(
    measured: CalorieMeasuredTdeeCalculation(
      trendWeightChangePerDay: snapshot.trendWeightChangePerDay,
      averageIntakeKcal: snapshot.calculatedTrueTdeeKcal,
      measuredTrueTdeeKcal: snapshot.calculatedTrueTdeeKcal,
    ),
    calculatedTrueTdeeKcal: snapshot.calculatedTrueTdeeKcal,
    newGoalKcal: learnedEntry?.dailyKcalGoal ?? storedGoalKcal,
    averageActiveKcal: snapshot.averageActiveKcal,
  );
}

List<_WeeklyLearnedWindow> _weeklyLearnedWindowsForDay({
  required CalorieGoalHistoryEntry anchorEntry,
  required DateTime day,
}) {
  final windows = <_WeeklyLearnedWindow>[];
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
    if (dueDate.isAfter(day)) {
      break;
    }
    final windowEndDate = addDiaryDays(windowStartDate, windowLengthDays - 1);
    final learningStartDate = _learningStartDateForWindow(
      anchorEntry: anchorEntry,
      windowEndDate: windowEndDate,
    );
    windows.add(
      _WeeklyLearnedWindow(
        windowStartDate: windowStartDate,
        windowEndDate: windowEndDate,
        dueDate: dueDate,
        learningStartDate: learningStartDate,
        windowDays: buildCalorieCarryoverDateRange(
          startInclusive: windowStartDate,
          endExclusive: dueDate,
        ),
        nextBoundaryDay: nextDiaryDay(windowEndDate),
        previousBoundaryDay: windows.isEmpty
            ? null
            : previousDiaryDay(windowStartDate),
      ),
    );
    windowStartDate = nextDiaryDay(windowEndDate);
  }
  return List<_WeeklyLearnedWindow>.unmodifiable(windows);
}

DateTime _learningStartDateForWindow({
  required CalorieGoalHistoryEntry anchorEntry,
  required DateTime windowEndDate,
}) {
  final anchorStartDate = CalorieWeeklyWindowResolver.firstWindowStartDate(
    anchorEntry,
  );
  final oldestAllowedStartDate = windowEndDate.subtract(
    const Duration(days: dailyLearnedTdeeMaximumLookbackDays - 1),
  );
  if (anchorStartDate.isBefore(oldestAllowedStartDate)) {
    return normalizeDiaryDay(oldestAllowedStartDate);
  }
  return normalizeDiaryDay(anchorStartDate);
}

DateTime _weightStartDateForLearning({
  required CalorieGoalHistoryEntry anchorEntry,
  required DateTime firstLearningStartDate,
}) {
  final anchorWeightSourceDay =
      CalorieWeeklyWindowResolver.anchorWeightSourceDayForWindow(
        anchorEntry: anchorEntry,
        windowStartDate: CalorieWeeklyWindowResolver.firstWindowStartDate(
          anchorEntry,
        ),
      );
  if (anchorWeightSourceDay != null &&
      anchorWeightSourceDay.isBefore(firstLearningStartDate)) {
    return anchorWeightSourceDay;
  }
  return firstLearningStartDate;
}

Future<List<HealthWeightSample>> _loadHealthWeights(
  Ref ref, {
  required HealthConnectionStatus healthStatus,
  required DateTime startDate,
  required DateTime endDateExclusive,
}) async {
  if (healthStatus.accessState != HealthDataAccessState.ready) {
    return const <HealthWeightSample>[];
  }
  return ref
      .watch(healthWeightServiceProvider)
      .loadWeightSamples(
        startInclusive: startDate,
        endExclusive: endDateExclusive,
      );
}

Future<Map<String, int>> _loadActiveKcalByDay(
  Ref ref, {
  required CalorieGoalSettings settings,
  required HealthConnectionStatus healthStatus,
  required List<_WeeklyLearnedWindow> windows,
}) async {
  final activeKcalByDay = <String, int>{};
  for (final window in windows) {
    for (final day in window.windowDays) {
      activeKcalByDay[diaryDayKey(day)] = 0;
    }
  }
  if (healthStatus.accessState != HealthDataAccessState.ready) {
    return activeKcalByDay;
  }

  final diaryHealthService = ref.watch(diaryHealthServiceProvider);
  final userHeightCm = settings.calculatorProfile?.heightCm;
  final days = {
    for (final window in windows)
      for (final windowDay in window.windowDays)
        diaryDayKey(windowDay): windowDay,
  }.values.toList(growable: false);
  final dayDataResults = await Future.wait([
    for (final day in days)
      () async {
        final dayData = await diaryHealthService.loadDayData(
          day: day,
          userHeightCm: userHeightCm,
        );
        return (day: day, dayData: dayData);
      }(),
  ]);
  if (!ref.mounted) {
    throw StateError('Weekly learned TDEE disposed.');
  }
  for (final result in dayDataResults) {
    activeKcalByDay[diaryDayKey(result.day)] = _resolveActiveKcal(
      day: result.day,
      dayData: result.dayData,
    );
  }
  return activeKcalByDay;
}

List<double>? _resolveLearningIntake({
  required List<DateTime> days,
  required Map<String, List<CalorieEntry>> entriesByDay,
  required CalorieGoalSettings settings,
}) {
  final intakeKcalByDay = <double>[];
  for (final day in days) {
    final dayEntries = entriesByDay[diaryDayKey(day)] ?? const <CalorieEntry>[];
    if (dayEntries.isNotEmpty) {
      intakeKcalByDay.add(
        dayEntries.fold<double>(
          0,
          (sum, entry) => sum + entry.totalKcal,
        ),
      );
      continue;
    }
    if (!settings.isSkippedIntakeDay(day) || intakeKcalByDay.isEmpty) {
      return null;
    }
    intakeKcalByDay.add(CalorieDomainMath.average(intakeKcalByDay));
  }
  return intakeKcalByDay;
}

List<CalorieWeeklyCheckInWeightPoint> _weeklyWeightPoints({
  required CalorieGoalSettings settings,
  required CalorieGoalHistoryEntry anchorEntry,
  required _WeeklyLearnedWindow window,
  required Map<String, double> manualWeightByDay,
  required Map<String, double> representativeWeightByDay,
}) {
  final weightPointsByDay = <String, CalorieWeeklyCheckInWeightPoint>{};
  for (
    var day = window.learningStartDate;
    !day.isAfter(window.windowEndDate);
    day = nextDiaryDay(day)
  ) {
    _putWeightPoint(
      pointsByDay: weightPointsByDay,
      displayDay: day,
      dayIndex: window.dayIndexFor(day),
      weightKg:
          manualWeightByDay[diaryDayKey(day)] ??
          representativeWeightByDay[diaryDayKey(day)],
    );
  }

  if (CalorieWeeklyWindowResolver.isFirstWindowStart(
    anchorEntry: anchorEntry,
    windowStartDate: window.windowStartDate,
  )) {
    final anchorWeightSourceDay =
        CalorieWeeklyWindowResolver.anchorWeightSourceDayForWindow(
          anchorEntry: anchorEntry,
          windowStartDate: window.windowStartDate,
        );
    final anchorWeightKey = anchorWeightSourceDay == null
        ? null
        : diaryDayKey(anchorWeightSourceDay);
    _putWeightPoint(
      pointsByDay: weightPointsByDay,
      displayDay: window.windowStartDate,
      dayIndex: window.dayIndexFor(window.windowStartDate),
      weightKg:
          (anchorWeightKey == null
              ? null
              : manualWeightByDay[anchorWeightKey] ??
                    representativeWeightByDay[anchorWeightKey]) ??
          anchorEntry.calculatorProfile?.weightKg ??
          settings.calculatorProfile?.weightKg,
    );
  }

  final previousBoundaryDay = window.previousBoundaryDay;
  if (previousBoundaryDay != null) {
    _putBoundaryWeightPoint(
      pointsByDay: weightPointsByDay,
      displayDay: window.windowStartDate,
      dayIndex: window.dayIndexFor(window.windowStartDate),
      sourceDay: previousBoundaryDay,
      manualWeightByDay: manualWeightByDay,
      representativeWeightByDay: representativeWeightByDay,
    );
  }
  _putBoundaryWeightPoint(
    pointsByDay: weightPointsByDay,
    displayDay: window.windowEndDate,
    dayIndex: window.dayIndexFor(window.nextBoundaryDay),
    sourceDay: window.nextBoundaryDay,
    manualWeightByDay: manualWeightByDay,
    representativeWeightByDay: representativeWeightByDay,
  );

  final weightPoints = weightPointsByDay.values.toList(growable: false)
    ..sort((left, right) => left.dayIndex.compareTo(right.dayIndex));
  return weightPoints;
}

void _putBoundaryWeightPoint({
  required Map<String, CalorieWeeklyCheckInWeightPoint> pointsByDay,
  required DateTime displayDay,
  required int dayIndex,
  required DateTime sourceDay,
  required Map<String, double> manualWeightByDay,
  required Map<String, double> representativeWeightByDay,
}) {
  _putWeightPoint(
    pointsByDay: pointsByDay,
    displayDay: displayDay,
    dayIndex: dayIndex,
    weightKg:
        manualWeightByDay[diaryDayKey(sourceDay)] ??
        representativeWeightByDay[diaryDayKey(sourceDay)],
  );
}

void _putWeightPoint({
  required Map<String, CalorieWeeklyCheckInWeightPoint> pointsByDay,
  required DateTime displayDay,
  required int dayIndex,
  required double? weightKg,
}) {
  if (weightKg == null) {
    return;
  }
  final dayKey = diaryDayKey(displayDay);
  if (pointsByDay.containsKey(dayKey)) {
    return;
  }
  pointsByDay[dayKey] = CalorieWeeklyCheckInWeightPoint(
    dayIndex: dayIndex,
    weightKg: weightKg,
  );
}

double _learnedTdeeSeed({
  required CalorieGoalSettings settings,
  required DateTime day,
  required double fallbackGoalKcal,
}) {
  final learnedTdeeKcal = _latestLearnedBeforeDay(
    settings: settings,
    day: day,
  )?.weeklyCheckInSnapshot?.calculatedTrueTdeeKcal;
  if (learnedTdeeKcal != null) {
    return learnedTdeeKcal;
  }
  final anchorLearnedTdeeKcal = settings
      .activeGoalEntryForDay(day)
      ?.weeklyCheckInSnapshot
      ?.calculatedTrueTdeeKcal;
  if (anchorLearnedTdeeKcal != null) {
    return anchorLearnedTdeeKcal;
  }
  final calculatorProfile = CalorieWeeklyWindowResolver.calculatorProfileForDay(
    settings: settings,
    day: day,
  );
  if (calculatorProfile != null) {
    return CalorieGoalCalculator.calculate(calculatorProfile).tdeeKcal;
  }
  return fallbackGoalKcal;
}

CalorieGoalHistoryEntry? _latestLearnedBeforeDay({
  required CalorieGoalSettings settings,
  required DateTime day,
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
  return learnedEntry;
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

double _averageActiveKcal({
  required List<DateTime> days,
  required Map<String, int> activeKcalByDay,
}) {
  if (days.isEmpty) {
    return 0;
  }
  final total = days.fold<int>(
    0,
    (sum, day) => sum + (activeKcalByDay[diaryDayKey(day)] ?? 0),
  );
  return total / days.length;
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

CalorieGoalMode _goalModeForDay({
  required CalorieGoalSettings settings,
  required DateTime day,
}) {
  return settings.goalEntryForDay(day)?.calculatorProfile?.goalMode ??
      settings.calculatorProfile?.goalMode ??
      CalorieGoalMode.maintain;
}

double _goalSpeedForDay({
  required CalorieGoalSettings settings,
  required DateTime day,
}) {
  return settings.goalEntryForDay(day)?.calculatorProfile?.goalSpeedKgPerWeek ??
      settings.calculatorProfile?.goalSpeedKgPerWeek ??
      0.0;
}

class _WeeklyLearnedWindow {
  const _WeeklyLearnedWindow({
    required this.windowStartDate,
    required this.windowEndDate,
    required this.dueDate,
    required this.learningStartDate,
    required this.windowDays,
    required this.nextBoundaryDay,
    required this.previousBoundaryDay,
  });

  final DateTime windowStartDate;
  final DateTime windowEndDate;
  final DateTime dueDate;
  final DateTime learningStartDate;
  final List<DateTime> windowDays;
  final DateTime nextBoundaryDay;
  final DateTime? previousBoundaryDay;

  int dayIndexFor(DateTime day) {
    return normalizeDiaryDay(day).difference(learningStartDate).inDays;
  }
}
