import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_health_trend_snapshot.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_health_trend_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_visible_window_controller.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/data/diary_health_service_provider.dart';
import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository.dart';
import 'package:yamt/features/health/data/'
    'manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_energy_segment.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

import '../support/fake_calories_repositories.dart';

const _readyStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.granted,
);

const _permissionRequiredStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.notGranted,
  historyAccess: HealthHistoryAccess.notGranted,
);

CalorieEntry _entry(
  String id, {
  required DateTime loggedAt,
  required double totalKcal,
}) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Item $id',
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: totalKcal,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 1,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

class _FakeHealthConnectionService implements HealthConnectionService {
  _FakeHealthConnectionService(this.status);

  final HealthConnectionStatus status;

  @override
  Future<HealthDisconnectResult> disconnect() async {
    return HealthDisconnectResult.disconnected;
  }

  @override
  Future<void> installHealthConnect() async {}

  @override
  Future<void> openAppPermissionSettings() async {}

  @override
  Future<void> openHealthPermissionSettings() async {}

  @override
  Future<HealthConnectionStatus> loadStatus() async => status;

  @override
  Future<HealthConnectionStatus> requestAuthorization() async => status;

  @override
  Future<HealthConnectionStatus> requestHistoryAuthorization() async => status;
}

class _FakeDiaryHealthService implements DiaryHealthService {
  _FakeDiaryHealthService(this.dataByDay);

  final Map<String, DiaryHealthDayData> dataByDay;

  @override
  Future<DiaryHealthDayData> loadDayData({
    required DateTime day,
    double? userHeightCm,
  }) async {
    return dataByDay[diaryDayKey(day)] ??
        const DiaryHealthDayData(totalSteps: 0, workouts: []);
  }
}

class _FakeHealthWeightService implements HealthWeightService {
  _FakeHealthWeightService(this.samples);

  final List<HealthWeightSample> samples;

  @override
  Future<List<HealthWeightSample>> loadWeightSamples({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    return samples
        .where(
          (sample) =>
              !sample.recordedAt.isBefore(startInclusive) &&
              sample.recordedAt.isBefore(endExclusive),
        )
        .toList(growable: false);
  }

  @override
  Future<bool> deleteWeightSample(HealthWeightSample sample) async {
    return true;
  }

  @override
  Future<bool> saveWeightSample({
    required DateTime recordedAt,
    required double weightKg,
  }) async {
    return true;
  }
}

class _FakeManualHealthWeightRepository
    implements ManualHealthWeightRepository {
  _FakeManualHealthWeightRepository(this.entries);

  final List<ManualHealthWeightEntry> entries;

  @override
  Future<bool> deleteEntryForDay(DateTime day) async => true;

  @override
  Future<List<ManualHealthWeightEntry>> readEntries() async => entries;

  @override
  Future<bool> saveEntry(ManualHealthWeightEntry entry) async => true;
}

void main() {
  test(
    'combines visible-week intake, burned calories, and latest weights',
    () async {
      final windowEnd = DateTime(2026, 3, 20);
      final firstVisibleDay = windowEnd.subtract(
        const Duration(days: diaryVisibleDayCount - 1),
      );
      final logRepository = FakeCalorieLogRepository(
        initialEntries: [
          _entry(
            'first-day',
            loggedAt: firstVisibleDay.add(const Duration(hours: 8)),
            totalKcal: 500,
          ),
          _entry(
            'last-day',
            loggedAt: windowEnd.add(const Duration(hours: 12)),
            totalKcal: 900,
          ),
        ],
      );
      addTearDown(logRepository.dispose);

      final diaryHealthService = _FakeDiaryHealthService({
        diaryDayKey(firstVisibleDay): const DiaryHealthDayData(
          totalSteps: 2000,
          workouts: [],
        ),
        diaryDayKey(windowEnd): DiaryHealthDayData(
          totalSteps: 6000,
          workouts: [
            HealthWorkoutSession(
              id: 'workout-1',
              start: windowEnd.add(const Duration(hours: 18)),
              endExclusive: windowEnd.add(
                const Duration(hours: 19, minutes: 15),
              ),
              durationMinutes: 75,
              activityLabel: 'Walk',
              sourceName: 'Health',
              totalCalories: 320,
              totalSteps: 2000,
            ),
          ],
          unassignedActiveEnergySegments: [
            HealthEnergySegment(
              id: 'energy-1',
              start: windowEnd.add(const Duration(hours: 16)),
              endExclusive: windowEnd.add(
                const Duration(hours: 16, minutes: 30),
              ),
              durationMinutes: 30,
              sourceName: 'Health',
              totalCalories: 100,
              totalSteps: 1000,
            ),
          ],
        ),
      });
      final weightService = _FakeHealthWeightService([
        HealthWeightSample(
          recordedAt: firstVisibleDay.add(const Duration(hours: 7)),
          weightKg: 71.2,
        ),
        HealthWeightSample(
          recordedAt: windowEnd.add(const Duration(hours: 8)),
          weightKg: 71,
        ),
        HealthWeightSample(
          recordedAt: windowEnd.add(const Duration(hours: 20)),
          weightKg: 70.8,
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
          healthConnectionServiceProvider.overrideWith(
            (ref) => _FakeHealthConnectionService(_readyStatus),
          ),
          diaryHealthServiceProvider.overrideWith((ref) => diaryHealthService),
          healthWeightServiceProvider.overrideWith((ref) => weightService),
          manualHealthWeightRepositoryProvider.overrideWith(
            (ref) => _FakeManualHealthWeightRepository(
              const <ManualHealthWeightEntry>[],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(calorieVisibleWindowControllerProvider.notifier)
          .setWindowEnd(windowEnd);

      final snapshot = await container.read(
        calorieHealthTrendSnapshotProvider.future,
      );

      expect(snapshot.healthAccessState, HealthDataAccessState.ready);
      expect(snapshot.healthPlatform, HealthPlatform.android);
      expect(snapshot.points, hasLength(diaryVisibleDayCount));
      expect(snapshot.points.first.day, firstVisibleDay);
      expect(snapshot.points.last.day, windowEnd);
      expect(snapshot.points.first.intakeKcal, 500);
      expect(snapshot.points.first.burnedKcal, 80);
      expect(snapshot.points.first.weightKg, 71.2);
      expect(
        snapshot.points.first.weightSource,
        CalorieHealthTrendWeightSource.health,
      );
      expect(snapshot.points.last.intakeKcal, 900);
      expect(snapshot.points.last.burnedKcal, 480);
      expect(snapshot.points.last.weightKg, 70.8);
      expect(
        snapshot.points.last.weightSource,
        CalorieHealthTrendWeightSource.health,
      );
      expect(snapshot.points[1].intakeKcal, 0);
      expect(snapshot.points[1].burnedKcal, 0);
      expect(snapshot.points[1].weightKg, isNull);
      expect(
        snapshot.points[1].weightSource,
        CalorieHealthTrendWeightSource.none,
      );
    },
  );

  test(
    'manual weights override imported health weights for same day',
    () async {
      final windowEnd = DateTime(2026, 3, 20);
      final logRepository = FakeCalorieLogRepository(
        initialEntries: [
          _entry(
            'intake-only',
            loggedAt: windowEnd.add(const Duration(hours: 8)),
            totalKcal: 750,
          ),
        ],
      );
      addTearDown(logRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
          healthConnectionServiceProvider.overrideWith(
            (ref) => _FakeHealthConnectionService(_readyStatus),
          ),
          diaryHealthServiceProvider.overrideWith(
            (ref) => _FakeDiaryHealthService({}),
          ),
          healthWeightServiceProvider.overrideWith(
            (ref) => _FakeHealthWeightService([
              HealthWeightSample(
                recordedAt: windowEnd.add(const Duration(hours: 7)),
                weightKg: 71.6,
              ),
            ]),
          ),
          manualHealthWeightRepositoryProvider.overrideWith(
            (ref) => _FakeManualHealthWeightRepository([
              ManualHealthWeightEntry(
                day: DateTime(2026, 3, 20),
                weightKg: 70.9,
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(calorieVisibleWindowControllerProvider.notifier)
          .setWindowEnd(windowEnd);

      final snapshot = await container.read(
        calorieHealthTrendSnapshotProvider.future,
      );

      expect(snapshot.points.last.weightKg, 70.9);
      expect(
        snapshot.points.last.weightSource,
        CalorieHealthTrendWeightSource.manual,
      );
    },
  );

  test('keeps intake only when health access is not ready', () async {
    final windowEnd = DateTime(2026, 3, 20);
    final logRepository = FakeCalorieLogRepository(
      initialEntries: [
        _entry(
          'intake-only',
          loggedAt: windowEnd.add(const Duration(hours: 8)),
          totalKcal: 750,
        ),
      ],
    );
    addTearDown(logRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        healthConnectionServiceProvider.overrideWith(
          (ref) => _FakeHealthConnectionService(_permissionRequiredStatus),
        ),
        diaryHealthServiceProvider.overrideWith(
          (ref) => _FakeDiaryHealthService({}),
        ),
        healthWeightServiceProvider.overrideWith(
          (ref) => _FakeHealthWeightService([]),
        ),
        manualHealthWeightRepositoryProvider.overrideWith(
          (ref) => _FakeManualHealthWeightRepository(
            const <ManualHealthWeightEntry>[],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(calorieVisibleWindowControllerProvider.notifier)
        .setWindowEnd(windowEnd);

    final snapshot = await container.read(
      calorieHealthTrendSnapshotProvider.future,
    );

    expect(
      snapshot.healthAccessState,
      HealthDataAccessState.permissionRequired,
    );
    expect(snapshot.points.last.intakeKcal, 750);
    expect(snapshot.points.last.burnedKcal, isNull);
    expect(snapshot.points.last.weightKg, isNull);
    expect(
      snapshot.points.last.weightSource,
      CalorieHealthTrendWeightSource.none,
    );
  });
}
