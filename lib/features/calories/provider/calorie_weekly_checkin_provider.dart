import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_balance_summary_provider.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_entries_controller.dart';

part 'calorie_weekly_checkin_provider.g.dart';

const _weeklyCheckInProviderLogName = 'CalorieWeeklyCheckInProvider';

enum CalorieWeeklyCheckInBlockedReason {
  missingIntakeDays,
  tooManyMissingIntakeDays,
  skippedDayWithoutPriorAverage,
  missingWindowStartWeight,
  missingWindowEndWeight,
  unstableWeightData,
}

enum CalorieLearnedTdeeFreshness { none, fresh, stale, urgent }

class CalorieWeeklyCheckInWindowDay {
  const CalorieWeeklyCheckInWindowDay({
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
}

class CalorieWeeklyCheckInViewModel {
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

  const CalorieWeeklyCheckInViewModel.empty()
    : pendingWeeklyCheckIn = null,
      shouldAutoOpen = false,
      days = const <CalorieWeeklyCheckInWindowDay>[],
      calculation = null,
      blockedReason = null,
      missingIntakeDays = const <DateTime>[],
      missingWeightDays = const <DateTime>[],
      freshness = CalorieLearnedTdeeFreshness.none,
      latestLearnedTdeeAt = null,
      lowConfidence = false;

  final PendingCalorieGoalWeeklyCheckIn? pendingWeeklyCheckIn;
  final bool shouldAutoOpen;
  final List<CalorieWeeklyCheckInWindowDay> days;
  final CalorieWeeklyCheckInCalculation? calculation;
  final CalorieWeeklyCheckInBlockedReason? blockedReason;
  final List<DateTime> missingIntakeDays;
  final List<DateTime> missingWeightDays;
  final CalorieLearnedTdeeFreshness freshness;
  final DateTime? latestLearnedTdeeAt;
  final bool lowConfidence;

  bool get hasPending => pendingWeeklyCheckIn != null;
  bool get isBlocked => blockedReason != null;
  bool get isReady => hasPending && !isBlocked && calculation != null;
  bool get showDiaryHint =>
      hasPending ||
      freshness == CalorieLearnedTdeeFreshness.stale ||
      freshness == CalorieLearnedTdeeFreshness.urgent;
}

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
  final anchorEntry = settings.cycleAnchorEntryForDay(today);
  if (anchorEntry == null || settings.goalKcalForDay(today) <= 0) {
    return null;
  }

  final resolvedWindowKeys = <String>{};
  for (final entry in settings.sortedGoalHistory) {
    final snapshot = entry.weeklyCheckInSnapshot;
    if (snapshot == null) {
      continue;
    }
    if (snapshot.windowStartDate.isBefore(anchorEntry.effectiveDate)) {
      continue;
    }
    resolvedWindowKeys.add(
      _windowKey(snapshot.windowStartDate, snapshot.windowEndDate),
    );
  }

  final persistedPending = settings.pendingWeeklyCheckIn;
  for (var index = 0; ; index += 1) {
    final windowStartDate = anchorEntry.effectiveDate.add(
      Duration(days: index * weeklyCheckInWindowLengthDays),
    );
    final dueDate = windowStartDate.add(
      const Duration(days: weeklyCheckInWindowLengthDays),
    );
    if (dueDate.isAfter(today)) {
      return null;
    }
    final windowEndDate = windowStartDate.add(
      const Duration(days: weeklyCheckInWindowLengthDays - 1),
    );
    final windowKey = _windowKey(windowStartDate, windowEndDate);
    if (resolvedWindowKeys.contains(windowKey)) {
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
  final days = <DateTime>[
    for (var index = 0; index < weeklyCheckInWindowLengthDays; index += 1)
      pendingWeeklyCheckIn.windowStartDate.add(Duration(days: index)),
  ];
  final calorieEntries = await ref
      .watch(calorieLogRepositoryProvider)
      .readEntriesInRange(
        startInclusive: pendingWeeklyCheckIn.windowStartDate,
        endExclusive: pendingWeeklyCheckIn.windowEndDate.add(
          const Duration(days: 1),
        ),
      );
  final calorieEntriesByDay = <String, List<CalorieEntry>>{};
  for (final entry in calorieEntries) {
    final key = diaryDayKey(entry.loggedAt);
    calorieEntriesByDay.putIfAbsent(key, () => <CalorieEntry>[]).add(entry);
  }

  final status = await ref.watch(healthConnectionControllerProvider.future);
  final manualEntries = await ref.watch(
    manualHealthWeightEntriesControllerProvider.future,
  );
  final anchorEntry = settings.cycleAnchorEntryForDay(
    pendingWeeklyCheckIn.windowEndDate,
  );
  final weightByDay = <String, double>{
    for (final entry in manualEntries)
      if (!entry.day.isBefore(pendingWeeklyCheckIn.windowStartDate) &&
          !entry.day.isAfter(pendingWeeklyCheckIn.windowEndDate))
        diaryDayKey(entry.day): entry.weightKg,
  };
  if (anchorEntry != null &&
      isSameDiaryDay(
        anchorEntry.effectiveDate,
        pendingWeeklyCheckIn.windowStartDate,
      )) {
    final anchorWeightKg = anchorEntry.calculatorProfile?.weightKg;
    if (anchorWeightKg != null) {
      weightByDay.putIfAbsent(
        diaryDayKey(pendingWeeklyCheckIn.windowStartDate),
        () => anchorWeightKg,
      );
    }
  }
  final activeKcalByDay = <String, int>{
    for (final day in days) diaryDayKey(day): 0,
  };
  var todayActiveKcal = 0;

  if (status.accessState == HealthDataAccessState.ready) {
    final healthWeightSamples = await ref
        .watch(healthWeightServiceProvider)
        .loadWeightSamples(
          startInclusive: pendingWeeklyCheckIn.windowStartDate,
          endExclusive: pendingWeeklyCheckIn.windowEndDate.add(
            const Duration(days: 1),
          ),
        );
    for (final entry in _representativeWeightByDay(
      healthWeightSamples,
    ).entries) {
      weightByDay.putIfAbsent(entry.key, () => entry.value);
    }

    final diaryHealthService = ref.watch(diaryHealthServiceProvider);
    final windowDayData = await Future.wait(
      days.map((day) => diaryHealthService.loadDayData(day: day)),
    );
    for (var index = 0; index < days.length; index += 1) {
      activeKcalByDay[diaryDayKey(days[index])] = _resolveActiveKcal(
        day: days[index],
        dayData: windowDayData[index],
      );
    }

    todayActiveKcal = _resolveActiveKcal(
      day: today,
      dayData: await diaryHealthService.loadDayData(day: today),
    );
  }

  final missingIntakeDays = <DateTime>[];
  final missingWeightDays = <DateTime>[];
  final resolvedIntakeKcalByDay = <String, double>{};
  final windowDays = <CalorieWeeklyCheckInWindowDay>[];
  final resolvedWindowIntake = <double>[];

  for (final day in days) {
    final dayEntries =
        calorieEntriesByDay[diaryDayKey(day)] ?? const <CalorieEntry>[];
    final loggedIntakeKcal = dayEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalKcal,
    );
    final hasEntries = dayEntries.isNotEmpty;
    final isSkippedIntakeDay = settings.isSkippedIntakeDay(day);
    final weightKg = weightByDay[diaryDayKey(day)];
    final activeKcal = activeKcalByDay[diaryDayKey(day)] ?? 0;

    if (!hasEntries) {
      missingIntakeDays.add(day);
    }

    windowDays.add(
      CalorieWeeklyCheckInWindowDay(
        day: day,
        hasEntries: hasEntries,
        loggedIntakeKcal: loggedIntakeKcal,
        resolvedIntakeKcal: null,
        isSkippedIntakeDay: isSkippedIntakeDay,
        activeKcal: activeKcal,
        weightKg: weightKg,
      ),
    );
  }

  if (missingIntakeDays.length >= weeklyCheckInMissingIntakeBlockThreshold) {
    return _CalorieWeeklyCheckInDayData(
      days: windowDays,
      calculation: null,
      blockedReason: CalorieWeeklyCheckInBlockedReason.tooManyMissingIntakeDays,
      missingIntakeDays: missingIntakeDays,
      missingWeightDays: const <DateTime>[],
      lowConfidence: false,
    );
  }

  for (var index = 0; index < windowDays.length; index += 1) {
    final day = windowDays[index];
    if (day.hasEntries) {
      resolvedWindowIntake.add(day.loggedIntakeKcal);
      resolvedIntakeKcalByDay[diaryDayKey(day.day)] = day.loggedIntakeKcal;
      windowDays[index] = CalorieWeeklyCheckInWindowDay(
        day: day.day,
        hasEntries: true,
        loggedIntakeKcal: day.loggedIntakeKcal,
        resolvedIntakeKcal: day.loggedIntakeKcal,
        isSkippedIntakeDay: day.isSkippedIntakeDay,
        activeKcal: day.activeKcal,
        weightKg: day.weightKg,
      );
      continue;
    }
    if (!day.isSkippedIntakeDay) {
      return _CalorieWeeklyCheckInDayData(
        days: windowDays,
        calculation: null,
        blockedReason: CalorieWeeklyCheckInBlockedReason.missingIntakeDays,
        missingIntakeDays: missingIntakeDays,
        missingWeightDays: const <DateTime>[],
        lowConfidence: false,
      );
    }
    if (resolvedWindowIntake.isEmpty) {
      return _CalorieWeeklyCheckInDayData(
        days: windowDays,
        calculation: null,
        blockedReason:
            CalorieWeeklyCheckInBlockedReason.skippedDayWithoutPriorAverage,
        missingIntakeDays: missingIntakeDays,
        missingWeightDays: const <DateTime>[],
        lowConfidence: false,
      );
    }
    final interpolatedIntakeKcal =
        resolvedWindowIntake.fold<double>(0, (sum, value) => sum + value) /
        resolvedWindowIntake.length;
    resolvedWindowIntake.add(interpolatedIntakeKcal);
    resolvedIntakeKcalByDay[diaryDayKey(day.day)] = interpolatedIntakeKcal;
    windowDays[index] = CalorieWeeklyCheckInWindowDay(
      day: day.day,
      hasEntries: false,
      loggedIntakeKcal: 0,
      resolvedIntakeKcal: interpolatedIntakeKcal,
      isSkippedIntakeDay: true,
      activeKcal: day.activeKcal,
      weightKg: day.weightKg,
    );
  }

  final firstDayWeight = weightByDay[diaryDayKey(days.first)];
  final lastDayWeight = weightByDay[diaryDayKey(days.last)];
  if (firstDayWeight == null) {
    missingWeightDays.add(days.first);
  }
  if (lastDayWeight == null) {
    missingWeightDays.add(days.last);
  }
  if (firstDayWeight == null) {
    return _CalorieWeeklyCheckInDayData(
      days: windowDays,
      calculation: null,
      blockedReason: CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight,
      missingIntakeDays: missingIntakeDays,
      missingWeightDays: missingWeightDays,
      lowConfidence: false,
    );
  }
  if (lastDayWeight == null) {
    return _CalorieWeeklyCheckInDayData(
      days: windowDays,
      calculation: null,
      blockedReason: CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight,
      missingIntakeDays: missingIntakeDays,
      missingWeightDays: missingWeightDays,
      lowConfidence: false,
    );
  }

  final weightPoints = <CalorieWeeklyCheckInWeightPoint>[
    for (var index = 0; index < windowDays.length; index += 1)
      if (windowDays[index].weightKg != null)
        CalorieWeeklyCheckInWeightPoint(
          dayIndex: index,
          weightKg: windowDays[index].weightKg!,
        ),
  ];
  final calculation = CalorieWeeklyCheckInCalculator.calculate(
    previousGoalKcal: settings.goalKcalForDay(
      pendingWeeklyCheckIn.windowEndDate,
    ),
    intakeKcalByDay: windowDays
        .map((day) => day.resolvedIntakeKcal ?? day.loggedIntakeKcal)
        .toList(growable: false),
    lastWeekActiveKcalByDay: windowDays
        .map((day) => day.activeKcal)
        .toList(growable: false),
    todayActiveKcal: todayActiveKcal,
    weightPoints: weightPoints,
  );
  if (!kReleaseMode) {
    final daysLabel = windowDays
        .map((day) {
          return '${diaryDayKey(day.day)}'
              ':logged=${day.loggedIntakeKcal.toStringAsFixed(2)}'
              ',resolved=${day.resolvedIntakeKcal?.toStringAsFixed(2) ?? 'null'}'
              ',active=${day.activeKcal}'
              ',weight=${day.weightKg?.toStringAsFixed(2) ?? 'null'}'
              ',skipped=${day.isSkippedIntakeDay}';
        })
        .join(' | ');
    final message =
        'WEEKLY_TDEE_WINDOW_DEBUG '
        'window=${diaryDayKey(pendingWeeklyCheckIn.windowStartDate)}'
        '..${diaryDayKey(pendingWeeklyCheckIn.windowEndDate)} '
        'today=${diaryDayKey(today)} '
        'previousGoalKcal='
        '${settings.goalKcalForDay(pendingWeeklyCheckIn.windowEndDate).toStringAsFixed(2)} '
        'days=[$daysLabel]';
    log(message, name: _weeklyCheckInProviderLogName);
  }

  return _CalorieWeeklyCheckInDayData(
    days: windowDays,
    calculation: calculation,
    blockedReason: null,
    missingIntakeDays: missingIntakeDays,
    missingWeightDays: missingWeightDays,
    lowConfidence: weightPoints.length <= 2,
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

int _resolveActiveKcal({required DateTime day, required dynamic dayData}) {
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
