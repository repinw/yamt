import 'dart:developer' show log;

import 'package:health/health.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yamt/features/health/data/health_weight_sample_cache.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

const _logName = 'HealthWeightService';
const _weightTypes = <HealthDataType>[HealthDataType.WEIGHT];
const _appWeightClientRecordPrefix = 'yamt-weight';

/// Create health weight service.
HealthWeightService createHealthWeightService() {
  return MobileHealthWeightService();
}

/// Defines mobile health weight service.
class MobileHealthWeightService implements HealthWeightService {
  /// Creates an instance.
  new({
    Health? health,
    DateTime Function()? now,
    Duration cacheTtl = const Duration(minutes: 5),
    HealthWeightSampleCache? cache,
  })  : _health = health ?? Health(),
        _now = now ?? DateTime.now,
        _cache = cache ?? HealthWeightSampleCache(ttl: cacheTtl);

  final Health _health;
  final DateTime Function() _now;
  final HealthWeightSampleCache _cache;
  bool _isConfigured = false;
  String? _packageName;

  @override
  Future<List<HealthWeightSample>> loadWeightSamples({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    await _ensureConfigured();

    final now = _now();
    final queryEndExclusive = _cache.queryEndExclusive(
      requestedEndExclusive: endExclusive,
      now: now,
    );
    final cachedSamples = _cache.get(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
      now: now,
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
    _cache.put(
      startInclusive: startInclusive,
      requestedEndExclusive: endExclusive,
      queryEndExclusive: queryEndExclusive,
      loadedAt: now,
      samples: querySamples,
    );
    final samples = HealthWeightSampleCache.filterSamples(
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
      clientRecordId: _weightClientRecordId(recordedAt),
      clientRecordVersion: _weightClientRecordVersion(),
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
      _cache.clear();
    }

    return saved;
  }

  @override
  Future<bool> deleteWeightSample(HealthWeightSample sample) async {
    await _ensureConfigured();
    if (!sample.isFromThisApp) {
      log(
        'Skipped weight delete. Sample belongs to another source. '
        'source=${sample.sourcePackageName}',
        name: _logName,
      );
      return false;
    }

    final uuid = sample.uuid?.trim();
    if (uuid == null || uuid.isEmpty) {
      log('Skipped weight delete. Missing sample uuid.', name: _logName);
      return false;
    }

    final deleted = await _health.deleteByUUID(
      uuid: uuid,
      type: HealthDataType.WEIGHT,
    );
    if (deleted) {
      _cache.clear();
    }
    log(
      'Deleted app-owned weight sample. '
      'uuid=$uuid deleted=$deleted',
      name: _logName,
    );
    return deleted;
  }

  Future<void> _ensureConfigured() async {
    if (_isConfigured) {
      return;
    }
    await _health.configure();
    _packageName = (await PackageInfo.fromPlatform()).packageName;
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
    final sourceId = point.sourceId.trim();
    final sourceName = point.sourceName.trim();
    final sourcePackageName =
        point.sourcePlatform == HealthPlatformType.appleHealth
            ? sourceId
            : sourceName.isNotEmpty
                ? sourceName
                : sourceId;
    final packageName = _packageName?.trim();
    return HealthWeightSample(
      recordedAt: point.dateFrom.toLocal(),
      weightKg: numericValue.toDouble(),
      uuid: point.uuid.trim().isEmpty ? null : point.uuid.trim(),
      sourcePackageName: sourcePackageName.isEmpty ? null : sourcePackageName,
      isFromThisApp:
          packageName != null &&
          packageName.isNotEmpty &&
          (sourceId == packageName || sourceName == packageName),
    );
  }
}

String _weightClientRecordId(DateTime recordedAt) {
  final day = DateTime(recordedAt.year, recordedAt.month, recordedAt.day);
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '$_appWeightClientRecordPrefix-${day.year}-$month-$date';
}

double _weightClientRecordVersion() {
  return DateTime.now().millisecondsSinceEpoch.toDouble();
}
