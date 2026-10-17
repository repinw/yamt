import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

/// Defines manual health weight repository.
abstract interface class ManualHealthWeightRepository {
  /// Read entries.
  Future<List<ManualHealthWeightEntry>> readEntries();

  /// Saves [entry] under its id, or under its day without one.
  Future<bool> saveEntry(ManualHealthWeightEntry entry);

  /// Deletes every entry of [day].
  Future<bool> deleteEntryForDay(DateTime day);
}
