import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Keeps plans in memory.
class FakePlannedEntryRepository extends PlannedEntryRepository {
  new({List<CalorieEntry>? plans})
    : plans = plans ?? <CalorieEntry>[],
      super(dataCipher: null, firestore: null);

  final List<CalorieEntry> plans;

  bool writeShouldFail = false;

  bool loadShouldFail = false;

  @override
  Future<List<CalorieEntry>> loadPlannedEntriesForDay(DateTime day) async {
    if (loadShouldFail) {
      throw StateError('Plan read failed.');
    }
    return plans.where((plan) => isSameDiaryDay(plan.loggedAt, day)).toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }

  @override
  Future<Set<DateTime>> loadPlannedDays(DateTime first, DateTime last) async {
    final from = normalizeDiaryDay(first);
    final to = normalizeDiaryDay(last);
    return {
      for (final plan in plans)
        if (!normalizeDiaryDay(plan.loggedAt).isBefore(from) &&
            !normalizeDiaryDay(plan.loggedAt).isAfter(to))
          normalizeDiaryDay(plan.loggedAt),
    };
  }

  @override
  Future<void> savePlannedEntry(CalorieEntry entry) async {
    _throwIfFailing();
    plans
      ..removeWhere((plan) => plan.id == entry.id)
      ..add(entry);
  }

  @override
  Future<void> deletePlannedEntry(String entryId) async {
    _throwIfFailing();
    plans.removeWhere((plan) => plan.id == entryId);
  }

  void _throwIfFailing() {
    if (writeShouldFail) {
      throw StateError('Plan write failed.');
    }
  }
}
