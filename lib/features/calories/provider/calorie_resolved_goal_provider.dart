import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';

part 'calorie_resolved_goal_provider.g.dart';

const _dayKeyListEquality = ListEquality<String>();

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
    this.correctedActivityKcal = 0,
    this.activityCapKcal = 0,
    this.wasActivityCapped = false,
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

  /// Activity kcal after import correction.
  final double correctedActivityKcal;

  /// Activity kcal cap for this day.
  final double activityCapKcal;

  /// Whether the activity cap lowered the credited kcal.
  final bool wasActivityCapped;

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
    Iterable<DateTime> days, {
    bool forceDetailedActivity = false,
  }) {
    final daysByKey = <String, DateTime>{};
    for (final day in days) {
      final normalizedDay = normalizeDiaryDay(day);
      daysByKey[diaryDayKey(normalizedDay)] = normalizedDay;
    }
    return ResolvedCalorieGoalDaysRequest._(
      List<DateTime>.unmodifiable(daysByKey.values),
      List<String>.unmodifiable(daysByKey.keys),
      forceDetailedActivity,
    );
  }

  const ResolvedCalorieGoalDaysRequest._(
    this.days,
    this._dayKeys,
    this.forceDetailedActivity,
  );

  /// Normalized days to resolve.
  final List<DateTime> days;

  /// Whether to bypass aggregate Health activity for requested days.
  final bool forceDetailedActivity;

  final List<String> _dayKeys;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ResolvedCalorieGoalDaysRequest &&
        _dayKeyListEquality.equals(_dayKeys, other._dayKeys) &&
        forceDetailedActivity == other.forceDetailedActivity;
  }

  @override
  int get hashCode {
    return Object.hash(
      _dayKeyListEquality.hash(_dayKeys),
      forceDetailedActivity,
    );
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
    ref.watch(calorieOverviewRevisionProvider);
    final settings = await ref.watch(calorieGoalControllerProvider.future);
    final goalsByDay = <String, ResolvedCalorieGoalData>{};

    for (final day in request.days) {
      final normalizedDay = normalizeDiaryDay(day);
      final dayKey = diaryDayKey(normalizedDay);
      final storedGoalKcal = settings.baseGoalKcalForDay(normalizedDay);
      final goalKcal = settings.goalKcalForDay(normalizedDay);

      goalsByDay[dayKey] = ResolvedCalorieGoalData(
        day: normalizedDay,
        storedGoalKcal: storedGoalKcal,
        goalKcal: goalKcal,
        activityDeltaKcal: 0,
        lastWeekAverageActiveKcal: 0,
        todayActiveKcal: 0,
        usedLearnedTdee: settings.hasLearnedTdee,
        usesPreLearningActivityBonus: false,
        wasClampedToMinimum: goalKcal <= 1200.0,
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
    ref.watch(calorieOverviewRevisionProvider);
    final normalizedDay = normalizeDiaryDay(day);
    final settings = await ref.watch(calorieGoalControllerProvider.future);
    final storedGoalKcal = settings.baseGoalKcalForDay(normalizedDay);
    final goalKcal = settings.goalKcalForDay(normalizedDay);

    return ResolvedCalorieGoalData(
      day: normalizedDay,
      storedGoalKcal: storedGoalKcal,
      goalKcal: goalKcal,
      activityDeltaKcal: 0,
      lastWeekAverageActiveKcal: 0,
      todayActiveKcal: 0,
      usedLearnedTdee: settings.hasLearnedTdee,
      usesPreLearningActivityBonus: false,
      wasClampedToMinimum: goalKcal <= 1200.0,
    );
  } finally {
    keepAliveLink.close();
  }
}
