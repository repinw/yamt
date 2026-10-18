import 'dart:async';
import 'dart:developer' show log;

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_sample_repository.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

part 'manual_health_weight_entries_controller.g.dart';

const _logName = 'ManualHealthWeightEntriesController';

/// Defines manual health weight entries controller.
@riverpod
class ManualHealthWeightEntriesController
    extends _$ManualHealthWeightEntriesController {
  @override
  FutureOr<List<ManualHealthWeightEntry>> build() async {
    return await ref.watch(manualHealthWeightRepositoryProvider).readEntries();
  }

  /// Save entry.
  Future<bool> saveEntry({
    required DateTime day,
    required double weightKg,
  }) async {
    final repository = ref.read(manualHealthWeightRepositoryProvider);
    final healthWeightService = ref.read(healthWeightServiceProvider);
    final healthConnectionService = ref.read(healthConnectionServiceProvider);
    final now = ref.read(clockProvider)();
    final previousEntries = await _loadCurrentEntries(repository);
    final normalizedDay = normalizeLocalDay(day);
    final connectionStatus = await healthConnectionService.loadStatus();

    final saved = connectionStatus.accessState == HealthDataAccessState.ready
        ? await _saveToHealth(
            repository: repository,
            healthWeightService: healthWeightService,
            sampleRepository: ref.read(healthWeightSampleRepositoryProvider),
            previousEntries: previousEntries,
            normalizedDay: normalizedDay,
            now: now,
            weightKg: weightKg,
          )
        : await _saveToRepository(
            repository: repository,
            previousEntries: previousEntries,
            entry: _dayEntry(
              previousEntries,
              _weightRecordedAtForDay(normalizedDay, now),
              weightKg,
            ),
          );
    return saved;
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
    required HealthWeightSampleRepository sampleRepository,
    required List<ManualHealthWeightEntry> previousEntries,
    required DateTime normalizedDay,
    required DateTime now,
    required double weightKg,
  }) async {
    final nextEntries = _entriesWithoutDay(previousEntries, normalizedDay);
    final recordedAt = _weightRecordedAtForDay(normalizedDay, now);
    try {
      final saved = await healthWeightService.saveWeightSample(
        recordedAt: recordedAt,
        weightKg: weightKg,
      );
      if (!saved) {
        return await _saveToRepository(
          repository: repository,
          previousEntries: previousEntries,
          entry: _dayEntry(previousEntries, recordedAt, weightKg),
        );
      }

      // Readers read the cloud, so the weight counts before the next sync.
      try {
        await sampleRepository.saveAppWeight(
          recordedAt: recordedAt,
          weightKg: weightKg,
        );
      } on Object catch (error, stackTrace) {
        log(
          'Failed to store the weight in the cloud; the sync retries.',
          name: _logName,
          error: error,
          stackTrace: stackTrace,
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
      return await _saveToRepository(
        repository: repository,
        previousEntries: previousEntries,
        entry: _dayEntry(previousEntries, recordedAt, weightKg),
      );
    }
  }

  Future<bool> _saveToRepository({
    required ManualHealthWeightRepository repository,
    required List<ManualHealthWeightEntry> previousEntries,
    required ManualHealthWeightEntry entry,
  }) async {
    // Other weighings of the day are their own documents and stay.
    final nextEntries = [
      for (final existingEntry in previousEntries)
        if (existingEntry.storageId != entry.storageId) existingEntry,
      entry,
    ]..sort((left, right) => left.at.compareTo(right.at));
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
      if (!saved) {
        return false;
      }
      return true;
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
      entries.where((entry) => !isSameLocalDay(entry.day, day)),
    );
  }
}

/// The weight of the day at [recordedAt], stored over the last entry of
/// that day.
ManualHealthWeightEntry _dayEntry(
  List<ManualHealthWeightEntry> entries,
  DateTime recordedAt,
  double weightKg,
) {
  return ManualHealthWeightEntry(
    day: recordedAt,
    weightKg: weightKg,
    recordedAt: recordedAt,
    id: entries
        .lastWhereOrNull((entry) => isSameLocalDay(entry.day, recordedAt))
        ?.id,
  );
}

DateTime _weightRecordedAtForDay(DateTime day, DateTime now) {
  // Stable midday timestamp avoids creating near-duplicate manual samples
  // for same day when user edits weight multiple times.
  final dayStart = DateTime(day.year, day.month, day.day);
  final midday = DateTime(day.year, day.month, day.day, 12);
  if (!isSameLocalDay(day, now) || !midday.isAfter(now)) {
    return midday;
  }

  final visibleNow = now.subtract(const Duration(seconds: 1));
  if (visibleNow.isAfter(dayStart)) {
    return visibleNow;
  }
  return dayStart;
}
