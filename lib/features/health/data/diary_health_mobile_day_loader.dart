import 'dart:async';
import 'dart:developer' show log;

import 'package:yamt/features/health/data/diary_health_day_cache_store.dart';
import 'package:yamt/features/health/data/diary_health_mobile_activity_trend_loader.dart';
import 'package:yamt/features/health/data/diary_health_mobile_cache_helpers.dart';
import 'package:yamt/features/health/data/diary_health_mobile_config.dart';
import 'package:yamt/features/health/data/diary_health_mobile_health_reader.dart';
import 'package:yamt/features/health/data/diary_health_service_cache_entry.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_energy_segment.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';

/// Loads and caches derived diary health day data for mobile Health.
class DiaryHealthMobileDayLoader {
  /// Creates a mobile diary health day loader.
  DiaryHealthMobileDayLoader({
    required DiaryHealthMobileHealthReader healthReader,
    required DiaryHealthMobileActivityTrendLoader activityTrendLoader,
    required DateTime Function() now,
    required Duration todayCacheTtl,
    required Duration historicalCacheTtl,
    DiaryHealthDayCacheStore? cacheStore,
  }) : _healthReader = healthReader,
       _activityTrendLoader = activityTrendLoader,
       _now = now,
       _todayCacheTtl = todayCacheTtl,
       _historicalCacheTtl = historicalCacheTtl,
       _cacheStore = cacheStore;

  final DiaryHealthMobileHealthReader _healthReader;
  final DiaryHealthMobileActivityTrendLoader _activityTrendLoader;
  final DateTime Function() _now;
  final Duration _todayCacheTtl;
  final Duration _historicalCacheTtl;
  final DiaryHealthDayCacheStore? _cacheStore;

  final Map<String, DiaryHealthDayCacheEntry> _cacheByKey =
      <String, DiaryHealthDayCacheEntry>{};
  final Map<String, Future<DiaryHealthDayData>> _inFlightByKey =
      <String, Future<DiaryHealthDayData>>{};
  final Set<String> _backgroundRefreshKeys = <String>{};

  /// Loads derived day data for one diary day.
  Future<DiaryHealthDayData> loadDayData({
    required DateTime day,
    double? userHeightCm,
  }) async {
    final normalizedUserHeightCm = normalizeDiaryHealthUserHeightCm(
      userHeightCm,
    );
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final cacheKey = _cacheKey(
      dayStart: dayStart,
      normalizedUserHeightCm: normalizedUserHeightCm,
    );
    final cachedEntry = await _readCachedEntry(
      cacheKey: cacheKey,
      dayStart: dayStart,
      dayEnd: dayEnd,
      normalizedUserHeightCm: normalizedUserHeightCm,
    );
    if (cachedEntry != null) {
      _logCachedDayData(dayStart: dayStart, data: cachedEntry.data);
      return cachedEntry.data;
    }

    final pendingData = _inFlightByKey[cacheKey];
    if (pendingData != null) {
      return pendingData;
    }

    final future = _loadAndCacheDayData(
      cacheKey: cacheKey,
      dayStart: dayStart,
      dayEnd: dayEnd,
      normalizedUserHeightCm: normalizedUserHeightCm,
    ).whenComplete(() => _removeInFlight(cacheKey));
    _inFlightByKey[cacheKey] = future;
    return future;
  }

  Future<DiaryHealthDayData> _loadAndCacheDayData({
    required String cacheKey,
    required DateTime dayStart,
    required DateTime dayEnd,
    required double? normalizedUserHeightCm,
  }) async {
    final staleEntry = _cacheByKey[cacheKey];
    final staleData = _usableStaleDayData(staleEntry, _now());
    try {
      final freshData = await _healthReader.loadDayData(
        dayStart: dayStart,
        dayEnd: dayEnd,
        normalizedUserHeightCm: normalizedUserHeightCm,
      );
      final data = _resolveCacheableDayData(
        dayStart: dayStart,
        freshData: freshData,
        staleData: staleData,
      );
      if (identical(data, staleData)) {
        _touchStaleDayDataCacheEntry(cacheKey);
        return data;
      }
      if (isEmptyDiaryHealthDayData(data)) {
        final trendFallback = await _fallbackDayDataFromTrendCache(dayStart);
        if (trendFallback != null) {
          log(
            'Used trend cache after empty Health day read. '
            'day=${dayStart.toIso8601String()}',
            name: diaryHealthLogName,
          );
          return trendFallback;
        }
        log(
          'Skipped caching empty Health day read. '
          'day=${dayStart.toIso8601String()}',
          name: diaryHealthLogName,
        );
        return data;
      }
      await _cacheDayData(cacheKey: cacheKey, dayStart: dayStart, data: data);
      return data;
    } on Object catch (error, stackTrace) {
      if (staleData != null) {
        log(
          'Kept stale day data after Health Connect read failed. '
          'day=${dayStart.toIso8601String()}',
          name: diaryHealthLogName,
          error: error,
          stackTrace: stackTrace,
        );
        _touchStaleDayDataCacheEntry(cacheKey);
        return staleData;
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  DiaryHealthDayData _resolveCacheableDayData({
    required DateTime dayStart,
    required DiaryHealthDayData freshData,
    required DiaryHealthDayData? staleData,
  }) {
    if (staleData == null ||
        !isEmptyDiaryHealthDayData(freshData) ||
        isEmptyDiaryHealthDayData(staleData)) {
      return freshData;
    }
    log(
      'Kept stale day data after empty Health Connect read. '
      'day=${dayStart.toIso8601String()}',
      name: diaryHealthLogName,
    );
    return staleData;
  }

  Future<void> _cacheDayData({
    required String cacheKey,
    required DateTime dayStart,
    required DiaryHealthDayData data,
  }) async {
    final loadedAt = _now();
    _cacheByKey[cacheKey] = DiaryHealthDayCacheEntry(
      dayStart: dayStart,
      loadedAt: loadedAt,
      checkedAt: loadedAt,
      data: data,
    );
    _trimDayDataCache(loadedAt);
    await _cacheStore?.save(
      cacheKey: cacheKey,
      dayStart: dayStart,
      loadedAt: loadedAt,
      data: data,
    );
  }

  Future<DiaryHealthDayData?> _fallbackDayDataFromTrendCache(
    DateTime dayStart,
  ) async {
    final trendEntry = await _activityTrendLoader.readCachedDay(dayStart);
    final trendDay = trendEntry?.day;
    if (trendDay == null ||
        (trendDay.totalSteps <= 0 && trendDay.activeEnergyKcal <= 0)) {
      return null;
    }
    return DiaryHealthDayData(
      totalSteps: trendDay.totalSteps,
      workouts: const <HealthWorkoutSession>[],
    );
  }

  void _logCachedDayData({
    required DateTime dayStart,
    required DiaryHealthDayData data,
  }) {
    log(
      'Read day data from cache. '
      'day=${dayStart.toIso8601String()} '
      'steps=${data.totalSteps} '
      'workouts=${data.workouts.length} '
      'workout_kcal=${_sumWorkoutCalories(data.workouts)} '
      'unassigned_active_energy_kcal='
      '${_sumUnassignedActiveEnergyCalories(
        data.unassignedActiveEnergySegments,
      )} '
      'workout_steps=${_sumWorkoutSteps(data.workouts)}',
      name: diaryHealthLogName,
    );
  }

  int _sumWorkoutCalories(List<HealthWorkoutSession> workouts) {
    return workouts.fold<int>(
      0,
      (sum, workout) => sum + (workout.totalCalories ?? 0),
    );
  }

  int _sumWorkoutSteps(List<HealthWorkoutSession> workouts) {
    return workouts.fold<int>(
      0,
      (sum, workout) => sum + (workout.totalSteps ?? 0),
    );
  }

  int _sumUnassignedActiveEnergyCalories(List<HealthEnergySegment> segments) {
    return segments.fold<int>(
      0,
      (sum, segment) => sum + segment.totalCalories,
    );
  }

  Future<DiaryHealthDayCacheEntry?> _readCachedEntry({
    required String cacheKey,
    required DateTime dayStart,
    required DateTime dayEnd,
    required double? normalizedUserHeightCm,
  }) async {
    final cacheEntry = _cacheByKey[cacheKey];
    final now = _now();
    if (cacheEntry != null) {
      if (_isTooStaleDayCacheEntry(cacheEntry, now)) {
        _cacheByKey.remove(cacheKey);
      } else {
        if (_isExpiredCacheEntry(cacheEntry, now)) {
          _refreshDayDataInBackground(
            cacheKey: cacheKey,
            dayStart: dayStart,
            dayEnd: dayEnd,
            normalizedUserHeightCm: normalizedUserHeightCm,
          );
        }
        return cacheEntry;
      }
    }

    final persistentEntry = await _readPersistentEntry(cacheKey);
    if (persistentEntry == null) {
      return null;
    }
    _cacheByKey[cacheKey] = persistentEntry;
    if (_isExpiredCacheEntry(persistentEntry, now)) {
      _refreshDayDataInBackground(
        cacheKey: cacheKey,
        dayStart: dayStart,
        dayEnd: dayEnd,
        normalizedUserHeightCm: normalizedUserHeightCm,
      );
    }
    return persistentEntry;
  }

  Future<DiaryHealthDayCacheEntry?> _readPersistentEntry(
    String cacheKey,
  ) async {
    final snapshot = await _cacheStore?.read(
      cacheKey: cacheKey,
      now: _now(),
      maxStaleAge: diaryHealthMaxStaleCacheAge,
    );
    if (snapshot == null) {
      return null;
    }
    final data = snapshot.toDomain();
    if (isEmptyDiaryHealthDayData(data)) {
      return null;
    }
    return DiaryHealthDayCacheEntry(
      dayStart: snapshot.dayStart,
      loadedAt: snapshot.loadedAt,
      checkedAt: snapshot.loadedAt,
      data: data,
    );
  }

  void _refreshDayDataInBackground({
    required String cacheKey,
    required DateTime dayStart,
    required DateTime dayEnd,
    required double? normalizedUserHeightCm,
  }) {
    if (_backgroundRefreshKeys.contains(cacheKey) ||
        _inFlightByKey.containsKey(cacheKey)) {
      return;
    }
    _backgroundRefreshKeys.add(cacheKey);
    final future =
        _loadAndCacheDayData(
              cacheKey: cacheKey,
              dayStart: dayStart,
              dayEnd: dayEnd,
              normalizedUserHeightCm: normalizedUserHeightCm,
            )
            .catchError((Object error, StackTrace stackTrace) {
              log(
                'Failed to refresh cached diary health day in background. '
                'day=${dayStart.toIso8601String()}',
                name: diaryHealthLogName,
                error: error,
                stackTrace: stackTrace,
              );
              final staleData = _cacheByKey[cacheKey]?.data;
              return staleData ??
                  const DiaryHealthDayData(
                    totalSteps: 0,
                    workouts: <HealthWorkoutSession>[],
                  );
            })
            .whenComplete(() {
              _backgroundRefreshKeys.remove(cacheKey);
            });
    unawaited(future);
  }

  bool _removeInFlight(String cacheKey) {
    return _inFlightByKey.remove(cacheKey) != null;
  }

  bool _isExpiredCacheEntry(DiaryHealthDayCacheEntry entry, DateTime now) {
    return now.difference(entry.checkedAt) >
        cacheTtlForDiaryHealthDay(
          dayStart: entry.dayStart,
          now: now,
          todayCacheTtl: _todayCacheTtl,
          historicalCacheTtl: _historicalCacheTtl,
        );
  }

  bool _isTooStaleDayCacheEntry(
    DiaryHealthDayCacheEntry entry,
    DateTime now,
  ) {
    return now.difference(entry.loadedAt) > diaryHealthMaxStaleCacheAge;
  }

  DiaryHealthDayData? _usableStaleDayData(
    DiaryHealthDayCacheEntry? entry,
    DateTime now,
  ) {
    if (entry == null || _isTooStaleDayCacheEntry(entry, now)) {
      return null;
    }
    return entry.data;
  }

  void _touchStaleDayDataCacheEntry(String cacheKey) {
    final entry = _cacheByKey[cacheKey];
    if (entry == null) {
      return;
    }
    _cacheByKey[cacheKey] = DiaryHealthDayCacheEntry(
      dayStart: entry.dayStart,
      loadedAt: entry.loadedAt,
      checkedAt: _now(),
      data: entry.data,
    );
  }

  void _trimDayDataCache(DateTime now) {
    _cacheByKey.removeWhere(
      (_, entry) => _isTooStaleDayCacheEntry(entry, now),
    );
    if (_cacheByKey.length <= maxDiaryHealthCacheEntries) {
      return;
    }

    final entriesByAge = _cacheByKey.entries.toList(growable: false)
      ..sort(
        (left, right) => left.value.loadedAt.compareTo(
          right.value.loadedAt,
        ),
      );
    final entriesToRemove = _cacheByKey.length - maxDiaryHealthCacheEntries;
    for (final entry in entriesByAge.take(entriesToRemove)) {
      _cacheByKey.remove(entry.key);
    }
  }

  String _cacheKey({
    required DateTime dayStart,
    required double? normalizedUserHeightCm,
  }) {
    final heightKey = normalizedUserHeightCm?.toStringAsFixed(2) ?? 'default';
    return '${dayStart.millisecondsSinceEpoch}:$heightKey';
  }
}
