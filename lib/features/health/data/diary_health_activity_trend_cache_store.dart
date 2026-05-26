import 'dart:convert';
import 'dart:developer' show log;

import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/health/data/diary_health_activity_trend_cache_codec.dart';
import 'package:yamt/features/health/domain/diary_health_activity_trend_day.dart';

const _logName = 'DiaryHealthActivityTrendCacheStore';
const _persistentActivityTrendCachePrefix =
    'diary_health_activity_trend_cache_v1:';
const _persistentActivityTrendCacheIndexKey =
    'diary_health_activity_trend_cache_v1:index';

/// Stores derived diary health activity trend totals in preferences.
class DiaryHealthActivityTrendCacheStore {
  /// Creates a persistent activity trend cache store.
  const DiaryHealthActivityTrendCacheStore({
    required AppPreferences preferences,
    required int maxEntries,
  }) : _preferences = preferences,
       _maxEntries = maxEntries;

  final AppPreferences _preferences;
  final int _maxEntries;

  /// Reads cached derived trend totals for [cacheKey].
  Future<DiaryHealthActivityTrendCacheSnapshot?> read({
    required String cacheKey,
    required DateTime now,
    required Duration maxStaleAge,
  }) async {
    try {
      final raw = await _preferences.getString(_cacheEntryKey(cacheKey));
      if (raw == null || raw.isEmpty) {
        return null;
      }
      final snapshot = DiaryHealthActivityTrendCacheSnapshot.decode(
        raw,
        cacheKey: cacheKey,
      );
      if (snapshot == null || _isTooStale(snapshot, now, maxStaleAge)) {
        await remove(cacheKey);
        return null;
      }
      return snapshot;
    } on Object catch (error, stackTrace) {
      log(
        'Ignoring malformed diary health activity trend cache.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      await remove(cacheKey);
      return null;
    }
  }

  /// Saves cached derived trend totals for [cacheKey].
  Future<void> save({
    required String cacheKey,
    required DateTime startInclusive,
    required DateTime endExclusive,
    required DateTime loadedAt,
    required List<DiaryHealthActivityTrendDay> days,
  }) async {
    try {
      final snapshot = DiaryHealthActivityTrendCacheSnapshot(
        startInclusive: startInclusive,
        endExclusive: endExclusive,
        loadedAt: loadedAt,
        days: days,
      );
      await _preferences.setString(
        _cacheEntryKey(cacheKey),
        snapshot.encode(cacheKey: cacheKey),
      );
      await _remember(cacheKey);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to persist diary health activity trend cache.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Removes cached derived trend totals for [cacheKey].
  Future<void> remove(String cacheKey) async {
    await _preferences.remove(_cacheEntryKey(cacheKey));
    final cacheKeys = await _readIndex();
    if (!cacheKeys.remove(cacheKey)) {
      return;
    }
    await _writeIndex(cacheKeys);
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
        _persistentActivityTrendCacheIndexKey,
      );
      if (raw == null || raw.isEmpty) {
        return <String>[];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        await _preferences.remove(_persistentActivityTrendCacheIndexKey);
        return <String>[];
      }
      return decoded.whereType<String>().toList(growable: true);
    } on Object catch (error, stackTrace) {
      log(
        'Reset malformed diary health activity trend cache index.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      await _preferences.remove(_persistentActivityTrendCacheIndexKey);
      return <String>[];
    }
  }

  Future<void> _writeIndex(List<String> cacheKeys) async {
    await _preferences.setString(
      _persistentActivityTrendCacheIndexKey,
      jsonEncode(cacheKeys),
    );
  }

  String _cacheEntryKey(String cacheKey) {
    return '$_persistentActivityTrendCachePrefix$cacheKey';
  }

  bool _isTooStale(
    DiaryHealthActivityTrendCacheSnapshot snapshot,
    DateTime now,
    Duration maxStaleAge,
  ) {
    return now.difference(snapshot.loadedAt) > maxStaleAge;
  }
}
