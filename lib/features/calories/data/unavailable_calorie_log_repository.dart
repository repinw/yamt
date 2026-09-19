import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';

/// Calorie log used when Firestore is not available. It stores nothing.
class UnavailableCalorieLogRepository implements CalorieLogRepositoryContract {
  /// Creates an unavailable calorie log repository.
  const new();

  @override
  Stream<List<CalorieEntry>> watchEntriesForDay(DateTime day) {
    return Stream<List<CalorieEntry>>.value(const <CalorieEntry>[]);
  }

  @override
  Future<List<CalorieEntry>> readEntriesForDay(DateTime day) async {
    return const <CalorieEntry>[];
  }

  @override
  Future<List<CalorieEntry>> readEntriesInRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    return const <CalorieEntry>[];
  }

  @override
  Future<DateTime?> readFirstEntryDate() async {
    return null;
  }

  @override
  Future<bool> saveEntry(CalorieEntry entry) async {
    return false;
  }

  @override
  Future<bool> saveEntryForCurrentUser(CalorieEntry entry) async {
    return false;
  }

  @override
  Future<bool> deleteEntry(String entryId) async {
    return false;
  }

  @override
  Future<CalorieEntry?> getById(String entryId) async {
    return null;
  }

  @override
  CalorieEntry? cachedById(String entryId) => null;
}
