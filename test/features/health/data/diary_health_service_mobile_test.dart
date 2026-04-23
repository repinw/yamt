import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/health/data/diary_health_service_mobile.dart';

void main() {
  test(
    'loadDayData prefers workout summary steps before inferring from distance',
    () async {
      final day = DateTime(2026, 4, 17);
      final dayEnd = day.add(const Duration(days: 1));
      final workoutStart = day.add(const Duration(hours: 18, minutes: 5));
      final workoutEnd = day.add(const Duration(hours: 18, minutes: 41));
      final fakeHealth = _FakeHealth(
        healthDataPoints: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.WORKOUT: <HealthDataPoint>[
            _buildWorkoutPoint(
              start: workoutStart,
              end: workoutEnd,
              totalCalories: 422,
              totalDistance: 5168,
              workoutSummarySteps: 5367,
            ),
          ],
          HealthDataType.ACTIVE_ENERGY_BURNED: const <HealthDataPoint>[],
        },
        totalStepsResponses: <String, int?>{
          _intervalKey(day, dayEnd): 6772,
        },
      );
      final service = MobileDiaryHealthService(health: fakeHealth);

      final dayData = await service.loadDayData(day: day);
      final summary = buildDiaryActivitySummary(day: day, dayData: dayData);

      expect(dayData.workouts.single.totalSteps, 5367);
      expect(summary.stepsDuringWorkouts, 5367);
      expect(summary.stepsOutsideWorkouts, 1405);
      expect(fakeHealth.requestedStepIntervals, <String>[
        _intervalKey(day, dayEnd),
      ]);
    },
  );

  test(
    'loadDayData preserves workout steps already present in the payload',
    () async {
      final day = DateTime(2026, 4, 17);
      final dayEnd = day.add(const Duration(days: 1));
      final workoutStart = day.add(const Duration(hours: 18));
      final workoutEnd = day.add(const Duration(hours: 19));
      final fakeHealth = _FakeHealth(
        healthDataPoints: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.WORKOUT: <HealthDataPoint>[
            _buildWorkoutPoint(
              start: workoutStart,
              end: workoutEnd,
              totalCalories: 240,
              totalSteps: 2800,
              totalDistance: 5000,
            ),
          ],
          HealthDataType.ACTIVE_ENERGY_BURNED: const <HealthDataPoint>[],
        },
        totalStepsResponses: <String, int?>{
          _intervalKey(day, dayEnd): 6700,
        },
      );
      final service = MobileDiaryHealthService(health: fakeHealth);

      final dayData = await service.loadDayData(day: day);
      final summary = buildDiaryActivitySummary(day: day, dayData: dayData);

      expect(dayData.workouts.single.totalSteps, 2800);
      expect(summary.stepsDuringWorkouts, 2800);
      expect(summary.stepsOutsideWorkouts, 3900);
      expect(fakeHealth.requestedStepIntervals, <String>[
        _intervalKey(day, dayEnd),
      ]);
    },
  );

  test(
    'loadDayData estimates running steps from distance when steps are zero',
    () async {
      final day = DateTime(2026, 4, 17);
      final dayEnd = day.add(const Duration(days: 1));
      final workoutStart = day.add(const Duration(hours: 18, minutes: 5));
      final workoutEnd = day.add(const Duration(hours: 18, minutes: 41));
      final fakeHealth = _FakeHealth(
        healthDataPoints: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.WORKOUT: <HealthDataPoint>[
            _buildWorkoutPoint(
              start: workoutStart,
              end: workoutEnd,
              totalCalories: 422,
              totalDistance: 5168,
              totalSteps: 0,
            ),
          ],
          HealthDataType.ACTIVE_ENERGY_BURNED: const <HealthDataPoint>[],
        },
        totalStepsResponses: <String, int?>{
          _intervalKey(day, dayEnd): 6700,
        },
      );
      final service = MobileDiaryHealthService(health: fakeHealth);

      final dayData = await service.loadDayData(day: day);
      final summary = buildDiaryActivitySummary(day: day, dayData: dayData);

      expect(dayData.workouts.single.totalSteps, 6080);
      expect(summary.stepsDuringWorkouts, 6080);
      expect(summary.stepsOutsideWorkouts, 620);
      expect(fakeHealth.requestedStepIntervals, <String>[
        _intervalKey(day, dayEnd),
      ]);
    },
  );

  test(
    'loadDayData personalizes distance estimate from saved height',
    () async {
      final day = DateTime(2026, 4, 17);
      final dayEnd = day.add(const Duration(days: 1));
      final workoutStart = day.add(const Duration(hours: 18, minutes: 5));
      final workoutEnd = day.add(const Duration(hours: 18, minutes: 41));
      final fakeHealth = _FakeHealth(
        healthDataPoints: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.WORKOUT: <HealthDataPoint>[
            _buildWorkoutPoint(
              start: workoutStart,
              end: workoutEnd,
              totalCalories: 422,
              totalDistance: 5168,
            ),
          ],
          HealthDataType.ACTIVE_ENERGY_BURNED: const <HealthDataPoint>[],
        },
        totalStepsResponses: <String, int?>{
          _intervalKey(day, dayEnd): 6700,
        },
      );
      final service = MobileDiaryHealthService(health: fakeHealth);

      final dayData = await service.loadDayData(day: day, userHeightCm: 160);
      final summary = buildDiaryActivitySummary(day: day, dayData: dayData);

      expect(dayData.workouts.single.totalSteps, 6840);
      expect(summary.stepsDuringWorkouts, 6840);
      expect(summary.stepsOutsideWorkouts, 0);
      expect(fakeHealth.requestedStepIntervals, <String>[
        _intervalKey(day, dayEnd),
      ]);
    },
  );

  test(
    'loadDayData clamps very small height to the minimum personalized height',
    () async {
      final day = DateTime(2026, 4, 17);
      final dayEnd = day.add(const Duration(days: 1));
      final workoutStart = day.add(const Duration(hours: 18, minutes: 5));
      final workoutEnd = day.add(const Duration(hours: 18, minutes: 41));
      final fakeHealth = _FakeHealth(
        healthDataPoints: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.WORKOUT: <HealthDataPoint>[
            _buildWorkoutPoint(
              start: workoutStart,
              end: workoutEnd,
              totalCalories: 422,
              totalDistance: 5168,
            ),
          ],
          HealthDataType.ACTIVE_ENERGY_BURNED: const <HealthDataPoint>[],
        },
        totalStepsResponses: <String, int?>{
          _intervalKey(day, dayEnd): 10000,
        },
      );
      final service = MobileDiaryHealthService(health: fakeHealth);

      final dayData = await service.loadDayData(day: day, userHeightCm: 50);

      expect(dayData.workouts.single.totalSteps, 9120);
    },
  );

  test(
    'loadDayData clamps very large height to the maximum personalized height',
    () async {
      final day = DateTime(2026, 4, 17);
      final dayEnd = day.add(const Duration(days: 1));
      final workoutStart = day.add(const Duration(hours: 18, minutes: 5));
      final workoutEnd = day.add(const Duration(hours: 18, minutes: 41));
      final fakeHealth = _FakeHealth(
        healthDataPoints: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.WORKOUT: <HealthDataPoint>[
            _buildWorkoutPoint(
              start: workoutStart,
              end: workoutEnd,
              totalCalories: 422,
              totalDistance: 5168,
            ),
          ],
          HealthDataType.ACTIVE_ENERGY_BURNED: const <HealthDataPoint>[],
        },
        totalStepsResponses: <String, int?>{
          _intervalKey(day, dayEnd): 5000,
        },
      );
      final service = MobileDiaryHealthService(health: fakeHealth);

      final dayData = await service.loadDayData(day: day, userHeightCm: 300);

      expect(dayData.workouts.single.totalSteps, 4378);
    },
  );

  test(
    'loadDayData treats zero and negative height as the default step length',
    () async {
      final day = DateTime(2026, 4, 17);
      final dayEnd = day.add(const Duration(days: 1));
      final workoutStart = day.add(const Duration(hours: 18, minutes: 5));
      final workoutEnd = day.add(const Duration(hours: 18, minutes: 41));
      final fakeHealth = _FakeHealth(
        healthDataPoints: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.WORKOUT: <HealthDataPoint>[
            _buildWorkoutPoint(
              start: workoutStart,
              end: workoutEnd,
              totalCalories: 422,
              totalDistance: 5168,
            ),
          ],
          HealthDataType.ACTIVE_ENERGY_BURNED: const <HealthDataPoint>[],
        },
        totalStepsResponses: <String, int?>{
          _intervalKey(day, dayEnd): 7000,
        },
      );
      final service = MobileDiaryHealthService(health: fakeHealth);

      final zeroHeightDayData = await service.loadDayData(
        day: day,
        userHeightCm: 0,
      );
      final negativeHeightDayData = await service.loadDayData(
        day: day,
        userHeightCm: -10,
      );

      expect(zeroHeightDayData.workouts.single.totalSteps, 6080);
      expect(negativeHeightDayData.workouts.single.totalSteps, 6080);
    },
  );

  test(
    'loadDayData does not estimate steps for non-step workouts with distance',
    () async {
      final day = DateTime(2026, 4, 17);
      final dayEnd = day.add(const Duration(days: 1));
      final workoutStart = day.add(const Duration(hours: 12));
      final workoutEnd = day.add(const Duration(hours: 13));
      final fakeHealth = _FakeHealth(
        healthDataPoints: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.WORKOUT: <HealthDataPoint>[
            _buildWorkoutPoint(
              start: workoutStart,
              end: workoutEnd,
              totalCalories: 600,
              totalSteps: 0,
              totalDistance: 25000,
              activityType: HealthWorkoutActivityType.BIKING,
            ),
          ],
          HealthDataType.ACTIVE_ENERGY_BURNED: const <HealthDataPoint>[],
        },
        totalStepsResponses: <String, int?>{
          _intervalKey(day, dayEnd): 4000,
        },
      );
      final service = MobileDiaryHealthService(health: fakeHealth);

      final dayData = await service.loadDayData(day: day);
      final summary = buildDiaryActivitySummary(day: day, dayData: dayData);

      expect(dayData.workouts.single.totalSteps, isNull);
      expect(summary.stepsDuringWorkouts, 0);
      expect(summary.stepsOutsideWorkouts, 4000);
    },
  );

  test(
    'loadDayData converts mile distance before estimating steps',
    () async {
      final day = DateTime(2026, 4, 17);
      final dayEnd = day.add(const Duration(days: 1));
      final workoutStart = day.add(const Duration(hours: 7));
      final workoutEnd = day.add(const Duration(hours: 8));
      final fakeHealth = _FakeHealth(
        healthDataPoints: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.WORKOUT: <HealthDataPoint>[
            _buildWorkoutPoint(
              start: workoutStart,
              end: workoutEnd,
              totalCalories: 350,
              totalDistance: 1,
              totalDistanceUnit: HealthDataUnit.MILE,
            ),
          ],
          HealthDataType.ACTIVE_ENERGY_BURNED: const <HealthDataPoint>[],
        },
        totalStepsResponses: <String, int?>{
          _intervalKey(day, dayEnd): 2500,
        },
      );
      final service = MobileDiaryHealthService(health: fakeHealth);

      final dayData = await service.loadDayData(day: day);
      final summary = buildDiaryActivitySummary(day: day, dayData: dayData);

      expect(dayData.workouts.single.totalSteps, 1893);
      expect(summary.stepsDuringWorkouts, 1893);
      expect(summary.stepsOutsideWorkouts, 607);
    },
  );

  test(
    'loadDayData leaves workout steps null when distance unit is missing',
    () async {
      final day = DateTime(2026, 4, 17);
      final dayEnd = day.add(const Duration(days: 1));
      final workoutStart = day.add(const Duration(hours: 9));
      final workoutEnd = day.add(const Duration(hours: 10));
      final fakeHealth = _FakeHealth(
        healthDataPoints: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.WORKOUT: <HealthDataPoint>[
            _buildWorkoutPoint(
              start: workoutStart,
              end: workoutEnd,
              totalCalories: 300,
              totalSteps: 0,
              totalDistance: 5168,
              keepNullDistanceUnit: true,
            ),
          ],
          HealthDataType.ACTIVE_ENERGY_BURNED: const <HealthDataPoint>[],
        },
        totalStepsResponses: <String, int?>{
          _intervalKey(day, dayEnd): 2500,
        },
      );
      final service = MobileDiaryHealthService(health: fakeHealth);

      final dayData = await service.loadDayData(day: day);
      final summary = buildDiaryActivitySummary(day: day, dayData: dayData);

      expect(dayData.workouts.single.totalSteps, isNull);
      expect(summary.stepsDuringWorkouts, 0);
      expect(summary.stepsOutsideWorkouts, 2500);
    },
  );

  test(
    'loadDayData leaves workout steps null without a distance estimate',
    () async {
      final day = DateTime(2026, 4, 17);
      final dayEnd = day.add(const Duration(days: 1));
      final workoutStart = day.add(const Duration(hours: 9));
      final workoutEnd = day.add(const Duration(hours: 10));
      final fakeHealth = _FakeHealth(
        healthDataPoints: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.WORKOUT: <HealthDataPoint>[
            _buildWorkoutPoint(
              start: workoutStart,
              end: workoutEnd,
              totalCalories: 300,
              totalSteps: 0,
            ),
          ],
          HealthDataType.ACTIVE_ENERGY_BURNED: const <HealthDataPoint>[],
        },
        totalStepsResponses: <String, int?>{
          _intervalKey(day, dayEnd): 2500,
        },
      );
      final service = MobileDiaryHealthService(health: fakeHealth);

      final dayData = await service.loadDayData(day: day);
      final summary = buildDiaryActivitySummary(day: day, dayData: dayData);

      expect(dayData.workouts.single.totalSteps, isNull);
      expect(summary.stepsDuringWorkouts, 0);
      expect(summary.stepsOutsideWorkouts, 2500);
      expect(fakeHealth.requestedStepIntervals, <String>[
        _intervalKey(day, dayEnd),
      ]);
    },
  );

  test(
    'loadDayData creates standalone workout from active energy without workout',
    () async {
      final day = DateTime(2026, 4, 17);
      final dayEnd = day.add(const Duration(days: 1));
      final energyStart = day.add(const Duration(hours: 15));
      final energyEnd = day.add(const Duration(hours: 16));
      final fakeHealth = _FakeHealth(
        healthDataPoints: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.WORKOUT: const <HealthDataPoint>[],
          HealthDataType.ACTIVE_ENERGY_BURNED: <HealthDataPoint>[
            _buildActiveEnergyPoint(
              start: energyStart,
              end: energyEnd,
              calories: 500,
            ),
          ],
        },
        totalStepsResponses: <String, int?>{
          _intervalKey(day, dayEnd): 4000,
        },
      );
      final service = MobileDiaryHealthService(health: fakeHealth);

      final dayData = await service.loadDayData(day: day);
      final summary = buildDiaryActivitySummary(day: day, dayData: dayData);
      final burnedCalories = calculateDiaryBurnedCalories(
        stepsOutsideWorkouts: summary.stepsOutsideWorkouts,
        workoutCalories: summary.workouts.map(
          (workout) => workout.totalCalories,
        ),
      );

      expect(dayData.workouts, hasLength(1));
      expect(dayData.workouts.single.activityLabel, isNull);
      expect(dayData.workouts.single.totalCalories, 500);
      expect(dayData.workouts.single.totalSteps, isNull);
      expect(summary.stepsDuringWorkouts, 0);
      expect(summary.stepsOutsideWorkouts, 4000);
      expect(burnedCalories, 660);
    },
  );

  test(
    'loadDayData does not duplicate active energy already covered by workout',
    () async {
      final day = DateTime(2026, 4, 17);
      final dayEnd = day.add(const Duration(days: 1));
      final workoutStart = day.add(const Duration(hours: 18));
      final workoutEnd = day.add(const Duration(hours: 19));
      final fakeHealth = _FakeHealth(
        healthDataPoints: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.WORKOUT: <HealthDataPoint>[
            _buildWorkoutPoint(
              start: workoutStart,
              end: workoutEnd,
              totalCalories: 240,
              totalSteps: 2800,
            ),
          ],
          HealthDataType.ACTIVE_ENERGY_BURNED: <HealthDataPoint>[
            _buildActiveEnergyPoint(
              start: workoutStart,
              end: workoutEnd,
              calories: 500,
            ),
          ],
        },
        totalStepsResponses: <String, int?>{
          _intervalKey(day, dayEnd): 6700,
        },
      );
      final service = MobileDiaryHealthService(health: fakeHealth);

      final dayData = await service.loadDayData(day: day);

      expect(dayData.workouts, hasLength(1));
      expect(dayData.workouts.single.totalCalories, 500);
    },
  );
}

class _FakeHealth extends Health {
  _FakeHealth({
    required this.healthDataPoints,
    required this.totalStepsResponses,
  });

  final Map<HealthDataType, List<HealthDataPoint>> healthDataPoints;
  final Map<String, int?> totalStepsResponses;
  final List<String> requestedStepIntervals = <String>[];

  @override
  Future<void> configure() async {}

  @override
  Future<List<HealthDataPoint>> getHealthDataFromTypes({
    required List<HealthDataType> types,
    required DateTime startTime,
    required DateTime endTime,
    Map<HealthDataType, HealthDataUnit>? preferredUnits,
    List<RecordingMethod> recordingMethodsToFilter = const [],
  }) async {
    return types
        .expand((type) => healthDataPoints[type] ?? const <HealthDataPoint>[])
        .toList(growable: false);
  }

  @override
  Future<int?> getTotalStepsInInterval(
    DateTime startTime,
    DateTime endTime, {
    bool includeManualEntry = true,
  }) async {
    final key = _intervalKey(startTime, endTime);
    requestedStepIntervals.add(key);
    return totalStepsResponses[key];
  }
}

HealthDataPoint _buildWorkoutPoint({
  required DateTime start,
  required DateTime end,
  required int totalCalories,
  HealthWorkoutActivityType activityType = HealthWorkoutActivityType.RUNNING,
  int? totalSteps,
  int? totalDistance,
  HealthDataUnit? totalDistanceUnit,
  bool keepNullDistanceUnit = false,
  int? workoutSummarySteps,
}) {
  return HealthDataPoint(
    uuid: 'run-1',
    value: WorkoutHealthValue(
      workoutActivityType: activityType,
      totalEnergyBurned: totalCalories,
      totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
      totalDistance: totalDistance,
      totalDistanceUnit: totalDistance == null
          ? null
          : keepNullDistanceUnit
          ? totalDistanceUnit
          : totalDistanceUnit ?? HealthDataUnit.METER,
      totalSteps: totalSteps,
      totalStepsUnit: totalSteps == null ? null : HealthDataUnit.COUNT,
    ),
    type: HealthDataType.WORKOUT,
    unit: HealthDataUnit.NO_UNIT,
    dateFrom: start,
    dateTo: end,
    sourcePlatform: HealthPlatformType.googleHealthConnect,
    sourceDeviceId: 'device-id',
    sourceId: 'samsung.health',
    sourceName: 'Samsung Health',
    workoutSummary: workoutSummarySteps == null
        ? null
        : WorkoutSummary(
            workoutType: 'running',
            totalDistance: totalDistance ?? 0,
            totalEnergyBurned: totalCalories,
            totalSteps: workoutSummarySteps,
          ),
  );
}

HealthDataPoint _buildActiveEnergyPoint({
  required DateTime start,
  required DateTime end,
  required num calories,
}) {
  return HealthDataPoint(
    uuid: 'energy-${start.millisecondsSinceEpoch}',
    value: NumericHealthValue(numericValue: calories),
    type: HealthDataType.ACTIVE_ENERGY_BURNED,
    unit: HealthDataUnit.KILOCALORIE,
    dateFrom: start,
    dateTo: end,
    sourcePlatform: HealthPlatformType.appleHealth,
    sourceDeviceId: 'device-id',
    sourceId: 'apple.health',
    sourceName: 'Apple Health',
  );
}

String _intervalKey(DateTime start, DateTime end) {
  return '${start.millisecondsSinceEpoch}:${end.millisecondsSinceEpoch}';
}
