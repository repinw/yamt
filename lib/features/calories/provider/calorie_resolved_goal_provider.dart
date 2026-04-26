import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_activity_adjustment.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_carryover_history.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_extensions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_balance_summary_provider.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_entries_controller.dart';

part 'calorie_resolved_goal_provider.g.dart';

const _resolvedGoalLogName = 'ResolvedCalorieGoalProvider';

/// Defines resolved calorie goal data.
class ResolvedCalorieGoalData {
  /// The resolved calorie goal data.
  const ResolvedCalorieGoalData({
    required this.day,
    required this.storedGoalKcal,
    required this.goalKcal,
    required this.activityDeltaKcal,
    required this.lastWeekAverageActiveKcal,
    required this.todayActiveKcal,
    required this.usedLearnedTdee,
    required this.usesPreLearningActivityBonus,
    required this.wasClampedToMinimum,
    this.activityComparisonKcal = 0,
    this.expectedActivityKcal = 0,
    this.isActivityTrackingActive = false,
  });

  /// The day.
  final DateTime day;

  /// The stored goal kcal.
  final double storedGoalKcal;

  /// The goal kcal.
  final double goalKcal;

  /// The activity delta kcal.
  final double activityDeltaKcal;

  /// The signed activity comparison against the learned baseline.
  final double activityComparisonKcal;

  /// Expected daily activity kcal baseline.
  final double expectedActivityKcal;

  /// Whether health/activity tracking is active for this day.
  final bool isActivityTrackingActive;

  /// The last week average active kcal.
  final double lastWeekAverageActiveKcal;

  /// The selected day active kcal.
  final int todayActiveKcal;

  /// The used learned tdee.
  final bool usedLearnedTdee;

  /// Whether using a pre-learning activity bonus.
  final bool usesPreLearningActivityBonus;

  /// Whether clamped to minimum.
  final bool wasClampedToMinimum;
}

/// Resolved calorie goal for day.
@riverpod
Future<ResolvedCalorieGoalData> resolvedCalorieGoalForDay(
  Ref ref,
  DateTime day,
) async {
  final normalizedDay = normalizeDiaryDay(day);
  final referenceNow = ref.watch(calorieBalanceNowProvider)();
  final now = normalizeDiaryDay(referenceNow);
  final healthStatus = await ref.watch(
    healthConnectionControllerProvider.future,
  );
  if (!ref.mounted) {
    throw StateError('Resolved calorie goal disposed.');
  }
  var settings = await ref.watch(calorieGoalControllerProvider.future);
  if (!ref.mounted) {
    throw StateError('Resolved calorie goal disposed.');
  }
  if (healthStatus.accessState == HealthDataAccessState.ready &&
      settings.activityTrackingStartDate == null) {
    settings = settings.markActivityTrackingStarted(referenceNow);
  }
  final storedGoalKcal = settings.goalKcalForDay(normalizedDay);
  if (!kReleaseMode) {
    final profileJson = settings.calculatorProfile?.toJson();
    final message =
        'CALC_GOAL_DEBUG '
        'day=${diaryDayKey(normalizedDay)} '
        'now=${diaryDayKey(now)} '
        'storedGoalKcal=${storedGoalKcal.toStringAsFixed(2)} '
        'hasLearnedTdee=${settings.hasLearnedTdee} '
        'latestLearnedTdeeKcal='
        '${settings.latestLearnedTdeeKcal?.toStringAsFixed(2) ?? 'null'} '
        'calculatorProfile=$profileJson';
    log(message, name: _resolvedGoalLogName);
  }

  if (storedGoalKcal <= 0) {
    return ResolvedCalorieGoalData(
      day: normalizedDay,
      storedGoalKcal: storedGoalKcal,
      goalKcal: storedGoalKcal,
      activityDeltaKcal: 0,
      lastWeekAverageActiveKcal: 0,
      todayActiveKcal: 0,
      usedLearnedTdee: false,
      usesPreLearningActivityBonus: false,
      wasClampedToMinimum: false,
    );
  }

  final dayActivity = await _loadDayActivityData(
    ref,
    normalizedDay,
    settings: settings,
    healthStatus: healthStatus,
    userHeightCm: settings.calculatorProfile?.heightCm,
  );
  final learnedEntry = settings.learnedTdeeEntryForDay(normalizedDay);
  if (learnedEntry == null) {
    final expectedActivityKcal = _expectedActivityKcalForDay(
      settings: settings,
      day: normalizedDay,
    );
    final activityBaselineKcal = dayActivity.isTrackingActive
        ? expectedActivityKcal
        : null;
    final activityComparisonKcal = activityBaselineKcal == null
        ? 0.0
        : calculateLearnedActivityComparisonKcal(
            todayActiveKcal: dayActivity.todayActiveKcal,
            averageActiveKcal: activityBaselineKcal,
          );
    final activityDeltaKcal = activityBaselineKcal == null
        ? 0.0
        : calculateLearnedActivityBonusKcal(
            todayActiveKcal: dayActivity.todayActiveKcal,
            averageActiveKcal: activityBaselineKcal,
          );
    final goalBreakdown = CalorieBudgetCalculator.resolveDailyGoal(
      storedGoalKcal: storedGoalKcal,
      activityDeltaKcal: activityDeltaKcal,
    );
    if (!kReleaseMode) {
      final message =
          'CALC_GOAL_DEBUG '
          'day=${diaryDayKey(normalizedDay)} '
          'isActivityTrackingActive=${dayActivity.isTrackingActive} '
          'expectedActivityKcal='
          '${expectedActivityKcal?.toStringAsFixed(2) ?? 'null'} '
          'todayActiveKcal=${dayActivity.todayActiveKcal} '
          'activityComparisonKcal=${activityComparisonKcal.toStringAsFixed(2)} '
          'activityDeltaKcal='
          '${activityDeltaKcal.toStringAsFixed(2)} '
          'resolvedGoalKcal=${goalBreakdown.goalKcal.toStringAsFixed(2)}';
      log(message, name: _resolvedGoalLogName);
    }

    return ResolvedCalorieGoalData(
      day: normalizedDay,
      storedGoalKcal: storedGoalKcal,
      goalKcal: goalBreakdown.goalKcal,
      activityDeltaKcal: activityDeltaKcal,
      activityComparisonKcal: activityComparisonKcal,
      expectedActivityKcal: expectedActivityKcal ?? 0,
      lastWeekAverageActiveKcal: 0,
      todayActiveKcal: dayActivity.todayActiveKcal,
      usedLearnedTdee: false,
      usesPreLearningActivityBonus: activityDeltaKcal > 0,
      isActivityTrackingActive: dayActivity.isTrackingActive,
      wasClampedToMinimum: goalBreakdown.wasClampedToMinimum,
    );
  }

  final averageActiveKcal =
      learnedEntry.weeklyCheckInSnapshot?.averageActiveKcal ?? 0;
  final activityComparisonKcal = dayActivity.isTrackingActive
      ? calculateLearnedActivityComparisonKcal(
          todayActiveKcal: dayActivity.todayActiveKcal,
          averageActiveKcal: averageActiveKcal,
        )
      : 0.0;
  final activityDeltaKcal = dayActivity.isTrackingActive
      ? calculateLearnedActivityBonusKcal(
          todayActiveKcal: dayActivity.todayActiveKcal,
          averageActiveKcal: averageActiveKcal,
        )
      : 0.0;
  final dailyLearnedGoal = await _resolveDailyLearnedGoal(
    ref,
    normalizedDay: normalizedDay,
    today: now,
    settings: settings,
    healthStatus: healthStatus,
    learnedEntry: learnedEntry,
    storedGoalKcal: storedGoalKcal,
  );
  if (!ref.mounted) {
    throw StateError('Resolved calorie goal disposed.');
  }
  final effectiveStoredGoalKcal =
      dailyLearnedGoal?.newGoalKcal ?? storedGoalKcal;
  final goalBreakdown = CalorieBudgetCalculator.resolveDailyGoal(
    storedGoalKcal: effectiveStoredGoalKcal,
    activityDeltaKcal: activityDeltaKcal,
  );
  if (!kReleaseMode) {
    final dailyLearnedTargetKcal =
        dailyLearnedGoal?.newGoalKcal.toStringAsFixed(2) ?? 'null';
    final dailyLearnedMeasuredTdeeKcal =
        dailyLearnedGoal?.measured.measuredTrueTdeeKcal.toStringAsFixed(2) ??
        'null';
    final dailyLearnedCalculatedTdeeKcal =
        dailyLearnedGoal?.calculatedTrueTdeeKcal.toStringAsFixed(2) ?? 'null';
    final message =
        'CALC_GOAL_DEBUG '
        'day=${diaryDayKey(normalizedDay)} '
        'averageActiveKcal=${averageActiveKcal.toStringAsFixed(2)} '
        'todayActiveKcal=${dayActivity.todayActiveKcal} '
        'activityComparisonKcal=${activityComparisonKcal.toStringAsFixed(2)} '
        'activityDeltaKcal=${activityDeltaKcal.toStringAsFixed(2)} '
        'dailyLearnedTargetKcal=$dailyLearnedTargetKcal '
        'dailyLearnedMeasuredTdeeKcal=$dailyLearnedMeasuredTdeeKcal '
        'dailyLearnedCalculatedTdeeKcal=$dailyLearnedCalculatedTdeeKcal '
        'resolvedGoalKcal=${goalBreakdown.goalKcal.toStringAsFixed(2)}';
    log(message, name: _resolvedGoalLogName);
  }

  return ResolvedCalorieGoalData(
    day: normalizedDay,
    storedGoalKcal: effectiveStoredGoalKcal,
    goalKcal: goalBreakdown.goalKcal,
    activityDeltaKcal: activityDeltaKcal,
    activityComparisonKcal: activityComparisonKcal,
    expectedActivityKcal: averageActiveKcal,
    lastWeekAverageActiveKcal: averageActiveKcal,
    todayActiveKcal: dayActivity.todayActiveKcal,
    usedLearnedTdee: true,
    usesPreLearningActivityBonus: false,
    isActivityTrackingActive: dayActivity.isTrackingActive,
    wasClampedToMinimum: goalBreakdown.wasClampedToMinimum,
  );
}

class _DailyLearnedGoalData {
  const _DailyLearnedGoalData({
    required this.measured,
    required this.calculatedTrueTdeeKcal,
    required this.newGoalKcal,
  });

  final CalorieMeasuredTdeeCalculation measured;
  final double calculatedTrueTdeeKcal;
  final double newGoalKcal;
}

Future<_DailyLearnedGoalData?> _resolveDailyLearnedGoal(
  Ref ref, {
  required DateTime normalizedDay,
  required DateTime today,
  required CalorieGoalSettings settings,
  required HealthConnectionStatus healthStatus,
  required CalorieGoalHistoryEntry learnedEntry,
  required double storedGoalKcal,
}) async {
  if (!isSameDiaryDay(normalizedDay, today)) {
    return null;
  }
  final snapshot = learnedEntry.weeklyCheckInSnapshot;
  if (snapshot == null) {
    return null;
  }
  final lastCompleteDay = previousDiaryDay(normalizedDay);
  if (!lastCompleteDay.isAfter(normalizeDiaryDay(snapshot.windowEndDate))) {
    return null;
  }

  final startDate = _dailyLearnedStartDate(
    settings: settings,
    snapshot: snapshot,
    today: normalizedDay,
  );
  final intakeDays = buildCalorieCarryoverDateRange(
    startInclusive: startDate,
    endExclusive: normalizedDay,
  );
  if (intakeDays.length < dailyLearnedTdeeMinimumCompleteDays) {
    return null;
  }

  final entries = await ref
      .watch(calorieLogRepositoryProvider)
      .readEntriesInRange(
        startInclusive: startDate,
        endExclusive: normalizedDay,
      );
  if (!ref.mounted) {
    throw StateError('Resolved calorie goal disposed.');
  }
  final intakeKcalByDay = _resolveDailyLearnedIntake(
    days: intakeDays,
    entriesByDay: entries.groupByDiaryDayKey(),
    settings: settings,
  );
  if (intakeKcalByDay == null) {
    return null;
  }

  final weightPoints = await _loadDailyLearnedWeightPoints(
    ref,
    startDate: startDate,
    endDateInclusive: normalizedDay,
    healthStatus: healthStatus,
  );
  if (!ref.mounted) {
    throw StateError('Resolved calorie goal disposed.');
  }
  if (weightPoints.length < 2) {
    return null;
  }

  final goalMode = _goalModeForDay(settings: settings, day: normalizedDay);
  final goalSpeedKgPerWeek = goalMode == CalorieGoalMode.maintain
      ? 0.0
      : _goalSpeedForDay(settings: settings, day: normalizedDay);
  final calculation = CalorieWeeklyCheckInCalculator.calculateLearnedGoal(
    previousGoalKcal: storedGoalKcal,
    previousLearnedTdeeKcal: snapshot.calculatedTrueTdeeKcal,
    goalSpeedKgPerWeek: goalSpeedKgPerWeek,
    isLosing: goalMode == CalorieGoalMode.lose,
    isGaining: goalMode == CalorieGoalMode.gain,
    intakeKcalByDay: intakeKcalByDay,
    weightPoints: weightPoints,
    maxGoalAdjustmentKcal: dailyLearnedTdeeMaxGoalAdjustmentKcal,
  );
  return _DailyLearnedGoalData(
    measured: calculation.measured,
    calculatedTrueTdeeKcal: calculation.calculatedTrueTdeeKcal,
    newGoalKcal: calculation.newGoalKcal,
  );
}

DateTime _dailyLearnedStartDate({
  required CalorieGoalSettings settings,
  required CalorieGoalWeeklyCheckInSnapshot snapshot,
  required DateTime today,
}) {
  CalorieGoalHistoryEntry? firstLearnedEntry;
  for (final entry in settings.sortedGoalHistory) {
    if (entry.weeklyCheckInSnapshot != null) {
      firstLearnedEntry = entry;
      break;
    }
  }
  var startDate = normalizeDiaryDay(
    firstLearnedEntry?.weeklyCheckInSnapshot?.windowStartDate ??
        snapshot.windowStartDate,
  );
  final oldestAllowed = today.subtract(
    const Duration(days: dailyLearnedTdeeMaximumLookbackDays),
  );
  if (startDate.isBefore(oldestAllowed)) {
    startDate = normalizeDiaryDay(oldestAllowed);
  }
  return startDate;
}

List<double>? _resolveDailyLearnedIntake({
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
    intakeKcalByDay.add(
      intakeKcalByDay.fold<double>(0, (sum, value) => sum + value) /
          intakeKcalByDay.length,
    );
  }
  return intakeKcalByDay;
}

Future<List<CalorieWeeklyCheckInWeightPoint>> _loadDailyLearnedWeightPoints(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDateInclusive,
  required HealthConnectionStatus healthStatus,
}) async {
  final manualEntries = await ref.watch(
    manualHealthWeightEntriesControllerProvider.future,
  );
  if (!ref.mounted) {
    throw StateError('Resolved calorie goal disposed.');
  }
  final healthWeights = healthStatus.accessState == HealthDataAccessState.ready
      ? await ref
            .watch(healthWeightServiceProvider)
            .loadWeightSamples(
              startInclusive: startDate,
              endExclusive: nextDiaryDay(endDateInclusive),
            )
      : const <HealthWeightSample>[];
  if (!ref.mounted) {
    throw StateError('Resolved calorie goal disposed.');
  }

  final manualWeightByDay = _manualWeightByDay(manualEntries);
  final healthWeightByDay = _representativeWeightByDay(healthWeights);
  final weightPoints = <CalorieWeeklyCheckInWeightPoint>[];
  for (
    var day = startDate;
    !day.isAfter(endDateInclusive);
    day = nextDiaryDay(day)
  ) {
    final key = diaryDayKey(day);
    final weightKg = manualWeightByDay[key] ?? healthWeightByDay[key];
    if (weightKg == null) {
      continue;
    }
    weightPoints.add(
      CalorieWeeklyCheckInWeightPoint(
        dayIndex: day.difference(startDate).inDays,
        weightKg: weightKg,
      ),
    );
  }
  return weightPoints;
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

class _ResolvedDayActivityData {
  const _ResolvedDayActivityData({
    required this.todayActiveKcal,
    required this.isTrackingActive,
  });

  final int todayActiveKcal;
  final bool isTrackingActive;
}

Future<_ResolvedDayActivityData> _loadDayActivityData(
  Ref ref,
  DateTime day, {
  required CalorieGoalSettings settings,
  required HealthConnectionStatus healthStatus,
  double? userHeightCm,
}) async {
  if (healthStatus.accessState != HealthDataAccessState.ready ||
      !settings.isActivityTrackingActiveForDay(day)) {
    return const _ResolvedDayActivityData(
      todayActiveKcal: 0,
      isTrackingActive: false,
    );
  }
  final dayData = await ref
      .watch(diaryHealthServiceProvider)
      .loadDayData(day: day, userHeightCm: userHeightCm);
  final summary = buildDiaryActivitySummary(day: day, dayData: dayData);
  return _ResolvedDayActivityData(
    todayActiveKcal:
        calculateDiaryBurnedCalories(
          stepsOutsideWorkouts: summary.stepsOutsideWorkouts,
          workoutCalories: summary.workouts.map(
            (workout) => workout.totalCalories,
          ),
        ) ??
        0,
    isTrackingActive: true,
  );
}

double? _expectedActivityKcalForDay({
  required CalorieGoalSettings settings,
  required DateTime day,
}) {
  final goalEntry = settings.goalEntryForDay(day);
  final storedExpectedActivityKcal =
      goalEntry?.expectedActivityKcal ?? settings.expectedActivityKcal;
  if (storedExpectedActivityKcal != null) {
    return storedExpectedActivityKcal;
  }
  final profile = goalEntry?.calculatorProfile ?? settings.calculatorProfile;
  if (profile == null) {
    return null;
  }
  return CalorieGoalCalculator.calculate(profile).expectedActivityKcal;
}
