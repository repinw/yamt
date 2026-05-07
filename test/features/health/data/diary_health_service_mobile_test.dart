import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/health/data/diary_health_service_mobile.dart';

void main() {
  test('loadDayData caches repeated same-day reads', () async {
    final day = DateTime(2026, 4, 17);
    final dayEnd = day.add(const Duration(days: 1));
    final fakeHealth = _FakeHealth(
      healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{
        HealthDataType.WORKOUT: <HealthDataPoint>[],
        HealthDataType.ACTIVE_ENERGY_BURNED: <HealthDataPoint>[],
      },
      totalStepsResponses: <String, int?>{
        _intervalKey(day, dayEnd): 6772,
      },
    );
    final service = MobileDiaryHealthService(
      health: fakeHealth,
      now: () => DateTime(2026, 4, 27, 12),
    );

    final firstRead = await service.loadDayData(day: day);
    final secondRead = await service.loadDayData(day: day);

    expect(firstRead.totalSteps, 6772);
    expect(secondRead.totalSteps, 6772);
    expect(fakeHealth.requestedStepIntervals, <String>[
      _intervalKey(day, dayEnd),
    ]);
  });

  test('loadDayData coalesces concurrent same-day reads', () async {
    final day = DateTime(2026, 4, 17);
    final dayEnd = day.add(const Duration(days: 1));
    final configureCompleter = Completer<void>();
    final fakeHealth = _FakeHealth(
      configureCompleter: configureCompleter,
      healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{
        HealthDataType.WORKOUT: <HealthDataPoint>[],
        HealthDataType.ACTIVE_ENERGY_BURNED: <HealthDataPoint>[],
      },
      totalStepsResponses: <String, int?>{
        _intervalKey(day, dayEnd): 6772,
      },
    );
    final service = MobileDiaryHealthService(health: fakeHealth);

    final firstRead = service.loadDayData(day: day);
    final secondRead = service.loadDayData(day: day);

    expect(fakeHealth.configureCalls, 1);
    configureCompleter.complete();
    final reads = await Future.wait([
      firstRead,
      secondRead,
    ]);

    expect(reads, hasLength(2));
    expect(fakeHealth.requestedStepIntervals, <String>[
      _intervalKey(day, dayEnd),
    ]);
    expect(fakeHealth.requestedHealthDataTypes, hasLength(2));
  });

  test('loadDayData retries after in-flight health read fails', () async {
    final day = DateTime(2026, 4, 17);
    final dayEnd = day.add(const Duration(days: 1));
    final fakeHealth = _FakeHealth(
      healthDataFailuresRemaining: 1,
      healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{
        HealthDataType.WORKOUT: <HealthDataPoint>[],
        HealthDataType.ACTIVE_ENERGY_BURNED: <HealthDataPoint>[],
      },
      totalStepsResponses: <String, int?>{
        _intervalKey(day, dayEnd): 6772,
      },
    );
    final service = MobileDiaryHealthService(health: fakeHealth);

    await expectLater(
      service.loadDayData(day: day),
      throwsA(isA<StateError>()),
    );
    final retryRead = await service.loadDayData(day: day);

    expect(retryRead.totalSteps, 6772);
    expect(fakeHealth.requestedStepIntervals, <String>[
      _intervalKey(day, dayEnd),
      _intervalKey(day, dayEnd),
    ]);
    expect(fakeHealth.requestedHealthDataTypes, <List<HealthDataType>>[
      <HealthDataType>[HealthDataType.WORKOUT],
      <HealthDataType>[HealthDataType.WORKOUT],
      <HealthDataType>[HealthDataType.ACTIVE_ENERGY_BURNED],
    ]);
  });

  test('loadDayData refreshes cache after ttl expires', () async {
    final day = DateTime(2026, 4, 17);
    final dayEnd = day.add(const Duration(days: 1));
    var now = DateTime(2026, 4, 27, 12);
    final totalStepsResponses = <String, int?>{
      _intervalKey(day, dayEnd): 6772,
    };
    final fakeHealth = _FakeHealth(
      healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{
        HealthDataType.WORKOUT: <HealthDataPoint>[],
        HealthDataType.ACTIVE_ENERGY_BURNED: <HealthDataPoint>[],
      },
      totalStepsResponses: totalStepsResponses,
    );
    final service = MobileDiaryHealthService(
      health: fakeHealth,
      now: () => now,
    );

    final firstRead = await service.loadDayData(day: day);
    totalStepsResponses[_intervalKey(day, dayEnd)] = 7000;
    now = now.add(const Duration(minutes: 6));
    final secondRead = await service.loadDayData(day: day);

    expect(firstRead.totalSteps, 6772);
    expect(secondRead.totalSteps, 7000);
    expect(fakeHealth.requestedStepIntervals, <String>[
      _intervalKey(day, dayEnd),
      _intervalKey(day, dayEnd),
    ]);
  });

  test('loadDayData evicts old entries when cache reaches cap', () async {
    var now = DateTime(2026, 4, 27, 12);
    final totalStepsResponses = <String, int?>{};
    for (var offset = 0; offset < 31; offset += 1) {
      final day = DateTime(2026, 4, 1 + offset);
      totalStepsResponses[_intervalKey(day, day.add(const Duration(days: 1)))] =
          6000 + offset;
    }
    final fakeHealth = _FakeHealth(
      healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{
        HealthDataType.WORKOUT: <HealthDataPoint>[],
        HealthDataType.ACTIVE_ENERGY_BURNED: <HealthDataPoint>[],
      },
      totalStepsResponses: totalStepsResponses,
    );
    final service = MobileDiaryHealthService(
      health: fakeHealth,
      now: () => now,
    );

    for (var offset = 0; offset < 31; offset += 1) {
      now = now.add(const Duration(seconds: 1));
      await service.loadDayData(day: DateTime(2026, 4, 1 + offset));
    }
    final firstDay = DateTime(2026, 4);
    final lastDay = DateTime(2026, 5);
    await service.loadDayData(day: firstDay);
    await service.loadDayData(day: lastDay);

    expect(
      fakeHealth.requestedStepIntervals.where(
        (key) =>
            key ==
            _intervalKey(firstDay, firstDay.add(const Duration(days: 1))),
      ),
      hasLength(2),
    );
    expect(
      fakeHealth.requestedStepIntervals.where(
        (key) =>
            key == _intervalKey(lastDay, lastDay.add(const Duration(days: 1))),
      ),
      hasLength(1),
    );
  });

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
    'loadDayData keeps unassigned active energy out of workouts',
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
          _intervalKey(energyStart, energyEnd): 1000,
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
        unassignedActiveEnergyCalories: summary.unassignedActiveEnergySegments
            .map((segment) => segment.totalCalories),
      );

      expect(dayData.workouts, isEmpty);
      expect(dayData.unassignedActiveEnergySegments, hasLength(1));
      expect(dayData.unassignedActiveEnergySegments.single.totalCalories, 500);
      expect(dayData.unassignedActiveEnergySegments.single.totalSteps, 1000);
      expect(summary.stepsDuringWorkouts, 0);
      expect(summary.stepsDuringUnassignedActiveEnergy, 1000);
      expect(summary.stepsOutsideWorkouts, 3000);
      expect(burnedCalories, 620);
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
      expect(dayData.unassignedActiveEnergySegments, isEmpty);
      expect(fakeHealth.requestedStepIntervals, <String>[
        _intervalKey(day, dayEnd),
      ]);
    },
  );

  test(
    'loadDayData splits active energy around covered workout intervals',
    () async {
      final day = DateTime(2026, 4, 17);
      final dayEnd = day.add(const Duration(days: 1));
      final workoutStart = day.add(const Duration(hours: 10));
      final workoutEnd = day.add(const Duration(hours: 11));
      final energyEnd = day.add(const Duration(hours: 12));
      final fakeHealth = _FakeHealth(
        healthDataPoints: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.WORKOUT: <HealthDataPoint>[
            _buildWorkoutPoint(
              start: workoutStart,
              end: workoutEnd,
              totalCalories: 999,
              totalSteps: 1200,
            ),
          ],
          HealthDataType.ACTIVE_ENERGY_BURNED: <HealthDataPoint>[
            _buildActiveEnergyPoint(
              start: workoutStart,
              end: energyEnd,
              calories: 600,
            ),
          ],
        },
        totalStepsResponses: <String, int?>{
          _intervalKey(day, dayEnd): 3000,
          _intervalKey(workoutEnd, energyEnd): 500,
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
        unassignedActiveEnergyCalories: summary.unassignedActiveEnergySegments
            .map((segment) => segment.totalCalories),
      );

      expect(dayData.workouts.single.totalCalories, 300);
      expect(dayData.unassignedActiveEnergySegments, hasLength(1));
      expect(dayData.unassignedActiveEnergySegments.single.totalCalories, 300);
      expect(dayData.unassignedActiveEnergySegments.single.totalSteps, 500);
      expect(summary.stepsOutsideWorkouts, 1300);
      expect(burnedCalories, 652);
      expect(fakeHealth.requestedStepIntervals, <String>[
        _intervalKey(day, dayEnd),
        _intervalKey(workoutEnd, energyEnd),
      ]);
    },
  );

  test(
    'loadDayData allocates overlapping active energy once across workouts',
    () async {
      final day = DateTime(2026, 4, 17);
      final dayEnd = day.add(const Duration(days: 1));
      final firstWorkoutStart = day.add(const Duration(hours: 10));
      final firstWorkoutEnd = day.add(const Duration(hours: 11));
      final secondWorkoutStart = day.add(
        const Duration(hours: 10, minutes: 30),
      );
      final secondWorkoutEnd = day.add(
        const Duration(hours: 11, minutes: 30),
      );
      final fakeHealth = _FakeHealth(
        healthDataPoints: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.WORKOUT: <HealthDataPoint>[
            _buildWorkoutPoint(
              uuid: 'workout-1',
              start: firstWorkoutStart,
              end: firstWorkoutEnd,
              totalCalories: 999,
            ),
            _buildWorkoutPoint(
              uuid: 'workout-2',
              start: secondWorkoutStart,
              end: secondWorkoutEnd,
              totalCalories: 999,
            ),
          ],
          HealthDataType.ACTIVE_ENERGY_BURNED: <HealthDataPoint>[
            _buildActiveEnergyPoint(
              start: firstWorkoutStart,
              end: secondWorkoutEnd,
              calories: 900,
            ),
          ],
        },
        totalStepsResponses: <String, int?>{
          _intervalKey(day, dayEnd): 0,
        },
      );
      final service = MobileDiaryHealthService(health: fakeHealth);

      final dayData = await service.loadDayData(day: day);
      final totalWorkoutCalories = dayData.workouts.fold<int>(
        0,
        (sum, workout) => sum + (workout.totalCalories ?? 0),
      );

      expect(dayData.workouts, hasLength(2));
      expect(
        dayData.workouts.map((workout) => workout.totalCalories),
        unorderedEquals(<int>[600, 300]),
      );
      expect(totalWorkoutCalories, 900);
    },
  );

  test(
    'loadDayData ignores low unassigned active energy without steps',
    () async {
      final day = DateTime(2026, 4, 17);
      final dayEnd = day.add(const Duration(days: 1));
      final energyStart = day.add(const Duration(hours: 12));
      final energyEnd = day.add(const Duration(hours: 12, minutes: 30));
      final fakeHealth = _FakeHealth(
        healthDataPoints: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.WORKOUT: const <HealthDataPoint>[],
          HealthDataType.ACTIVE_ENERGY_BURNED: <HealthDataPoint>[
            _buildActiveEnergyPoint(
              start: energyStart,
              end: energyEnd,
              calories: 30,
            ),
          ],
        },
        totalStepsResponses: <String, int?>{
          _intervalKey(day, dayEnd): 0,
          _intervalKey(energyStart, energyEnd): 0,
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
        unassignedActiveEnergyCalories: summary.unassignedActiveEnergySegments
            .map((segment) => segment.totalCalories),
      );

      expect(dayData.workouts, isEmpty);
      expect(dayData.unassignedActiveEnergySegments, isEmpty);
      expect(summary.stepsOutsideWorkouts, 0);
      expect(burnedCalories, 0);
    },
  );

  test(
    'loadDayData keeps high unassigned active energy without steps',
    () async {
      final day = DateTime(2026, 4, 17);
      final dayEnd = day.add(const Duration(days: 1));
      final energyStart = day.add(const Duration(hours: 12));
      final energyEnd = day.add(const Duration(hours: 13));
      final fakeHealth = _FakeHealth(
        healthDataPoints: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.WORKOUT: const <HealthDataPoint>[],
          HealthDataType.ACTIVE_ENERGY_BURNED: <HealthDataPoint>[
            _buildActiveEnergyPoint(
              start: energyStart,
              end: energyEnd,
              calories: 300,
            ),
          ],
        },
        totalStepsResponses: <String, int?>{
          _intervalKey(day, dayEnd): 0,
          _intervalKey(energyStart, energyEnd): 0,
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
        unassignedActiveEnergyCalories: summary.unassignedActiveEnergySegments
            .map((segment) => segment.totalCalories),
      );

      expect(dayData.workouts, isEmpty);
      expect(dayData.unassignedActiveEnergySegments, hasLength(1));
      expect(dayData.unassignedActiveEnergySegments.single.totalCalories, 300);
      expect(dayData.unassignedActiveEnergySegments.single.totalSteps, isNull);
      expect(burnedCalories, 300);
    },
  );
}

class _FakeHealth extends Health {
  _FakeHealth({
    required this.healthDataPoints,
    required this.totalStepsResponses,
    this.configureCompleter,
    this.healthDataFailuresRemaining = 0,
  });

  final Map<HealthDataType, List<HealthDataPoint>> healthDataPoints;
  final Map<String, int?> totalStepsResponses;
  final Completer<void>? configureCompleter;
  int healthDataFailuresRemaining;
  final List<String> requestedStepIntervals = <String>[];
  final List<List<HealthDataType>> requestedHealthDataTypes =
      <List<HealthDataType>>[];
  int configureCalls = 0;

  @override
  Future<void> configure() async {
    configureCalls += 1;
    await configureCompleter?.future;
  }

  @override
  Future<List<HealthDataPoint>> getHealthDataFromTypes({
    required List<HealthDataType> types,
    required DateTime startTime,
    required DateTime endTime,
    Map<HealthDataType, HealthDataUnit>? preferredUnits,
    List<RecordingMethod> recordingMethodsToFilter = const [],
  }) async {
    requestedHealthDataTypes.add(types);
    if (healthDataFailuresRemaining > 0) {
      healthDataFailuresRemaining -= 1;
      throw StateError('health data read failed');
    }
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
  String uuid = 'run-1',
  HealthWorkoutActivityType activityType = HealthWorkoutActivityType.RUNNING,
  int? totalSteps,
  int? totalDistance,
  HealthDataUnit? totalDistanceUnit,
  bool keepNullDistanceUnit = false,
  int? workoutSummarySteps,
}) {
  return HealthDataPoint(
    uuid: uuid,
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
