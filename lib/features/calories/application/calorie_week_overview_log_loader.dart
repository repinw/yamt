import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_extensions.dart';

/// Reads visible entries grouped by diary day key.
Future<Map<String, List<CalorieEntry>>> readVisibleEntriesByDay({
  required CalorieLogRepositoryContract repository,
  required List<DateTime> days,
}) async {
  if (days.isEmpty) {
    return const <String, List<CalorieEntry>>{};
  }
  final entries = await repository.readEntriesInRange(
    startInclusive: days.first,
    endExclusive: nextLocalDay(days.last),
  );
  return entries.groupByDiaryDayKey();
}

/// Reads entries in a range, or none when the range is empty.
Future<List<CalorieEntry>> readEntriesInRangeOrEmpty({
  required CalorieLogRepositoryContract repository,
  required DateTime startInclusive,
  required DateTime endExclusive,
}) async {
  if (!startInclusive.isBefore(endExclusive)) {
    return const <CalorieEntry>[];
  }
  return await repository.readEntriesInRange(
    startInclusive: startInclusive,
    endExclusive: endExclusive,
  );
}
