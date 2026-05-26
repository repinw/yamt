import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/activity/application/diary_activity_weight_service.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/domain/diary_health_activity_trend_day.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_energy_segment.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

void main() {
  final selectedDay = DateTime(2026, 4, 27);
  const service = DiaryActivityWeightService();

  test('aggregates seven day activity and weight data', () async {
    final workout = _workout(selectedDay, totalCalories: 150);
    final data = await service.load(
      day: selectedDay,
      profile: _profile,
      healthStatus: _readyStatus,
      manualEntries: [
        ManualHealthWeightEntry(
          day: selectedDay.subtract(const Duration(days: 1)),
          weightKg: 77.4,
        ),
      ],
      diaryHealthService: _FakeDiaryHealthService({
        diaryDayKey(selectedDay): DiaryHealthDayData(
          totalSteps: 4000,
          workouts: [workout],
        ),
        diaryDayKey(selectedDay.subtract(const Duration(days: 1))):
            const DiaryHealthDayData(totalSteps: 3000, workouts: []),
      }),
      healthWeightService: _FakeHealthWeightService([
        HealthWeightSample(
          recordedAt: selectedDay.add(const Duration(hours: 7)),
          weightKg: 76.8,
          uuid: 'selected-health',
          sourcePackageName: 'de.yamt.app',
          isFromThisApp: true,
        ),
      ]),
    );

    expect(data.healthAccessState, HealthDataAccessState.ready);
    expect(data.activityKcal, 270);
    expect(data.activeMinutes, 30);
    expect(data.profileWeightKg, 80);
    expect(data.selectedWeightKg, 76.8);
    expect(data.hasSelectedDayWeight, isTrue);
    expect(data.activityTrend[5], 120);
    expect(data.activityTrend.last, 270);
    expect(data.weightTrend[5], 77.4);
    expect(data.weightTrend.last, 76.8);
    expect(data.weightDays.last.canDeleteWeight, isTrue);
  });

  test('uses aggregate activity trend when available', () async {
    var rawDayLoadCount = 0;
    final workout = _workout(selectedDay, totalCalories: 150);
    final data = await service.load(
      day: selectedDay,
      profile: _profile,
      healthStatus: _readyStatus,
      manualEntries: const <ManualHealthWeightEntry>[],
      diaryHealthService: _FakeTrendDiaryHealthService(
        {
          diaryDayKey(selectedDay): DiaryHealthDayData(
            totalSteps: 4000,
            workouts: [workout],
          ),
        },
        trendDays: [
          DiaryHealthActivityTrendDay(
            day: selectedDay.subtract(const Duration(days: 1)),
            totalSteps: 3000,
            activeEnergyKcal: 80,
          ),
          DiaryHealthActivityTrendDay(
            day: selectedDay.subtract(const Duration(days: 2)),
            totalSteps: 1000,
            activeEnergyKcal: 120,
          ),
        ],
        onLoad: () {
          rawDayLoadCount += 1;
        },
      ),
      healthWeightService: _FakeHealthWeightService(
        const <HealthWeightSample>[],
      ),
    );

    expect(rawDayLoadCount, 1);
    expect(data.activityKcal, 270);
    expect(data.activityTrend[4], 120);
    expect(data.activityTrend[5], 120);
    expect(data.activityTrend.last, 270);
  });

  test('ignores suspicious total calorie aggregate trend values', () async {
    final data = await service.load(
      day: selectedDay,
      profile: _profile,
      healthStatus: _readyStatus,
      manualEntries: const <ManualHealthWeightEntry>[],
      diaryHealthService: _FakeTrendDiaryHealthService(
        {
          diaryDayKey(selectedDay): const DiaryHealthDayData(
            totalSteps: 4000,
            workouts: [],
          ),
        },
        trendDays: [
          DiaryHealthActivityTrendDay(
            day: selectedDay.subtract(const Duration(days: 3)),
            totalSteps: 0,
            activeEnergyKcal: 1600,
          ),
          DiaryHealthActivityTrendDay(
            day: selectedDay.subtract(const Duration(days: 2)),
            totalSteps: 5000,
            activeEnergyKcal: 2000,
          ),
          DiaryHealthActivityTrendDay(
            day: selectedDay.subtract(const Duration(days: 1)),
            totalSteps: 20000,
            activeEnergyKcal: 1600,
          ),
        ],
      ),
      healthWeightService: _FakeHealthWeightService(
        const <HealthWeightSample>[],
      ),
    );

    expect(data.activityTrend[3], 0);
    expect(data.activityTrend[4], 200);
    expect(data.activityTrend[5], 1600);
    expect(data.activityTrend.last, 160);
  });

  test('caps unassigned active energy in activity totals', () async {
    final data = await service.load(
      day: selectedDay,
      profile: _profile,
      healthStatus: _readyStatus,
      manualEntries: const <ManualHealthWeightEntry>[],
      diaryHealthService: _FakeDiaryHealthService({
        diaryDayKey(selectedDay): DiaryHealthDayData(
          totalSteps: 5000,
          workouts: [_workout(selectedDay, totalCalories: 150)],
          unassignedActiveEnergySegments: [
            HealthEnergySegment(
              id: 'energy-1',
              start: selectedDay.add(const Duration(hours: 12)),
              endExclusive: selectedDay.add(
                const Duration(hours: 12, minutes: 20),
              ),
              durationMinutes: 20,
              sourceName: 'Health Connect',
              totalCalories: 90,
              totalSteps: 800,
            ),
          ],
        ),
      }),
      healthWeightService: _FakeHealthWeightService(
        const <HealthWeightSample>[],
      ),
    );

    expect(data.activityKcal, 310);
    expect(data.activeMinutes, 50);
    expect(data.activityTrend.last, 310);
  });

  test('uses Health Connect weights when manual entries are empty', () async {
    final data = await service.load(
      day: selectedDay,
      profile: _profile,
      healthStatus: _readyStatus,
      manualEntries: const <ManualHealthWeightEntry>[],
      diaryHealthService: _FakeDiaryHealthService(const {}),
      healthWeightService: _FakeHealthWeightService([
        HealthWeightSample(
          recordedAt: selectedDay.add(const Duration(hours: 7)),
          weightKg: 77.1,
          uuid: 'health-weight',
          sourcePackageName: 'external.app',
        ),
      ]),
    );

    expect(data.selectedWeightKg, 77.1);
    expect(data.hasSelectedDayWeight, isTrue);
    expect(data.weightDays.last.hasManualWeight, isFalse);
    expect(data.weightDays.last.hasAppOwnedHealthWeight, isFalse);
    expect(data.weightDays.last.canDeleteWeight, isFalse);
  });

  test('falls back to profile weight when no saved weight exists', () async {
    final data = await service.load(
      day: selectedDay,
      profile: _profile,
      healthStatus: _readyStatus,
      manualEntries: const <ManualHealthWeightEntry>[],
      diaryHealthService: _FakeDiaryHealthService(const {}),
      healthWeightService: _FakeHealthWeightService(
        const <HealthWeightSample>[],
      ),
    );

    expect(data.profileWeightKg, 80);
    expect(data.selectedWeightKg, 80);
    expect(data.hasSelectedDayWeight, isFalse);
    expect(data.weightTrend.last, isNull);
    expect(data.weightDays.last.canDeleteWeight, isFalse);
  });

  test(
    'manual weight overrides Health Connect weight for the same day',
    () async {
      final data = await service.load(
        day: selectedDay,
        profile: _profile,
        healthStatus: _readyStatus,
        manualEntries: [
          ManualHealthWeightEntry(day: selectedDay, weightKg: 76.8),
        ],
        diaryHealthService: _FakeDiaryHealthService(const {}),
        healthWeightService: _FakeHealthWeightService([
          HealthWeightSample(
            recordedAt: selectedDay.add(const Duration(hours: 7)),
            weightKg: 77.1,
            uuid: 'health-weight',
            sourcePackageName: 'de.yamt.app',
            isFromThisApp: true,
          ),
        ]),
      );

      expect(data.selectedWeightKg, 76.8);
      expect(data.weightTrend.last, 76.8);
      expect(data.weightDays.last.hasManualWeight, isTrue);
      expect(data.weightDays.last.hasAppOwnedHealthWeight, isTrue);
      expect(data.weightDays.last.healthSample?.weightKg, 77.1);
    },
  );

  test('keeps partial data when health access calls fail', () async {
    final previousDay = selectedDay.subtract(const Duration(days: 1));
    final data = await service.load(
      day: selectedDay,
      profile: _profile,
      healthStatus: _readyStatus,
      manualEntries: [
        ManualHealthWeightEntry(day: selectedDay, weightKg: 76.8),
      ],
      diaryHealthService: _FakeDiaryHealthService(
        {
          diaryDayKey(selectedDay): const DiaryHealthDayData(
            totalSteps: 4000,
            workouts: [],
          ),
        },
        failingDays: {diaryDayKey(previousDay)},
      ),
      healthWeightService: _FakeHealthWeightService(
        const <HealthWeightSample>[],
        shouldThrow: true,
      ),
    );

    expect(data.activityTrend[5], 0);
    expect(data.activityTrend.last, 160);
    expect(data.activityKcal, 160);
    expect(data.selectedWeightKg, 76.8);
    expect(data.hasSelectedDayWeight, isTrue);
  });

  test('does not swallow fatal health service errors', () async {
    await expectLater(
      service.load(
        day: selectedDay,
        profile: _profile,
        healthStatus: _readyStatus,
        manualEntries: const <ManualHealthWeightEntry>[],
        diaryHealthService: _FakeDiaryHealthService(
          const {},
          failingDays: {diaryDayKey(selectedDay)},
          error: StateError('load failed'),
        ),
        healthWeightService: _FakeHealthWeightService(
          const <HealthWeightSample>[],
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('stops loading trend days after cancellation', () async {
    var loadCount = 0;
    final healthService = _FakeDiaryHealthService(
      {
        diaryDayKey(selectedDay): const DiaryHealthDayData(
          totalSteps: 4000,
          workouts: [],
        ),
      },
      onLoad: () {
        loadCount += 1;
      },
    );

    await expectLater(
      service.load(
        day: selectedDay,
        profile: _profile,
        healthStatus: _readyStatus,
        manualEntries: const <ManualHealthWeightEntry>[],
        diaryHealthService: healthService,
        healthWeightService: _FakeHealthWeightService(
          const <HealthWeightSample>[],
        ),
        isCancelled: () => loadCount >= 1,
      ),
      throwsA(isA<StateError>()),
    );

    expect(loadCount, 1);
  });
}

const _readyStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.granted,
);

const _profile = DiaryActivityWeightProfile(weightKg: 80, heightCm: 180);

HealthWorkoutSession _workout(
  DateTime day, {
  required int totalCalories,
}) {
  return HealthWorkoutSession(
    id: 'workout',
    start: day.add(const Duration(hours: 7)),
    endExclusive: day.add(const Duration(hours: 7, minutes: 30)),
    durationMinutes: 30,
    activityLabel: 'Walk',
    sourceName: 'Health Connect',
    totalCalories: totalCalories,
    totalSteps: 1000,
  );
}

class _FakeTrendDiaryHealthService extends _FakeDiaryHealthService
    implements DiaryHealthActivityTrendService {
  _FakeTrendDiaryHealthService(
    super.dataByDay, {
    required this.trendDays,
    super.onLoad,
  });

  final List<DiaryHealthActivityTrendDay> trendDays;

  @override
  Future<List<DiaryHealthActivityTrendDay>> loadActivityTrendDays({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    return trendDays
        .where(
          (day) =>
              !day.day.isBefore(startInclusive) &&
              day.day.isBefore(endExclusive),
        )
        .toList(growable: false);
  }
}

class _FakeDiaryHealthService implements DiaryHealthService {
  _FakeDiaryHealthService(
    this.dataByDay, {
    this.failingDays = const <String>{},
    this.error,
    this.onLoad,
  });

  final Map<String, DiaryHealthDayData> dataByDay;
  final Set<String> failingDays;
  final Error? error;
  final void Function()? onLoad;

  @override
  Future<DiaryHealthDayData> loadDayData({
    required DateTime day,
    double? userHeightCm,
  }) async {
    onLoad?.call();
    final key = diaryDayKey(day);
    if (failingDays.contains(key)) {
      final error = this.error;
      if (error != null) {
        throw error;
      }
      throw Exception('load failed');
    }
    return dataByDay[key] ??
        const DiaryHealthDayData(totalSteps: 0, workouts: []);
  }
}

class _FakeHealthWeightService implements HealthWeightService {
  _FakeHealthWeightService(this.samples, {this.shouldThrow = false});

  final List<HealthWeightSample> samples;
  final bool shouldThrow;

  @override
  Future<List<HealthWeightSample>> loadWeightSamples({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    if (shouldThrow) {
      throw Exception('weight load failed');
    }
    return samples
        .where(
          (sample) =>
              !sample.recordedAt.isBefore(startInclusive) &&
              sample.recordedAt.isBefore(endExclusive),
        )
        .toList(growable: false);
  }

  @override
  Future<bool> deleteWeightSample(HealthWeightSample sample) async => true;

  @override
  Future<bool> saveWeightSample({
    required DateTime recordedAt,
    required double weightKg,
  }) async {
    return true;
  }
}
