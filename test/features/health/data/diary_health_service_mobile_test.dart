import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:yamt/features/health/data/diary_health_service_mobile.dart';
import 'package:yamt/features/health/domain/diary_activity_summary.dart';

import '../../../helpers/memory_app_preferences.dart';

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
    await Future<void>.delayed(Duration.zero);

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

  test('loadDayData queues concurrent different-day reads', () async {
    final firstDay = DateTime(2026, 4, 17);
    final secondDay = DateTime(2026, 4, 18);
    final firstDayEnd = firstDay.add(const Duration(days: 1));
    final secondDayEnd = secondDay.add(const Duration(days: 1));
    final firstStepReadCompleter = Completer<void>();
    final fakeHealth = _FakeHealth(
      stepReadCompleters: <String, Completer<void>>{
        _intervalKey(firstDay, firstDayEnd): firstStepReadCompleter,
      },
      healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{
        HealthDataType.WORKOUT: <HealthDataPoint>[],
        HealthDataType.ACTIVE_ENERGY_BURNED: <HealthDataPoint>[],
      },
      totalStepsResponses: <String, int?>{
        _intervalKey(firstDay, firstDayEnd): 6772,
        _intervalKey(secondDay, secondDayEnd): 8123,
      },
    );
    final service = MobileDiaryHealthService(health: fakeHealth);

    final firstRead = service.loadDayData(day: firstDay);
    final secondRead = service.loadDayData(day: secondDay);
    await Future<void>.delayed(Duration.zero);

    expect(fakeHealth.requestedStepIntervals, <String>[
      _intervalKey(firstDay, firstDayEnd),
    ]);
    expect(fakeHealth.requestedHealthDataTypes, isEmpty);

    firstStepReadCompleter.complete();
    final reads = await Future.wait([firstRead, secondRead]);

    expect(reads.map((data) => data.totalSteps), <int>[6772, 8123]);
    expect(fakeHealth.requestedStepIntervals, <String>[
      _intervalKey(firstDay, firstDayEnd),
      _intervalKey(secondDay, secondDayEnd),
    ]);
    expect(fakeHealth.requestedHealthDataTypes, <List<HealthDataType>>[
      <HealthDataType>[HealthDataType.WORKOUT],
      <HealthDataType>[HealthDataType.ACTIVE_ENERGY_BURNED],
      <HealthDataType>[HealthDataType.WORKOUT],
      <HealthDataType>[HealthDataType.ACTIVE_ENERGY_BURNED],
    ]);
  });

  test(
    'loadActivityTrendDays includes workout kcal in trend buckets',
    () async {
      final firstDay = DateTime(2026, 4, 17);
      final secondDay = DateTime(2026, 4, 18);
      final endDay = DateTime(2026, 4, 19);
      final fakeHealth = _FakeHealth(
        intervalDataPoints: [
          _buildNumericPoint(
            type: HealthDataType.STEPS,
            unit: HealthDataUnit.COUNT,
            start: firstDay,
            end: secondDay,
            value: 4000,
          ),
          _buildNumericPoint(
            type: HealthDataType.ACTIVE_ENERGY_BURNED,
            unit: HealthDataUnit.KILOCALORIE,
            start: firstDay,
            end: secondDay,
            value: 220,
          ),
          _buildNumericPoint(
            type: HealthDataType.STEPS,
            unit: HealthDataUnit.COUNT,
            start: secondDay,
            end: endDay,
            value: 3000,
          ),
        ],
        healthDataPoints: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.WORKOUT: <HealthDataPoint>[
            _buildWorkoutPoint(
              start: firstDay.add(const Duration(hours: 18)),
              end: firstDay.add(const Duration(hours: 19)),
              totalCalories: 899,
            ),
          ],
          HealthDataType.ACTIVE_ENERGY_BURNED: <HealthDataPoint>[],
        },
        totalStepsResponses: const <String, int?>{},
      );
      final service = MobileDiaryHealthService(health: fakeHealth);

      final trendDays = await service.loadActivityTrendDays(
        startInclusive: firstDay,
        endExclusive: endDay,
      );

      expect(fakeHealth.requestedIntervalTypes, <List<HealthDataType>>[
        <HealthDataType>[
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
        ],
      ]);
      expect(fakeHealth.requestedHealthDataTypes, <List<HealthDataType>>[
        <HealthDataType>[HealthDataType.WORKOUT],
      ]);
      expect(trendDays.map((day) => day.day), <DateTime>[firstDay, secondDay]);
      expect(trendDays.map((day) => day.totalSteps), <int>[4000, 3000]);
      expect(trendDays.map((day) => day.activeEnergyKcal), <int>[899, 0]);
    },
  );

  test(
    'loadActivityTrendDays reads persisted trend before health connect',
    () async {
      final firstDay = DateTime(2026, 4, 17);
      final secondDay = DateTime(2026, 4, 18);
      final endDay = DateTime(2026, 4, 19);
      final preferences = MemoryAppPreferences();
      final fakeHealth = _FakeHealth(
        intervalDataPoints: [
          _buildNumericPoint(
            type: HealthDataType.STEPS,
            unit: HealthDataUnit.COUNT,
            start: firstDay,
            end: secondDay,
            value: 4000,
          ),
          _buildNumericPoint(
            type: HealthDataType.ACTIVE_ENERGY_BURNED,
            unit: HealthDataUnit.KILOCALORIE,
            start: firstDay,
            end: secondDay,
            value: 220,
          ),
          _buildNumericPoint(
            type: HealthDataType.STEPS,
            unit: HealthDataUnit.COUNT,
            start: secondDay,
            end: endDay,
            value: 3000,
          ),
        ],
        healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{},
        totalStepsResponses: const <String, int?>{},
      );
      final service = MobileDiaryHealthService(
        health: fakeHealth,
        preferences: preferences,
        now: () => DateTime(2026, 4, 27, 12),
      );

      final firstRead = await service.loadActivityTrendDays(
        startInclusive: firstDay,
        endExclusive: endDay,
      );
      final cachedHealth = _FakeHealth(
        healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{},
        totalStepsResponses: const <String, int?>{},
      );
      final cachedService = MobileDiaryHealthService(
        health: cachedHealth,
        preferences: preferences,
        now: () => DateTime(2026, 4, 27, 12, 1),
      );
      final cachedRead = await cachedService.loadActivityTrendDays(
        startInclusive: firstDay,
        endExclusive: endDay,
      );

      expect(firstRead.map((day) => day.totalSteps), <int>[4000, 3000]);
      expect(cachedRead.map((day) => day.totalSteps), <int>[4000, 3000]);
      expect(cachedRead.map((day) => day.activeEnergyKcal), <int>[220, 0]);
      expect(cachedHealth.configureCalls, 0);
      expect(cachedHealth.requestedIntervalTypes, isEmpty);
    },
  );

  test(
    'loadActivityTrendDays treats persisted zero trend as complete cache',
    () async {
      final day = DateTime(2026, 4, 17);
      final endDay = DateTime(2026, 4, 18);
      final preferences = MemoryAppPreferences();
      final service = MobileDiaryHealthService(
        health: _FakeHealth(
          healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{},
          totalStepsResponses: const <String, int?>{},
        ),
        preferences: preferences,
        now: () => DateTime(2026, 4, 27, 12),
      );

      final firstRead = await service.loadActivityTrendDays(
        startInclusive: day,
        endExclusive: endDay,
      );
      final cachedHealth = _FakeHealth(
        healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{},
        totalStepsResponses: const <String, int?>{},
      );
      final cachedService = MobileDiaryHealthService(
        health: cachedHealth,
        preferences: preferences,
        now: () => DateTime(2026, 4, 27, 12, 1),
      );
      final cachedRead = await cachedService.loadActivityTrendDays(
        startInclusive: day,
        endExclusive: endDay,
      );
      final indexValue = await preferences.getString(
        'diary_health_activity_trend_day_cache_v1:index',
      );

      expect(firstRead.single.totalSteps, 0);
      expect(firstRead.single.activeEnergyKcal, 0);
      expect(cachedRead.single.totalSteps, 0);
      expect(cachedRead.single.activeEnergyKcal, 0);
      expect(indexValue, contains('2026-4-17'));
      expect(cachedHealth.configureCalls, 0);
      expect(cachedHealth.requestedIntervalTypes, isEmpty);
    },
  );

  test('refreshActivityTrendDays bypasses fresh in-memory cache', () async {
    final day = DateTime(2026, 4, 27);
    final endDay = DateTime(2026, 4, 28);
    final intervalDataPoints = <HealthDataPoint>[
      _buildNumericPoint(
        type: HealthDataType.ACTIVE_ENERGY_BURNED,
        unit: HealthDataUnit.KILOCALORIE,
        start: day,
        end: endDay,
        value: 120,
      ),
    ];
    final fakeHealth = _FakeHealth(
      intervalDataPoints: intervalDataPoints,
      healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{},
      totalStepsResponses: const <String, int?>{},
    );
    final service = MobileDiaryHealthService(
      health: fakeHealth,
      now: () => DateTime(2026, 4, 27, 12),
    );

    final firstRead = await service.loadActivityTrendDays(
      startInclusive: day,
      endExclusive: endDay,
    );
    intervalDataPoints
      ..clear()
      ..add(
        _buildNumericPoint(
          type: HealthDataType.ACTIVE_ENERGY_BURNED,
          unit: HealthDataUnit.KILOCALORIE,
          start: day,
          end: endDay,
          value: 899,
        ),
      );
    final cachedRead = await service.loadActivityTrendDays(
      startInclusive: day,
      endExclusive: endDay,
    );
    final refreshedRead = await service.refreshActivityTrendDays(
      startInclusive: day,
      endExclusive: endDay,
    );
    intervalDataPoints.clear();
    final deletedRead = await service.refreshActivityTrendDays(
      startInclusive: day,
      endExclusive: endDay,
    );
    final cachedDeletedRead = await service.loadActivityTrendDays(
      startInclusive: day,
      endExclusive: endDay,
    );

    expect(firstRead.single.activeEnergyKcal, 120);
    expect(cachedRead.single.activeEnergyKcal, 120);
    expect(refreshedRead.single.activeEnergyKcal, 899);
    expect(deletedRead.single.activeEnergyKcal, 0);
    expect(cachedDeletedRead.single.activeEnergyKcal, 0);
    expect(fakeHealth.requestedIntervalTypes, hasLength(3));
  });

  test(
    'loadActivityTrendDays resets malformed persisted trend index',
    () async {
      final firstDay = DateTime(2026, 4, 17);
      final endDay = DateTime(2026, 4, 18);
      final preferences = MemoryAppPreferences(
        initialStrings: const <String, String>{
          'diary_health_activity_trend_day_cache_v1:index': '{bad',
        },
      );
      final fakeHealth = _FakeHealth(
        intervalDataPoints: [
          _buildNumericPoint(
            type: HealthDataType.STEPS,
            unit: HealthDataUnit.COUNT,
            start: firstDay,
            end: endDay,
            value: 4000,
          ),
        ],
        healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{},
        totalStepsResponses: const <String, int?>{},
      );
      final service = MobileDiaryHealthService(
        health: fakeHealth,
        preferences: preferences,
        now: () => DateTime(2026, 4, 27, 12),
      );

      final trendDays = await service.loadActivityTrendDays(
        startInclusive: firstDay,
        endExclusive: endDay,
      );
      final indexValue = await preferences.getString(
        'diary_health_activity_trend_day_cache_v1:index',
      );

      expect(trendDays.single.totalSteps, 4000);
      expect(indexValue, isNot('{bad'));
      expect(indexValue, contains('2026-4-17'));
    },
  );

  test(
    'loadActivityTrendDays uses expired persisted cache after failure',
    () async {
      final firstDay = DateTime(2026, 4, 17);
      final secondDay = DateTime(2026, 4, 18);
      final endDay = DateTime(2026, 4, 19);
      final preferences = MemoryAppPreferences();
      var now = DateTime(2026, 4, 27, 12);
      final fakeHealth = _FakeHealth(
        intervalDataPoints: [
          _buildNumericPoint(
            type: HealthDataType.STEPS,
            unit: HealthDataUnit.COUNT,
            start: firstDay,
            end: secondDay,
            value: 4000,
          ),
          _buildNumericPoint(
            type: HealthDataType.STEPS,
            unit: HealthDataUnit.COUNT,
            start: secondDay,
            end: endDay,
            value: 3000,
          ),
        ],
        healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{},
        totalStepsResponses: const <String, int?>{},
      );
      final service = MobileDiaryHealthService(
        health: fakeHealth,
        preferences: preferences,
        now: () => now,
      );

      final firstRead = await service.loadActivityTrendDays(
        startInclusive: firstDay,
        endExclusive: endDay,
      );
      now = now.add(const Duration(hours: 13));
      final failingHealth = _FakeHealth(
        intervalDataFailuresRemaining: 1,
        healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{},
        totalStepsResponses: const <String, int?>{},
      );
      final staleService = MobileDiaryHealthService(
        health: failingHealth,
        preferences: preferences,
        now: () => now,
      );
      final staleRead = await staleService.loadActivityTrendDays(
        startInclusive: firstDay,
        endExclusive: endDay,
      );
      await Future<void>.delayed(Duration.zero);

      expect(firstRead.map((day) => day.totalSteps), <int>[4000, 3000]);
      expect(staleRead.map((day) => day.totalSteps), <int>[4000, 3000]);
      expect(failingHealth.requestedIntervalTypes, <List<HealthDataType>>[
        <HealthDataType>[
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
        ],
      ]);
    },
  );

  test(
    'loadActivityTrendDays keeps expired persisted trend after empty refresh',
    () async {
      final firstDay = DateTime(2026, 4, 17);
      final secondDay = DateTime(2026, 4, 18);
      final endDay = DateTime(2026, 4, 19);
      final preferences = MemoryAppPreferences();
      var now = DateTime(2026, 4, 27, 12);
      final fakeHealth = _FakeHealth(
        intervalDataPoints: [
          _buildNumericPoint(
            type: HealthDataType.STEPS,
            unit: HealthDataUnit.COUNT,
            start: firstDay,
            end: secondDay,
            value: 4000,
          ),
          _buildNumericPoint(
            type: HealthDataType.STEPS,
            unit: HealthDataUnit.COUNT,
            start: secondDay,
            end: endDay,
            value: 3000,
          ),
        ],
        healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{},
        totalStepsResponses: const <String, int?>{},
      );
      final service = MobileDiaryHealthService(
        health: fakeHealth,
        preferences: preferences,
        now: () => now,
      );

      final firstRead = await service.loadActivityTrendDays(
        startInclusive: firstDay,
        endExclusive: endDay,
      );
      now = now.add(const Duration(hours: 13));
      final emptyHealth = _FakeHealth(
        healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{},
        totalStepsResponses: const <String, int?>{},
      );
      final staleService = MobileDiaryHealthService(
        health: emptyHealth,
        preferences: preferences,
        now: () => now,
      );
      final staleRead = await staleService.loadActivityTrendDays(
        startInclusive: firstDay,
        endExclusive: endDay,
      );
      await Future<void>.delayed(Duration.zero);
      final secondRead = await staleService.loadActivityTrendDays(
        startInclusive: firstDay,
        endExclusive: endDay,
      );

      expect(firstRead.map((day) => day.totalSteps), <int>[4000, 3000]);
      expect(staleRead.map((day) => day.totalSteps), <int>[4000, 3000]);
      expect(secondRead.map((day) => day.totalSteps), <int>[4000, 3000]);
      expect(emptyHealth.requestedIntervalTypes, <List<HealthDataType>>[
        <HealthDataType>[
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
        ],
      ]);
    },
  );

  test(
    'loadActivityTrendDays drops persisted cache after hard stale age',
    () async {
      final firstDay = DateTime(2026, 4, 17);
      final secondDay = DateTime(2026, 4, 18);
      final endDay = DateTime(2026, 4, 19);
      final preferences = MemoryAppPreferences();
      var now = DateTime(2026, 4, 27, 12);
      final fakeHealth = _FakeHealth(
        intervalDataPoints: [
          _buildNumericPoint(
            type: HealthDataType.STEPS,
            unit: HealthDataUnit.COUNT,
            start: firstDay,
            end: secondDay,
            value: 4000,
          ),
          _buildNumericPoint(
            type: HealthDataType.STEPS,
            unit: HealthDataUnit.COUNT,
            start: secondDay,
            end: endDay,
            value: 3000,
          ),
        ],
        healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{},
        totalStepsResponses: const <String, int?>{},
      );
      final service = MobileDiaryHealthService(
        health: fakeHealth,
        preferences: preferences,
        now: () => now,
      );

      final firstRead = await service.loadActivityTrendDays(
        startInclusive: firstDay,
        endExclusive: endDay,
      );
      now = now.add(const Duration(days: 8));
      final failingHealth = _FakeHealth(
        intervalDataFailuresRemaining: 1,
        healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{},
        totalStepsResponses: const <String, int?>{},
      );
      final staleService = MobileDiaryHealthService(
        health: failingHealth,
        preferences: preferences,
        now: () => now,
      );

      await expectLater(
        staleService.loadActivityTrendDays(
          startInclusive: firstDay,
          endExclusive: endDay,
        ),
        throwsA(isA<StateError>()),
      );

      expect(firstRead.map((day) => day.totalSteps), <int>[4000, 3000]);
      expect(failingHealth.requestedIntervalTypes, <List<HealthDataType>>[
        <HealthDataType>[
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
        ],
      ]);
    },
  );

  test(
    'loadActivityTrendDays evicts old persisted entries through index',
    () async {
      final preferences = MemoryAppPreferences();
      final fakeHealth = _FakeHealth(
        intervalDataPoints: [
          for (var offset = 0; offset < 31; offset += 1)
            _buildNumericPoint(
              type: HealthDataType.STEPS,
              unit: HealthDataUnit.COUNT,
              start: DateTime(2026, 4, 1 + offset),
              end: DateTime(2026, 4, 2 + offset),
              value: 1,
            ),
        ],
        healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{},
        totalStepsResponses: const <String, int?>{},
      );
      final service = MobileDiaryHealthService(
        health: fakeHealth,
        preferences: preferences,
        now: () => DateTime(2026, 4, 27, 12),
      );

      for (var offset = 0; offset < 31; offset += 1) {
        final day = DateTime(2026, 4, 1 + offset);
        await service.loadActivityTrendDays(
          startInclusive: day,
          endExclusive: day.add(const Duration(days: 1)),
        );
      }

      final firstDay = DateTime(2026, 4);
      final lastDay = DateTime(2026, 5);
      final reloadHealth = _FakeHealth(
        intervalDataPoints: [
          _buildNumericPoint(
            type: HealthDataType.STEPS,
            unit: HealthDataUnit.COUNT,
            start: firstDay,
            end: firstDay.add(const Duration(days: 1)),
            value: 9000,
          ),
        ],
        healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{},
        totalStepsResponses: const <String, int?>{},
      );
      final reloadService = MobileDiaryHealthService(
        health: reloadHealth,
        preferences: preferences,
        now: () => DateTime(2026, 4, 27, 12, 1),
      );

      final firstRead = await reloadService.loadActivityTrendDays(
        startInclusive: firstDay,
        endExclusive: firstDay.add(const Duration(days: 1)),
      );
      final lastRead = await reloadService.loadActivityTrendDays(
        startInclusive: lastDay,
        endExclusive: lastDay.add(const Duration(days: 1)),
      );

      expect(firstRead.single.totalSteps, 9000);
      expect(lastRead.single.totalSteps, 1);
      expect(reloadHealth.requestedIntervalTypes, hasLength(1));
    },
  );

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
    final day = DateTime(2026, 4, 27);
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
    await Future<void>.delayed(Duration.zero);
    final refreshedRead = await service.loadDayData(day: day);

    expect(firstRead.totalSteps, 6772);
    expect(secondRead.totalSteps, 6772);
    expect(refreshedRead.totalSteps, 7000);
    expect(fakeHealth.requestedStepIntervals, <String>[
      _intervalKey(day, dayEnd),
      _intervalKey(day, dayEnd),
    ]);
  });

  test('loadDayData keeps historical cache beyond today ttl', () async {
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
    expect(secondRead.totalSteps, 6772);
    expect(fakeHealth.requestedStepIntervals, <String>[
      _intervalKey(day, dayEnd),
    ]);
  });

  test('loadDayData persists derived day cache', () async {
    final day = DateTime(2026, 4, 17);
    final dayEnd = day.add(const Duration(days: 1));
    final workoutStart = day.add(const Duration(hours: 18));
    final workoutEnd = day.add(const Duration(hours: 19));
    final preferences = MemoryAppPreferences();
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
        HealthDataType.ACTIVE_ENERGY_BURNED: const <HealthDataPoint>[],
      },
      totalStepsResponses: <String, int?>{
        _intervalKey(day, dayEnd): 6772,
      },
    );
    final service = MobileDiaryHealthService(
      health: fakeHealth,
      preferences: preferences,
      now: () => DateTime(2026, 4, 27, 12),
    );

    final firstRead = await service.loadDayData(day: day);
    final cachedHealth = _FakeHealth(
      healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{
        HealthDataType.WORKOUT: <HealthDataPoint>[],
        HealthDataType.ACTIVE_ENERGY_BURNED: <HealthDataPoint>[],
      },
      totalStepsResponses: <String, int?>{
        _intervalKey(day, dayEnd): 8123,
      },
    );
    final cachedService = MobileDiaryHealthService(
      health: cachedHealth,
      preferences: preferences,
      now: () => DateTime(2026, 4, 27, 12, 1),
    );
    final cachedRead = await cachedService.loadDayData(day: day);

    expect(firstRead.totalSteps, 6772);
    expect(cachedRead.totalSteps, 6772);
    expect(cachedRead.workouts.single.totalCalories, 240);
    expect(cachedHealth.configureCalls, 0);
    expect(cachedHealth.requestedStepIntervals, isEmpty);
  });

  test(
    'refreshDayData overwrites persisted workout with empty Health day',
    () async {
      final day = DateTime(2026, 4, 17);
      final dayEnd = day.add(const Duration(days: 1));
      final workoutStart = day.add(const Duration(hours: 18));
      final workoutEnd = day.add(const Duration(hours: 19));
      final preferences = MemoryAppPreferences();
      final fakeHealth = _FakeHealth(
        healthDataPoints: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.WORKOUT: <HealthDataPoint>[
            _buildWorkoutPoint(
              start: workoutStart,
              end: workoutEnd,
              totalCalories: 899,
              totalSteps: 2800,
            ),
          ],
          HealthDataType.ACTIVE_ENERGY_BURNED: const <HealthDataPoint>[],
        },
        totalStepsResponses: <String, int?>{
          _intervalKey(day, dayEnd): 6772,
        },
      );
      final service = MobileDiaryHealthService(
        health: fakeHealth,
        preferences: preferences,
        now: () => DateTime(2026, 4, 27, 12),
      );

      final firstRead = await service.loadDayData(day: day);
      final deletedHealth = _FakeHealth(
        healthDataPoints: const <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.WORKOUT: <HealthDataPoint>[],
          HealthDataType.ACTIVE_ENERGY_BURNED: <HealthDataPoint>[],
        },
        totalStepsResponses: <String, int?>{
          _intervalKey(day, dayEnd): null,
        },
      );
      final deletedService = MobileDiaryHealthService(
        health: deletedHealth,
        preferences: preferences,
        now: () => DateTime(2026, 4, 27, 12, 1),
      );

      final cachedRead = await deletedService.loadDayData(day: day);
      final refreshedRead = await deletedService.refreshDayData(day: day);
      final overwrittenRead = await deletedService.loadDayData(day: day);

      expect(firstRead.workouts.single.totalCalories, 899);
      expect(cachedRead.workouts.single.totalCalories, 899);
      expect(refreshedRead.totalSteps, 0);
      expect(refreshedRead.workouts, isEmpty);
      expect(overwrittenRead.totalSteps, 0);
      expect(overwrittenRead.workouts, isEmpty);
      expect(deletedHealth.requestedStepIntervals, <String>[
        _intervalKey(day, dayEnd),
      ]);
    },
  );

  test(
    'loadDayData drops stale cache after hard stale age',
    () async {
      final day = DateTime(2026, 4, 17);
      final dayEnd = day.add(const Duration(days: 1));
      var now = DateTime(2026, 4, 27, 12);
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
        now: () => now,
      );

      final firstRead = await service.loadDayData(day: day);
      fakeHealth.healthDataFailuresRemaining = 1;
      now = now.add(const Duration(days: 8));

      await expectLater(
        service.loadDayData(day: day),
        throwsA(isA<StateError>()),
      );

      expect(firstRead.totalSteps, 6772);
      expect(fakeHealth.requestedStepIntervals, <String>[
        _intervalKey(day, dayEnd),
        _intervalKey(day, dayEnd),
      ]);
      expect(fakeHealth.requestedHealthDataTypes, <List<HealthDataType>>[
        <HealthDataType>[HealthDataType.WORKOUT],
        <HealthDataType>[HealthDataType.ACTIVE_ENERGY_BURNED],
        <HealthDataType>[HealthDataType.WORKOUT],
      ]);
    },
  );

  test('loadDayData keeps stale cache after empty refresh', () async {
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
    totalStepsResponses[_intervalKey(day, dayEnd)] = null;
    now = now.add(const Duration(hours: 13));
    final staleRead = await service.loadDayData(day: day);
    final cachedStaleRead = await service.loadDayData(day: day);

    expect(firstRead.totalSteps, 6772);
    expect(staleRead.totalSteps, 6772);
    expect(cachedStaleRead.totalSteps, 6772);
    expect(fakeHealth.requestedStepIntervals, <String>[
      _intervalKey(day, dayEnd),
      _intervalKey(day, dayEnd),
    ]);
  });

  test('loadDayData keeps stale cache after refresh failure', () async {
    final day = DateTime(2026, 4, 17);
    final dayEnd = day.add(const Duration(days: 1));
    var now = DateTime(2026, 4, 27, 12);
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
      now: () => now,
    );

    final firstRead = await service.loadDayData(day: day);
    fakeHealth.healthDataFailuresRemaining = 1;
    now = now.add(const Duration(hours: 13));
    final staleRead = await service.loadDayData(day: day);
    await Future<void>.delayed(Duration.zero);

    expect(firstRead.totalSteps, 6772);
    expect(staleRead.totalSteps, 6772);
    expect(fakeHealth.requestedStepIntervals, <String>[
      _intervalKey(day, dayEnd),
      _intervalKey(day, dayEnd),
    ]);
    expect(fakeHealth.requestedHealthDataTypes, <List<HealthDataType>>[
      <HealthDataType>[HealthDataType.WORKOUT],
      <HealthDataType>[HealthDataType.ACTIVE_ENERGY_BURNED],
      <HealthDataType>[HealthDataType.WORKOUT],
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
        unassignedActiveEnergySegments: summary.unassignedActiveEnergySegments,
      );

      expect(dayData.workouts, isEmpty);
      expect(dayData.unassignedActiveEnergySegments, hasLength(1));
      expect(dayData.unassignedActiveEnergySegments.single.totalCalories, 500);
      expect(dayData.unassignedActiveEnergySegments.single.totalSteps, 1000);
      expect(summary.stepsDuringWorkouts, 0);
      expect(summary.stepsDuringUnassignedActiveEnergy, 1000);
      expect(summary.stepsOutsideWorkouts, 3000);
      expect(burnedCalories, 160);
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
        unassignedActiveEnergySegments: summary.unassignedActiveEnergySegments,
      );

      expect(dayData.workouts.single.totalCalories, 300);
      expect(dayData.unassignedActiveEnergySegments, hasLength(1));
      expect(dayData.unassignedActiveEnergySegments.single.totalCalories, 300);
      expect(dayData.unassignedActiveEnergySegments.single.totalSteps, 500);
      expect(summary.stepsOutsideWorkouts, 1300);
      expect(burnedCalories, 372);
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
        unassignedActiveEnergySegments: summary.unassignedActiveEnergySegments,
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
        unassignedActiveEnergySegments: summary.unassignedActiveEnergySegments,
      );

      expect(dayData.workouts, isEmpty);
      expect(dayData.unassignedActiveEnergySegments, hasLength(1));
      expect(dayData.unassignedActiveEnergySegments.single.totalCalories, 300);
      expect(dayData.unassignedActiveEnergySegments.single.totalSteps, isNull);
      expect(burnedCalories, 0);
    },
  );
}

class _FakeHealth extends Health {
  _FakeHealth({
    required this.healthDataPoints,
    required this.totalStepsResponses,
    this.intervalDataPoints = const <HealthDataPoint>[],
    this.configureCompleter,
    this.stepReadCompleters = const <String, Completer<void>>{},
    this.healthDataFailuresRemaining = 0,
    this.intervalDataFailuresRemaining = 0,
  });

  final Map<HealthDataType, List<HealthDataPoint>> healthDataPoints;
  final Map<String, int?> totalStepsResponses;
  final List<HealthDataPoint> intervalDataPoints;
  final Completer<void>? configureCompleter;
  final Map<String, Completer<void>> stepReadCompleters;
  int healthDataFailuresRemaining;
  int intervalDataFailuresRemaining;
  final List<String> requestedStepIntervals = <String>[];
  final List<List<HealthDataType>> requestedIntervalTypes =
      <List<HealthDataType>>[];
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
  Future<List<HealthDataPoint>> getHealthIntervalDataFromTypes({
    required DateTime startDate,
    required DateTime endDate,
    required List<HealthDataType> types,
    required int interval,
    List<RecordingMethod> recordingMethodsToFilter = const [],
  }) async {
    requestedIntervalTypes.add(types);
    if (intervalDataFailuresRemaining > 0) {
      intervalDataFailuresRemaining -= 1;
      throw StateError('interval data read failed');
    }
    return intervalDataPoints
        .where(
          (point) =>
              types.contains(point.type) &&
              !point.dateFrom.isBefore(startDate) &&
              point.dateFrom.isBefore(endDate),
        )
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
    await stepReadCompleters[key]?.future;
    return totalStepsResponses[key];
  }
}

HealthDataPoint _buildNumericPoint({
  required HealthDataType type,
  required HealthDataUnit unit,
  required DateTime start,
  required DateTime end,
  required num value,
}) {
  return HealthDataPoint(
    uuid: '${type.name}-${start.millisecondsSinceEpoch}',
    value: NumericHealthValue(numericValue: value),
    type: type,
    unit: unit,
    dateFrom: start,
    dateTo: end,
    sourcePlatform: HealthPlatformType.appleHealth,
    sourceDeviceId: 'device-id',
    sourceId: 'apple.health',
    sourceName: 'Apple Health',
  );
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
