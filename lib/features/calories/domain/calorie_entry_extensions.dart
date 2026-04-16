import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Shared helpers for calorie-entry collections.
extension CalorieEntryIterableX on Iterable<CalorieEntry> {
  /// Groups entries by their local diary-day key.
  Map<String, List<CalorieEntry>> groupByDiaryDayKey() {
    final entriesByDay = <String, List<CalorieEntry>>{};
    for (final entry in this) {
      entriesByDay
          .putIfAbsent(diaryDayKey(entry.loggedAt), () => <CalorieEntry>[])
          .add(entry);
    }
    return entriesByDay;
  }
}
