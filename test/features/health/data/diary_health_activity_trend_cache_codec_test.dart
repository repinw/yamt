import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/health/data/diary_health_activity_trend_cache_codec.dart';
import 'package:yamt/features/health/domain/diary_health_activity_trend_day.dart';

void main() {
  test('round trips derived trend totals', () {
    final start = DateTime(2026, 4, 21);
    final end = DateTime(2026, 4, 28);
    final loadedAt = DateTime(2026, 4, 28, 7);
    final snapshot = DiaryHealthActivityTrendCacheSnapshot(
      startInclusive: start,
      endExclusive: end,
      loadedAt: loadedAt,
      days: [
        DiaryHealthActivityTrendDay(
          day: start,
          totalSteps: 4124,
          activeEnergyKcal: 187,
        ),
      ],
    );

    final encoded = snapshot.encode(cacheKey: 'week');
    final decoded = DiaryHealthActivityTrendCacheSnapshot.decode(
      encoded,
      cacheKey: 'week',
    );

    expect(decoded?.startInclusive, start);
    expect(decoded?.endExclusive, end);
    expect(decoded?.loadedAt, loadedAt);
    expect(decoded?.days.single.day, start);
    expect(decoded?.days.single.totalSteps, 4124);
    expect(decoded?.days.single.activeEnergyKcal, 187);
    expect(
      DiaryHealthActivityTrendCacheSnapshot.decode(
        encoded,
        cacheKey: 'other-week',
      ),
      isNull,
    );
  });

  test('rounds numeric totals from JSON', () {
    final start = DateTime(2026, 4, 21);
    final end = DateTime(2026, 4, 28);
    final loadedAt = DateTime(2026, 4, 28, 7);

    final decoded = DiaryHealthActivityTrendCacheSnapshot.decode(
      jsonEncode(<String, Object?>{
        'version': 1,
        'cache_key': 'week',
        'start_inclusive': start.toIso8601String(),
        'end_exclusive': end.toIso8601String(),
        'loaded_at': loadedAt.toIso8601String(),
        'days': [
          <String, Object?>{
            'day': start.toIso8601String(),
            'total_steps': 4123.6,
            'active_energy_kcal': 187.2,
          },
        ],
      }),
      cacheKey: 'week',
    );

    expect(decoded?.days.single.totalSteps, 4124);
    expect(decoded?.days.single.activeEnergyKcal, 187);
  });

  test('rejects malformed payloads', () {
    final start = DateTime(2026, 4, 21);
    final end = DateTime(2026, 4, 28);
    final loadedAt = DateTime(2026, 4, 28, 7);

    expect(
      DiaryHealthActivityTrendCacheSnapshot.decode('[]', cacheKey: 'week'),
      isNull,
    );
    expect(
      DiaryHealthActivityTrendCacheSnapshot.decode(
        jsonEncode(<String, Object?>{
          'version': 1,
          'cache_key': 'week',
          'start_inclusive': 'bad',
          'end_exclusive': end.toIso8601String(),
          'loaded_at': loadedAt.toIso8601String(),
          'days': <Object?>[],
        }),
        cacheKey: 'week',
      ),
      isNull,
    );
    expect(
      DiaryHealthActivityTrendCacheSnapshot.decode(
        jsonEncode(<String, Object?>{
          'version': 1,
          'cache_key': 'week',
          'start_inclusive': start.toIso8601String(),
          'end_exclusive': end.toIso8601String(),
          'loaded_at': loadedAt.toIso8601String(),
          'days': [
            <String, Object?>{
              'day': start.toIso8601String(),
              'total_steps': '4000',
              'active_energy_kcal': 180,
            },
          ],
        }),
        cacheKey: 'week',
      ),
      isNull,
    );
  });
}
