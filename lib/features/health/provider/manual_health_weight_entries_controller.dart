import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/manual_health_weight_repository_provider.dart';

part 'manual_health_weight_entries_controller.g.dart';

const _logName = 'ManualHealthWeightEntriesController';

@Riverpod(keepAlive: true)
class ManualHealthWeightEntriesController
    extends _$ManualHealthWeightEntriesController {
  @override
  FutureOr<List<ManualHealthWeightEntry>> build() async {
    return ref.read(manualHealthWeightRepositoryProvider).readEntries();
  }

  Future<bool> saveEntry({
    required DateTime day,
    required double weightKg,
  }) async {
    final previousEntries = await _loadCurrentEntries();
    final normalizedDay = normalizeDiaryDay(day);
    final connectionStatus = await ref.read(
      healthConnectionControllerProvider.future,
    );

    if (connectionStatus.accessState == HealthDataAccessState.ready) {
      return _saveToHealth(
        previousEntries: previousEntries,
        normalizedDay: normalizedDay,
        weightKg: weightKg,
      );
    }

    return _saveToRepository(
      previousEntries: previousEntries,
      entry: ManualHealthWeightEntry(day: normalizedDay, weightKg: weightKg),
    );
  }

  Future<bool> deleteEntryForDay(DateTime day) async {
    final previousEntries = await _loadCurrentEntries();
    final normalizedDay = normalizeDiaryDay(day);
    final nextEntries = previousEntries
        .where((entry) => !isSameDiaryDay(entry.day, normalizedDay))
        .toList(growable: false);
    state = AsyncData(List<ManualHealthWeightEntry>.unmodifiable(nextEntries));

    try {
      final deleted = await ref
          .read(manualHealthWeightRepositoryProvider)
          .deleteEntryForDay(normalizedDay);
      if (!deleted && ref.mounted) {
        state = AsyncData(previousEntries);
      }
      return deleted;
    } catch (error, stackTrace) {
      log(
        'Failed to delete manual weight entry.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      if (ref.mounted) {
        state = AsyncData(previousEntries);
      }
      return false;
    }
  }

  Future<List<ManualHealthWeightEntry>> _loadCurrentEntries() async {
    final currentEntries = state.asData?.value;
    if (currentEntries != null) {
      return currentEntries;
    }
    final loadedEntries = await ref
        .read(manualHealthWeightRepositoryProvider)
        .readEntries();
    return List<ManualHealthWeightEntry>.unmodifiable(loadedEntries);
  }

  Future<bool> _saveToHealth({
    required List<ManualHealthWeightEntry> previousEntries,
    required DateTime normalizedDay,
    required double weightKg,
  }) async {
    final nextEntries = _entriesWithoutDay(previousEntries, normalizedDay);
    try {
      final saved = await ref
          .read(healthWeightServiceProvider)
          .saveWeightSample(
            recordedAt: _weightRecordedAtForDay(normalizedDay),
            weightKg: weightKg,
          );
      if (!saved) {
        return _saveToRepository(
          previousEntries: previousEntries,
          entry: ManualHealthWeightEntry(
            day: normalizedDay,
            weightKg: weightKg,
          ),
        );
      }

      if (ref.mounted) {
        state = AsyncData(nextEntries);
      }
      final deleted = await ref
          .read(manualHealthWeightRepositoryProvider)
          .deleteEntryForDay(normalizedDay);
      if (!deleted) {
        log(
          'Failed to clear fallback weight entry after health save.',
          name: _logName,
        );
      }
      return true;
    } catch (error, stackTrace) {
      log(
        'Failed to save weight entry to health platform.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return _saveToRepository(
        previousEntries: previousEntries,
        entry: ManualHealthWeightEntry(day: normalizedDay, weightKg: weightKg),
      );
    }
  }

  Future<bool> _saveToRepository({
    required List<ManualHealthWeightEntry> previousEntries,
    required ManualHealthWeightEntry entry,
  }) async {
    final nextEntries = [
      for (final existingEntry in previousEntries)
        if (!isSameDiaryDay(existingEntry.day, entry.day)) existingEntry,
      entry,
    ]..sort((left, right) => left.day.compareTo(right.day));
    state = AsyncData(List<ManualHealthWeightEntry>.unmodifiable(nextEntries));

    try {
      final saved = await ref
          .read(manualHealthWeightRepositoryProvider)
          .saveEntry(entry);
      if (!saved && ref.mounted) {
        state = AsyncData(previousEntries);
      }
      return saved;
    } catch (error, stackTrace) {
      log(
        'Failed to save fallback weight entry.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      if (ref.mounted) {
        state = AsyncData(previousEntries);
      }
      return false;
    }
  }

  List<ManualHealthWeightEntry> _entriesWithoutDay(
    List<ManualHealthWeightEntry> entries,
    DateTime day,
  ) {
    return List<ManualHealthWeightEntry>.unmodifiable(
      entries.where((entry) => !isSameDiaryDay(entry.day, day)),
    );
  }
}

DateTime _weightRecordedAtForDay(DateTime day) {
  // Stable midday timestamp avoids creating near-duplicate manual samples
  // for same day when user edits weight multiple times.
  return DateTime(day.year, day.month, day.day, 12);
}
