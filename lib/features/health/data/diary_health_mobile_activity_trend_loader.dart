import 'dart:async';
import 'dart:developer' show log;

import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/health/data/diary_health_activity_trend_day_cache_store.dart';
import 'package:yamt/features/health/data/diary_health_mobile_cache_helpers.dart';
import 'package:yamt/features/health/data/diary_health_mobile_config.dart';
import 'package:yamt/features/health/data/diary_health_mobile_health_reader.dart';
import 'package:yamt/features/health/data/diary_health_service_cache_entry.dart';
import 'package:yamt/features/health/domain/diary_health_activity_trend_day.dart';

/// Loads and caches aggregate activity trend days for mobile Health.
class DiaryHealthMobileActivityTrendLoader {
  /// Creates an aggregate activity trend loader.
  DiaryHealthMobileActivityTrendLoader({
    required DiaryHealthMobileHealthReader healthReader,
    required DateTime Function() now,
    required Duration todayCacheTtl,
    required Duration historicalCacheTtl,
    DiaryHealthActivityTrendDayCacheStore? cacheStore,
  }) : _healthReader = healthReader,
       _now = now,
       _todayCacheTtl = todayCacheTtl,
       _historicalCacheTtl = historicalCacheTtl,
       _cacheStore = cacheStore;

  final DiaryHealthMobileHealthReader _healthReader;
  final DateTime Function() _now;
  final Duration _todayCacheTtl;
  final Duration _historicalCacheTtl;
  final DiaryHealthActivityTrendDayCacheStore? _cacheStore;

  final Map<String, DiaryHealthActivityTrendCacheEntry> _rangeCacheByKey =
      <String, DiaryHealthActivityTrendCacheEntry>{};
  final Map<String, DiaryHealthActivityTrendDayCacheEntry> _dayCacheByKey =
      <String, DiaryHealthActivityTrendDayCacheEntry>{};
  final Map<String, Future<List<DiaryHealthActivityTrendDay>>> _inFlightByKey =
      <String, Future<List<DiaryHealthActivityTrendDay>>>{};
  final Set<String> _backgroundRefreshKeys = <String>{};

  /// Loads aggregate trend days for a normalized local-day range.
  Future<List<DiaryHealthActivityTrendDay>> loadActivityTrendDays({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    final start = normalizeLocalDay(startInclusive);
    final end = normalizeLocalDay(endExclusive);
    if (!start.isBefore(end)) {
      return const <DiaryHealthActivityTrendDay>[];
    }

    final cacheKey = _rangeCacheKey(
      startInclusive: start,
      endExclusive: end,
    );
    final cachedDays = _cachedRangeDays(cacheKey);
    if (cachedDays != null) {
      return cachedDays;
    }

    final cachedRange = await _readCachedRangeDays(
      startInclusive: start,
      endExclusive: end,
    );
    if (cachedRange.isComplete) {
      if (cachedRange.hasExpiredDays) {
        final loadedAt = cachedRange.oldestLoadedAt ?? _now();
        _cacheRangeInMemory(
          cacheKey: cacheKey,
          startInclusive: start,
          endExclusive: end,
          loadedAt: loadedAt,
          checkedAt: loadedAt,
          days: cachedRange.days,
        );
        _refreshRangeInBackground(
          cacheKey: cacheKey,
          startInclusive: start,
          endExclusive: end,
        );
      }
      return cachedRange.days;
    }

    final pendingDays = _inFlightByKey[cacheKey];
    if (pendingDays != null) {
      return pendingDays;
    }

    final future = _loadAndCacheRangeDays(
      cacheKey: cacheKey,
      startInclusive: start,
      endExclusive: end,
      cachedRange: cachedRange,
    ).whenComplete(() => _removeInFlight(cacheKey));
    _inFlightByKey[cacheKey] = future;
    return future;
  }

  /// Reads one cached aggregate trend day from memory or persistence.
  Future<DiaryHealthActivityTrendDayCacheEntry?> readCachedDay(
    DateTime day,
  ) async {
    final cacheKey = localDayKey(day);
    final now = _now();
    final cacheEntry = _dayCacheByKey[cacheKey];
    if (cacheEntry != null) {
      if (_isTooStaleDayEntry(cacheEntry, now)) {
        _dayCacheByKey.remove(cacheKey);
      } else {
        return cacheEntry;
      }
    }

    final persistentEntry = await _cacheStore?.readDay(
      day: day,
      now: now,
      maxStaleAge: diaryHealthMaxStaleCacheAge,
    );
    if (persistentEntry == null) {
      return null;
    }
    _dayCacheByKey[cacheKey] = persistentEntry;
    return persistentEntry;
  }

  Future<List<DiaryHealthActivityTrendDay>> _loadAndCacheRangeDays({
    required String cacheKey,
    required DateTime startInclusive,
    required DateTime endExclusive,
    _ActivityTrendCacheRange? cachedRange,
  }) async {
    if (cachedRange != null &&
        cachedRange.hasCachedDays &&
        cachedRange.missingRanges.isNotEmpty) {
      return _loadAndCacheMissingDays(
        cacheKey: cacheKey,
        startInclusive: startInclusive,
        endExclusive: endExclusive,
        cachedRange: cachedRange,
      );
    }
    final staleEntry = _rangeCacheByKey[cacheKey];
    final staleDays = _usableStaleRangeDays(staleEntry, _now());
    try {
      final freshDays = await _healthReader.loadActivityTrendDays(
        startInclusive: startInclusive,
        endExclusive: endExclusive,
      );
      final days = _resolveCacheableDays(
        startInclusive: startInclusive,
        freshDays: freshDays,
        staleDays: staleDays,
      );
      if (identical(days, staleDays)) {
        _touchStaleRange(cacheKey);
        return days;
      }
      await _cacheRangeDays(
        cacheKey: cacheKey,
        startInclusive: startInclusive,
        endExclusive: endExclusive,
        days: days,
      );
      return days;
    } on Object catch (error, stackTrace) {
      if (staleDays != null) {
        log(
          'Kept stale activity trend after Health Connect read failed. '
          'start=${startInclusive.toIso8601String()} '
          'end=${endExclusive.toIso8601String()}',
          name: diaryHealthLogName,
          error: error,
          stackTrace: stackTrace,
        );
        _touchStaleRange(cacheKey);
        return staleDays;
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<List<DiaryHealthActivityTrendDay>> _loadAndCacheMissingDays({
    required String cacheKey,
    required DateTime startInclusive,
    required DateTime endExclusive,
    required _ActivityTrendCacheRange cachedRange,
  }) async {
    final daysByKey = <String, DiaryHealthActivityTrendDay>{
      for (final day in cachedRange.cachedDays) localDayKey(day.day): day,
    };

    for (final range in cachedRange.missingRanges) {
      final freshDays = await _healthReader.loadActivityTrendDays(
        startInclusive: range.startInclusive,
        endExclusive: range.endExclusive,
      );
      await _cacheDayEntries(days: freshDays);
      for (final day in freshDays) {
        daysByKey[localDayKey(day.day)] = day;
      }
    }

    final days = <DiaryHealthActivityTrendDay>[];
    for (
      var day = startInclusive;
      day.isBefore(endExclusive);
      day = nextLocalDay(day)
    ) {
      final cachedDay = daysByKey[localDayKey(day)];
      if (cachedDay == null) {
        throw StateError('Missing activity trend day after Health refresh.');
      }
      days.add(cachedDay);
    }

    await _cacheRangeDays(
      cacheKey: cacheKey,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
      days: days,
    );
    return List<DiaryHealthActivityTrendDay>.unmodifiable(days);
  }

  List<DiaryHealthActivityTrendDay> _resolveCacheableDays({
    required DateTime startInclusive,
    required List<DiaryHealthActivityTrendDay> freshDays,
    required List<DiaryHealthActivityTrendDay>? staleDays,
  }) {
    if (staleDays == null ||
        !isEmptyDiaryHealthActivityTrendDays(freshDays) ||
        isEmptyDiaryHealthActivityTrendDays(staleDays)) {
      return freshDays;
    }
    log(
      'Kept stale activity trend after empty Health Connect read. '
      'start=${startInclusive.toIso8601String()}',
      name: diaryHealthLogName,
    );
    return staleDays;
  }

  Future<void> _cacheRangeDays({
    required String cacheKey,
    required DateTime startInclusive,
    required DateTime endExclusive,
    required List<DiaryHealthActivityTrendDay> days,
  }) async {
    final loadedAt = _now();
    final cachedDays = List<DiaryHealthActivityTrendDay>.unmodifiable(days);
    _cacheRangeInMemory(
      cacheKey: cacheKey,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
      loadedAt: loadedAt,
      checkedAt: loadedAt,
      days: cachedDays,
    );
    await _cacheDayEntries(loadedAt: loadedAt, days: cachedDays);
  }

  void _cacheRangeInMemory({
    required String cacheKey,
    required DateTime startInclusive,
    required DateTime endExclusive,
    required DateTime loadedAt,
    required DateTime checkedAt,
    required List<DiaryHealthActivityTrendDay> days,
  }) {
    _rangeCacheByKey[cacheKey] = DiaryHealthActivityTrendCacheEntry(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
      loadedAt: loadedAt,
      checkedAt: checkedAt,
      days: List<DiaryHealthActivityTrendDay>.unmodifiable(days),
    );
    _trimRangeCache(_now());
  }

  Future<void> _cacheDayEntries({
    required List<DiaryHealthActivityTrendDay> days,
    DateTime? loadedAt,
  }) async {
    final effectiveLoadedAt = loadedAt ?? _now();
    final persistedDays = <DiaryHealthActivityTrendDay>[];
    for (final day in days) {
      final cacheKey = localDayKey(day.day);
      final existing = _dayCacheByKey[cacheKey];
      if (isEmptyDiaryHealthActivityTrendDay(day) &&
          existing != null &&
          !isEmptyDiaryHealthActivityTrendDay(existing.day)) {
        continue;
      }
      _dayCacheByKey[cacheKey] = DiaryHealthActivityTrendDayCacheEntry(
        loadedAt: effectiveLoadedAt,
        day: day,
      );
      persistedDays.add(day);
    }
    if (persistedDays.isEmpty) {
      return;
    }
    await _cacheStore?.saveDays(
      loadedAt: effectiveLoadedAt,
      days: persistedDays,
    );
  }

  List<DiaryHealthActivityTrendDay>? _cachedRangeDays(String cacheKey) {
    final cacheEntry = _rangeCacheByKey[cacheKey];
    if (cacheEntry == null) {
      return null;
    }
    final now = _now();
    if (_isTooStaleRangeEntry(cacheEntry, now)) {
      _rangeCacheByKey.remove(cacheKey);
      return null;
    }
    if (_isExpiredRangeEntry(cacheEntry, now)) {
      return null;
    }
    return cacheEntry.days;
  }

  Future<_ActivityTrendCacheRange> _readCachedRangeDays({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    final cachedDays = <DiaryHealthActivityTrendDay>[];
    final missingDays = <DateTime>[];
    var hasExpiredDays = false;
    DateTime? oldestLoadedAt;

    for (
      var day = startInclusive;
      day.isBefore(endExclusive);
      day = nextLocalDay(day)
    ) {
      final entry = await readCachedDay(day);
      if (entry == null) {
        missingDays.add(day);
        continue;
      }
      cachedDays.add(entry.day);
      final loadedAt = entry.loadedAt;
      if (oldestLoadedAt == null || loadedAt.isBefore(oldestLoadedAt)) {
        oldestLoadedAt = loadedAt;
      }
      if (_isExpiredDayEntry(entry, _now())) {
        hasExpiredDays = true;
      }
    }

    return _ActivityTrendCacheRange(
      cachedDays: List<DiaryHealthActivityTrendDay>.unmodifiable(cachedDays),
      missingRanges: _buildMissingDayRanges(missingDays),
      hasExpiredDays: hasExpiredDays,
      oldestLoadedAt: oldestLoadedAt,
    );
  }

  List<_LocalDayRange> _buildMissingDayRanges(List<DateTime> missingDays) {
    if (missingDays.isEmpty) {
      return const <_LocalDayRange>[];
    }
    final ranges = <_LocalDayRange>[];
    var start = missingDays.first;
    var previous = start;

    for (final day in missingDays.skip(1)) {
      if (isSameLocalDay(day, nextLocalDay(previous))) {
        previous = day;
        continue;
      }
      ranges.add(_LocalDayRange(start, nextLocalDay(previous)));
      start = day;
      previous = day;
    }
    ranges.add(_LocalDayRange(start, nextLocalDay(previous)));
    return List<_LocalDayRange>.unmodifiable(ranges);
  }

  void _refreshRangeInBackground({
    required String cacheKey,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    if (_backgroundRefreshKeys.contains(cacheKey) ||
        _inFlightByKey.containsKey(cacheKey)) {
      return;
    }
    _backgroundRefreshKeys.add(cacheKey);
    final future =
        _loadAndCacheRangeDays(
              cacheKey: cacheKey,
              startInclusive: startInclusive,
              endExclusive: endExclusive,
            )
            .catchError((Object error, StackTrace stackTrace) {
              log(
                'Failed to refresh cached diary health activity trend '
                'in background. start=${startInclusive.toIso8601String()} '
                'end=${endExclusive.toIso8601String()}',
                name: diaryHealthLogName,
                error: error,
                stackTrace: stackTrace,
              );
              return _rangeCacheByKey[cacheKey]?.days ??
                  const <DiaryHealthActivityTrendDay>[];
            })
            .whenComplete(() {
              _backgroundRefreshKeys.remove(cacheKey);
            });
    unawaited(future);
  }

  bool _removeInFlight(String cacheKey) {
    return _inFlightByKey.remove(cacheKey) != null;
  }

  List<DiaryHealthActivityTrendDay>? _usableStaleRangeDays(
    DiaryHealthActivityTrendCacheEntry? entry,
    DateTime now,
  ) {
    if (entry == null || _isTooStaleRangeEntry(entry, now)) {
      return null;
    }
    return entry.days;
  }

  void _touchStaleRange(String cacheKey) {
    final entry = _rangeCacheByKey[cacheKey];
    if (entry == null) {
      return;
    }
    _rangeCacheByKey[cacheKey] = DiaryHealthActivityTrendCacheEntry(
      startInclusive: entry.startInclusive,
      endExclusive: entry.endExclusive,
      loadedAt: entry.loadedAt,
      checkedAt: _now(),
      days: entry.days,
    );
  }

  bool _isExpiredRangeEntry(
    DiaryHealthActivityTrendCacheEntry entry,
    DateTime now,
  ) {
    return now.difference(entry.checkedAt) >
        cacheTtlForActivityTrend(
          endExclusive: entry.endExclusive,
          now: now,
          todayCacheTtl: _todayCacheTtl,
          historicalCacheTtl: _historicalCacheTtl,
        );
  }

  bool _isTooStaleRangeEntry(
    DiaryHealthActivityTrendCacheEntry entry,
    DateTime now,
  ) {
    return now.difference(entry.loadedAt) > diaryHealthMaxStaleCacheAge;
  }

  bool _isExpiredDayEntry(
    DiaryHealthActivityTrendDayCacheEntry entry,
    DateTime now,
  ) {
    return now.difference(entry.loadedAt) >
        cacheTtlForDiaryHealthDay(
          dayStart: entry.day.day,
          now: now,
          todayCacheTtl: _todayCacheTtl,
          historicalCacheTtl: _historicalCacheTtl,
        );
  }

  bool _isTooStaleDayEntry(
    DiaryHealthActivityTrendDayCacheEntry entry,
    DateTime now,
  ) {
    return now.difference(entry.loadedAt) > diaryHealthMaxStaleCacheAge;
  }

  void _trimRangeCache(DateTime now) {
    _rangeCacheByKey.removeWhere(
      (_, entry) => _isTooStaleRangeEntry(entry, now),
    );
    if (_rangeCacheByKey.length <= maxActivityTrendCacheEntries) {
      return;
    }

    final entriesByAge =
        _rangeCacheByKey.entries.toList(
          growable: false,
        )..sort(
          (left, right) => left.value.loadedAt.compareTo(
            right.value.loadedAt,
          ),
        );
    final entriesToRemove =
        _rangeCacheByKey.length - maxActivityTrendCacheEntries;
    for (final entry in entriesByAge.take(entriesToRemove)) {
      _rangeCacheByKey.remove(entry.key);
    }
  }

  String _rangeCacheKey({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    return '${startInclusive.millisecondsSinceEpoch}:'
        '${endExclusive.millisecondsSinceEpoch}';
  }
}

class _LocalDayRange {
  const _LocalDayRange(this.startInclusive, this.endExclusive);

  final DateTime startInclusive;
  final DateTime endExclusive;
}

class _ActivityTrendCacheRange {
  const _ActivityTrendCacheRange({
    required this.cachedDays,
    required this.missingRanges,
    required this.hasExpiredDays,
    required this.oldestLoadedAt,
  });

  final List<DiaryHealthActivityTrendDay> cachedDays;
  final List<_LocalDayRange> missingRanges;
  final bool hasExpiredDays;
  final DateTime? oldestLoadedAt;

  bool get hasCachedDays => cachedDays.isNotEmpty;

  List<DiaryHealthActivityTrendDay> get days => cachedDays;

  bool get isComplete => missingRanges.isEmpty;
}
