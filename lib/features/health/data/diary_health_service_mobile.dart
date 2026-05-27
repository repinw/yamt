import 'dart:async';
import 'dart:developer' show log;

import 'package:health/health.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/health/data/diary_health_activity_trend_day_cache_store.dart';
import 'package:yamt/features/health/data/diary_health_day_cache_store.dart';
import 'package:yamt/features/health/data/diary_health_read_queue.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/data/diary_health_service_cache_entry.dart';
import 'package:yamt/features/health/domain/diary_health_activity_trend_day.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_energy_segment.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';

const _logName = 'DiaryHealthService';
const _workoutQueryTypes = <HealthDataType>[HealthDataType.WORKOUT];
const _activeEnergyQueryTypes = <HealthDataType>[
  HealthDataType.ACTIVE_ENERGY_BURNED,
];
const _activityTrendQueryTypes = <HealthDataType>[
  HealthDataType.STEPS,
  HealthDataType.ACTIVE_ENERGY_BURNED,
];
const int _activityTrendIntervalSeconds = Duration.secondsPerDay;
const _diaryHealthTodayCacheTtl = Duration(minutes: 5);
const _diaryHealthHistoricalCacheTtl = Duration(hours: 12);
const _diaryHealthMaxStaleCacheAge = Duration(days: 7);
const _maxDiaryHealthCacheEntries = 30;
const _maxActivityTrendCacheEntries = 30;
const _defaultCalculatorProfileHeightCm = 180.0;
const _minPersonalizedHeightCm = 120.0;
const _maxPersonalizedHeightCm = 250.0;
const _minimumUnassignedActivityKcalPerMinute = 3.0;
const _stepBasedWorkoutTypes = <HealthWorkoutActivityType>{
  HealthWorkoutActivityType.HIKING,
  HealthWorkoutActivityType.RUNNING,
  HealthWorkoutActivityType.RUNNING_TREADMILL,
  HealthWorkoutActivityType.STAIRS,
  HealthWorkoutActivityType.STAIR_CLIMBING,
  HealthWorkoutActivityType.STAIR_CLIMBING_MACHINE,
  HealthWorkoutActivityType.STEP_TRAINING,
  HealthWorkoutActivityType.TRACK_AND_FIELD,
  HealthWorkoutActivityType.WALKING,
  HealthWorkoutActivityType.WALKING_TREADMILL,
  HealthWorkoutActivityType.WHEELCHAIR_RUN_PACE,
  HealthWorkoutActivityType.WHEELCHAIR_WALK_PACE,
};

/// Create diary health service.
DiaryHealthService createDiaryHealthService({AppPreferences? preferences}) {
  return MobileDiaryHealthService(preferences: preferences);
}

/// Defines mobile diary health service.
class MobileDiaryHealthService
    implements DiaryHealthService, DiaryHealthActivityTrendService {
  /// Creates an instance.
  MobileDiaryHealthService({
    Health? health,
    AppPreferences? preferences,
    DateTime Function()? now,
    Duration cacheTtl = _diaryHealthTodayCacheTtl,
    Duration historicalCacheTtl = _diaryHealthHistoricalCacheTtl,
  }) : _health = health ?? Health(),
       _dayCacheStore = preferences == null
           ? null
           : DiaryHealthDayCacheStore(
               preferences: preferences,
               maxEntries: _maxDiaryHealthCacheEntries,
             ),
       _activityTrendDayCacheStore = preferences == null
           ? null
           : DiaryHealthActivityTrendDayCacheStore(
               preferences: preferences,
               maxEntries: _maxActivityTrendCacheEntries,
             ),
       _now = now ?? DateTime.now,
       _todayCacheTtl = cacheTtl,
       _historicalCacheTtl = historicalCacheTtl;

  final Health _health;
  final DiaryHealthDayCacheStore? _dayCacheStore;
  final DiaryHealthActivityTrendDayCacheStore? _activityTrendDayCacheStore;
  final DateTime Function() _now;
  final Duration _todayCacheTtl;
  final Duration _historicalCacheTtl;
  final DiaryHealthReadQueue _readQueue = DiaryHealthReadQueue();
  bool _isConfigured = false;
  final Map<String, DiaryHealthDayCacheEntry> _cacheByKey =
      <String, DiaryHealthDayCacheEntry>{};
  final Map<String, Future<DiaryHealthDayData>> _inFlightByKey =
      <String, Future<DiaryHealthDayData>>{};
  final Set<String> _backgroundRefreshKeys = <String>{};
  final Map<String, DiaryHealthActivityTrendCacheEntry>
  _activityTrendCacheByKey = <String, DiaryHealthActivityTrendCacheEntry>{};
  final Map<String, DiaryHealthActivityTrendDayCacheEntry>
  _activityTrendDayCacheByKey =
      <String, DiaryHealthActivityTrendDayCacheEntry>{};
  final Map<String, Future<List<DiaryHealthActivityTrendDay>>>
  _activityTrendInFlightByKey =
      <String, Future<List<DiaryHealthActivityTrendDay>>>{};
  final Set<String> _activityTrendBackgroundRefreshKeys = <String>{};

  @override
  Future<DiaryHealthDayData> loadDayData({
    required DateTime day,
    double? userHeightCm,
  }) async {
    final normalizedUserHeightCm = _normalizeUserHeightCm(userHeightCm);
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final cacheKey = _cacheKey(
      dayStart: dayStart,
      normalizedUserHeightCm: normalizedUserHeightCm,
    );
    final cachedEntry = await _readCachedDayDataEntry(
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
    ).whenComplete(() => _removeInFlightDayData(cacheKey));
    _inFlightByKey[cacheKey] = future;
    return future;
  }

  @override
  Future<List<DiaryHealthActivityTrendDay>> loadActivityTrendDays({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    final start = normalizeLocalDay(startInclusive);
    final end = normalizeLocalDay(endExclusive);
    if (!start.isBefore(end)) {
      return const <DiaryHealthActivityTrendDay>[];
    }

    final cacheKey = _activityTrendCacheKey(
      startInclusive: start,
      endExclusive: end,
    );
    final cachedDays = _cachedActivityTrendDays(cacheKey);
    if (cachedDays != null) {
      return cachedDays;
    }
    final cachedRange = await _readCachedActivityTrendDays(
      startInclusive: start,
      endExclusive: end,
    );
    if (cachedRange.isComplete) {
      if (cachedRange.hasExpiredDays) {
        final loadedAt = cachedRange.oldestLoadedAt ?? _now();
        _cacheActivityTrendDaysInMemory(
          cacheKey: cacheKey,
          startInclusive: start,
          endExclusive: end,
          loadedAt: loadedAt,
          checkedAt: loadedAt,
          days: cachedRange.days,
        );
        _refreshActivityTrendDaysInBackground(
          cacheKey: cacheKey,
          startInclusive: start,
          endExclusive: end,
        );
      }
      return cachedRange.days;
    }
    final pendingDays = _activityTrendInFlightByKey[cacheKey];
    if (pendingDays != null) {
      return pendingDays;
    }
    final refreshedPendingDays = _activityTrendInFlightByKey[cacheKey];
    if (refreshedPendingDays != null) {
      return refreshedPendingDays;
    }
    final future =
        _loadAndCacheActivityTrendDays(
          cacheKey: cacheKey,
          startInclusive: start,
          endExclusive: end,
          cachedRange: cachedRange,
        ).whenComplete(
          () => _removeInFlightActivityTrendDays(cacheKey),
        );
    _activityTrendInFlightByKey[cacheKey] = future;
    return future;
  }

  Future<List<DiaryHealthActivityTrendDay>> _loadAndCacheActivityTrendDays({
    required String cacheKey,
    required DateTime startInclusive,
    required DateTime endExclusive,
    _ActivityTrendCacheRange? cachedRange,
  }) async {
    if (cachedRange != null &&
        cachedRange.hasCachedDays &&
        cachedRange.missingRanges.isNotEmpty) {
      return _loadAndCacheMissingActivityTrendDays(
        cacheKey: cacheKey,
        startInclusive: startInclusive,
        endExclusive: endExclusive,
        cachedRange: cachedRange,
      );
    }
    final staleEntry = _activityTrendCacheByKey[cacheKey];
    final staleDays = _usableStaleActivityTrendDays(staleEntry, _now());
    try {
      final freshDays = await _readActivityTrendDaysFromHealth(
        startInclusive: startInclusive,
        endExclusive: endExclusive,
      );
      final days = _resolveCacheableActivityTrendDays(
        startInclusive: startInclusive,
        freshDays: freshDays,
        staleDays: staleDays,
      );
      if (identical(days, staleDays)) {
        _touchStaleActivityTrendCacheEntry(cacheKey);
        return days;
      }
      await _cacheActivityTrendDays(
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
          name: _logName,
          error: error,
          stackTrace: stackTrace,
        );
        _touchStaleActivityTrendCacheEntry(cacheKey);
        return staleDays;
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<List<DiaryHealthActivityTrendDay>>
  _loadAndCacheMissingActivityTrendDays({
    required String cacheKey,
    required DateTime startInclusive,
    required DateTime endExclusive,
    required _ActivityTrendCacheRange cachedRange,
  }) async {
    final daysByKey = <String, DiaryHealthActivityTrendDay>{
      for (final day in cachedRange.cachedDays) localDayKey(day.day): day,
    };

    for (final range in cachedRange.missingRanges) {
      final freshDays = await _readActivityTrendDaysFromHealth(
        startInclusive: range.startInclusive,
        endExclusive: range.endExclusive,
      );
      await _cacheActivityTrendDayEntries(days: freshDays);
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

    await _cacheActivityTrendDays(
      cacheKey: cacheKey,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
      days: days,
    );
    return List<DiaryHealthActivityTrendDay>.unmodifiable(days);
  }

  Future<List<DiaryHealthActivityTrendDay>> _readActivityTrendDaysFromHealth({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    return _readQueue.run(() async {
      await _ensureConfigured();
      final points = await _health.getHealthIntervalDataFromTypes(
        startDate: startInclusive,
        endDate: endExclusive,
        types: _activityTrendQueryTypes,
        interval: _activityTrendIntervalSeconds,
      );
      return _buildActivityTrendDays(
        startInclusive: startInclusive,
        endExclusive: endExclusive,
        points: points,
      );
    });
  }

  List<DiaryHealthActivityTrendDay> _resolveCacheableActivityTrendDays({
    required DateTime startInclusive,
    required List<DiaryHealthActivityTrendDay> freshDays,
    required List<DiaryHealthActivityTrendDay>? staleDays,
  }) {
    if (staleDays == null ||
        !_isEmptyActivityTrendDays(freshDays) ||
        _isEmptyActivityTrendDays(staleDays)) {
      return freshDays;
    }
    log(
      'Kept stale activity trend after empty Health Connect read. '
      'start=${startInclusive.toIso8601String()}',
      name: _logName,
    );
    return staleDays;
  }

  Future<void> _cacheActivityTrendDays({
    required String cacheKey,
    required DateTime startInclusive,
    required DateTime endExclusive,
    required List<DiaryHealthActivityTrendDay> days,
  }) async {
    final loadedAt = _now();
    final cachedDays = List<DiaryHealthActivityTrendDay>.unmodifiable(days);
    _cacheActivityTrendDaysInMemory(
      cacheKey: cacheKey,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
      loadedAt: loadedAt,
      checkedAt: loadedAt,
      days: cachedDays,
    );
    await _cacheActivityTrendDayEntries(
      loadedAt: loadedAt,
      days: cachedDays,
    );
  }

  void _cacheActivityTrendDaysInMemory({
    required String cacheKey,
    required DateTime startInclusive,
    required DateTime endExclusive,
    required DateTime loadedAt,
    required DateTime checkedAt,
    required List<DiaryHealthActivityTrendDay> days,
  }) {
    _activityTrendCacheByKey[cacheKey] = DiaryHealthActivityTrendCacheEntry(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
      loadedAt: loadedAt,
      checkedAt: checkedAt,
      days: List<DiaryHealthActivityTrendDay>.unmodifiable(days),
    );
    _trimActivityTrendCache(_now());
  }

  Future<void> _cacheActivityTrendDayEntries({
    required List<DiaryHealthActivityTrendDay> days,
    DateTime? loadedAt,
  }) async {
    final effectiveLoadedAt = loadedAt ?? _now();
    final persistedDays = <DiaryHealthActivityTrendDay>[];
    for (final day in days) {
      final cacheKey = localDayKey(day.day);
      final existing = _activityTrendDayCacheByKey[cacheKey];
      if (_isEmptyActivityTrendDay(day) &&
          existing != null &&
          !_isEmptyActivityTrendDay(existing.day)) {
        continue;
      }
      _activityTrendDayCacheByKey[cacheKey] =
          DiaryHealthActivityTrendDayCacheEntry(
            loadedAt: effectiveLoadedAt,
            day: day,
          );
      persistedDays.add(day);
    }
    if (persistedDays.isEmpty) {
      return;
    }
    await _activityTrendDayCacheStore?.saveDays(
      loadedAt: effectiveLoadedAt,
      days: persistedDays,
    );
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
      final freshData = await _readQueue.run(
        () => _loadConfiguredDayDataFromHealth(
          dayStart: dayStart,
          dayEnd: dayEnd,
          normalizedUserHeightCm: normalizedUserHeightCm,
        ),
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
      if (_isEmptyDayData(data)) {
        final trendFallback = await _fallbackDayDataFromTrendCache(dayStart);
        if (trendFallback != null) {
          log(
            'Used trend cache after empty Health day read. '
            'day=${dayStart.toIso8601String()}',
            name: _logName,
          );
          return trendFallback;
        }
        log(
          'Skipped caching empty Health day read. '
          'day=${dayStart.toIso8601String()}',
          name: _logName,
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
          name: _logName,
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
        !_isEmptyDayData(freshData) ||
        _isEmptyDayData(staleData)) {
      return freshData;
    }
    log(
      'Kept stale day data after empty Health Connect read. '
      'day=${dayStart.toIso8601String()}',
      name: _logName,
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
    await _dayCacheStore?.save(
      cacheKey: cacheKey,
      dayStart: dayStart,
      loadedAt: loadedAt,
      data: data,
    );
  }

  Future<DiaryHealthDayData?> _fallbackDayDataFromTrendCache(
    DateTime dayStart,
  ) async {
    final trendEntry = await _readCachedActivityTrendDay(dayStart);
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

  Future<DiaryHealthDayData> _loadConfiguredDayDataFromHealth({
    required DateTime dayStart,
    required DateTime dayEnd,
    required double? normalizedUserHeightCm,
  }) async {
    await _ensureConfigured();
    return _loadDayDataFromHealth(
      dayStart: dayStart,
      dayEnd: dayEnd,
      normalizedUserHeightCm: normalizedUserHeightCm,
    );
  }

  Future<DiaryHealthDayData> _loadDayDataFromHealth({
    required DateTime dayStart,
    required DateTime dayEnd,
    required double? normalizedUserHeightCm,
  }) async {
    final totalSteps =
        await _health.getTotalStepsInInterval(dayStart, dayEnd) ?? 0;
    final workoutPoints = await _health.getHealthDataFromTypes(
      types: _workoutQueryTypes,
      startTime: dayStart,
      endTime: dayEnd,
    );
    final activeEnergyPoints = await _health.getHealthDataFromTypes(
      types: _activeEnergyQueryTypes,
      startTime: dayStart,
      endTime: dayEnd,
    );
    final activeEnergySamples = activeEnergyPoints
        .map(_buildActiveEnergySample)
        .whereType<HealthActiveEnergySample>()
        .toList(growable: false);
    final baseWorkouts = workoutPoints
        .map(
          (point) => _resolveWorkoutBase(
            point: point,
            userHeightCm: normalizedUserHeightCm,
          ),
        )
        .toList(growable: false);
    final resolvedWorkouts = _mergeWorkoutCaloriesWithoutDoubleCounting(
      workouts: baseWorkouts,
      activeEnergySamples: activeEnergySamples,
    );
    final unassignedActiveEnergySegments = <HealthEnergySegment>[];
    for (final point in activeEnergyPoints) {
      unassignedActiveEnergySegments.addAll(
        await _buildUnassignedActiveEnergySegments(
          point: point,
          dayStart: dayStart,
          dayEnd: dayEnd,
          workouts: resolvedWorkouts,
        ),
      );
    }
    final workouts = resolvedWorkouts.toList(growable: false)
      ..sort((left, right) => right.start.compareTo(left.start));
    final activeEnergySegments = unassignedActiveEnergySegments.toList(
      growable: false,
    )..sort((left, right) => right.start.compareTo(left.start));

    _logHealthDayData(
      dayStart: dayStart,
      totalSteps: totalSteps,
      workoutPoints: workoutPoints,
      activeEnergyPoints: activeEnergyPoints,
      workouts: workouts,
      unassignedActiveEnergySegments: activeEnergySegments,
    );

    return DiaryHealthDayData(
      totalSteps: totalSteps,
      workouts: List<HealthWorkoutSession>.unmodifiable(workouts),
      unassignedActiveEnergySegments: List<HealthEnergySegment>.unmodifiable(
        activeEnergySegments,
      ),
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
      name: _logName,
    );
  }

  void _logHealthDayData({
    required DateTime dayStart,
    required int totalSteps,
    required List<HealthDataPoint> workoutPoints,
    required List<HealthDataPoint> activeEnergyPoints,
    required List<HealthWorkoutSession> workouts,
    required List<HealthEnergySegment> unassignedActiveEnergySegments,
  }) {
    log(
      'Read day data. '
      'day=${dayStart.toIso8601String()} '
      'steps=$totalSteps '
      'workout_points=${workoutPoints.length} '
      'active_energy_points=${activeEnergyPoints.length} '
      'workouts=${workouts.length} '
      'workout_kcal=${_sumWorkoutCalories(workouts)} '
      'unassigned_active_energy_segments='
      '${unassignedActiveEnergySegments.length} '
      'unassigned_active_energy_kcal='
      '${_sumUnassignedActiveEnergyCalories(unassignedActiveEnergySegments)} '
      'workout_steps=${_sumWorkoutSteps(workouts)} '
      'workout_sources=${_sourceNames(workoutPoints)} '
      'active_energy_sources=${_sourceNames(activeEnergyPoints)}',
      name: _logName,
    );
    if (totalSteps > 0 && workoutPoints.isEmpty && activeEnergyPoints.isEmpty) {
      log(
        'Read day data has steps only. '
        'day=${dayStart.toIso8601String()} '
        'Health Connect returned no workouts or active energy.',
        name: _logName,
      );
    }
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

  String _sourceNames(List<HealthDataPoint> points) {
    final sourceNames =
        points
            .map((point) => point.sourceName)
            .where((sourceName) => sourceName.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return sourceNames.isEmpty ? '[]' : sourceNames.join(',');
  }

  String _cacheKey({
    required DateTime dayStart,
    required double? normalizedUserHeightCm,
  }) {
    final heightKey = normalizedUserHeightCm?.toStringAsFixed(2) ?? 'default';
    return '${dayStart.millisecondsSinceEpoch}:$heightKey';
  }

  String _activityTrendCacheKey({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    return '${startInclusive.millisecondsSinceEpoch}:'
        '${endExclusive.millisecondsSinceEpoch}';
  }

  Future<DiaryHealthDayCacheEntry?> _readCachedDayDataEntry({
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

    final persistentEntry = await _readPersistentDayCacheEntry(cacheKey);
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

  Future<DiaryHealthDayCacheEntry?> _readPersistentDayCacheEntry(
    String cacheKey,
  ) async {
    final snapshot = await _dayCacheStore?.read(
      cacheKey: cacheKey,
      now: _now(),
      maxStaleAge: _diaryHealthMaxStaleCacheAge,
    );
    if (snapshot == null) {
      return null;
    }
    final data = snapshot.toDomain();
    if (_isEmptyDayData(data)) {
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
                name: _logName,
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

  List<DiaryHealthActivityTrendDay>? _cachedActivityTrendDays(
    String cacheKey,
  ) {
    final cacheEntry = _activityTrendCacheByKey[cacheKey];
    if (cacheEntry == null) {
      return null;
    }
    final now = _now();
    if (_isTooStaleActivityTrendCacheEntry(cacheEntry, now)) {
      _activityTrendCacheByKey.remove(cacheKey);
      return null;
    }
    if (_isExpiredActivityTrendCacheEntry(cacheEntry, now)) {
      return null;
    }
    return cacheEntry.days;
  }

  Future<_ActivityTrendCacheRange> _readCachedActivityTrendDays({
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
      final entry = await _readCachedActivityTrendDay(day);
      if (entry == null) {
        missingDays.add(day);
        continue;
      }
      cachedDays.add(entry.day);
      final loadedAt = entry.loadedAt;
      if (oldestLoadedAt == null || loadedAt.isBefore(oldestLoadedAt)) {
        oldestLoadedAt = loadedAt;
      }
      if (_isExpiredActivityTrendDayCacheEntry(entry, _now())) {
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

  Future<DiaryHealthActivityTrendDayCacheEntry?> _readCachedActivityTrendDay(
    DateTime day,
  ) async {
    final cacheKey = localDayKey(day);
    final now = _now();
    final cacheEntry = _activityTrendDayCacheByKey[cacheKey];
    if (cacheEntry != null) {
      if (_isTooStaleActivityTrendDayCacheEntry(cacheEntry, now)) {
        _activityTrendDayCacheByKey.remove(cacheKey);
      } else {
        return cacheEntry;
      }
    }

    final persistentEntry = await _activityTrendDayCacheStore?.readDay(
      day: day,
      now: now,
      maxStaleAge: _diaryHealthMaxStaleCacheAge,
    );
    if (persistentEntry == null) {
      return null;
    }
    _activityTrendDayCacheByKey[cacheKey] = persistentEntry;
    return persistentEntry;
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

  void _refreshActivityTrendDaysInBackground({
    required String cacheKey,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    if (_activityTrendBackgroundRefreshKeys.contains(cacheKey) ||
        _activityTrendInFlightByKey.containsKey(cacheKey)) {
      return;
    }
    _activityTrendBackgroundRefreshKeys.add(cacheKey);
    final future =
        _loadAndCacheActivityTrendDays(
              cacheKey: cacheKey,
              startInclusive: startInclusive,
              endExclusive: endExclusive,
            )
            .catchError((Object error, StackTrace stackTrace) {
              log(
                'Failed to refresh cached diary health activity trend '
                'in background. start=${startInclusive.toIso8601String()} '
                'end=${endExclusive.toIso8601String()}',
                name: _logName,
                error: error,
                stackTrace: stackTrace,
              );
              return _activityTrendCacheByKey[cacheKey]?.days ??
                  const <DiaryHealthActivityTrendDay>[];
            })
            .whenComplete(() {
              _activityTrendBackgroundRefreshKeys.remove(cacheKey);
            });
    unawaited(future);
  }

  bool _removeInFlightDayData(String cacheKey) {
    return _inFlightByKey.remove(cacheKey) != null;
  }

  bool _removeInFlightActivityTrendDays(String cacheKey) {
    return _activityTrendInFlightByKey.remove(cacheKey) != null;
  }

  void _trimDayDataCache(DateTime now) {
    _cacheByKey.removeWhere(
      (_, entry) => _isTooStaleDayCacheEntry(entry, now),
    );
    if (_cacheByKey.length <= _maxDiaryHealthCacheEntries) {
      return;
    }

    final entriesByAge = _cacheByKey.entries.toList(growable: false)
      ..sort(
        (left, right) => left.value.loadedAt.compareTo(
          right.value.loadedAt,
        ),
      );
    final entriesToRemove = _cacheByKey.length - _maxDiaryHealthCacheEntries;
    for (final entry in entriesByAge.take(entriesToRemove)) {
      _cacheByKey.remove(entry.key);
    }
  }

  bool _isExpiredCacheEntry(DiaryHealthDayCacheEntry entry, DateTime now) {
    return now.difference(entry.checkedAt) >
        _cacheTtlForDay(entry.dayStart, now);
  }

  bool _isTooStaleDayCacheEntry(
    DiaryHealthDayCacheEntry entry,
    DateTime now,
  ) {
    return now.difference(entry.loadedAt) > _diaryHealthMaxStaleCacheAge;
  }

  bool _isExpiredActivityTrendCacheEntry(
    DiaryHealthActivityTrendCacheEntry entry,
    DateTime now,
  ) {
    return now.difference(entry.checkedAt) >
        _cacheTtlForActivityTrend(entry.endExclusive, now);
  }

  bool _isTooStaleActivityTrendCacheEntry(
    DiaryHealthActivityTrendCacheEntry entry,
    DateTime now,
  ) {
    return now.difference(entry.loadedAt) > _diaryHealthMaxStaleCacheAge;
  }

  bool _isExpiredActivityTrendDayCacheEntry(
    DiaryHealthActivityTrendDayCacheEntry entry,
    DateTime now,
  ) {
    return now.difference(entry.loadedAt) > _cacheTtlForDay(entry.day.day, now);
  }

  bool _isTooStaleActivityTrendDayCacheEntry(
    DiaryHealthActivityTrendDayCacheEntry entry,
    DateTime now,
  ) {
    return now.difference(entry.loadedAt) > _diaryHealthMaxStaleCacheAge;
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

  List<DiaryHealthActivityTrendDay>? _usableStaleActivityTrendDays(
    DiaryHealthActivityTrendCacheEntry? entry,
    DateTime now,
  ) {
    if (entry == null || _isTooStaleActivityTrendCacheEntry(entry, now)) {
      return null;
    }
    return entry.days;
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

  void _touchStaleActivityTrendCacheEntry(String cacheKey) {
    final entry = _activityTrendCacheByKey[cacheKey];
    if (entry == null) {
      return;
    }
    _activityTrendCacheByKey[cacheKey] = DiaryHealthActivityTrendCacheEntry(
      startInclusive: entry.startInclusive,
      endExclusive: entry.endExclusive,
      loadedAt: entry.loadedAt,
      checkedAt: _now(),
      days: entry.days,
    );
  }

  Duration _cacheTtlForDay(DateTime dayStart, DateTime now) {
    final todayStart = DateTime(now.year, now.month, now.day);
    if (dayStart.isBefore(todayStart)) {
      return _historicalCacheTtl;
    }
    return _todayCacheTtl;
  }

  Duration _cacheTtlForActivityTrend(DateTime endExclusive, DateTime now) {
    final todayStart = DateTime(now.year, now.month, now.day);
    if (!endExclusive.isAfter(todayStart)) {
      return _historicalCacheTtl;
    }
    return _todayCacheTtl;
  }

  void _trimActivityTrendCache(DateTime now) {
    _activityTrendCacheByKey.removeWhere(
      (_, entry) => _isTooStaleActivityTrendCacheEntry(entry, now),
    );
    if (_activityTrendCacheByKey.length <= _maxActivityTrendCacheEntries) {
      return;
    }

    final entriesByAge =
        _activityTrendCacheByKey.entries.toList(
          growable: false,
        )..sort(
          (left, right) => left.value.loadedAt.compareTo(
            right.value.loadedAt,
          ),
        );
    final entriesToRemove =
        _activityTrendCacheByKey.length - _maxActivityTrendCacheEntries;
    for (final entry in entriesByAge.take(entriesToRemove)) {
      _activityTrendCacheByKey.remove(entry.key);
    }
  }

  List<DiaryHealthActivityTrendDay> _buildActivityTrendDays({
    required DateTime startInclusive,
    required DateTime endExclusive,
    required List<HealthDataPoint> points,
  }) {
    final stepsByDay = <String, int>{};
    final activeEnergyByDay = <String, int>{};
    for (final point in points) {
      final value = _numericHealthValue(point)?.round();
      if (value == null || value <= 0) {
        continue;
      }
      final day = normalizeLocalDay(point.dateFrom.toLocal());
      if (day.isBefore(startInclusive) || !day.isBefore(endExclusive)) {
        continue;
      }
      final key = localDayKey(day);
      if (point.type == HealthDataType.STEPS) {
        stepsByDay[key] = (stepsByDay[key] ?? 0) + value;
      } else if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
        activeEnergyByDay[key] = (activeEnergyByDay[key] ?? 0) + value;
      }
    }

    final days = <DiaryHealthActivityTrendDay>[];
    for (
      var day = startInclusive;
      day.isBefore(endExclusive);
      day = nextLocalDay(day)
    ) {
      final key = localDayKey(day);
      days.add(
        DiaryHealthActivityTrendDay(
          day: day,
          totalSteps: stepsByDay[key] ?? 0,
          activeEnergyKcal: activeEnergyByDay[key] ?? 0,
        ),
      );
    }
    return List<DiaryHealthActivityTrendDay>.unmodifiable(days);
  }

  Future<void> _ensureConfigured() async {
    if (_isConfigured) {
      return;
    }
    await _health.configure();
    _isConfigured = true;
  }

  HealthWorkoutSession _resolveWorkoutBase({
    required HealthDataPoint point,
    required double? userHeightCm,
  }) {
    return _backfillWorkoutSteps(
      workout: _buildWorkoutSession(point),
      point: point,
      userHeightCm: userHeightCm,
    );
  }

  List<HealthWorkoutSession> _mergeWorkoutCaloriesWithoutDoubleCounting({
    required List<HealthWorkoutSession> workouts,
    required List<HealthActiveEnergySample> activeEnergySamples,
  }) {
    final allocatedIntervals = <_DateTimeInterval>[];
    final orderedWorkouts = workouts.toList(growable: false)
      ..sort(_compareWorkoutStartThenEnd);
    final resolvedWorkouts = <HealthWorkoutSession>[];

    for (final workout in orderedWorkouts) {
      final workoutInterval = _DateTimeInterval(
        workout.start,
        workout.endExclusive,
      );
      final availableIntervals = _subtractIntervals(
        intervals: <_DateTimeInterval>[workoutInterval],
        blockers: allocatedIntervals,
      );
      final visibleCalories = _activeEnergyValueForIntervals(
        samples: activeEnergySamples,
        intervals: availableIntervals,
      );
      final overlappedCalories = _activeEnergyValueForIntervals(
        samples: activeEnergySamples,
        intervals: <_DateTimeInterval>[workoutInterval],
      );

      if (visibleCalories > 0) {
        resolvedWorkouts.add(
          workout.copyWith(totalCalories: visibleCalories.round()),
        );
      } else if (overlappedCalories > 0) {
        resolvedWorkouts.add(_copyWorkoutWithTotalCalories(workout, null));
      } else {
        resolvedWorkouts.add(workout);
      }
      allocatedIntervals.add(workoutInterval);
    }

    return resolvedWorkouts;
  }

  HealthWorkoutSession _buildWorkoutSession(HealthDataPoint point) {
    final workoutValue = point.value is WorkoutHealthValue
        ? point.value as WorkoutHealthValue
        : null;
    final summarySteps = _positiveWorkoutSummarySteps(point.workoutSummary);
    return HealthWorkoutSession(
      id: point.uuid.isNotEmpty
          ? point.uuid
          : '${point.sourceId}:'
                '${point.dateFrom.toUtc().millisecondsSinceEpoch}',
      start: point.dateFrom.toLocal(),
      endExclusive: point.dateTo.toLocal(),
      durationMinutes: point.dateTo.difference(point.dateFrom).inSeconds / 60,
      activityLabel: workoutValue == null
          ? null
          : _formatWorkoutActivityLabel(workoutValue.workoutActivityType),
      sourceName: point.sourceName.isEmpty ? null : point.sourceName,
      totalCalories: workoutValue?.totalEnergyBurned,
      totalSteps: _resolveInitialWorkoutSteps(
        workoutValueSteps: workoutValue?.totalSteps,
        summarySteps: summarySteps,
      ),
    );
  }

  HealthWorkoutSession _backfillWorkoutSteps({
    required HealthWorkoutSession workout,
    required HealthDataPoint point,
    required double? userHeightCm,
  }) {
    if (!_needsWorkoutStepBackfill(point: point, workout: workout)) {
      return workout;
    }

    final estimatedSteps = _estimateStepsFromWorkoutDistance(
      point,
      userHeightCm: userHeightCm,
    );
    if (estimatedSteps == null || estimatedSteps <= 0) {
      return workout;
    }

    return workout.copyWith(totalSteps: estimatedSteps);
  }

  bool _needsWorkoutStepBackfill({
    required HealthDataPoint point,
    required HealthWorkoutSession workout,
  }) {
    final workoutValue = point.value is WorkoutHealthValue
        ? point.value as WorkoutHealthValue
        : null;
    if (workoutValue == null) {
      return false;
    }
    if (!_stepBasedWorkoutTypes.contains(workoutValue.workoutActivityType)) {
      return false;
    }
    final totalSteps = workout.totalSteps;
    return totalSteps == null || totalSteps <= 0;
  }

  int? _resolveInitialWorkoutSteps({
    required int? workoutValueSteps,
    required int? summarySteps,
  }) {
    final positiveWorkoutValueSteps = _positiveStepCount(workoutValueSteps);
    return positiveWorkoutValueSteps ?? summarySteps;
  }

  int? _positiveStepCount(int? value) {
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }

  int? _positiveWorkoutSummarySteps(WorkoutSummary? workoutSummary) {
    if (workoutSummary == null) {
      return null;
    }
    final roundedSteps = workoutSummary.totalSteps.round();
    return roundedSteps > 0 ? roundedSteps : null;
  }

  HealthActiveEnergySample? _buildActiveEnergySample(HealthDataPoint point) {
    final numericValue = _numericHealthValue(point);
    if (numericValue == null) {
      return null;
    }
    return HealthActiveEnergySample(
      startAt: point.dateFrom.toLocal(),
      endAt: point.dateTo.toLocal(),
      numericValue: numericValue,
    );
  }

  Future<List<HealthEnergySegment>> _buildUnassignedActiveEnergySegments({
    required HealthDataPoint point,
    required DateTime dayStart,
    required DateTime dayEnd,
    required List<HealthWorkoutSession> workouts,
  }) async {
    final sample = _buildActiveEnergySample(point);
    if (sample == null) {
      return const <HealthEnergySegment>[];
    }

    final clippedStart = sample.startAt.isAfter(dayStart)
        ? sample.startAt
        : dayStart;
    final clippedEnd = sample.endAt.isBefore(dayEnd) ? sample.endAt : dayEnd;
    if (!clippedEnd.isAfter(clippedStart)) {
      return const <HealthEnergySegment>[];
    }

    final overlappingWorkouts =
        workouts
            .where(
              (workout) =>
                  workout.endExclusive.isAfter(clippedStart) &&
                  workout.start.isBefore(clippedEnd),
            )
            .toList(growable: false)
          ..sort((left, right) => left.start.compareTo(right.start));

    final unassignedSegments = <HealthEnergySegment>[];
    var cursor = clippedStart;
    var segmentIndex = 0;

    for (final workout in overlappingWorkouts) {
      final overlapStart = workout.start.isAfter(clippedStart)
          ? workout.start
          : clippedStart;
      final overlapEnd = workout.endExclusive.isBefore(clippedEnd)
          ? workout.endExclusive
          : clippedEnd;
      if (!overlapEnd.isAfter(overlapStart)) {
        continue;
      }
      if (overlapStart.isAfter(cursor)) {
        final segment = await _buildUnassignedActiveEnergySegment(
          point: point,
          sample: sample,
          start: cursor,
          endExclusive: overlapStart,
          segmentIndex: segmentIndex,
        );
        if (segment != null) {
          unassignedSegments.add(segment);
          segmentIndex += 1;
        }
      }
      if (overlapEnd.isAfter(cursor)) {
        cursor = overlapEnd;
      }
      if (!clippedEnd.isAfter(cursor)) {
        break;
      }
    }

    if (clippedEnd.isAfter(cursor)) {
      final segment = await _buildUnassignedActiveEnergySegment(
        point: point,
        sample: sample,
        start: cursor,
        endExclusive: clippedEnd,
        segmentIndex: segmentIndex,
      );
      if (segment != null) {
        unassignedSegments.add(segment);
      }
    }

    return unassignedSegments;
  }

  Future<HealthEnergySegment?> _buildUnassignedActiveEnergySegment({
    required HealthDataPoint point,
    required HealthActiveEnergySample sample,
    required DateTime start,
    required DateTime endExclusive,
    required int segmentIndex,
  }) async {
    final calories = _activeEnergyValueForRange(
      sample: sample,
      start: start,
      endExclusive: endExclusive,
    );
    if (calories <= 0) {
      return null;
    }
    final totalSteps = await _health.getTotalStepsInInterval(
      start,
      endExclusive,
    );
    if (!_shouldCountUnassignedActiveEnergy(
      calories: calories,
      totalSteps: totalSteps,
      start: start,
      endExclusive: endExclusive,
    )) {
      return null;
    }

    return HealthEnergySegment(
      id: _unassignedActiveEnergySegmentId(
        point: point,
        start: start,
        segmentIndex: segmentIndex,
      ),
      start: start,
      endExclusive: endExclusive,
      durationMinutes: endExclusive.difference(start).inSeconds / 60,
      sourceName: point.sourceName.isEmpty ? null : point.sourceName,
      totalCalories: calories.round(),
      totalSteps: _positiveStepCount(totalSteps),
    );
  }

  bool _shouldCountUnassignedActiveEnergy({
    required double calories,
    required int? totalSteps,
    required DateTime start,
    required DateTime endExclusive,
  }) {
    if (calories <= 0) {
      return false;
    }
    if (totalSteps != null && totalSteps > 0) {
      return true;
    }

    final durationMinutes =
        endExclusive.difference(start).inMilliseconds / 60000;
    if (durationMinutes <= 0) {
      return false;
    }
    return calories / durationMinutes >=
        _minimumUnassignedActivityKcalPerMinute;
  }

  String _unassignedActiveEnergySegmentId({
    required HealthDataPoint point,
    required DateTime start,
    required int segmentIndex,
  }) {
    final baseId = point.uuid.isNotEmpty
        ? point.uuid
        : '${point.sourceId}:${start.toUtc().millisecondsSinceEpoch}';
    return 'unassigned-active-energy:$baseId:$segmentIndex';
  }

  int? _estimateStepsFromWorkoutDistance(
    HealthDataPoint point, {
    required double? userHeightCm,
  }) {
    final workoutValue = point.value is WorkoutHealthValue
        ? point.value as WorkoutHealthValue
        : null;
    if (workoutValue == null || workoutValue.totalDistance == null) {
      return null;
    }

    final distanceMeters = _distanceToMeters(
      distance: workoutValue.totalDistance!,
      unit: workoutValue.totalDistanceUnit,
    );
    if (distanceMeters == null || distanceMeters <= 0) {
      return null;
    }

    final stepLengthMeters = _personalizeStepLengthMeters(
      defaultStepLengthMeters: _defaultStepLengthMetersForWorkoutType(
        workoutValue.workoutActivityType,
      ),
      userHeightCm: userHeightCm,
    );
    final estimatedSteps = (distanceMeters / stepLengthMeters).round();
    return estimatedSteps > 0 ? estimatedSteps : null;
  }

  double? _distanceToMeters({
    required int distance,
    required HealthDataUnit? unit,
  }) {
    return switch (unit) {
      HealthDataUnit.CENTIMETER => distance / 100,
      HealthDataUnit.FOOT => distance * 0.3048,
      HealthDataUnit.INCH => distance * 0.0254,
      HealthDataUnit.METER => distance.toDouble(),
      HealthDataUnit.MILE => distance * 1609.344,
      HealthDataUnit.YARD => distance * 0.9144,
      _ => null,
    };
  }

  double _defaultStepLengthMetersForWorkoutType(
    HealthWorkoutActivityType type,
  ) {
    return switch (type) {
      HealthWorkoutActivityType.RUNNING ||
      HealthWorkoutActivityType.RUNNING_TREADMILL ||
      HealthWorkoutActivityType.TRACK_AND_FIELD ||
      HealthWorkoutActivityType.WHEELCHAIR_RUN_PACE => 0.85,
      HealthWorkoutActivityType.STAIRS ||
      HealthWorkoutActivityType.STAIR_CLIMBING ||
      HealthWorkoutActivityType.STAIR_CLIMBING_MACHINE ||
      HealthWorkoutActivityType.STEP_TRAINING => 0.6,
      _ => 0.75,
    };
  }

  double _personalizeStepLengthMeters({
    required double defaultStepLengthMeters,
    required double? userHeightCm,
  }) {
    if (userHeightCm == null) {
      return defaultStepLengthMeters;
    }

    return defaultStepLengthMeters *
        (userHeightCm / _defaultCalculatorProfileHeightCm);
  }

  String _formatWorkoutActivityLabel(HealthWorkoutActivityType type) {
    return type.name.split('_').map(_capitalizeWord).join(' ');
  }

  String _capitalizeWord(String word) {
    if (word.isEmpty) {
      return word;
    }
    final lowerCaseWord = word.toLowerCase();
    return '${lowerCaseWord[0].toUpperCase()}${lowerCaseWord.substring(1)}';
  }
}

bool _isEmptyDayData(DiaryHealthDayData data) {
  return data.totalSteps <= 0 &&
      data.workouts.isEmpty &&
      data.unassignedActiveEnergySegments.isEmpty;
}

bool _isEmptyActivityTrendDays(List<DiaryHealthActivityTrendDay> days) {
  return days.every(_isEmptyActivityTrendDay);
}

bool _isEmptyActivityTrendDay(DiaryHealthActivityTrendDay day) {
  return day.totalSteps <= 0 && day.activeEnergyKcal <= 0;
}

num? _numericHealthValue(HealthDataPoint point) {
  final value = point.value;
  return switch (value) {
    NumericHealthValue(:final numericValue) => numericValue,
    _ => null,
  };
}

double? _normalizeUserHeightCm(double? userHeightCm) {
  if (userHeightCm == null || userHeightCm <= 0) {
    return null;
  }

  return userHeightCm.clamp(
    _minPersonalizedHeightCm,
    _maxPersonalizedHeightCm,
  );
}

double _activeEnergyValueForRange({
  required HealthActiveEnergySample sample,
  required DateTime start,
  required DateTime endExclusive,
}) {
  final overlapStart = start.isAfter(sample.startAt) ? start : sample.startAt;
  final overlapEnd = endExclusive.isBefore(sample.endAt)
      ? endExclusive
      : sample.endAt;
  if (!overlapEnd.isAfter(overlapStart)) {
    return 0;
  }

  final sampleDurationMs = sample.endAt
      .difference(sample.startAt)
      .inMilliseconds;
  if (sampleDurationMs <= 0) {
    return sample.numericValue.toDouble();
  }

  final overlapMs = overlapEnd.difference(overlapStart).inMilliseconds;
  if (overlapMs <= 0) {
    return 0;
  }

  return sample.numericValue.toDouble() * overlapMs / sampleDurationMs;
}

int _compareWorkoutStartThenEnd(
  HealthWorkoutSession left,
  HealthWorkoutSession right,
) {
  final startComparison = left.start.compareTo(right.start);
  if (startComparison != 0) {
    return startComparison;
  }
  return left.endExclusive.compareTo(right.endExclusive);
}

HealthWorkoutSession _copyWorkoutWithTotalCalories(
  HealthWorkoutSession workout,
  int? totalCalories,
) {
  return HealthWorkoutSession(
    id: workout.id,
    start: workout.start,
    endExclusive: workout.endExclusive,
    durationMinutes: workout.durationMinutes,
    activityLabel: workout.activityLabel,
    sourceName: workout.sourceName,
    totalCalories: totalCalories,
    totalSteps: workout.totalSteps,
  );
}

double _activeEnergyValueForIntervals({
  required List<HealthActiveEnergySample> samples,
  required List<_DateTimeInterval> intervals,
}) {
  var total = 0.0;
  for (final sample in samples) {
    for (final interval in intervals) {
      total += _activeEnergyValueForRange(
        sample: sample,
        start: interval.start,
        endExclusive: interval.endExclusive,
      );
    }
  }
  return total;
}

List<_DateTimeInterval> _subtractIntervals({
  required List<_DateTimeInterval> intervals,
  required List<_DateTimeInterval> blockers,
}) {
  var remaining = intervals;
  for (final blocker in blockers) {
    remaining = remaining
        .expand((interval) => interval.subtract(blocker))
        .toList(growable: false);
  }
  return remaining;
}

class _DateTimeInterval {
  const _DateTimeInterval(this.start, this.endExclusive);

  final DateTime start;
  final DateTime endExclusive;

  List<_DateTimeInterval> subtract(_DateTimeInterval blocker) {
    final overlapStart = blocker.start.isAfter(start) ? blocker.start : start;
    final overlapEnd = blocker.endExclusive.isBefore(endExclusive)
        ? blocker.endExclusive
        : endExclusive;
    if (!overlapEnd.isAfter(overlapStart)) {
      return <_DateTimeInterval>[this];
    }

    final remaining = <_DateTimeInterval>[];
    if (overlapStart.isAfter(start)) {
      remaining.add(_DateTimeInterval(start, overlapStart));
    }
    if (endExclusive.isAfter(overlapEnd)) {
      remaining.add(_DateTimeInterval(overlapEnd, endExclusive));
    }
    return remaining;
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
