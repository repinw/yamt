import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/health/data/diary_health_activity_trend_cache_store.dart';
import 'package:yamt/features/health/domain/diary_health_activity_trend_day.dart';

import '../../../helpers/memory_app_preferences.dart';

const _indexKey = 'diary_health_activity_trend_cache_v1:index';
const _entryPrefix = 'diary_health_activity_trend_cache_v1:';

void main() {
  test('store saves and reads derived trend totals', () async {
    final preferences = MemoryAppPreferences();
    final store = DiaryHealthActivityTrendCacheStore(
      preferences: preferences,
      maxEntries: 2,
    );
    final start = DateTime(2026, 4, 21);
    final end = DateTime(2026, 4, 28);
    final loadedAt = DateTime(2026, 4, 28, 7);

    await store.save(
      cacheKey: 'week',
      startInclusive: start,
      endExclusive: end,
      loadedAt: loadedAt,
      days: [
        DiaryHealthActivityTrendDay(
          day: start,
          totalSteps: 4000,
          activeEnergyKcal: 180,
        ),
      ],
    );
    final snapshot = await store.read(
      cacheKey: 'week',
      now: loadedAt.add(const Duration(minutes: 1)),
      maxStaleAge: const Duration(days: 7),
    );

    expect(snapshot?.days.single.totalSteps, 4000);
    expect(snapshot?.days.single.activeEnergyKcal, 180);
    expect(await preferences.getString(_indexKey), contains('week'));
  });

  test('store evicts oldest entries and removes index records', () async {
    final preferences = MemoryAppPreferences();
    final store = DiaryHealthActivityTrendCacheStore(
      preferences: preferences,
      maxEntries: 2,
    );
    final now = DateTime(2026, 4, 28, 7);

    await _saveOneDay(store, cacheKey: 'first', loadedAt: now, steps: 1000);
    await _saveOneDay(store, cacheKey: 'second', loadedAt: now, steps: 2000);
    await _saveOneDay(store, cacheKey: 'third', loadedAt: now, steps: 3000);
    await store.remove('second');

    expect(await preferences.getString(_entryKey('first')), isNull);
    expect(await preferences.getString(_entryKey('second')), isNull);
    expect(await preferences.getString(_entryKey('third')), isNotNull);
    expect(await preferences.getString(_indexKey), isNot(contains('first')));
    expect(await preferences.getString(_indexKey), isNot(contains('second')));
    expect(await preferences.getString(_indexKey), contains('third'));
  });

  test('store drops hard-stale and malformed entries', () async {
    final staleLoadedAt = DateTime(2026, 4, 20, 7);
    final preferences = MemoryAppPreferences(
      initialStrings: <String, String>{
        _entryKey('malformed'): '{bad',
        _indexKey: jsonEncode(<String>['malformed']),
      },
    );
    final store = DiaryHealthActivityTrendCacheStore(
      preferences: preferences,
      maxEntries: 2,
    );

    await _saveOneDay(
      store,
      cacheKey: 'stale',
      loadedAt: staleLoadedAt,
      steps: 1000,
    );
    final staleRead = await store.read(
      cacheKey: 'stale',
      now: staleLoadedAt.add(const Duration(days: 8)),
      maxStaleAge: const Duration(days: 7),
    );
    final malformedRead = await store.read(
      cacheKey: 'malformed',
      now: staleLoadedAt,
      maxStaleAge: const Duration(days: 7),
    );

    expect(staleRead, isNull);
    expect(malformedRead, isNull);
    expect(await preferences.getString(_entryKey('stale')), isNull);
    expect(await preferences.getString(_entryKey('malformed')), isNull);
  });

  test('store resets malformed index before saving', () async {
    final preferences = MemoryAppPreferences(
      initialStrings: const <String, String>{_indexKey: '{bad'},
    );
    final store = DiaryHealthActivityTrendCacheStore(
      preferences: preferences,
      maxEntries: 2,
    );

    await _saveOneDay(
      store,
      cacheKey: 'fresh',
      loadedAt: DateTime(2026, 4, 28, 7),
      steps: 1000,
    );

    expect(await preferences.getString(_indexKey), '["fresh"]');
  });
}

Future<void> _saveOneDay(
  DiaryHealthActivityTrendCacheStore store, {
  required String cacheKey,
  required DateTime loadedAt,
  required int steps,
}) {
  final start = DateTime(2026, 4, 21);
  return store.save(
    cacheKey: cacheKey,
    startInclusive: start,
    endExclusive: start.add(const Duration(days: 1)),
    loadedAt: loadedAt,
    days: [
      DiaryHealthActivityTrendDay(
        day: start,
        totalSteps: steps,
        activeEnergyKcal: steps ~/ 20,
      ),
    ],
  );
}

String _entryKey(String cacheKey) {
  return '$_entryPrefix$cacheKey';
}
