import 'package:yamt/features/health/domain/health_weight_sample.dart';

const _defaultWeightCacheTtl = Duration(minutes: 5);
const _recentPastWeightQueryWindow = Duration(days: 30);

class _WeightSampleCacheEntry {
  const new({
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

/// In-memory cache and range expansion for health weight samples.
class HealthWeightSampleCache {
  /// Creates a health weight sample cache.
  new({
    this._ttl = _defaultWeightCacheTtl,
    this._recentPastQueryWindow = _recentPastWeightQueryWindow,
  });

  final Duration _ttl;
  final Duration _recentPastQueryWindow;
  _WeightSampleCacheEntry? _entry;

  /// Clears the cached samples.
  void clear() {
    _entry = null;
  }

  /// Calculates the query end time, expanding recent queries up to [now].
  DateTime queryEndExclusive({
    required DateTime requestedEndExclusive,
    required DateTime now,
  }) {
    if (requestedEndExclusive.isAfter(now)) {
      return now;
    }
    if (now.difference(requestedEndExclusive) > _recentPastQueryWindow) {
      return requestedEndExclusive;
    }
    return now;
  }

  /// Calculates the end time of the cached window.
  DateTime cacheEndExclusive({
    required DateTime requestedEndExclusive,
    required DateTime queryEndExclusive,
  }) {
    if (requestedEndExclusive.isAfter(queryEndExclusive)) {
      return requestedEndExclusive;
    }
    return queryEndExclusive;
  }

  /// Retrieves cached samples matching [startInclusive] and [endExclusive]
  /// if the cache contains the full window and has not expired relative
  /// to [now].
  List<HealthWeightSample>? get({
    required DateTime startInclusive,
    required DateTime endExclusive,
    required DateTime now,
  }) {
    final entry = _entry;
    if (entry == null || now.difference(entry.loadedAt) > _ttl) {
      _entry = null;
      return null;
    }
    final containsRequest =
        !startInclusive.isBefore(entry.startInclusive) &&
        !endExclusive.isAfter(entry.endExclusive);
    if (!containsRequest) {
      return null;
    }
    return filterSamples(
      entry.samples,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );
  }

  /// Stores [samples] in cache for the specified range loaded at [loadedAt].
  void put({
    required DateTime startInclusive,
    required DateTime requestedEndExclusive,
    required DateTime queryEndExclusive,
    required DateTime loadedAt,
    required List<HealthWeightSample> samples,
  }) {
    _entry = _WeightSampleCacheEntry(
      startInclusive: startInclusive,
      endExclusive: cacheEndExclusive(
        requestedEndExclusive: requestedEndExclusive,
        queryEndExclusive: queryEndExclusive,
      ),
      loadedAt: loadedAt,
      samples: List<HealthWeightSample>.unmodifiable(samples),
    );
  }

  /// Filters [samples] to the `[startInclusive, endExclusive)` window.
  static List<HealthWeightSample> filterSamples(
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
}
