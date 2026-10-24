import 'package:yamt/features/calories/domain/calorie_entry.dart';

/// Defines calorie log repository contract.
abstract interface class CalorieLogRepositoryContract {
  /// Watch entries for day.
  Stream<List<CalorieEntry>> watchEntriesForDay(DateTime day);

  /// Watches every entry from [startInclusive] on. The first list comes from
  /// the local cache when it has one, later lists follow each change. A
  /// failed read is delivered as an error, never as an empty list.
  Stream<List<CalorieEntry>> watchEntriesFrom(DateTime startInclusive);

  /// Read entries for day.
  Future<List<CalorieEntry>> readEntriesForDay(DateTime day);

  /// Read entries in range. A failed read throws, never returns an empty list.
  Future<List<CalorieEntry>> readEntriesInRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
  });

  /// Read first entry date, or `null` without entries. A failed read throws.
  Future<DateTime?> readFirstEntryDate();

  /// Save entry.
  Future<bool> saveEntry(CalorieEntry entry);

  /// Save entry for current user, ignoring any user id on the draft entry.
  Future<bool> saveEntryForCurrentUser(CalorieEntry entry);

  /// Delete entry. Does not wait for the server, so it also works offline.
  Future<bool> deleteEntry(String entryId);

  /// Get by id.
  Future<CalorieEntry?> getById(String entryId);

  /// Last known copy of an entry that this repository read or wrote, or
  /// `null`. Never reaches the backend, so screens can open without waiting.
  CalorieEntry? cachedById(String entryId);
}
