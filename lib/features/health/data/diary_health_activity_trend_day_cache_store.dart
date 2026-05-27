import 'dart:convert';
import 'dart:developer' show log;

import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/health/data/diary_health_activity_trend_day_cache_codec.dart';
import 'package:yamt/features/health/domain/diary_health_activity_trend_day.dart';

const _logName = 'DiaryHealthActivityTrendDayCacheStore';
const _persistentTrendDayCachePrefix =
    'diary_health_activity_trend_day_cache_v1:';
const _persistentTrendDayCacheIndexKey =
    'diary_health_activity_trend_day_cache_v1:index';

/// Persisted aggregate activity totals for one diary day.
class DiaryHealthActivityTrendDayCacheEntry {
  /// Creates a persisted activity trend day entry.
  const DiaryHealthActivityTrendDayCacheEntry({
    required this.loadedAt,
    required this.day,
  });

  /// Time when Health aggregate data was loaded.
  final DateTime loadedAt;

  /// Cached aggregate day.
  final DiaryHealthActivityTrendDay day;
}

/// Stores derived per-day activity trend totals in preferences.
class DiaryHealthActivityTrendDayCacheStore {
  /// Creates a per-day activity trend cache store.
  const DiaryHealthActivityTrendDayCacheStore({
    required AppPreferences preferences,
    required int maxEntries,
  }) : _preferences = preferences,
       _maxEntries = maxEntries;

  final AppPreferences _preferences;
  final int _maxEntries;

  /// Reads cached aggregate totals for one day.
  Future<DiaryHealthActivityTrendDayCacheEntry?> readDay({
    required DateTime day,
    required DateTime now,
    required Duration maxStaleAge,
  }) async {
    final cacheKey = _cacheKey(day);
    try {
      final raw = await _preferences.getString(_cacheEntryKey(cacheKey));
      if (raw == null || raw.isEmpty) {
        return null;
      }
      final snapshot = DiaryHealthActivityTrendDayCacheSnapshot.decode(
        raw,
        cacheKey: cacheKey,
      );
      if (snapshot == null || now.difference(snapshot.loadedAt) > maxStaleAge) {
        await removeDay(day);
        return null;
      }
      return DiaryHealthActivityTrendDayCacheEntry(
        loadedAt: snapshot.loadedAt,
        day: snapshot.toDomain(),
      );
    } on Object catch (error, stackTrace) {
      log(
        'Ignoring malformed diary health trend day cache.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      await removeDay(day);
      return null;
    }
  }

  /// Saves cached aggregate totals for [days].
  Future<void> saveDays({
    required DateTime loadedAt,
    required List<DiaryHealthActivityTrendDay> days,
  }) async {
    for (final day in days) {
      await _saveDay(loadedAt: loadedAt, day: day);
    }
  }

  /// Removes cached aggregate totals for [day].
  Future<void> removeDay(DateTime day) async {
    final cacheKey = _cacheKey(day);
    await _preferences.remove(_cacheEntryKey(cacheKey));
    final cacheKeys = await _readIndex();
    if (!cacheKeys.remove(cacheKey)) {
      return;
    }
    await _writeIndex(cacheKeys);
  }

  Future<void> _saveDay({
    required DateTime loadedAt,
    required DiaryHealthActivityTrendDay day,
  }) async {
    final cacheKey = _cacheKey(day.day);
    try {
      await _preferences.setString(
        _cacheEntryKey(cacheKey),
        DiaryHealthActivityTrendDayCacheSnapshot.fromDomain(
          cacheKey: cacheKey,
          loadedAt: loadedAt,
          day: day,
        ).encode(),
      );
      await _remember(cacheKey);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to persist diary health trend day cache.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _remember(String cacheKey) async {
    final cacheKeys = await _readIndex();
    cacheKeys
      ..remove(cacheKey)
      ..add(cacheKey);
    while (cacheKeys.length > _maxEntries) {
      final evictedCacheKey = cacheKeys.removeAt(0);
      await _preferences.remove(_cacheEntryKey(evictedCacheKey));
    }
    await _writeIndex(cacheKeys);
  }

  Future<List<String>> _readIndex() async {
    try {
      final raw = await _preferences.getString(
        _persistentTrendDayCacheIndexKey,
      );
      if (raw == null || raw.isEmpty) {
        return <String>[];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        await _preferences.remove(_persistentTrendDayCacheIndexKey);
        return <String>[];
      }
      return decoded.whereType<String>().toList(growable: true);
    } on Object catch (error, stackTrace) {
      log(
        'Reset malformed diary health trend day cache index.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      await _preferences.remove(_persistentTrendDayCacheIndexKey);
      return <String>[];
    }
  }

  Future<void> _writeIndex(List<String> cacheKeys) async {
    await _preferences.setString(
      _persistentTrendDayCacheIndexKey,
      jsonEncode(cacheKeys),
    );
  }

  String _cacheKey(DateTime day) {
    return localDayKey(day);
  }

  String _cacheEntryKey(String cacheKey) {
    return '$_persistentTrendDayCachePrefix$cacheKey';
  }
}
