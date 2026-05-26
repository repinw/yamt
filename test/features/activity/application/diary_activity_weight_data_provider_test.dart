import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/activity/application/diary_activity_weight_data_provider.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/health/data/diary_health_service_provider.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/presentation/controllers/health_connection_controller.dart';
import 'package:yamt/features/health/presentation/controllers/manual_health_weight_entries_controller.dart';

import '../../../helpers/memory_app_preferences.dart';
import '../../calories/support/fake_calories_repositories.dart';

void main() {
  final selectedDay = DateTime(2026, 4, 27);

  test('combines health and manual weights', () async {
    final previousDay = selectedDay.subtract(const Duration(days: 1));
    final olderTrendDay = selectedDay.subtract(const Duration(days: 2));
    final workout = _workout(
      selectedDay,
      activityLabel: 'Walk',
      durationMinutes: 30,
      totalCalories: 150,
      sourceName: 'Health Connect',
    );
    final healthWeightSample = HealthWeightSample(
      recordedAt: selectedDay.add(const Duration(hours: 7)),
      weightKg: 77.1,
      uuid: 'selected-health-weight',
      sourcePackageName: 'de.yamt.app',
      isFromThisApp: true,
    );
    final olderTrendSample = HealthWeightSample(
      recordedAt: olderTrendDay.add(const Duration(hours: 7)),
      weightKg: 79.4,
      uuid: 'older-trend-weight',
      sourcePackageName: 'external.app',
    );
    final newerTrendSample = HealthWeightSample(
      recordedAt: olderTrendDay.add(const Duration(hours: 18)),
      weightKg: 78.9,
      uuid: 'newer-trend-weight',
      sourcePackageName: 'external.app',
    );
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
        calorieGoalControllerProvider.overrideWith(
          () => _FakeCalorieGoalController(
            CalorieGoalSettings.single(
              dailyKcalGoal: 2200,
              calculatorProfile: const CalorieCalculatorProfile.defaults(),
              effectiveDate: selectedDay,
            ),
          ),
        ),
        healthConnectionServiceProvider.overrideWith(
          (ref) => FakeHealthConnectionService(_readyHealthStatus),
        ),
        diaryHealthServiceProvider.overrideWith(
          (ref) => FakeDiaryHealthService({
            diaryDayKey(selectedDay): DiaryHealthDayData(
              totalSteps: 4000,
              workouts: [workout],
            ),
          }),
        ),
        healthWeightServiceProvider.overrideWith(
          (ref) => FakeHealthWeightService([
            healthWeightSample,
            olderTrendSample,
            newerTrendSample,
          ]),
        ),
        manualHealthWeightRepositoryProvider.overrideWith(
          (ref) => FakeManualHealthWeightRepository([
            ManualHealthWeightEntry(day: selectedDay, weightKg: 76.8),
            ManualHealthWeightEntry(day: previousDay, weightKg: 77.4),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final data = await container.read(
      diaryActivityWeightDataProvider(selectedDay).future,
    );

    expect(data.healthAccessState, HealthDataAccessState.ready);
    expect(data.activityKcal, 250);
    expect(data.activeMinutes, 30);
    expect(data.profileWeightKg, 80);
    expect(data.selectedWeightKg, 76.8);
    expect(data.hasSelectedDayWeight, isTrue);
    expect(data.activityTrend.last, 250);
    expect(data.weightTrend[4], 78.9);
    expect(data.weightTrend[5], 77.4);
    expect(data.weightTrend.last, 76.8);
    expect(data.weightDays.last.canDeleteWeight, isTrue);
    expect(data.weightDays[4].canDeleteWeight, isFalse);
  });

  test('stops after disposed status gap', () async {
    final statusCompleter = Completer<HealthConnectionStatus>();
    final container = ProviderContainer(
      overrides: [
        calorieGoalControllerProvider.overrideWith(
          () => _FakeCalorieGoalController(
            CalorieGoalSettings.single(
              dailyKcalGoal: 2200,
              calculatorProfile: const CalorieCalculatorProfile.defaults(),
              effectiveDate: selectedDay,
            ),
          ),
        ),
        healthConnectionControllerProvider.overrideWith(
          () => _PendingHealthConnectionController(statusCompleter.future),
        ),
        manualHealthWeightEntriesControllerProvider.overrideWith(
          () => _PendingManualHealthWeightEntriesController(
            Future<List<ManualHealthWeightEntry>>.value(
              const <ManualHealthWeightEntry>[],
            ),
          ),
        ),
        diaryHealthServiceProvider.overrideWith(
          (ref) => FakeDiaryHealthService(const {}),
        ),
        healthWeightServiceProvider.overrideWith(
          (ref) => FakeHealthWeightService(const <HealthWeightSample>[]),
        ),
      ],
    );

    final future = container.read(
      diaryActivityWeightDataProvider(selectedDay).future,
    );
    await Future<void>.delayed(Duration.zero);
    container.dispose();
    statusCompleter.complete(_readyHealthStatus);

    await expectLater(future, throwsA(isA<StateError>()));
  });

  test('stops after disposed manual entries gap', () async {
    final manualEntriesCompleter = Completer<List<ManualHealthWeightEntry>>();
    final container = ProviderContainer(
      overrides: [
        calorieGoalControllerProvider.overrideWith(
          () => _FakeCalorieGoalController(
            CalorieGoalSettings.single(
              dailyKcalGoal: 2200,
              calculatorProfile: const CalorieCalculatorProfile.defaults(),
              effectiveDate: selectedDay,
            ),
          ),
        ),
        healthConnectionControllerProvider.overrideWith(
          () => _PendingHealthConnectionController(
            Future<HealthConnectionStatus>.value(_readyHealthStatus),
          ),
        ),
        manualHealthWeightEntriesControllerProvider.overrideWith(
          () => _PendingManualHealthWeightEntriesController(
            manualEntriesCompleter.future,
          ),
        ),
        diaryHealthServiceProvider.overrideWith(
          (ref) => FakeDiaryHealthService(const {}),
        ),
        healthWeightServiceProvider.overrideWith(
          (ref) => FakeHealthWeightService(const <HealthWeightSample>[]),
        ),
      ],
    );

    final future = container.read(
      diaryActivityWeightDataProvider(selectedDay).future,
    );
    await Future<void>.delayed(Duration.zero);
    container.dispose();
    manualEntriesCompleter.complete(const <ManualHealthWeightEntry>[]);

    await expectLater(future, throwsA(isA<StateError>()));
  });
}

class _FakeCalorieGoalController extends CalorieGoalController {
  _FakeCalorieGoalController(this.settings);

  final CalorieGoalSettings settings;

  @override
  CalorieGoalSettings build() => settings;
}

class _PendingHealthConnectionController extends HealthConnectionController {
  _PendingHealthConnectionController(this.statusFuture);

  final Future<HealthConnectionStatus> statusFuture;

  @override
  FutureOr<HealthConnectionStatus> build() => statusFuture;
}

class _PendingManualHealthWeightEntriesController
    extends ManualHealthWeightEntriesController {
  _PendingManualHealthWeightEntriesController(this.entriesFuture);

  final Future<List<ManualHealthWeightEntry>> entriesFuture;

  @override
  FutureOr<List<ManualHealthWeightEntry>> build() => entriesFuture;
}

const _readyHealthStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.granted,
);

HealthWorkoutSession _workout(
  DateTime day, {
  required String activityLabel,
  required int durationMinutes,
  required int totalCalories,
  required String sourceName,
}) {
  return HealthWorkoutSession(
    id: activityLabel,
    start: day.add(const Duration(hours: 7)),
    endExclusive: day.add(Duration(hours: 7, minutes: durationMinutes)),
    durationMinutes: durationMinutes.toDouble(),
    activityLabel: activityLabel,
    sourceName: sourceName,
    totalCalories: totalCalories,
    totalSteps: 1500,
  );
}
