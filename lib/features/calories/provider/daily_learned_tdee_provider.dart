import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_carryover_history.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_extensions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
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
  if (normalizedDay.isAfter(normalizedToday)) {
    return null;
  }

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
    day: normalizedDay,
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
  final snapshotFallback = _snapshotLearnedGoalForDay(
    settings: settings,
    day: normalizedDay,
    storedGoalKcal: storedGoalKcal,
  );
  if (entries.isEmpty) {
    return snapshotFallback;
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
    startDate: firstLearningStartDate,
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
      return latest ?? snapshotFallback;
    }

    final weightPoints = _weeklyWeightPoints(
      settings: settings,
      anchorEntry: anchorEntry,
      window: window,
      manualWeightByDay: manualWeightByDay,
      representativeWeightByDay: representativeWeightByDay,
    );
    if (weightPoints.length < 2) {
      return latest ?? snapshotFallback;
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

DailyLearnedTdeeGoalData? _snapshotLearnedGoalForDay({
  required CalorieGoalSettings settings,
  required DateTime day,
  required double storedGoalKcal,
}) {
  final learnedEntry = settings.learnedTdeeEntryForDay(day);
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
  var windowStartDate = _firstWeeklyCheckInWindowStartDate(anchorEntry);
  while (true) {
    final windowLengthDays = _weeklyCheckInWindowLengthDaysForStart(
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
  final anchorStartDate = _firstWeeklyCheckInWindowStartDate(anchorEntry);
  final oldestAllowedStartDate = windowEndDate.subtract(
    const Duration(days: dailyLearnedTdeeMaximumLookbackDays - 1),
  );
  if (anchorStartDate.isBefore(oldestAllowedStartDate)) {
    return normalizeDiaryDay(oldestAllowedStartDate);
  }
  return normalizeDiaryDay(anchorStartDate);
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
  for (final day in {
    for (final window in windows)
      for (final windowDay in window.windowDays)
        diaryDayKey(windowDay): windowDay,
  }.values) {
    final dayData = await diaryHealthService.loadDayData(
      day: day,
      userHeightCm: userHeightCm,
    );
    if (!ref.mounted) {
      throw StateError('Weekly learned TDEE disposed.');
    }
    activeKcalByDay[diaryDayKey(day)] = _resolveActiveKcal(
      day: day,
      dayData: dayData,
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
    intakeKcalByDay.add(_averageDouble(intakeKcalByDay));
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

  if (_isFirstWeeklyCheckInWindowStart(
    anchorEntry: anchorEntry,
    windowStartDate: window.windowStartDate,
  )) {
    _putWeightPoint(
      pointsByDay: weightPointsByDay,
      displayDay: window.windowStartDate,
      dayIndex: window.dayIndexFor(window.windowStartDate),
      weightKg:
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
  final calculatorProfile = _calculatorProfileForDay(
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
      entry.key: _medianWeight(entry.value),
  };
}

double _medianWeight(List<double> values) {
  if (values.isEmpty) {
    return 0;
  }
  final sorted = List<double>.from(values)..sort();
  final middleIndex = sorted.length ~/ 2;
  if (sorted.length.isOdd) {
    return sorted[middleIndex];
  }
  return (sorted[middleIndex - 1] + sorted[middleIndex]) / 2;
}

double _averageDouble(List<double> values) {
  if (values.isEmpty) {
    return 0;
  }
  return values.fold<double>(0, (sum, value) => sum + value) / values.length;
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

CalorieCalculatorProfile? _calculatorProfileForDay({
  required CalorieGoalSettings settings,
  required DateTime day,
}) {
  return settings.activeGoalEntryForDay(day)?.calculatorProfile ??
      settings.calculatorProfile;
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

bool _isFirstWeeklyCheckInWindowStart({
  required CalorieGoalHistoryEntry anchorEntry,
  required DateTime windowStartDate,
}) {
  return isSameDiaryDay(
    _firstWeeklyCheckInWindowStartDate(anchorEntry),
    windowStartDate,
  );
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
