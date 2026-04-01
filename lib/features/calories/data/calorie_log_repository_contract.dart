import 'package:yamt/features/calories/domain/calorie_entry.dart';

abstract interface class CalorieLogRepositoryContract {
  Stream<List<CalorieEntry>> watchEntriesForDay(DateTime day);

  Future<List<CalorieEntry>> readEntriesForDay(DateTime day);

  Future<List<CalorieEntry>> readEntriesInRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
  });

  Future<DateTime?> readFirstEntryDate();

  Future<bool> saveEntry(CalorieEntry entry);

  Future<bool> deleteEntry(String entryId);

  Future<CalorieEntry?> getById(String entryId);
}
