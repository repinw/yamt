import 'dart:developer' show log;

import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_extensions.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

const _weekOverviewLogName = 'CalorieWeekOverviewProvider';

/// Safely reads visible entries grouped by diary day key.
Future<Map<String, List<CalorieEntry>>> readVisibleEntriesByDaySafely({
  required CalorieLogRepositoryContract repository,
  required List<DateTime> days,
}) async {
  if (days.isEmpty) {
    return const <String, List<CalorieEntry>>{};
  }

  try {
    final entries = await repository.readEntriesInRange(
      startInclusive: days.first,
      endExclusive: nextDiaryDay(days.last),
    );
    return entries.groupByDiaryDayKey();
  } on Object catch (error, stackTrace) {
    log(
      'Failed to load calorie visible range for week overview.',
      name: _weekOverviewLogName,
      error: error,
      stackTrace: stackTrace,
    );
  }

  final dayEntries = await Future.wait(
    days.map((day) => readEntriesForDaySafely(repository, day)),
  );
  return <String, List<CalorieEntry>>{
    for (var index = 0; index < days.length; index += 1)
      diaryDayKey(days[index]): dayEntries[index],
  };
}

/// Safely reads entries for a single day, returning empty list on failure.
Future<List<CalorieEntry>> readEntriesForDaySafely(
  CalorieLogRepositoryContract repository,
  DateTime day,
) async {
  try {
    return await repository.readEntriesForDay(day);
  } on Object catch (error, stackTrace) {
    log(
      'Failed to load calorie entries for week overview on $day.',
      name: _weekOverviewLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return const <CalorieEntry>[];
  }
}

/// Safely reads entries in a range, returning empty list on failure.
Future<List<CalorieEntry>> readEntriesInRangeSafely({
  required CalorieLogRepositoryContract repository,
  required DateTime startInclusive,
  required DateTime endExclusive,
}) async {
  if (!startInclusive.isBefore(endExclusive)) {
    return const <CalorieEntry>[];
  }

  try {
    return await repository.readEntriesInRange(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );
  } on Object catch (error, stackTrace) {
    log(
      'Failed to load calorie history range for week overview.',
      name: _weekOverviewLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return const <CalorieEntry>[];
  }
}
