import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/health/data/'
    'app_preferences_manual_health_weight_repository.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

import '../../../helpers/memory_app_preferences.dart';

void main() {
  test(
    'saveEntry persists sorted entries and replaces same-day value',
    () async {
      final preferences = MemoryAppPreferences();
      final repository = AppPreferencesManualHealthWeightRepository(
        preferences: preferences,
      );

      await repository.saveEntry(
        ManualHealthWeightEntry(day: DateTime(2026, 3, 20), weightKg: 71.4),
      );
      await repository.saveEntry(
        ManualHealthWeightEntry(day: DateTime(2026, 3, 18), weightKg: 72.1),
      );
      await repository.saveEntry(
        ManualHealthWeightEntry(day: DateTime(2026, 3, 20), weightKg: 71),
      );

      final entries = await repository.readEntries();

      expect(entries, hasLength(2));
      expect(entries.first.day, DateTime(2026, 3, 18));
      expect(entries.first.weightKg, 72.1);
      expect(entries.last.day, DateTime(2026, 3, 20));
      expect(entries.last.weightKg, 71.0);
    },
  );

  test('readEntries ignores malformed stored payload', () async {
    final preferences = MemoryAppPreferences(
      initialStrings: {manualHealthWeightEntriesPreferenceKey: '{"bad":true}'},
    );
    final repository = AppPreferencesManualHealthWeightRepository(
      preferences: preferences,
    );

    expect(await repository.readEntries(), isEmpty);
  });

  test('deleteEntryForDay removes only matching day', () async {
    final preferences = MemoryAppPreferences(
      initialStrings: {
        manualHealthWeightEntriesPreferenceKey: jsonEncode([
          ManualHealthWeightEntry(
            day: DateTime(2026, 3, 18),
            weightKg: 72.1,
          ).toJson(),
          ManualHealthWeightEntry(
            day: DateTime(2026, 3, 20),
            weightKg: 71,
          ).toJson(),
        ]),
      },
    );
    final repository = AppPreferencesManualHealthWeightRepository(
      preferences: preferences,
    );

    await repository.deleteEntryForDay(DateTime(2026, 3, 20, 12));

    final entries = await repository.readEntries();
    expect(entries, hasLength(1));
    expect(entries.single.day, DateTime(2026, 3, 18));
  });
}
