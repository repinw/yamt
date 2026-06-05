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

/// Loads imported activity kcal for days, preferring aggregate range reads.
///
/// [detailedActivityDayKeys] prefer detailed day data over aggregate data.
/// [forceRefreshDayKeys] additionally bypass the day cache, so selected/today
/// views can use workout details that may be fresher than aggregate cache.
Future<Map<String, int>> loadHealthActivityKcalByDay({
  required DiaryHealthService diaryHealthService,
  required Iterable<DateTime> days,
  required String logName,
  required String aggregateFailureMessage,
  double? userHeightCm,
  Set<String> detailedActivityDayKeys = const <String>{},
  Set<String> forceRefreshDayKeys = const <String>{},
}) async {
  final normalizedDaysByKey = <String, DateTime>{
    for (final day in days)
      diaryDayKey(normalizeDiaryDay(day)): normalizeDiaryDay(day),
  };
  final activeKcalByDay = <String, int>{
    for (final dayKey in normalizedDaysByKey.keys) dayKey: 0,
  };
  final allDetailedDayKeys = <String>{
    ...detailedActivityDayKeys,
    ...forceRefreshDayKeys,
  };
  final cachedDetailedDays = normalizedDaysByKey.values
      .where((day) {
        final dayKey = diaryDayKey(day);
        return detailedActivityDayKeys.contains(dayKey) &&
            !forceRefreshDayKeys.contains(dayKey);
      })
      .toList(growable: false);
  final refreshedDetailedDays = normalizedDaysByKey.values
      .where((day) => forceRefreshDayKeys.contains(diaryDayKey(day)))
      .toList(growable: false);
  final nonDetailedDays = normalizedDaysByKey.values
      .where((day) => !allDetailedDayKeys.contains(diaryDayKey(day)))
      .toList(growable: false);
  final aggregateDays = normalizedDaysByKey.values.toList(growable: false);

  if (aggregateDays.isNotEmpty) {
    final aggregateActiveKcalByDay = await loadAggregateHealthActivityKcalByDay(
      diaryHealthService: diaryHealthService,
      days: aggregateDays,
      logName: logName,
      failureMessage: aggregateFailureMessage,
    );
    if (aggregateActiveKcalByDay == null) {
      await _loadDetailedActivityKcalByDay(
        activeKcalByDay: activeKcalByDay,
        diaryHealthService: diaryHealthService,
        days: nonDetailedDays,
        userHeightCm: userHeightCm,
      );
    } else {
      activeKcalByDay.addAll(aggregateActiveKcalByDay);
    }
  }

  await _overlayDetailedActivityKcalByDay(
    activeKcalByDay: activeKcalByDay,
    diaryHealthService: diaryHealthService,
    days: cachedDetailedDays,
    userHeightCm: userHeightCm,
    logName: logName,
    failureMessage: 'Failed to load detailed activity.',
  );
  await _overlayDetailedActivityKcalByDay(
    activeKcalByDay: activeKcalByDay,
    diaryHealthService: diaryHealthService,
    days: refreshedDetailedDays,
    userHeightCm: userHeightCm,
    forceRefresh: true,
    logName: logName,
    failureMessage: 'Failed to refresh detailed activity.',
  );
  return activeKcalByDay;
}

Future<void> _loadDetailedActivityKcalByDay({
  required Map<String, int> activeKcalByDay,
  required DiaryHealthService diaryHealthService,
  required Iterable<DateTime> days,
  double? userHeightCm,
  bool forceRefresh = false,
}) async {
  for (final day in days) {
    activeKcalByDay[diaryDayKey(day)] = await _loadDetailedActivityKcal(
      diaryHealthService: diaryHealthService,
      day: day,
      userHeightCm: userHeightCm,
      forceRefresh: forceRefresh,
    );
  }
}

Future<void> _overlayDetailedActivityKcalByDay({
  required Map<String, int> activeKcalByDay,
  required DiaryHealthService diaryHealthService,
  required Iterable<DateTime> days,
  required String logName,
  required String failureMessage,
  double? userHeightCm,
  bool forceRefresh = false,
}) async {
  for (final day in days) {
    try {
      activeKcalByDay[diaryDayKey(day)] = await _loadDetailedActivityKcal(
        diaryHealthService: diaryHealthService,
        day: day,
        userHeightCm: userHeightCm,
        forceRefresh: forceRefresh,
      );
    } on Object catch (error, stackTrace) {
      log(
        failureMessage,
        name: logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

Future<int> _loadDetailedActivityKcal({
  required DiaryHealthService diaryHealthService,
  required DateTime day,
  double? userHeightCm,
  bool forceRefresh = false,
}) async {
  final refreshService = diaryHealthService is DiaryHealthDayRefreshService
      ? diaryHealthService as DiaryHealthDayRefreshService
      : null;
  final dayData = forceRefresh && refreshService != null
      ? await refreshService.refreshDayData(
          day: day,
          userHeightCm: userHeightCm,
        )
      : await diaryHealthService.loadDayData(
          day: day,
          userHeightCm: userHeightCm,
        );
  final summary = buildDiaryActivitySummary(day: day, dayData: dayData);
  return calculateImportedHealthActivityKcal(
    stepsOutsideWorkouts: summary.stepsOutsideWorkouts,
    workoutCalories: summary.workouts.map((workout) => workout.totalCalories),
    unassignedActiveEnergySegments: summary.unassignedActiveEnergySegments,
  );
}
