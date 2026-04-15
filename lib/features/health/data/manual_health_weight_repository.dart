import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

abstract interface class ManualHealthWeightRepository {
  Future<List<ManualHealthWeightEntry>> readEntries();

  Future<bool> saveEntry(ManualHealthWeightEntry entry);

  Future<bool> deleteEntryForDay(DateTime day);
}
