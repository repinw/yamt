import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_activity_adjustment.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_balance_summary_provider.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';

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
    required this.usesBootstrapActivityBonus,
    required this.wasClampedToMinimum,
    this.activityComparisonKcal = 0,
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

  /// The last week average active kcal.
  final double lastWeekAverageActiveKcal;

  /// The selected day active kcal.
  final int todayActiveKcal;

  /// The used learned tdee.
  final bool usedLearnedTdee;

  /// Whether using the temporary bootstrap workout bonus.
  final bool usesBootstrapActivityBonus;

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
  final now = normalizeDiaryDay(ref.watch(calorieBalanceNowProvider)());
  final settings = await ref.watch(calorieGoalControllerProvider.future);
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
      usesBootstrapActivityBonus: false,
      wasClampedToMinimum: false,
    );
  }

  final dayActivity = await _loadDayActivityData(
    ref,
    normalizedDay,
    userHeightCm: settings.calculatorProfile?.heightCm,
  );
  final learnedEntry = settings.learnedTdeeEntryForDay(normalizedDay);
  if (learnedEntry == null) {
    final activityDeltaKcal =
        _isBootstrapWorkoutBonusEligible(
          settings: settings,
          day: normalizedDay,
        )
        ? calculateBootstrapWorkoutBonusKcal(
            workoutCalories: dayActivity.totalWorkoutCalories,
          )
        : 0.0;
    final resolvedGoalKcal = (storedGoalKcal + activityDeltaKcal).clamp(
      minimumResolvedDailyCalorieGoalKcal,
      double.infinity,
    );
    if (!kReleaseMode) {
      final message =
          'CALC_GOAL_DEBUG '
          'day=${diaryDayKey(normalizedDay)} '
          'totalWorkoutCalories=${dayActivity.totalWorkoutCalories} '
          'todayActiveKcal=${dayActivity.todayActiveKcal} '
          'bootstrapActivityBonusKcal='
          '${activityDeltaKcal.toStringAsFixed(2)} '
          'resolvedGoalKcal=${resolvedGoalKcal.toStringAsFixed(2)}';
      log(message, name: _resolvedGoalLogName);
    }

    return ResolvedCalorieGoalData(
      day: normalizedDay,
      storedGoalKcal: storedGoalKcal,
      goalKcal: resolvedGoalKcal,
      activityDeltaKcal: activityDeltaKcal,
      lastWeekAverageActiveKcal: 0,
      todayActiveKcal: dayActivity.todayActiveKcal,
      usedLearnedTdee: false,
      usesBootstrapActivityBonus: activityDeltaKcal > 0,
      wasClampedToMinimum:
          resolvedGoalKcal == minimumResolvedDailyCalorieGoalKcal &&
          storedGoalKcal + activityDeltaKcal <
              minimumResolvedDailyCalorieGoalKcal,
    );
  }

  final averageActiveKcal =
      learnedEntry.weeklyCheckInSnapshot?.averageActiveKcal ?? 0;
  final activityComparisonKcal = calculateLearnedActivityComparisonKcal(
    todayActiveKcal: dayActivity.todayActiveKcal,
    averageActiveKcal: averageActiveKcal,
  );
  final activityDeltaKcal = calculateLearnedActivityBonusKcal(
    todayActiveKcal: dayActivity.todayActiveKcal,
    averageActiveKcal: averageActiveKcal,
  );
  final resolvedGoalKcal = (storedGoalKcal + activityDeltaKcal).clamp(
    minimumResolvedDailyCalorieGoalKcal,
    double.infinity,
  );
  if (!kReleaseMode) {
    final message =
        'CALC_GOAL_DEBUG '
        'day=${diaryDayKey(normalizedDay)} '
        'averageActiveKcal=${averageActiveKcal.toStringAsFixed(2)} '
        'todayActiveKcal=${dayActivity.todayActiveKcal} '
        'activityComparisonKcal=${activityComparisonKcal.toStringAsFixed(2)} '
        'activityDeltaKcal=${activityDeltaKcal.toStringAsFixed(2)} '
        'resolvedGoalKcal=${resolvedGoalKcal.toStringAsFixed(2)}';
    log(message, name: _resolvedGoalLogName);
  }

  return ResolvedCalorieGoalData(
    day: normalizedDay,
    storedGoalKcal: storedGoalKcal,
    goalKcal: resolvedGoalKcal,
    activityDeltaKcal: activityDeltaKcal,
    activityComparisonKcal: activityComparisonKcal,
    lastWeekAverageActiveKcal: averageActiveKcal,
    todayActiveKcal: dayActivity.todayActiveKcal,
    usedLearnedTdee: true,
    usesBootstrapActivityBonus: false,
    wasClampedToMinimum:
        resolvedGoalKcal == minimumResolvedDailyCalorieGoalKcal &&
        storedGoalKcal + activityDeltaKcal <
            minimumResolvedDailyCalorieGoalKcal,
  );
}

class _ResolvedDayActivityData {
  const _ResolvedDayActivityData({
    required this.todayActiveKcal,
    required this.totalWorkoutCalories,
  });

  final int todayActiveKcal;
  final int totalWorkoutCalories;
}

Future<_ResolvedDayActivityData> _loadDayActivityData(
  Ref ref,
  DateTime day, {
  double? userHeightCm,
}) async {
  final status = await ref.watch(healthConnectionControllerProvider.future);
  if (status.accessState != HealthDataAccessState.ready) {
    return const _ResolvedDayActivityData(
      todayActiveKcal: 0,
      totalWorkoutCalories: 0,
    );
  }
  final dayData = await ref
      .watch(diaryHealthServiceProvider)
      .loadDayData(day: day, userHeightCm: userHeightCm);
  final summary = buildDiaryActivitySummary(day: day, dayData: dayData);
  final totalWorkoutCalories = summary.workouts.fold<int>(
    0,
    (sum, workout) => sum + (workout.totalCalories ?? 0),
  );
  return _ResolvedDayActivityData(
    todayActiveKcal:
        calculateDiaryBurnedCalories(
          stepsOutsideWorkouts: summary.stepsOutsideWorkouts,
          workoutCalories: summary.workouts.map(
            (workout) => workout.totalCalories,
          ),
        ) ??
        0,
    totalWorkoutCalories: totalWorkoutCalories,
  );
}

bool _isBootstrapWorkoutBonusEligible({
  required CalorieGoalSettings settings,
  required DateTime day,
}) {
  final anchorEntry =
      settings.cycleAnchorEntryForDay(day) ?? settings.goalEntryForDay(day);
  if (anchorEntry?.hasGoal != true) {
    return false;
  }

  final changedAt = anchorEntry!.effectiveChangedAt.toLocal();
  if (!isSameDiaryDay(changedAt, day)) {
    return true;
  }

  return !_startsOnPartialDiaryDay(changedAt);
}

bool _startsOnPartialDiaryDay(DateTime changedAt) {
  return changedAt.hour != 0 ||
      changedAt.minute != 0 ||
      changedAt.second != 0 ||
      changedAt.millisecond != 0 ||
      changedAt.microsecond != 0;
}
