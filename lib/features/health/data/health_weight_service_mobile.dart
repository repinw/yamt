import 'dart:developer' show log;

import 'package:health/health.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

const _logName = 'HealthWeightService';
const _weightTypes = <HealthDataType>[HealthDataType.WEIGHT];
const _weightCacheTtl = Duration(minutes: 5);
const _recentPastWeightQueryWindow = Duration(days: 30);

/// Create health weight service.
HealthWeightService createHealthWeightService() {
  return MobileHealthWeightService();
}

/// Defines mobile health weight service.
class MobileHealthWeightService implements HealthWeightService {
  /// Creates an instance.
  MobileHealthWeightService({
    Health? health,
    DateTime Function()? now,
    Duration cacheTtl = _weightCacheTtl,
  }) : _health = health ?? Health(),
       _now = now ?? DateTime.now,
       _cacheTtl = cacheTtl;

  final Health _health;
  final DateTime Function() _now;
  final Duration _cacheTtl;
  bool _isConfigured = false;
  _WeightSampleCacheEntry? _cache;

  @override
  Future<List<HealthWeightSample>> loadWeightSamples({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    await _ensureConfigured();

    final queryEndExclusive = _queryEndExclusive(endExclusive);
    final cachedSamples = _cachedSamples(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );
    if (cachedSamples != null) {
      log(
        'Read weight samples from cache. '
        'start=${startInclusive.toIso8601String()} '
        'end=${endExclusive.toIso8601String()} '
        'count=${cachedSamples.length}',
        name: _logName,
      );
      return cachedSamples;
    }

    final points = queryEndExclusive.isAfter(startInclusive)
        ? await _health.getHealthDataFromTypes(
            types: _weightTypes,
            startTime: startInclusive,
            endTime: queryEndExclusive,
          )
        : const <HealthDataPoint>[];
    final querySamples =
        points
            .map(_buildSample)
            .whereType<HealthWeightSample>()
            .toList(growable: false)
          ..sort((left, right) => left.recordedAt.compareTo(right.recordedAt));
    _cache = _WeightSampleCacheEntry(
      startInclusive: startInclusive,
      endExclusive: _cacheEndExclusive(
        requestedEndExclusive: endExclusive,
        queryEndExclusive: queryEndExclusive,
      ),
      loadedAt: _now(),
      samples: List<HealthWeightSample>.unmodifiable(querySamples),
    );
    final samples = _filterSamples(
      querySamples,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );

    log(
      'Read weight samples. '
      'start=${startInclusive.toIso8601String()} '
      'end=${endExclusive.toIso8601String()} '
      'queryEnd=${queryEndExclusive.toIso8601String()} '
      'count=${samples.length}',
      name: _logName,
    );

    return samples;
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
    if (saved) {
      _cache = null;
    }

    return saved;
  }

  Future<void> _ensureConfigured() async {
    if (_isConfigured) {
      return;
    }
    await _health.configure();
    _isConfigured = true;
  }

  DateTime _queryEndExclusive(DateTime requestedEndExclusive) {
    final now = _now();
    if (requestedEndExclusive.isAfter(now)) {
      return now;
    }
    if (now.difference(requestedEndExclusive) > _recentPastWeightQueryWindow) {
      return requestedEndExclusive;
    }
    return now;
  }

  DateTime _cacheEndExclusive({
    required DateTime requestedEndExclusive,
    required DateTime queryEndExclusive,
  }) {
    if (requestedEndExclusive.isAfter(queryEndExclusive)) {
      return requestedEndExclusive;
    }
    return queryEndExclusive;
  }

  List<HealthWeightSample>? _cachedSamples({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    final cache = _cache;
    if (cache == null || _now().difference(cache.loadedAt) > _cacheTtl) {
      _cache = null;
      return null;
    }
    final cacheContainsRequest =
        !startInclusive.isBefore(cache.startInclusive) &&
        !endExclusive.isAfter(cache.endExclusive);
    if (!cacheContainsRequest) {
      return null;
    }
    return _filterSamples(
      cache.samples,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );
  }

  List<HealthWeightSample> _filterSamples(
    List<HealthWeightSample> samples, {
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    return List<HealthWeightSample>.unmodifiable(
      samples.where(
        (sample) =>
            !sample.recordedAt.isBefore(startInclusive) &&
            sample.recordedAt.isBefore(endExclusive),
      ),
    );
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

class _WeightSampleCacheEntry {
  const _WeightSampleCacheEntry({
    required this.startInclusive,
    required this.endExclusive,
    required this.loadedAt,
    required this.samples,
  });

  final DateTime startInclusive;
  final DateTime endExclusive;
  final DateTime loadedAt;
  final List<HealthWeightSample> samples;
}
