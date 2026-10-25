import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';

/// Shared helpers for calorie-entry collections.
extension CalorieEntryIterableX on Iterable<CalorieEntry> {
  /// Groups entries by their local diary-day key.
  Map<String, List<CalorieEntry>> groupByDiaryDayKey() {
    final entriesByDay = <String, List<CalorieEntry>>{};
    for (final entry in this) {
      entriesByDay
          .putIfAbsent(localDayKey(entry.loggedAt), () => <CalorieEntry>[])
          .add(entry);
    }
    return entriesByDay;
  }
}
