import 'package:yamt/features/calories/domain/calorie_entry.dart';

/// Defines calorie log repository contract.
abstract interface class CalorieLogRepositoryContract {
  /// Watch entries for day.
  Stream<List<CalorieEntry>> watchEntriesForDay(DateTime day);

  /// Read entries for day.
  Future<List<CalorieEntry>> readEntriesForDay(DateTime day);

  /// Read entries in range.
  Future<List<CalorieEntry>> readEntriesInRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
  });

  /// Read first entry date.
  Future<DateTime?> readFirstEntryDate();

  /// Save entry.
  Future<bool> saveEntry(CalorieEntry entry);

  /// Delete entry.
  Future<bool> deleteEntry(String entryId);

  /// Get by id.
  Future<CalorieEntry?> getById(String entryId);
}
