import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/health/data/health_weight_sample_repository.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

part 'health_app_weight_service.g.dart';

const _logName = 'HealthAppWeightService';

/// Writes and deletes the weighings that this app keeps in Health.
@riverpod
HealthAppWeightService healthAppWeightService(Ref ref) {
  return HealthAppWeightService(
    healthWeightService: ref.watch(healthWeightServiceProvider),
    sampleRepository: ref.watch(healthWeightSampleRepositoryProvider),
  );
}

/// Keeps each weighing of this app in the Health store of this device and
/// in its cloud copy, which every weight reader reads.
class HealthAppWeightService {
  /// Creates the service.
  const new({
    required this._healthWeightService,
    required this._sampleRepository,
  });

  final HealthWeightService _healthWeightService;
  final HealthWeightSampleRepository _sampleRepository;

  /// Writes [weightKg] at [recordedAt] to Health as a weighing of its own.
  /// Returns `false` when Health refuses it, for example without write
  /// access.
  Future<bool> add({
    required DateTime recordedAt,
    required double weightKg,
  }) async {
    final saved = await _healthWeightService.saveWeightSample(
      recordedAt: recordedAt,
      weightKg: weightKg,
    );
    if (!saved) {
      return false;
    }
    // Readers read the cloud, so the weight counts before the next sync.
    try {
      await _sampleRepository.saveAppWeight(
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
    return true;
  }

  /// Whether the Health store of this device holds the weighing [sample],
  /// which this app wrote, so this device can change it.
  Future<bool> isOnThisDevice(HealthWeightSample sample) async {
    return await _findOnThisDevice(sample) != null;
  }

  /// Deletes the weighing [sample], which this app wrote to the Health store
  /// of this device, there and in the cloud. Throws when this device does
  /// not hold it or Health refuses.
  Future<void> delete(HealthWeightSample sample) async {
    final local = await _findOnThisDevice(sample);
    if (local == null ||
        !await _healthWeightService.deleteWeightSample(local)) {
      throw StateError('Health did not delete the weight.');
    }
    // The device sync mirrors the deletion when this fails.
    try {
      await _sampleRepository.deleteSample(sample);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to delete the cloud copy; the sync mirrors it.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// The sample of this device's Health store with the minute and weight of
  /// [sample], as the cloud copy keys it; it carries the Health id.
  Future<HealthWeightSample?> _findOnThisDevice(
    HealthWeightSample sample,
  ) async {
    final at = sample.recordedAt;
    final minute = DateTime.fromMillisecondsSinceEpoch(
      at.millisecondsSinceEpoch -
          at.millisecondsSinceEpoch % Duration.millisecondsPerMinute,
    );
    final samples = await _healthWeightService.loadWeightSamples(
      startInclusive: minute,
      endExclusive: minute.add(const Duration(minutes: 1)),
    );
    final weight = sample.weightKg.toStringAsFixed(2);
    return samples
        .where(
          (local) =>
              local.isFromThisApp &&
              local.weightKg.toStringAsFixed(2) == weight &&
              !local.recordedAt.isBefore(minute) &&
              local.recordedAt.isBefore(minute.add(const Duration(minutes: 1))),
        )
        .firstOrNull;
  }
}
