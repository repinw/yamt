import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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

class ResolvedCalorieGoalData {
  const ResolvedCalorieGoalData({
    required this.day,
    required this.storedGoalKcal,
    required this.goalKcal,
    required this.activityDeltaKcal,
    required this.lastWeekAverageActiveKcal,
    required this.todayActiveKcal,
    required this.usedLearnedTdee,
    required this.wasClampedToMinimum,
  });

  final DateTime day;
  final double storedGoalKcal;
  final double goalKcal;
  final double activityDeltaKcal;
  final double lastWeekAverageActiveKcal;
  final int todayActiveKcal;
  final bool usedLearnedTdee;
  final bool wasClampedToMinimum;
}

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

  if (!isSameDiaryDay(normalizedDay, now) ||
      storedGoalKcal <= 0 ||
      !settings.hasLearnedTdee) {
    return ResolvedCalorieGoalData(
      day: normalizedDay,
      storedGoalKcal: storedGoalKcal,
      goalKcal: storedGoalKcal,
      activityDeltaKcal: 0,
      lastWeekAverageActiveKcal: 0,
      todayActiveKcal: 0,
      usedLearnedTdee: false,
      wasClampedToMinimum: false,
    );
  }

  final averageActiveKcal =
      settings
          .latestLearnedTdeeEntry
          ?.weeklyCheckInSnapshot
          ?.averageActiveKcal ??
      0;
  final todayActiveKcal = await _loadTodayActiveKcal(ref, normalizedDay);
  final activityDeltaKcal = todayActiveKcal - averageActiveKcal;
  final resolvedGoalKcal = (storedGoalKcal + activityDeltaKcal)
      .clamp(minimumResolvedDailyCalorieGoalKcal, double.infinity)
      .toDouble();
  if (!kReleaseMode) {
    final message =
        'CALC_GOAL_DEBUG '
        'day=${diaryDayKey(normalizedDay)} '
        'averageActiveKcal=${averageActiveKcal.toStringAsFixed(2)} '
        'todayActiveKcal=$todayActiveKcal '
        'activityDeltaKcal=${activityDeltaKcal.toStringAsFixed(2)} '
        'resolvedGoalKcal=${resolvedGoalKcal.toStringAsFixed(2)}';
    log(message, name: _resolvedGoalLogName);
  }

  return ResolvedCalorieGoalData(
    day: normalizedDay,
    storedGoalKcal: storedGoalKcal,
    goalKcal: resolvedGoalKcal,
    activityDeltaKcal: activityDeltaKcal,
    lastWeekAverageActiveKcal: averageActiveKcal,
    todayActiveKcal: todayActiveKcal,
    usedLearnedTdee: true,
    wasClampedToMinimum:
        resolvedGoalKcal == minimumResolvedDailyCalorieGoalKcal &&
        storedGoalKcal + activityDeltaKcal <
            minimumResolvedDailyCalorieGoalKcal,
  );
}

Future<int> _loadTodayActiveKcal(Ref ref, DateTime today) async {
  final status = await ref.watch(healthConnectionControllerProvider.future);
  if (status.accessState != HealthDataAccessState.ready) {
    return 0;
  }
  final dayData = await ref
      .watch(diaryHealthServiceProvider)
      .loadDayData(day: today);
  final summary = buildDiaryActivitySummary(day: today, dayData: dayData);
  return calculateDiaryBurnedCalories(
        stepsOutsideWorkouts: summary.stepsOutsideWorkouts,
        workoutCalories: summary.workouts.map(
          (workout) => workout.totalCalories,
        ),
      ) ??
      0;
}
