import 'dart:developer' show log;

import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/domain/diary_activity_summary.dart';

/// Loads aggregate active kcal when the health service supports it.
Future<Map<String, int>?> loadAggregateHealthActivityKcalByDay({
  required DiaryHealthService diaryHealthService,
  required Iterable<DateTime> days,
  required String logName,
  required String failureMessage,
}) async {
  final trendService = diaryHealthService is DiaryHealthActivityTrendService
      ? diaryHealthService as DiaryHealthActivityTrendService
      : null;
  final sortedDays = days.map(normalizeDiaryDay).toList(growable: false)
    ..sort();
  if (trendService == null || sortedDays.isEmpty) {
    return null;
  }

  try {
    final trendDays = await trendService.loadActivityTrendDays(
      startInclusive: sortedDays.first,
      endExclusive: nextDiaryDay(sortedDays.last),
    );
    return <String, int>{
      for (final trendDay in trendDays)
        diaryDayKey(trendDay.day): calculateAggregateDiaryBurnedCalories(
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
}) async {
  final activeKcalByDay = await loadAggregateHealthActivityKcalByDay(
    diaryHealthService: diaryHealthService,
    days: [day],
    logName: logName,
    failureMessage: failureMessage,
  );
  return activeKcalByDay?[diaryDayKey(day)];
}
