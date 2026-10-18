import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/health/application/health_app_weight_service.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

part 'manual_health_weight_entries_controller.g.dart';

const _logName = 'ManualHealthWeightEntriesController';

/// The manual weight entries, and the weighings that the user adds, changes,
/// or deletes: in Health when it is ready, else as manual entries.
@riverpod
class ManualHealthWeightEntriesController
    extends _$ManualHealthWeightEntriesController {
  @override
  FutureOr<List<ManualHealthWeightEntry>> build() async {
    return await ref.watch(manualHealthWeightRepositoryProvider).readEntries();
  }

  /// Adds a weighing of [day]: now for today, midday for another day.
  Future<bool> saveEntry({required DateTime day, required double weightKg}) {
    return _add(
      _weightRecordedAtForDay(
        normalizeLocalDay(day),
        ref.read(clockProvider)(),
      ),
      weightKg,
    );
  }

  /// Changes [entry] to [weightKg] at [recordedAt].
  Future<bool> updateEntry(
    ManualHealthWeightEntry entry, {
    required DateTime recordedAt,
    required double weightKg,
  }) async {
    final next = ManualHealthWeightEntry(
      day: recordedAt,
      weightKg: weightKg,
      recordedAt: recordedAt,
      id: entry.id,
    );
    ManualHealthWeightEntry? stored;
    final updated = await _write(
      ref.read(manualHealthWeightRepositoryProvider),
      (repository) async => stored = await repository.updateEntry(entry, next),
      removed: entry,
      added: next,
    );
    // The repository may store it under a new id.
    if (updated && ref.mounted && stored?.storageId != next.storageId) {
      state = AsyncData(
        List<ManualHealthWeightEntry>.unmodifiable(
          <ManualHealthWeightEntry>[
            for (final other in state.requireValue)
              if (other.storageId != next.storageId) other,
            ?stored,
          ]..sort((left, right) => left.at.compareTo(right.at)),
        ),
      );
    }
    return updated;
  }

  /// Deletes exactly [entry].
  Future<bool> deleteEntry(ManualHealthWeightEntry entry) {
    return _write(
      ref.read(manualHealthWeightRepositoryProvider),
      (repository) => repository.deleteEntry(entry),
      removed: entry,
    );
  }

  /// Replaces the Health weighing [sample] of this device with [weightKg]
  /// at [recordedAt]. The new weighing comes first, so a failed save loses
  /// nothing; when the old one then fails to go, both stay visible.
  Future<bool> updateAppWeight(
    HealthWeightSample sample, {
    required DateTime recordedAt,
    required double weightKg,
  }) async {
    final unchanged =
        _minute(sample.recordedAt) == _minute(recordedAt) &&
        sample.weightKg.toStringAsFixed(2) == weightKg.toStringAsFixed(2);
    if (unchanged) return true;
    if (!await _add(recordedAt, weightKg)) return false;
    // deleteAppWeight logs a failure; the old weighing then stays listed.
    await deleteAppWeight(sample);
    return true;
  }

  /// Deletes the Health weighing [sample] of this device.
  Future<bool> deleteAppWeight(HealthWeightSample sample) async {
    try {
      await ref.read(healthAppWeightServiceProvider).delete(sample);
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to delete a Health weight.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Writes the weighing to Health when it is ready, else, or when Health
  /// refuses, as a manual entry of its own.
  Future<bool> _add(DateTime recordedAt, double weightKg) async {
    // Read first, so the weighing is still stored when this controller is
    // disposed meanwhile.
    final repository = ref.read(manualHealthWeightRepositoryProvider);
    final status = await ref.read(healthConnectionServiceProvider).loadStatus();
    if (status.accessState == HealthDataAccessState.ready && ref.mounted) {
      try {
        if (await ref
            .read(healthAppWeightServiceProvider)
            .add(recordedAt: recordedAt, weightKg: weightKg)) {
          return true;
        }
      } on Object catch (error, stackTrace) {
        log(
          'Failed to save weight entry to health platform.',
          name: _logName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    final entry = ManualHealthWeightEntry(
      day: recordedAt,
      weightKg: weightKg,
      recordedAt: recordedAt,
      id: const Uuid().v4(),
    );
    return await _write(repository, (repository) async {
      if (!await repository.saveEntry(entry)) {
        throw StateError('The weight was not saved.');
      }
    }, added: entry);
  }

  /// Shows the entries without [removed] and with [added] at once, and
  /// restores them when [write] fails.
  Future<bool> _write(
    ManualHealthWeightRepository repository,
    Future<void> Function(ManualHealthWeightRepository repository) write, {
    ManualHealthWeightEntry? removed,
    ManualHealthWeightEntry? added,
  }) async {
    final previousEntries = await _loadCurrentEntries(repository);
    final nextEntries = [
      for (final entry in previousEntries)
        if (entry.storageId != removed?.storageId &&
            entry.storageId != added?.storageId)
          entry,
      ?added,
    ]..sort((left, right) => left.at.compareTo(right.at));
    if (ref.mounted) {
      state = AsyncData(
        List<ManualHealthWeightEntry>.unmodifiable(nextEntries),
      );
    }

    try {
      await write(repository);
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to write a manual weight entry.',
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
    final currentEntries = ref.mounted ? state.asData?.value : null;
    if (currentEntries != null) {
      return currentEntries;
    }
    final loadedEntries = await repository.readEntries();
    return List<ManualHealthWeightEntry>.unmodifiable(loadedEntries);
  }
}

/// The minute of [at], as the cloud copy keys a weighing.
int _minute(DateTime at) =>
    at.millisecondsSinceEpoch ~/ Duration.millisecondsPerMinute;

/// Now for today, midday for another day.
DateTime _weightRecordedAtForDay(DateTime day, DateTime now) {
  final dayStart = DateTime(day.year, day.month, day.day);
  if (!isSameLocalDay(day, now)) {
    return DateTime(day.year, day.month, day.day, 12);
  }

  final visibleNow = now.subtract(const Duration(seconds: 1));
  if (visibleNow.isAfter(dayStart)) {
    return visibleNow;
  }
  return dayStart;
}
