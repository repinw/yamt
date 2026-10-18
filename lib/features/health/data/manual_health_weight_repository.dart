import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

/// Defines manual health weight repository.
abstract interface class ManualHealthWeightRepository {
  /// Read entries.
  Future<List<ManualHealthWeightEntry>> readEntries();

  /// Saves [entry] under its id, or under its day without one.
  Future<bool> saveEntry(ManualHealthWeightEntry entry);

  /// Stores [next] in place of [previous] and returns what it stored.
  /// Throws when it fails or without a signed-in user.
  Future<ManualHealthWeightEntry> updateEntry(
    ManualHealthWeightEntry previous,
    ManualHealthWeightEntry next,
  );

  /// Deletes exactly [entry]. Throws when it fails or without a signed-in
  /// user.
  Future<void> deleteEntry(ManualHealthWeightEntry entry);
}
