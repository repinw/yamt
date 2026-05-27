import 'dart:developer' show log;

import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/domain/diary_activity_summary.dart';
import 'package:yamt/features/health/domain/health_energy_segment.dart';

/// Resolves raw imported activity kcal for calorie target math.
///
/// Calorie math applies tracker correction and daily caps later, so this keeps
/// the imported source value intact instead of using diary display filters.
int calculateImportedHealthActivityKcal({
  required int? stepsOutsideWorkouts,
  required Iterable<int?> workoutCalories,
  Iterable<HealthEnergySegment> unassignedActiveEnergySegments =
      const <HealthEnergySegment>[],
}) {
  final totalWorkoutCalories = workoutCalories.fold<int>(
    0,
    (sum, calories) => sum + (calories ?? 0),
  );
  final totalUnassignedActiveEnergyCalories = unassignedActiveEnergySegments
      .fold<int>(
        0,
        (sum, segment) => sum + segment.totalCalories,
      );
  final nonWorkoutActivityCalories = totalUnassignedActiveEnergyCalories > 0
      ? totalUnassignedActiveEnergyCalories
      : estimateOutsideActivityStepCalories(stepsOutsideWorkouts ?? 0);
  return totalWorkoutCalories + nonWorkoutActivityCalories;
}

/// Resolves raw aggregate imported activity kcal for calorie target math.
int calculateAggregateImportedHealthActivityKcal({
  required int totalSteps,
  required int activeEnergyKcal,
}) {
  if (activeEnergyKcal > 0) {
    return activeEnergyKcal;
  }
  return estimateOutsideActivityStepCalories(totalSteps);
}

/// Loads aggregate active kcal when the health service supports it.
Future<Map<String, int>?> loadAggregateHealthActivityKcalByDay({
  required DiaryHealthService diaryHealthService,
  required Iterable<DateTime> days,
  required String logName,
  required String failureMessage,
  bool forceRefresh = false,
}) async {
  final trendService = diaryHealthService is DiaryHealthActivityTrendService
      ? diaryHealthService as DiaryHealthActivityTrendService
      : null;
  final refreshService =
      diaryHealthService is DiaryHealthActivityTrendRefreshService
      ? diaryHealthService as DiaryHealthActivityTrendRefreshService
      : null;
  final sortedDays = days.map(normalizeDiaryDay).toList(growable: false)
    ..sort();
  if (trendService == null || sortedDays.isEmpty) {
    return null;
  }

  try {
    final startInclusive = sortedDays.first;
    final endExclusive = nextDiaryDay(sortedDays.last);
    final trendDays = forceRefresh && refreshService != null
        ? await refreshService.refreshActivityTrendDays(
            startInclusive: startInclusive,
            endExclusive: endExclusive,
          )
        : await trendService.loadActivityTrendDays(
            startInclusive: startInclusive,
            endExclusive: endExclusive,
          );
    return <String, int>{
      for (final trendDay in trendDays)
        diaryDayKey(trendDay.day): calculateAggregateImportedHealthActivityKcal(
          totalSteps: trendDay.totalSteps,
          activeEnergyKcal: trendDay.activeEnergyKcal,
        ),
    };
  } on Object catch (error, stackTrace) {
    log(
      failureMessage,
      name: logName,
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

/// Loads aggregate active kcal for one diary day.
Future<int?> loadAggregateHealthActivityKcalForDay({
  required DiaryHealthService diaryHealthService,
  required DateTime day,
  required String logName,
  required String failureMessage,
  bool forceRefresh = false,
}) async {
  final activeKcalByDay = await loadAggregateHealthActivityKcalByDay(
    diaryHealthService: diaryHealthService,
    days: [day],
    logName: logName,
    failureMessage: failureMessage,
    forceRefresh: forceRefresh,
  );
  return activeKcalByDay?[diaryDayKey(day)];
}
