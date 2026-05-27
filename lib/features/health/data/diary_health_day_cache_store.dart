import 'dart:convert';
import 'dart:developer' show log;

import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/health/data/diary_health_day_cache_codec.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';

const _logName = 'DiaryHealthDayCacheStore';
const _persistentDayCachePrefix = 'diary_health_day_cache_v1:';
const _persistentDayCacheIndexKey = 'diary_health_day_cache_v1:index';

/// Stores derived diary health day data in preferences.
class DiaryHealthDayCacheStore {
  /// Creates a persistent day cache store.
  const DiaryHealthDayCacheStore({
    required AppPreferences preferences,
    required int maxEntries,
  }) : _preferences = preferences,
       _maxEntries = maxEntries;

  final AppPreferences _preferences;
  final int _maxEntries;

  /// Reads cached derived day data for [cacheKey].
  Future<DiaryHealthDayCacheSnapshot?> read({
    required String cacheKey,
    required DateTime now,
    required Duration maxStaleAge,
  }) async {
    try {
      final raw = await _preferences.getString(_cacheEntryKey(cacheKey));
      if (raw == null || raw.isEmpty) {
        return null;
      }
      final snapshot = DiaryHealthDayCacheSnapshot.decode(
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
        'Ignoring malformed diary health day cache.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      await remove(cacheKey);
      return null;
    }
  }

  /// Saves cached derived day data for [cacheKey].
  Future<void> save({
    required String cacheKey,
    required DateTime dayStart,
    required DateTime loadedAt,
    required DiaryHealthDayData data,
  }) async {
    try {
      final snapshot = DiaryHealthDayCacheSnapshot.fromDomain(
        cacheKey: cacheKey,
        dayStart: dayStart,
        loadedAt: loadedAt,
        data: data,
      );
      await _preferences.setString(
        _cacheEntryKey(cacheKey),
        snapshot.encode(),
      );
      await _remember(cacheKey);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to persist diary health day cache.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Removes cached derived day data for [cacheKey].
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
      final raw = await _preferences.getString(_persistentDayCacheIndexKey);
      if (raw == null || raw.isEmpty) {
        return <String>[];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        await _preferences.remove(_persistentDayCacheIndexKey);
        return <String>[];
      }
      return decoded.whereType<String>().toList(growable: true);
    } on Object catch (error, stackTrace) {
      log(
        'Reset malformed diary health day cache index.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      await _preferences.remove(_persistentDayCacheIndexKey);
      return <String>[];
    }
  }

  Future<void> _writeIndex(List<String> cacheKeys) async {
    await _preferences.setString(
      _persistentDayCacheIndexKey,
      jsonEncode(cacheKeys),
    );
  }

  String _cacheEntryKey(String cacheKey) {
    return '$_persistentDayCachePrefix$cacheKey';
  }

  bool _isTooStale(
    DiaryHealthDayCacheSnapshot snapshot,
    DateTime now,
    Duration maxStaleAge,
  ) {
    return now.difference(snapshot.loadedAt) > maxStaleAge;
  }
}
