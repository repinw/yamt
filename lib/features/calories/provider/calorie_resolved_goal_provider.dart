import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';

part 'calorie_resolved_goal_provider.g.dart';

const _dayKeyListEquality = ListEquality<String>();

/// Defines resolved calorie goal data.
class ResolvedCalorieGoalData {
  /// The resolved calorie goal data.
  const new({
    required this.day,
    required this.storedGoalKcal,
    required this.goalKcal,
    required this.usedLearnedTdee,
    required this.wasClampedToMinimum,
  });

  /// The day.
  final DateTime day;

  /// The stored goal kcal.
  final double storedGoalKcal;

  /// The goal kcal.
  final double goalKcal;

  /// The used learned tdee.
  final bool usedLearnedTdee;

  /// Whether clamped to minimum.
  final bool wasClampedToMinimum;
}

/// Stable request key for resolving goals for multiple days.
@immutable
class ResolvedCalorieGoalDaysRequest {
  /// Creates request from diary days.
  factory fromDays(Iterable<DateTime> days) {
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

  const new _(this.days, this._dayKeys);

  /// Normalized days to resolve.
  final List<DateTime> days;

  final List<String> _dayKeys;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ResolvedCalorieGoalDaysRequest &&
        _dayKeyListEquality.equals(_dayKeys, other._dayKeys);
  }

  @override
  int get hashCode {
    return _dayKeyListEquality.hash(_dayKeys);
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
        usedLearnedTdee: settings.hasLearnedTdee,
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
      usedLearnedTdee: settings.hasLearnedTdee,
      wasClampedToMinimum: goalKcal <= 1200.0,
    );
  } finally {
    keepAliveLink.close();
  }
}
