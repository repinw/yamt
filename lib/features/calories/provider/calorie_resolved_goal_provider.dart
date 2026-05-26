import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_activity_adjustment.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_balance_now_provider.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/daily_learned_tdee_provider.dart';
import 'package:yamt/features/health/data/diary_health_service_provider.dart';
import 'package:yamt/features/health/domain/diary_activity_summary.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/presentation/controllers/health_connection_controller.dart';

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

/// Stable request key for resolving goals for multiple days.
@immutable
class ResolvedCalorieGoalDaysRequest {
  /// Creates request from diary days.
  factory ResolvedCalorieGoalDaysRequest.fromDays(
    Iterable<DateTime> days,
  ) {
    final daysByKey = <String, DateTime>{};
    for (final day in days) {
      final normalizedDay = normalizeDiaryDay(day);
      daysByKey[diaryDayKey(normalizedDay)] = normalizedDay;
    }
    return ResolvedCalorieGoalDaysRequest._(
      List<DateTime>.unmodifiable(daysByKey.values),
      List<String>.unmodifiable(daysByKey.keys),
    );
  }

  const ResolvedCalorieGoalDaysRequest._(this.days, this._dayKeys);

  /// Normalized days to resolve.
  final List<DateTime> days;

  final List<String> _dayKeys;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ResolvedCalorieGoalDaysRequest &&
        _hasSameDayKeys(other._dayKeys);
  }

  @override
  int get hashCode => Object.hashAll(_dayKeys);

  bool _hasSameDayKeys(List<String> otherKeys) {
    if (_dayKeys.length != otherKeys.length) {
      return false;
    }
    for (var index = 0; index < _dayKeys.length; index += 1) {
      if (_dayKeys[index] != otherKeys[index]) {
        return false;
      }
    }
    return true;
  }
}

/// Resolved calorie goals keyed by diary day key.
@riverpod
Future<Map<String, ResolvedCalorieGoalData>> resolvedCalorieGoalsForDays(
  Ref ref,
  ResolvedCalorieGoalDaysRequest request,
) async {
  final keepAliveLink = ref.keepAlive();
  try {
    final referenceNow = ref.watch(calorieBalanceNowProvider)();
    final now = normalizeDiaryDay(referenceNow);
    final healthStatus = await ref.watch(
      healthConnectionControllerProvider.future,
    );
    if (!ref.mounted) {
      throw StateError('Resolved calorie goals disposed.');
    }
    var settings = await ref.watch(calorieGoalControllerProvider.future);
    if (!ref.mounted) {
      throw StateError('Resolved calorie goals disposed.');
    }
    if (healthStatus.accessState == HealthDataAccessState.ready &&
        settings.activityTrackingStartDate == null) {
      settings = settings.markActivityTrackingStarted(referenceNow);
    }

    final storedGoalsByDay = <String, double>{};
    final learnedRequests = <DailyLearnedTdeeGoalDayRequest>[];
    for (final day in request.days) {
      final normalizedDay = normalizeDiaryDay(day);
      final storedGoalKcal = settings.goalKcalForDay(normalizedDay);
      storedGoalsByDay[diaryDayKey(normalizedDay)] = storedGoalKcal;
      if (storedGoalKcal > 0) {
        learnedRequests.add(
          DailyLearnedTdeeGoalDayRequest(
            day: normalizedDay,
            storedGoalKcal: storedGoalKcal,
          ),
        );
      }
    }

    final learnedGoalsFuture = learnedRequests.isEmpty
        ? Future<Map<String, DailyLearnedTdeeGoalData?>>.value(
            const <String, DailyLearnedTdeeGoalData?>{},
          )
        : ref.watch(
            dailyLearnedTdeeGoalsForDaysProvider(
              DailyLearnedTdeeGoalDaysRequest(
                today: now,
                days: learnedRequests,
              ),
            ).future,
          );
    final dayActivityEntries = await Future.wait(
      learnedRequests.map((request) async {
        final dayActivity = await _loadDayActivityData(
          ref,
          request.day,
          settings: settings,
          healthStatus: healthStatus,
          userHeightCm: settings.calculatorProfile?.heightCm,
        );
        return MapEntry<String, _ResolvedDayActivityData>(
          diaryDayKey(request.day),
          dayActivity,
        );
      }),
    );
    if (!ref.mounted) {
      throw StateError('Resolved calorie goals disposed.');
    }
    final learnedGoals = await learnedGoalsFuture;
    if (!ref.mounted) {
      throw StateError('Resolved calorie goals disposed.');
    }
    final dayActivityByKey = Map<String, _ResolvedDayActivityData>.fromEntries(
      dayActivityEntries,
    );
    final goalsByDay = <String, ResolvedCalorieGoalData>{};

    for (final day in request.days) {
      final normalizedDay = normalizeDiaryDay(day);
      final dayKey = diaryDayKey(normalizedDay);
      final storedGoalKcal = storedGoalsByDay[dayKey] ?? 0;
      if (storedGoalKcal <= 0) {
        goalsByDay[dayKey] = ResolvedCalorieGoalData(
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
        continue;
      }

      goalsByDay[dayKey] = _resolveGoalDataFromLoadedInputs(
        day: normalizedDay,
        storedGoalKcal: storedGoalKcal,
        settings: settings,
        dayActivity:
            dayActivityByKey[dayKey] ??
            const _ResolvedDayActivityData(
              todayActiveKcal: 0,
              isTrackingActive: false,
            ),
        learnedGoal: learnedGoals[dayKey],
      );
    }

    return Map<String, ResolvedCalorieGoalData>.unmodifiable(goalsByDay);
  } finally {
    keepAliveLink.close();
  }
}

/// Resolved calorie goal for day.
@riverpod
Future<ResolvedCalorieGoalData> resolvedCalorieGoalForDay(
  Ref ref,
  DateTime day,
) async {
  final keepAliveLink = ref.keepAlive();
  try {
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
    final learnedGoal = await ref.watch(
      dailyLearnedTdeeGoalForDayProvider(
        day: normalizedDay,
        today: now,
        storedGoalKcal: storedGoalKcal,
      ).future,
    );
    if (!ref.mounted) {
      throw StateError('Resolved calorie goal disposed.');
    }
    if (learnedGoal == null) {
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
            'activityComparisonKcal='
            '${activityComparisonKcal.toStringAsFixed(2)} '
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

    final averageActiveKcal = learnedGoal.averageActiveKcal;
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
    final goalBreakdown = CalorieBudgetCalculator.resolveDailyGoal(
      storedGoalKcal: learnedGoal.newGoalKcal,
      activityDeltaKcal: activityDeltaKcal,
    );
    if (!kReleaseMode) {
      final message =
          'CALC_GOAL_DEBUG '
          'day=${diaryDayKey(normalizedDay)} '
          'averageActiveKcal=${averageActiveKcal.toStringAsFixed(2)} '
          'todayActiveKcal=${dayActivity.todayActiveKcal} '
          'activityComparisonKcal=${activityComparisonKcal.toStringAsFixed(2)} '
          'activityDeltaKcal=${activityDeltaKcal.toStringAsFixed(2)} '
          'learnedTargetKcal=${learnedGoal.newGoalKcal.toStringAsFixed(2)} '
          'learnedTdeeKcal='
          '${learnedGoal.calculatedTrueTdeeKcal.toStringAsFixed(2)} '
          'resolvedGoalKcal=${goalBreakdown.goalKcal.toStringAsFixed(2)}';
      log(message, name: _resolvedGoalLogName);
    }

    return ResolvedCalorieGoalData(
      day: normalizedDay,
      storedGoalKcal: learnedGoal.newGoalKcal,
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
  } finally {
    keepAliveLink.close();
  }
}

ResolvedCalorieGoalData _resolveGoalDataFromLoadedInputs({
  required DateTime day,
  required double storedGoalKcal,
  required CalorieGoalSettings settings,
  required _ResolvedDayActivityData dayActivity,
  required DailyLearnedTdeeGoalData? learnedGoal,
}) {
  if (learnedGoal == null) {
    final expectedActivityKcal = _expectedActivityKcalForDay(
      settings: settings,
      day: day,
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

    return ResolvedCalorieGoalData(
      day: day,
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

  final averageActiveKcal = learnedGoal.averageActiveKcal;
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
  final goalBreakdown = CalorieBudgetCalculator.resolveDailyGoal(
    storedGoalKcal: learnedGoal.newGoalKcal,
    activityDeltaKcal: activityDeltaKcal,
  );

  return ResolvedCalorieGoalData(
    day: day,
    storedGoalKcal: learnedGoal.newGoalKcal,
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
          unassignedActiveEnergySegments:
              summary.unassignedActiveEnergySegments,
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
