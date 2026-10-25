import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';

/// Keeps plans in memory.
class FakePlannedEntryRepository extends PlannedEntryRepository {
  new({List<CalorieEntry>? plans})
    : plans = plans ?? <CalorieEntry>[],
      super(dataCipher: null, firestore: null);

  final List<CalorieEntry> plans;

  bool writeShouldFail = false;

  bool loadShouldFail = false;

  @override
  Future<List<CalorieEntry>> loadPlannedEntries(
    DateTime first,
    DateTime last,
  ) async {
    if (loadShouldFail) {
      throw StateError('Plan read failed.');
    }
    final from = normalizeLocalDay(first);
    final to = normalizeLocalDay(last);
    return plans.where((plan) {
      final day = normalizeLocalDay(plan.loggedAt);
      return !day.isBefore(from) && !day.isAfter(to);
    }).toList()..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }

  @override
  Future<Set<DateTime>> loadPlannedDays(DateTime first, DateTime last) async {
    final from = normalizeLocalDay(first);
    final to = normalizeLocalDay(last);
    return {
      for (final plan in plans)
        if (!normalizeLocalDay(plan.loggedAt).isBefore(from) &&
            !normalizeLocalDay(plan.loggedAt).isAfter(to))
          normalizeLocalDay(plan.loggedAt),
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
