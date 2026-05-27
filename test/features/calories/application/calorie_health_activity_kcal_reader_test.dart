import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/'
    'calorie_health_activity_kcal_reader.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/domain/diary_health_activity_trend_day.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';

import '../support/fake_calories_repositories.dart';

void main() {
  test('loads aggregate kcal by day from trend service', () async {
    final firstDay = DateTime(2026, 4, 8);
    final secondDay = DateTime(2026, 4, 9);
    final service = FakeTrendDiaryHealthService(
      const <String, DiaryHealthDayData>{},
      trendDays: [
        DiaryHealthActivityTrendDay(
          day: firstDay,
          totalSteps: 4000,
          activeEnergyKcal: 250,
        ),
        DiaryHealthActivityTrendDay(
          day: secondDay,
          totalSteps: 3000,
          activeEnergyKcal: 0,
        ),
      ],
    );

    final activeKcalByDay = await loadAggregateHealthActivityKcalByDay(
      diaryHealthService: service,
      days: [secondDay, firstDay],
      logName: 'test',
      failureMessage: 'failed',
    );

    expect(activeKcalByDay, {
      diaryDayKey(firstDay): 250,
      diaryDayKey(secondDay): 120,
    });
    expect(service.trendRequests, [
      (
        startInclusive: firstDay,
        endExclusive: nextDiaryDay(secondDay),
      ),
    ]);
  });

  test('returns null when service has no aggregate trend support', () async {
    final activeKcalByDay = await loadAggregateHealthActivityKcalByDay(
      diaryHealthService: FakeDiaryHealthService(
        const <String, DiaryHealthDayData>{},
      ),
      days: [DateTime(2026, 4, 8)],
      logName: 'test',
      failureMessage: 'failed',
    );

    expect(activeKcalByDay, isNull);
  });

  test('returns null when aggregate trend load fails', () async {
    final activeKcalByDay = await loadAggregateHealthActivityKcalByDay(
      diaryHealthService: FakeTrendDiaryHealthService(
        const <String, DiaryHealthDayData>{},
        trendDays: const <DiaryHealthActivityTrendDay>[],
        shouldThrowTrend: true,
      ),
      days: [DateTime(2026, 4, 8)],
      logName: 'test',
      failureMessage: 'failed',
    );

    expect(activeKcalByDay, isNull);
  });
}
