import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_mutation.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Collects only foods created in one local diary input session.
class DiaryFoodLogSession {
  final _entries = <String, CalorieEntry>{};

  /// Retains edits to new entries and removes reverted selections.
  void record(CalorieEntryMutation mutation) {
    switch (mutation.kind) {
      case CalorieEntryMutationKind.created:
        if (mutation.entry case final CalorieEntry entry) {
          _entries[entry.id] = entry;
        }
      case CalorieEntryMutationKind.updated:
        if (_entries.containsKey(mutation.entryId) && mutation.entry != null) {
          _entries[mutation.entryId] = mutation.entry!;
        }
      case CalorieEntryMutationKind.deleted:
        _entries.remove(mutation.entryId);
    }
  }

  /// Confirmed entries grouped by their actual day, in chronological order.
  List<List<CalorieEntry>> get dayGroups {
    final groups = <DateTime, List<CalorieEntry>>{};
    for (final entry in _entries.values) {
      groups
          .putIfAbsent(normalizeDiaryDay(entry.loggedAt), () => [])
          .add(entry);
    }
    final days = groups.keys.toList()..sort();
    return [for (final day in days) List.unmodifiable(groups[day]!)];
  }
}
