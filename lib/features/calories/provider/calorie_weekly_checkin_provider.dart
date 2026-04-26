import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_balance_summary_provider.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_entries_controller.dart';

part 'calorie_weekly_checkin_provider.g.dart';

const _weeklyCheckInProviderLogName = 'CalorieWeeklyCheckInProvider';

/// Defines calorie weekly check in blocked reason.
enum CalorieWeeklyCheckInBlockedReason {
  /// Documented member.
  missingIntakeDays,

  /// Documented member.
  tooManyMissingIntakeDays,

  /// Documented member.
  skippedDayWithoutPriorAverage,

  /// Documented member.
  missingWindowStartWeight,

  /// Documented member.
  missingWindowEndWeight,

  /// Documented member.
  unstableWeightData,
}

/// Defines calorie learned tdee freshness.
enum CalorieLearnedTdeeFreshness {
  /// None.
  none,

  /// Fresh.
  fresh,

  /// Stale.
  stale,

  /// Urgent.
  urgent,
}

/// Defines calorie weekly check in window day.
class CalorieWeeklyCheckInWindowDay {
  /// The calorie weekly check in window day.
  const CalorieWeeklyCheckInWindowDay({
    required this.day,
    required this.hasEntries,
    required this.loggedIntakeKcal,
    required this.resolvedIntakeKcal,
    required this.isSkippedIntakeDay,
    required this.activeKcal,
    required this.weightKg,
  });

  /// The day.
  final DateTime day;

  /// Whether entries.
  final bool hasEntries;

  /// The logged intake kcal.
  final double loggedIntakeKcal;

  /// The resolved intake kcal.
  final double? resolvedIntakeKcal;

  /// Whether skipped intake day.
  final bool isSkippedIntakeDay;

  /// The active kcal.
  final int activeKcal;

  /// The weight kg.
  final double? weightKg;
}

/// Defines calorie weekly check in view model.
class CalorieWeeklyCheckInViewModel {
  /// The calorie weekly check in view model.
  const CalorieWeeklyCheckInViewModel({
    required this.pendingWeeklyCheckIn,
    required this.shouldAutoOpen,
    required this.days,
    required this.calculation,
    required this.blockedReason,
    required this.missingIntakeDays,
    required this.missingWeightDays,
    required this.freshness,
    required this.latestLearnedTdeeAt,
    required this.lowConfidence,
  });

  /// The pending weekly check in.
  final PendingCalorieGoalWeeklyCheckIn? pendingWeeklyCheckIn;

  /// Whether auto open.
  final bool shouldAutoOpen;

  /// The days.
  final List<CalorieWeeklyCheckInWindowDay> days;

  /// The calculation.
  final CalorieWeeklyCheckInCalculation? calculation;

  /// The blocked reason.
  final CalorieWeeklyCheckInBlockedReason? blockedReason;

  /// The missing intake days.
  final List<DateTime> missingIntakeDays;

  /// The missing weight days.
  final List<DateTime> missingWeightDays;

  /// The freshness.
  final CalorieLearnedTdeeFreshness freshness;

  /// The latest learned tdee at.
  final DateTime? latestLearnedTdeeAt;

  /// The low confidence.
  final bool lowConfidence;

  /// Whether pending.
  bool get hasPending => pendingWeeklyCheckIn != null;

  /// Whether blocked.
  bool get isBlocked => blockedReason != null;

  /// Whether ready.
  bool get isReady => hasPending && !isBlocked && calculation != null;

  /// The show diary hint.
  bool get showDiaryHint =>
      hasPending ||
      freshness == CalorieLearnedTdeeFreshness.stale ||
      freshness == CalorieLearnedTdeeFreshness.urgent;
}

/// Calorie weekly check in view model.
@riverpod
Future<CalorieWeeklyCheckInViewModel> calorieWeeklyCheckInViewModel(
  Ref ref,
) async {
  final settings = await ref.watch(calorieGoalControllerProvider.future);
  final today = normalizeDiaryDay(ref.watch(calorieBalanceNowProvider)());
  final pendingWeeklyCheckIn = _resolvePendingWeeklyCheckIn(
    settings: settings,
    today: today,
  );
  final freshness = _resolveLearnedTdeeFreshness(
    settings: settings,
    today: today,
  );

  if (pendingWeeklyCheckIn == null) {
    return CalorieWeeklyCheckInViewModel(
      pendingWeeklyCheckIn: null,
      shouldAutoOpen: false,
      days: const <CalorieWeeklyCheckInWindowDay>[],
      calculation: null,
      blockedReason: null,
      missingIntakeDays: const <DateTime>[],
      missingWeightDays: const <DateTime>[],
      freshness: freshness,
      latestLearnedTdeeAt: settings.latestLearnedTdeeChangedAt,
      lowConfidence: false,
    );
  }

  final dayData = await _loadWindowDayData(
    ref: ref,
    settings: settings,
    pendingWeeklyCheckIn: pendingWeeklyCheckIn,
    today: today,
  );

  return CalorieWeeklyCheckInViewModel(
    pendingWeeklyCheckIn: pendingWeeklyCheckIn,
    shouldAutoOpen: !pendingWeeklyCheckIn.isDismissed,
    days: dayData.days,
    calculation: dayData.calculation,
    blockedReason: dayData.blockedReason,
    missingIntakeDays: dayData.missingIntakeDays,
    missingWeightDays: dayData.missingWeightDays,
    freshness: freshness,
    latestLearnedTdeeAt: settings.latestLearnedTdeeChangedAt,
    lowConfidence: dayData.lowConfidence,
  );
}

PendingCalorieGoalWeeklyCheckIn? _resolvePendingWeeklyCheckIn({
  required CalorieGoalSettings settings,
  required DateTime today,
}) {
  final countingGoalEntry = settings.countingGoalEntryForDay(today);
  if (countingGoalEntry == null) {
    return null;
  }
  final anchorEntry =
      settings.cycleAnchorEntryForDay(today) ?? countingGoalEntry;
  if (!anchorEntry.hasGoal) {
    return null;
  }
  final firstWindowStartDate = _firstWeeklyCheckInWindowStartDate(anchorEntry);

  final resolvedWindowKeys = <String>{};
  for (final entry in settings.sortedGoalHistory) {
    final snapshot = entry.weeklyCheckInSnapshot;
    if (snapshot == null) {
      continue;
    }
    if (snapshot.windowStartDate.isBefore(firstWindowStartDate)) {
      continue;
    }
    resolvedWindowKeys.add(
      _windowKey(snapshot.windowStartDate, snapshot.windowEndDate),
    );
  }

  final persistedPending = settings.pendingWeeklyCheckIn;
  var windowStartDate = firstWindowStartDate;
  while (true) {
    final windowLengthDays = _weeklyCheckInWindowLengthDaysForStart(
      anchorEntry: anchorEntry,
      windowStartDate: windowStartDate,
    );
    final dueDate = windowStartDate.add(Duration(days: windowLengthDays));
    if (dueDate.isAfter(today)) {
      return null;
    }
    final windowEndDate = windowStartDate.add(
      Duration(days: windowLengthDays - 1),
    );
    final windowKey = _windowKey(windowStartDate, windowEndDate);
    if (resolvedWindowKeys.contains(windowKey)) {
      windowStartDate = nextDiaryDay(windowEndDate);
      continue;
    }

    if (persistedPending != null && persistedPending.windowKey == windowKey) {
      return persistedPending;
    }

    return PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: windowStartDate,
      windowEndDate: windowEndDate,
      dueDate: dueDate,
    );
  }
}

CalorieLearnedTdeeFreshness _resolveLearnedTdeeFreshness({
  required CalorieGoalSettings settings,
  required DateTime today,
}) {
  final learnedAt = settings.latestLearnedTdeeChangedAt;
  if (learnedAt == null) {
    return CalorieLearnedTdeeFreshness.none;
  }
  final daysSinceLearned = today
      .difference(normalizeDiaryDay(learnedAt))
      .inDays;
  if (daysSinceLearned >= learnedTdeeUrgentStaleAfterDays) {
    return CalorieLearnedTdeeFreshness.urgent;
  }
  if (daysSinceLearned >= learnedTdeeStaleAfterDays) {
    return CalorieLearnedTdeeFreshness.stale;
  }
  return CalorieLearnedTdeeFreshness.fresh;
}

Future<_CalorieWeeklyCheckInDayData> _loadWindowDayData({
  required Ref ref,
  required CalorieGoalSettings settings,
  required PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
  required DateTime today,
}) async {
  final dates = _resolveWeeklyCheckInWindowDates(
    settings: settings,
    pendingWeeklyCheckIn: pendingWeeklyCheckIn,
  );
  final calorieEntriesByDay = await _readCheckInCalorieEntriesByDay(
    ref: ref,
    startInclusive: dates.learningStartDate,
    endExclusive: nextDiaryDay(pendingWeeklyCheckIn.windowEndDate),
  );
  if (!ref.mounted) {
    throw StateError('Calorie weekly check-in disposed.');
  }
  final manualEntries = await ref.watch(
    manualHealthWeightEntriesControllerProvider.future,
  );
  if (!ref.mounted) {
    throw StateError('Calorie weekly check-in disposed.');
  }
  final healthData = await _loadWeeklyCheckInHealthData(
    ref: ref,
    settings: settings,
    dates: dates,
    today: today,
  );
  final weightData = _mergeWeeklyCheckInWeights(
    dates: dates,
    anchorEntry: dates.anchorEntry,
    manualWeightByDay: _manualWeightByDay(manualEntries),
    representativeWeightByDay: healthData.representativeWeightByDay,
  );
  final windowIntakeData = _resolveWindowIntakeData(
    days: dates.windowDays,
    calorieEntriesByDay: calorieEntriesByDay,
    settings: settings,
    activeKcalByDay: healthData.activeKcalByDay,
    weightByDay: weightData.weightByDay,
  );
  if (windowIntakeData.blockedReason != null) {
    return _CalorieWeeklyCheckInDayData(
      days: windowIntakeData.days,
      calculation: null,
      blockedReason: windowIntakeData.blockedReason,
      missingIntakeDays: windowIntakeData.missingIntakeDays,
      missingWeightDays: const <DateTime>[],
      lowConfidence: false,
    );
  }

  final learningIntakeData = _resolveLearningIntakeData(
    days: dates.learningDays,
    calorieEntriesByDay: calorieEntriesByDay,
    settings: settings,
  );
  if (learningIntakeData.blockedReason != null) {
    return _CalorieWeeklyCheckInDayData(
      days: windowIntakeData.days,
      calculation: null,
      blockedReason: learningIntakeData.blockedReason,
      missingIntakeDays: learningIntakeData.missingIntakeDays,
      missingWeightDays: const <DateTime>[],
      lowConfidence: false,
    );
  }

  final weightBlockedData = _validateWeeklyCheckInWeightData(
    dates: dates,
    weightData: weightData,
    windowDays: windowIntakeData.days,
    missingIntakeDays: windowIntakeData.missingIntakeDays,
  );
  if (weightBlockedData != null) {
    return weightBlockedData;
  }

  final previousGoalKcal = settings.goalKcalForDay(
    pendingWeeklyCheckIn.windowEndDate,
  );
  final calculatorProfile = _calculatorProfileForDay(
    settings: settings,
    day: pendingWeeklyCheckIn.windowEndDate,
  );
  final calculation = CalorieWeeklyCheckInCalculator.calculate(
    previousGoalKcal: previousGoalKcal,
    previousLearnedTdeeKcal: _previousLearnedTdeeKcal(
      settings: settings,
      day: pendingWeeklyCheckIn.windowEndDate,
    ),
    goalMode: calculatorProfile?.goalMode ?? CalorieGoalMode.maintain,
    goalSpeedKgPerWeek: calculatorProfile?.goalSpeedKgPerWeek ?? 0,
    intakeKcalByDay: learningIntakeData.intakeKcalByDay,
    lastWeekActiveKcalByDay: windowIntakeData.days
        .map((day) => day.activeKcal)
        .toList(growable: false),
    todayActiveKcal: healthData.todayActiveKcal,
    weightPoints: weightData.weightPoints,
  );
  if (!kReleaseMode) {
    final daysLabel = windowIntakeData.days
        .map((day) {
          return '${diaryDayKey(day.day)}'
              ':logged=${day.loggedIntakeKcal.toStringAsFixed(2)}'
              ',resolved='
              '${day.resolvedIntakeKcal?.toStringAsFixed(2) ?? 'null'}'
              ',active=${day.activeKcal}'
              ',weight=${day.weightKg?.toStringAsFixed(2) ?? 'null'}'
              ',skipped=${day.isSkippedIntakeDay}';
        })
        .join(' | ');
    final message =
        'WEEKLY_TDEE_WINDOW_DEBUG '
        'window=${diaryDayKey(pendingWeeklyCheckIn.windowStartDate)}'
        '..${diaryDayKey(pendingWeeklyCheckIn.windowEndDate)} '
        'learningWindow=${diaryDayKey(dates.learningStartDate)}'
        '..${diaryDayKey(pendingWeeklyCheckIn.windowEndDate)} '
        'today=${diaryDayKey(today)} '
        'previousGoalKcal='
        '${previousGoalKcal.toStringAsFixed(2)} '
        'days=[$daysLabel]';
    log(message, name: _weeklyCheckInProviderLogName);
  }

  return _CalorieWeeklyCheckInDayData(
    days: windowIntakeData.days,
    calculation: calculation,
    blockedReason: null,
    missingIntakeDays: windowIntakeData.missingIntakeDays,
    missingWeightDays: const <DateTime>[],
    lowConfidence: weightData.weightPoints.length <= 2,
  );
}

CalorieCalculatorProfile? _calculatorProfileForDay({
  required CalorieGoalSettings settings,
  required DateTime day,
}) {
  return settings.activeGoalEntryForDay(day)?.calculatorProfile ??
      settings.calculatorProfile;
}

double _previousLearnedTdeeKcal({
  required CalorieGoalSettings settings,
  required DateTime day,
}) {
  final learnedTdeeKcal = settings.latestLearnedTdeeKcal;
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
  return settings.goalKcalForDay(day);
}

_WeeklyCheckInWindowDates _resolveWeeklyCheckInWindowDates({
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
  return _WeeklyCheckInWindowDates(
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

Future<Map<String, List<CalorieEntry>>> _readCheckInCalorieEntriesByDay({
  required Ref ref,
  required DateTime startInclusive,
  required DateTime endExclusive,
}) async {
  final calorieEntries = await ref
      .watch(calorieLogRepositoryProvider)
      .readEntriesInRange(
        startInclusive: startInclusive,
        endExclusive: endExclusive,
      );
  final calorieEntriesByDay = <String, List<CalorieEntry>>{};
  for (final entry in calorieEntries) {
    final key = diaryDayKey(entry.loggedAt);
    calorieEntriesByDay.putIfAbsent(key, () => <CalorieEntry>[]).add(entry);
  }
  return calorieEntriesByDay;
}

Future<_WeeklyCheckInHealthData> _loadWeeklyCheckInHealthData({
  required Ref ref,
  required CalorieGoalSettings settings,
  required _WeeklyCheckInWindowDates dates,
  required DateTime today,
}) async {
  final activeKcalByDay = <String, int>{
    for (final day in dates.windowDays) diaryDayKey(day): 0,
  };
  var todayActiveKcal = 0;
  var representativeWeightByDay = const <String, double>{};

  final status = await ref.watch(healthConnectionControllerProvider.future);
  if (!ref.mounted) {
    throw StateError('Calorie weekly check-in disposed.');
  }
  if (status.accessState != HealthDataAccessState.ready) {
    return _WeeklyCheckInHealthData(
      activeKcalByDay: activeKcalByDay,
      todayActiveKcal: todayActiveKcal,
      representativeWeightByDay: representativeWeightByDay,
    );
  }

  final healthWeightSamples = await ref
      .watch(healthWeightServiceProvider)
      .loadWeightSamples(
        startInclusive: _earliestDay(dates.healthWeightStartCandidates),
        endExclusive: nextDiaryDay(dates.nextBoundaryDay),
      );
  if (!ref.mounted) {
    throw StateError('Calorie weekly check-in disposed.');
  }
  representativeWeightByDay = _representativeWeightByDay(healthWeightSamples);

  final diaryHealthService = ref.watch(diaryHealthServiceProvider);
  final userHeightCm = settings.calculatorProfile?.heightCm;
  final windowDayData = await Future.wait(
    dates.windowDays.map(
      (day) => diaryHealthService.loadDayData(
        day: day,
        userHeightCm: userHeightCm,
      ),
    ),
  );
  if (!ref.mounted) {
    throw StateError('Calorie weekly check-in disposed.');
  }
  for (var index = 0; index < dates.windowDays.length; index += 1) {
    activeKcalByDay[diaryDayKey(dates.windowDays[index])] = _resolveActiveKcal(
      day: dates.windowDays[index],
      dayData: windowDayData[index],
    );
  }

  todayActiveKcal = _resolveActiveKcal(
    day: today,
    dayData: await diaryHealthService.loadDayData(
      day: today,
      userHeightCm: userHeightCm,
    ),
  );
  return _WeeklyCheckInHealthData(
    activeKcalByDay: activeKcalByDay,
    todayActiveKcal: todayActiveKcal,
    representativeWeightByDay: representativeWeightByDay,
  );
}

_WeeklyCheckInWeightData _mergeWeeklyCheckInWeights({
  required _WeeklyCheckInWindowDates dates,
  required CalorieGoalHistoryEntry? anchorEntry,
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

  final anchorWeightSourceDay = dates.anchorWeightSourceDay;
  if (anchorWeightSourceDay != null) {
    final anchorDayKey = diaryDayKey(anchorWeightSourceDay);
    _putBoundaryWeightIfAbsent(
      weightByDay: weightByDay,
      weightPointByDay: weightPointByDay,
      displayDay: dates.pendingWeeklyCheckIn.windowStartDate,
      dayIndex: dates.dayIndexFor(dates.pendingWeeklyCheckIn.windowStartDate),
      dayKey: anchorDayKey,
      manualWeightByDay: manualWeightByDay,
      representativeWeightByDay: representativeWeightByDay,
    );
  }

  if (dates.shouldUseLearningPreviousBoundary) {
    final learningPreviousBoundaryDayKey = diaryDayKey(
      dates.learningPreviousBoundaryDay,
    );
    _putBoundaryWeightIfAbsent(
      weightByDay: weightByDay,
      weightPointByDay: weightPointByDay,
      displayDay: dates.learningStartDate,
      dayIndex: 0,
      dayKey: learningPreviousBoundaryDayKey,
      manualWeightByDay: manualWeightByDay,
      representativeWeightByDay: representativeWeightByDay,
    );
  }

  if (dates.isFirstWindow && anchorEntry != null) {
    _putWeightIfAbsent(
      weightByDay: weightByDay,
      weightPointByDay: weightPointByDay,
      displayDay: dates.pendingWeeklyCheckIn.windowStartDate,
      weightKg: anchorEntry.calculatorProfile?.weightKg,
      dayIndex: dates.dayIndexFor(dates.pendingWeeklyCheckIn.windowStartDate),
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

  final weightPoints = weightPointByDay.values.toList(growable: false)
    ..sort((left, right) => left.dayIndex.compareTo(right.dayIndex));
  return _WeeklyCheckInWeightData(
    weightByDay: Map<String, double>.unmodifiable(weightByDay),
    weightPoints: List<CalorieWeeklyCheckInWeightPoint>.unmodifiable(
      weightPoints,
    ),
  );
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

_WeeklyWindowIntakeData _resolveWindowIntakeData({
  required List<DateTime> days,
  required Map<String, List<CalorieEntry>> calorieEntriesByDay,
  required CalorieGoalSettings settings,
  required Map<String, int> activeKcalByDay,
  required Map<String, double> weightByDay,
}) {
  final missingIntakeDays = <DateTime>[];
  final windowDays = <CalorieWeeklyCheckInWindowDay>[];
  for (final day in days) {
    final dayEntries =
        calorieEntriesByDay[diaryDayKey(day)] ?? const <CalorieEntry>[];
    if (dayEntries.isEmpty) {
      missingIntakeDays.add(day);
    }
    windowDays.add(
      CalorieWeeklyCheckInWindowDay(
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
    return _WeeklyWindowIntakeData.blocked(
      days: windowDays,
      blockedReason: CalorieWeeklyCheckInBlockedReason.tooManyMissingIntakeDays,
      missingIntakeDays: missingIntakeDays,
    );
  }

  return _resolveSkippedWindowIntake(
    windowDays: windowDays,
    missingIntakeDays: missingIntakeDays,
  );
}

_WeeklyWindowIntakeData _resolveSkippedWindowIntake({
  required List<CalorieWeeklyCheckInWindowDay> windowDays,
  required List<DateTime> missingIntakeDays,
}) {
  final resolvedWindowIntake = <double>[];
  for (var index = 0; index < windowDays.length; index += 1) {
    final day = windowDays[index];
    if (day.hasEntries) {
      resolvedWindowIntake.add(day.loggedIntakeKcal);
      windowDays[index] = _copyWindowDayWithResolvedIntake(
        day: day,
        hasEntries: true,
        loggedIntakeKcal: day.loggedIntakeKcal,
        resolvedIntakeKcal: day.loggedIntakeKcal,
      );
      continue;
    }
    if (!day.isSkippedIntakeDay) {
      return _WeeklyWindowIntakeData.blocked(
        days: windowDays,
        blockedReason: CalorieWeeklyCheckInBlockedReason.missingIntakeDays,
        missingIntakeDays: missingIntakeDays,
      );
    }
    if (resolvedWindowIntake.isEmpty) {
      return _WeeklyWindowIntakeData.blocked(
        days: windowDays,
        blockedReason:
            CalorieWeeklyCheckInBlockedReason.skippedDayWithoutPriorAverage,
        missingIntakeDays: missingIntakeDays,
      );
    }
    final interpolatedIntakeKcal = _averageDouble(resolvedWindowIntake);
    resolvedWindowIntake.add(interpolatedIntakeKcal);
    windowDays[index] = _copyWindowDayWithResolvedIntake(
      day: day,
      hasEntries: false,
      loggedIntakeKcal: 0,
      resolvedIntakeKcal: interpolatedIntakeKcal,
    );
  }

  return _WeeklyWindowIntakeData.ready(
    days: windowDays,
    missingIntakeDays: missingIntakeDays,
  );
}

CalorieWeeklyCheckInWindowDay _copyWindowDayWithResolvedIntake({
  required CalorieWeeklyCheckInWindowDay day,
  required bool hasEntries,
  required double loggedIntakeKcal,
  required double resolvedIntakeKcal,
}) {
  return CalorieWeeklyCheckInWindowDay(
    day: day.day,
    hasEntries: hasEntries,
    loggedIntakeKcal: loggedIntakeKcal,
    resolvedIntakeKcal: resolvedIntakeKcal,
    isSkippedIntakeDay: day.isSkippedIntakeDay,
    activeKcal: day.activeKcal,
    weightKg: day.weightKg,
  );
}

_CalorieWeeklyCheckInDayData? _validateWeeklyCheckInWeightData({
  required _WeeklyCheckInWindowDates dates,
  required _WeeklyCheckInWeightData weightData,
  required List<CalorieWeeklyCheckInWindowDay> windowDays,
  required List<DateTime> missingIntakeDays,
}) {
  final missingWeightDays = <DateTime>[];
  final hasLearningStartWeight =
      weightData.weightByDay[diaryDayKey(dates.learningStartDate)] != null;
  final hasWindowEndWeight =
      weightData.weightByDay[diaryDayKey(
        dates.pendingWeeklyCheckIn.windowEndDate,
      )] !=
      null;
  if (weightData.weightPoints.length < 2 && !hasLearningStartWeight) {
    missingWeightDays.add(dates.learningStartDate);
    return _CalorieWeeklyCheckInDayData(
      days: windowDays,
      calculation: null,
      blockedReason: CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight,
      missingIntakeDays: missingIntakeDays,
      missingWeightDays: missingWeightDays,
      lowConfidence: false,
    );
  }
  if (weightData.weightPoints.length < 2 && !hasWindowEndWeight) {
    missingWeightDays.add(dates.pendingWeeklyCheckIn.windowEndDate);
    return _CalorieWeeklyCheckInDayData(
      days: windowDays,
      calculation: null,
      blockedReason: CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight,
      missingIntakeDays: missingIntakeDays,
      missingWeightDays: missingWeightDays,
      lowConfidence: false,
    );
  }
  return null;
}

double _sumCalories(List<CalorieEntry> entries) {
  return entries.fold<double>(0, (sum, entry) => sum + entry.totalKcal);
}

double _averageDouble(List<double> values) {
  return values.fold<double>(0, (sum, value) => sum + value) / values.length;
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

_WeeklyLearningIntakeData _resolveLearningIntakeData({
  required List<DateTime> days,
  required Map<String, List<CalorieEntry>> calorieEntriesByDay,
  required CalorieGoalSettings settings,
}) {
  final missingIntakeDays = <DateTime>[];
  final intakeKcalByDay = <double>[];

  for (final day in days) {
    final dayEntries =
        calorieEntriesByDay[diaryDayKey(day)] ?? const <CalorieEntry>[];
    if (dayEntries.isNotEmpty) {
      intakeKcalByDay.add(
        dayEntries.fold<double>(
          0,
          (sum, entry) => sum + entry.totalKcal,
        ),
      );
      continue;
    }

    missingIntakeDays.add(day);
    if (!settings.isSkippedIntakeDay(day)) {
      return _WeeklyLearningIntakeData.blocked(
        blockedReason:
            missingIntakeDays.length >= weeklyCheckInMissingIntakeBlockThreshold
            ? CalorieWeeklyCheckInBlockedReason.tooManyMissingIntakeDays
            : CalorieWeeklyCheckInBlockedReason.missingIntakeDays,
        missingIntakeDays: missingIntakeDays,
      );
    }
    if (intakeKcalByDay.isEmpty) {
      return _WeeklyLearningIntakeData.blocked(
        blockedReason:
            CalorieWeeklyCheckInBlockedReason.skippedDayWithoutPriorAverage,
        missingIntakeDays: missingIntakeDays,
      );
    }

    intakeKcalByDay.add(
      intakeKcalByDay.fold<double>(0, (sum, value) => sum + value) /
          intakeKcalByDay.length,
    );
  }

  return _WeeklyLearningIntakeData.ready(
    intakeKcalByDay: intakeKcalByDay,
    missingIntakeDays: missingIntakeDays,
  );
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

String _windowKey(DateTime startDate, DateTime endDate) {
  return '${diaryDayKey(startDate)}:${diaryDayKey(endDate)}';
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

Map<String, double> _manualWeightByDay(
  List<ManualHealthWeightEntry> manualEntries,
) {
  return <String, double>{
    for (final entry in manualEntries) diaryDayKey(entry.day): entry.weightKg,
  };
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

DateTime _earliestDay(List<DateTime> days) {
  assert(days.isNotEmpty, 'At least one day is required.');
  var earliest = normalizeDiaryDay(days.first);
  for (final day in days.skip(1)) {
    final normalizedDay = normalizeDiaryDay(day);
    if (normalizedDay.isBefore(earliest)) {
      earliest = normalizedDay;
    }
  }
  return earliest;
}

class _CalorieWeeklyCheckInDayData {
  const _CalorieWeeklyCheckInDayData({
    required this.days,
    required this.calculation,
    required this.blockedReason,
    required this.missingIntakeDays,
    required this.missingWeightDays,
    required this.lowConfidence,
  });

  final List<CalorieWeeklyCheckInWindowDay> days;
  final CalorieWeeklyCheckInCalculation? calculation;
  final CalorieWeeklyCheckInBlockedReason? blockedReason;
  final List<DateTime> missingIntakeDays;
  final List<DateTime> missingWeightDays;
  final bool lowConfidence;
}

class _WeeklyCheckInWindowDates {
  const _WeeklyCheckInWindowDates({
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
      if (anchorWeightSourceDay != null) anchorWeightSourceDay!,
      if (shouldUseLearningPreviousBoundary) learningPreviousBoundaryDay,
      if (previousBoundaryDay != null) previousBoundaryDay!,
    ];
  }

  int dayIndexFor(DateTime day) {
    return normalizeDiaryDay(day).difference(learningStartDate).inDays;
  }
}

class _WeeklyCheckInHealthData {
  const _WeeklyCheckInHealthData({
    required this.activeKcalByDay,
    required this.todayActiveKcal,
    required this.representativeWeightByDay,
  });

  final Map<String, int> activeKcalByDay;
  final int todayActiveKcal;
  final Map<String, double> representativeWeightByDay;
}

class _WeeklyCheckInWeightData {
  const _WeeklyCheckInWeightData({
    required this.weightByDay,
    required this.weightPoints,
  });

  final Map<String, double> weightByDay;
  final List<CalorieWeeklyCheckInWeightPoint> weightPoints;
}

class _WeeklyWindowIntakeData {
  const _WeeklyWindowIntakeData._({
    required this.days,
    required this.missingIntakeDays,
    required this.blockedReason,
  });

  factory _WeeklyWindowIntakeData.ready({
    required List<CalorieWeeklyCheckInWindowDay> days,
    required List<DateTime> missingIntakeDays,
  }) {
    return _WeeklyWindowIntakeData._(
      days: List<CalorieWeeklyCheckInWindowDay>.unmodifiable(days),
      missingIntakeDays: List<DateTime>.unmodifiable(missingIntakeDays),
      blockedReason: null,
    );
  }

  factory _WeeklyWindowIntakeData.blocked({
    required List<CalorieWeeklyCheckInWindowDay> days,
    required CalorieWeeklyCheckInBlockedReason blockedReason,
    required List<DateTime> missingIntakeDays,
  }) {
    return _WeeklyWindowIntakeData._(
      days: List<CalorieWeeklyCheckInWindowDay>.unmodifiable(days),
      missingIntakeDays: List<DateTime>.unmodifiable(missingIntakeDays),
      blockedReason: blockedReason,
    );
  }

  final List<CalorieWeeklyCheckInWindowDay> days;
  final List<DateTime> missingIntakeDays;
  final CalorieWeeklyCheckInBlockedReason? blockedReason;
}

class _WeeklyLearningIntakeData {
  const _WeeklyLearningIntakeData._({
    required this.intakeKcalByDay,
    required this.missingIntakeDays,
    required this.blockedReason,
  });

  factory _WeeklyLearningIntakeData.ready({
    required List<double> intakeKcalByDay,
    required List<DateTime> missingIntakeDays,
  }) {
    return _WeeklyLearningIntakeData._(
      intakeKcalByDay: List<double>.unmodifiable(intakeKcalByDay),
      missingIntakeDays: List<DateTime>.unmodifiable(missingIntakeDays),
      blockedReason: null,
    );
  }

  factory _WeeklyLearningIntakeData.blocked({
    required CalorieWeeklyCheckInBlockedReason blockedReason,
    required List<DateTime> missingIntakeDays,
  }) {
    return _WeeklyLearningIntakeData._(
      intakeKcalByDay: const <double>[],
      missingIntakeDays: List<DateTime>.unmodifiable(missingIntakeDays),
      blockedReason: blockedReason,
    );
  }

  final List<double> intakeKcalByDay;
  final List<DateTime> missingIntakeDays;
  final CalorieWeeklyCheckInBlockedReason? blockedReason;
}
