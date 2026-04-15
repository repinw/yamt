import 'dart:convert';
import 'dart:developer' show log;

import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

const manualHealthWeightEntriesPreferenceKey =
    'manual_health_weight_entries_v1';
const _logName = 'ManualHealthWeightRepository';

class AppPreferencesManualHealthWeightRepository
    implements ManualHealthWeightRepository {
  AppPreferencesManualHealthWeightRepository({
    required AppPreferences preferences,
    this.storageKey = manualHealthWeightEntriesPreferenceKey,
  }) : _preferences = preferences;

  final AppPreferences _preferences;
  final String storageKey;

  @override
  Future<List<ManualHealthWeightEntry>> readEntries() async {
    final raw = await _preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return const <ManualHealthWeightEntry>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<Object?>) {
        return const <ManualHealthWeightEntry>[];
      }

      final entries =
          decoded
              .whereType<Map<String, dynamic>>()
              .map(ManualHealthWeightEntry.fromJson)
              .whereType<ManualHealthWeightEntry>()
              .toList(growable: false)
            ..sort((left, right) => left.day.compareTo(right.day));
      return List<ManualHealthWeightEntry>.unmodifiable(entries);
    } catch (error, stackTrace) {
      log(
        'Failed to decode manual weight entries.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <ManualHealthWeightEntry>[];
    }
  }

  @override
  Future<bool> saveEntry(ManualHealthWeightEntry entry) async {
    final existingEntries = await readEntries();
    final nextEntries = [
      for (final existingEntry in existingEntries)
        if (!isSameDiaryDay(existingEntry.day, entry.day)) existingEntry,
      entry,
    ]..sort((left, right) => left.day.compareTo(right.day));
    return _writeEntries(nextEntries);
  }

  @override
  Future<bool> deleteEntryForDay(DateTime day) async {
    final normalizedDay = normalizeDiaryDay(day);
    final existingEntries = await readEntries();
    final nextEntries = existingEntries
        .where((entry) => !isSameDiaryDay(entry.day, normalizedDay))
        .toList(growable: false);
    return _writeEntries(nextEntries);
  }

  Future<bool> _writeEntries(List<ManualHealthWeightEntry> entries) {
    final encoded = jsonEncode(
      entries.map((entry) => entry.toJson()).toList(growable: false),
    );
    return _preferences.setString(storageKey, encoded);
  }
}
