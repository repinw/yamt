import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

/// Defines manual health weight repository.
abstract interface class ManualHealthWeightRepository {
  /// Read entries.
  Future<List<ManualHealthWeightEntry>> readEntries();

  /// Save entry.
  Future<bool> saveEntry(ManualHealthWeightEntry entry);

  /// Delete entry for day.
  Future<bool> deleteEntryForDay(DateTime day);
}
