import 'dart:developer' show log;

import 'package:health/health.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

const _logName = 'HealthWeightService';
const _weightTypes = <HealthDataType>[HealthDataType.WEIGHT];

/// Create health weight service.
HealthWeightService createHealthWeightService() {
  return MobileHealthWeightService();
}

/// Defines mobile health weight service.
class MobileHealthWeightService implements HealthWeightService {
  /// Creates an instance.
  MobileHealthWeightService({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _isConfigured = false;

  @override
  Future<List<HealthWeightSample>> loadWeightSamples({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    await _ensureConfigured();

    final points = await _health.getHealthDataFromTypes(
      types: _weightTypes,
      startTime: startInclusive,
      endTime: endExclusive,
    );
    final samples =
        points
            .map(_buildSample)
            .whereType<HealthWeightSample>()
            .toList(growable: false)
          ..sort((left, right) => left.recordedAt.compareTo(right.recordedAt));

    log(
      'Read weight samples. '
      'start=${startInclusive.toIso8601String()} '
      'end=${endExclusive.toIso8601String()} '
      'count=${samples.length}',
      name: _logName,
    );

    return List<HealthWeightSample>.unmodifiable(samples);
  }

  @override
  Future<bool> saveWeightSample({
    required DateTime recordedAt,
    required double weightKg,
  }) async {
    await _ensureConfigured();

    final hasWritePermission = await _health.hasPermissions(
      _weightTypes,
      permissions: const <HealthDataAccess>[HealthDataAccess.READ_WRITE],
    );
    final authorized =
        hasWritePermission ??
        await _health.requestAuthorization(
          _weightTypes,
          permissions: const <HealthDataAccess>[HealthDataAccess.READ_WRITE],
        );
    if (!authorized) {
      log(
        'Skipped weight write. Missing read/write permission.',
        name: _logName,
      );
      return false;
    }

    final saved = await _health.writeHealthData(
      value: weightKg,
      type: HealthDataType.WEIGHT,
      startTime: recordedAt,
      recordingMethod: RecordingMethod.manual,
    );

    log(
      'Wrote weight sample. '
      'recordedAt=${recordedAt.toIso8601String()} '
      'weightKg=$weightKg '
      'saved=$saved',
      name: _logName,
    );

    return saved;
  }

  Future<void> _ensureConfigured() async {
    if (_isConfigured) {
      return;
    }
    await _health.configure();
    _isConfigured = true;
  }

  HealthWeightSample? _buildSample(HealthDataPoint point) {
    final value = point.value;
    final numericValue = switch (value) {
      NumericHealthValue(:final numericValue) => numericValue,
      _ => null,
    };
    if (numericValue == null) {
      return null;
    }
    return HealthWeightSample(
      recordedAt: point.dateFrom.toLocal(),
      weightKg: numericValue.toDouble(),
    );
  }
}
