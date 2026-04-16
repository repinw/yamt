import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/manual_health_weight_repository_provider.dart';

part 'manual_health_weight_entries_controller.g.dart';

const _logName = 'ManualHealthWeightEntriesController';

/// Defines manual health weight entries controller.
@riverpod
class ManualHealthWeightEntriesController
    extends _$ManualHealthWeightEntriesController {
  @override
  FutureOr<List<ManualHealthWeightEntry>> build() async {
    return ref.read(manualHealthWeightRepositoryProvider).readEntries();
  }

  /// Save entry.
  Future<bool> saveEntry({
    required DateTime day,
    required double weightKg,
  }) async {
    final repository = ref.read(manualHealthWeightRepositoryProvider);
    final healthWeightService = ref.read(healthWeightServiceProvider);
    final connectionStatusFuture = ref.read(
      healthConnectionControllerProvider.future,
    );
    final previousEntries = await _loadCurrentEntries(repository);
    final normalizedDay = normalizeDiaryDay(day);
    final connectionStatus = await connectionStatusFuture;

    if (connectionStatus.accessState == HealthDataAccessState.ready) {
      return _saveToHealth(
        repository: repository,
        healthWeightService: healthWeightService,
        previousEntries: previousEntries,
        normalizedDay: normalizedDay,
        weightKg: weightKg,
      );
    }

    return _saveToRepository(
      repository: repository,
      previousEntries: previousEntries,
      entry: ManualHealthWeightEntry(day: normalizedDay, weightKg: weightKg),
    );
  }

  /// Delete entry for day.
  Future<bool> deleteEntryForDay(DateTime day) async {
    final repository = ref.read(manualHealthWeightRepositoryProvider);
    final previousEntries = await _loadCurrentEntries(repository);
    final normalizedDay = normalizeDiaryDay(day);
    final nextEntries = previousEntries
        .where((entry) => !isSameDiaryDay(entry.day, normalizedDay))
        .toList(growable: false);
    if (ref.mounted) {
      state = AsyncData(
        List<ManualHealthWeightEntry>.unmodifiable(nextEntries),
      );
    }

    try {
      final deleted = await repository.deleteEntryForDay(normalizedDay);
      if (!deleted && ref.mounted) {
        state = AsyncData(previousEntries);
      }
      return deleted;
    } on Object catch (error, stackTrace) {
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

  Future<List<ManualHealthWeightEntry>> _loadCurrentEntries(
    ManualHealthWeightRepository repository,
  ) async {
    final currentEntries = state.asData?.value;
    if (currentEntries != null) {
      return currentEntries;
    }
    final loadedEntries = await repository.readEntries();
    return List<ManualHealthWeightEntry>.unmodifiable(loadedEntries);
  }

  Future<bool> _saveToHealth({
    required ManualHealthWeightRepository repository,
    required HealthWeightService healthWeightService,
    required List<ManualHealthWeightEntry> previousEntries,
    required DateTime normalizedDay,
    required double weightKg,
  }) async {
    final nextEntries = _entriesWithoutDay(previousEntries, normalizedDay);
    try {
      final saved = await healthWeightService.saveWeightSample(
        recordedAt: _weightRecordedAtForDay(normalizedDay),
        weightKg: weightKg,
      );
      if (!saved) {
        return _saveToRepository(
          repository: repository,
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
      final deleted = await repository.deleteEntryForDay(normalizedDay);
      if (!deleted) {
        log(
          'Failed to clear fallback weight entry after health save.',
          name: _logName,
        );
      }
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to save weight entry to health platform.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return _saveToRepository(
        repository: repository,
        previousEntries: previousEntries,
        entry: ManualHealthWeightEntry(day: normalizedDay, weightKg: weightKg),
      );
    }
  }

  Future<bool> _saveToRepository({
    required ManualHealthWeightRepository repository,
    required List<ManualHealthWeightEntry> previousEntries,
    required ManualHealthWeightEntry entry,
  }) async {
    final nextEntries = [
      for (final existingEntry in previousEntries)
        if (!isSameDiaryDay(existingEntry.day, entry.day)) existingEntry,
      entry,
    ]..sort((left, right) => left.day.compareTo(right.day));
    if (ref.mounted) {
      state = AsyncData(
        List<ManualHealthWeightEntry>.unmodifiable(nextEntries),
      );
    }

    try {
      final saved = await repository.saveEntry(entry);
      if (!saved && ref.mounted) {
        state = AsyncData(previousEntries);
      }
      return saved;
    } on Object catch (error, stackTrace) {
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
