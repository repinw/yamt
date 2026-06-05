import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/'
    'calorie_health_activity_kcal_reader.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/domain/diary_health_activity_trend_day.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_energy_segment.dart';

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

  test('force refresh uses refresh trend service when available', () async {
    final day = DateTime(2026, 4, 8);
    final service = _RefreshTrendDiaryHealthService(
      loadedTrendDays: [
        DiaryHealthActivityTrendDay(
          day: day,
          totalSteps: 4000,
          activeEnergyKcal: 120,
        ),
      ],
      refreshedTrendDays: [
        DiaryHealthActivityTrendDay(
          day: day,
          totalSteps: 4000,
          activeEnergyKcal: 899,
        ),
      ],
    );

    final activeKcalByDay = await loadAggregateHealthActivityKcalByDay(
      diaryHealthService: service,
      days: [day],
      logName: 'test',
      failureMessage: 'failed',
      forceRefresh: true,
    );

    expect(activeKcalByDay, {diaryDayKey(day): 899});
    expect(service.loadCallCount, 0);
    expect(service.refreshCallCount, 1);
  });

  test('keeps raw high aggregate active energy for calorie math', () {
    final activeKcal = calculateAggregateImportedHealthActivityKcal(
      totalSteps: 0,
      activeEnergyKcal: 899,
    );

    expect(activeKcal, 899);
  });

  test('overlays detailed activity on aggregate fallback', () async {
    final aggregateDay = DateTime(2026, 4, 8);
    final detailedDay = DateTime(2026, 4, 9);
    final service = FakeTrendDiaryHealthService(
      <String, DiaryHealthDayData>{
        diaryDayKey(detailedDay): const DiaryHealthDayData(
          totalSteps: 1000,
          workouts: [],
        ),
      },
      trendDays: [
        DiaryHealthActivityTrendDay(
          day: aggregateDay,
          totalSteps: 0,
          activeEnergyKcal: 250,
        ),
        DiaryHealthActivityTrendDay(
          day: detailedDay,
          totalSteps: 0,
          activeEnergyKcal: 999,
        ),
      ],
    );

    final activeKcalByDay = await loadHealthActivityKcalByDay(
      diaryHealthService: service,
      days: [aggregateDay, detailedDay],
      logName: 'test',
      aggregateFailureMessage: 'failed',
      forceRefreshDayKeys: {diaryDayKey(detailedDay)},
    );

    expect(activeKcalByDay, {
      diaryDayKey(aggregateDay): 250,
      diaryDayKey(detailedDay): 40,
    });
    expect(service.trendRequests, [
      (
        startInclusive: aggregateDay,
        endExclusive: nextDiaryDay(detailedDay),
      ),
    ]);
    expect(service.loadDayDataCallCount, 1);
  });

  test('keeps aggregate activity when detailed activity fails', () async {
    final aggregateDay = DateTime(2026, 4, 8);
    final detailedDay = DateTime(2026, 4, 9);
    final service = _ThrowingDayTrendDiaryHealthService(
      const <String, DiaryHealthDayData>{},
      trendDays: [
        DiaryHealthActivityTrendDay(
          day: aggregateDay,
          totalSteps: 0,
          activeEnergyKcal: 250,
        ),
        DiaryHealthActivityTrendDay(
          day: detailedDay,
          totalSteps: 0,
          activeEnergyKcal: 999,
        ),
      ],
      throwingDayKeys: {diaryDayKey(detailedDay)},
    );

    final activeKcalByDay = await loadHealthActivityKcalByDay(
      diaryHealthService: service,
      days: [aggregateDay, detailedDay],
      logName: 'test',
      aggregateFailureMessage: 'failed',
      detailedActivityDayKeys: {diaryDayKey(detailedDay)},
    );

    expect(activeKcalByDay, {
      diaryDayKey(aggregateDay): 250,
      diaryDayKey(detailedDay): 999,
    });
    expect(service.trendRequests, [
      (
        startInclusive: aggregateDay,
        endExclusive: nextDiaryDay(detailedDay),
      ),
    ]);
    expect(service.loadDayDataCallCount, 1);
  });

  test('falls back to detailed activity when aggregate load fails', () async {
    final firstDay = DateTime(2026, 4, 8);
    final secondDay = DateTime(2026, 4, 9);
    final service = FakeTrendDiaryHealthService(
      <String, DiaryHealthDayData>{
        diaryDayKey(firstDay): const DiaryHealthDayData(
          totalSteps: 1000,
          workouts: [],
        ),
        diaryDayKey(secondDay): const DiaryHealthDayData(
          totalSteps: 2000,
          workouts: [],
        ),
      },
      trendDays: const <DiaryHealthActivityTrendDay>[],
      shouldThrowTrend: true,
    );

    final activeKcalByDay = await loadHealthActivityKcalByDay(
      diaryHealthService: service,
      days: [firstDay, secondDay],
      logName: 'test',
      aggregateFailureMessage: 'failed',
    );

    expect(activeKcalByDay, {
      diaryDayKey(firstDay): 40,
      diaryDayKey(secondDay): 80,
    });
    expect(service.trendRequests, [
      (
        startInclusive: firstDay,
        endExclusive: nextDiaryDay(secondDay),
      ),
    ]);
    expect(service.loadDayDataCallCount, 2);
  });

  test('keeps unassigned active energy without steps for calorie math', () {
    final activeKcal = calculateImportedHealthActivityKcal(
      stepsOutsideWorkouts: 0,
      workoutCalories: const <int?>[],
      unassignedActiveEnergySegments: [
        HealthEnergySegment(
          id: 'manual-active-energy',
          start: DateTime(2026, 4, 15, 18),
          endExclusive: DateTime(2026, 4, 15, 19),
          durationMinutes: 60,
          sourceName: 'Health',
          totalCalories: 899,
          totalSteps: null,
        ),
      ],
    );

    expect(activeKcal, 899);
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

class _RefreshTrendDiaryHealthService
    implements
        DiaryHealthService,
        DiaryHealthActivityTrendService,
        DiaryHealthActivityTrendRefreshService {
  _RefreshTrendDiaryHealthService({
    required this.loadedTrendDays,
    required this.refreshedTrendDays,
  });

  final List<DiaryHealthActivityTrendDay> loadedTrendDays;
  final List<DiaryHealthActivityTrendDay> refreshedTrendDays;
  int loadCallCount = 0;
  int refreshCallCount = 0;

  @override
  Future<DiaryHealthDayData> loadDayData({
    required DateTime day,
    double? userHeightCm,
  }) async {
    return const DiaryHealthDayData(totalSteps: 0, workouts: []);
  }

  @override
  Future<List<DiaryHealthActivityTrendDay>> loadActivityTrendDays({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    loadCallCount += 1;
    return loadedTrendDays;
  }

  @override
  Future<List<DiaryHealthActivityTrendDay>> refreshActivityTrendDays({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    refreshCallCount += 1;
    return refreshedTrendDays;
  }
}

class _ThrowingDayTrendDiaryHealthService extends FakeTrendDiaryHealthService {
  _ThrowingDayTrendDiaryHealthService(
    super.dataByDay, {
    required super.trendDays,
    required this.throwingDayKeys,
  });

  final Set<String> throwingDayKeys;

  @override
  Future<DiaryHealthDayData> loadDayData({
    required DateTime day,
    double? userHeightCm,
  }) async {
    if (throwingDayKeys.contains(diaryDayKey(day))) {
      loadDayDataCallCount += 1;
      throw StateError('day failed');
    }
    return super.loadDayData(day: day, userHeightCm: userHeightCm);
  }
}
