import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/health/data/'
    'health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/'
    'manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

import '../support/fake_calories_repositories.dart';

CalorieEntry _entry(String id, DateTime loggedAt) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Item $id',
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 200,
    per100Protein: 10,
    per100Carbs: 10,
    per100Fat: 5,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

class _WatchErrorCalorieSettingsRepository
    extends FakeCalorieSettingsRepository {
  @override
  Stream<CalorieGoalSettings> watchSettings() {
    return Stream<CalorieGoalSettings>.error(StateError('watch failed'));
  }
}

void main() {
  test(
    'saveCalculatedGoal persists profile and calculated daily goal',
    () async {
      final repository = FakeCalorieSettingsRepository();
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);

      const profile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.male,
        weightKg: 80,
        heightCm: 180,
        ageYears: 30,
        activityLevel: 1.2,
        goalMode: CalorieGoalMode.maintain,
        goalSpeedKgPerWeek: 0,
      );
      final goalStartDate = DateTime(2026, 4, 10, 16, 30);

      final saved = await container
          .read(calorieGoalControllerProvider.notifier)
          .saveCalculatedGoal(
            profile,
            goalStartDate: goalStartDate,
          );

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.dailyKcalGoal, 2136);
      expect(settings.calculatorProfile?.goalMode, CalorieGoalMode.maintain);
      expect(settings.calculatorProfile?.weightKg, 80);
      expect(settings.goalHistory.single.changedAt, DateTime(2026, 4, 10));
    },
  );

  test('manual setGoal clears an existing calculator profile', () async {
    final repository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: const CalorieCalculatorProfile(
          sex: CalorieCalculatorSex.female,
          weightKg: 65,
          heightCm: 170,
          ageYears: 28,
          activityLevel: 1.5,
          goalMode: CalorieGoalMode.lose,
          goalSpeedKgPerWeek: 0.5,
        ),
        effectiveDate: DateTime(2026, 2, 25, 9),
      ),
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);

    final saved = await container
        .read(calorieGoalControllerProvider.notifier)
        .setGoal(2300);

    expect(saved, isTrue);
    final settings = await repository.readSettings();
    expect(settings.dailyKcalGoal, 2300);
    expect(settings.calculatorProfile, isNull);
    expect(settings.goalKcalForDay(DateTime(2026, 2, 25)), 2200);
    expect(settings.goalKcalForDay(DateTime.now()), 2300);
    expect(settings.goalHistory, hasLength(2));
  });

  test('setGoal rejects non-positive values', () async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);

    final saved = await container
        .read(calorieGoalControllerProvider.notifier)
        .setGoal(0);

    expect(saved, isFalse);
    final settings = await repository.readSettings();
    expect(settings.hasGoal, isFalse);
  });

  test('build surfaces initial settings stream errors', () async {
    final repository = _WatchErrorCalorieSettingsRepository();
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(calorieGoalControllerProvider.future),
      throwsA(isA<StateError>()),
    );
  });

  test('setGoal restores previous state when save throws', () async {
    final previousSettings = CalorieGoalSettings.single(
      dailyKcalGoal: 2100,
      calculatorProfile: null,
      effectiveDate: DateTime(2026, 4, 8),
    );
    final repository =
        FakeCalorieSettingsRepository(
            initialSettings: previousSettings,
          )
          ..onSaveSettings = (settings) async {
            throw StateError('save failed');
          };
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);

    final saved = await container
        .read(calorieGoalControllerProvider.notifier)
        .setGoal(2200);

    expect(saved, isFalse);
    expect(
      container.read(calorieGoalControllerProvider).asData?.value,
      previousSettings,
    );
  });

  test('clearGoal removes active goal', () async {
    final repository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2100,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 4, 8),
      ),
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);

    final saved = await container
        .read(calorieGoalControllerProvider.notifier)
        .clearGoal();

    expect(saved, isTrue);
    final settings = await repository.readSettings();
    expect(settings.hasGoal, isFalse);
    expect(settings.goalHistory, hasLength(2));
  });

  test(
    'saveCalculatedGoal restores previous state when saving fails',
    () async {
      final previousSettings = CalorieGoalSettings.single(
        dailyKcalGoal: 2100,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 2, 25, 9),
      );
      final repository = FakeCalorieSettingsRepository(
        initialSettings: previousSettings,
      )..saveShouldFail = true;
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);

      const profile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.male,
        weightKg: 90,
        heightCm: 185,
        ageYears: 32,
        activityLevel: 1.6,
        goalMode: CalorieGoalMode.gain,
        goalSpeedKgPerWeek: 0.5,
      );

      final saved = await container
          .read(calorieGoalControllerProvider.notifier)
          .saveCalculatedGoal(
            profile,
            goalStartDate: DateTime(2026, 4, 10, 18),
          );

      expect(saved, isFalse);
      final state = container.read(calorieGoalControllerProvider);
      expect(state.asData?.value.dailyKcalGoal, previousSettings.dailyKcalGoal);
      expect(state.asData?.value.calculatorProfile, isNull);
    },
  );

  test(
    'saveCalculatedGoal replaces later history from the selected goal start',
    () async {
      final initialSettings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: DateTime(2026, 4, 1, 9),
            dailyKcalGoal: 2100,
            calculatorProfile: null,
          )
          .applyGoalChange(
            changedAt: DateTime(2026, 4, 5, 10),
            dailyKcalGoal: 1900,
            calculatorProfile: null,
          );
      final repository = FakeCalorieSettingsRepository(
        initialSettings: initialSettings,
      );
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);

      const profile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.male,
        weightKg: 80,
        heightCm: 180,
        ageYears: 30,
        activityLevel: 1.2,
        goalMode: CalorieGoalMode.maintain,
        goalSpeedKgPerWeek: 0,
      );
      final goalStartDate = DateTime(2026, 4, 3, 16);

      final saved = await container
          .read(calorieGoalControllerProvider.notifier)
          .saveCalculatedGoal(profile, goalStartDate: goalStartDate);

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.goalHistory, hasLength(2));
      expect(settings.goalHistory.last.changedAt, DateTime(2026, 4, 3));
      expect(settings.goalKcalForDay(DateTime(2026, 4, 2)), 2100);
      expect(settings.goalKcalForDay(DateTime(2026, 4, 6)), 2136);
    },
  );

  test('saveCalculatedGoal rejects a future goal start', () async {
    final today = DateTime.now();
    final initialSettings = CalorieGoalSettings.single(
      dailyKcalGoal: 1900,
      calculatorProfile: null,
      effectiveDate: today,
    );
    final repository = FakeCalorieSettingsRepository(
      initialSettings: initialSettings,
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);

    const profile = CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.male,
      weightKg: 80,
      heightCm: 180,
      ageYears: 30,
      activityLevel: 1.2,
      goalMode: CalorieGoalMode.maintain,
      goalSpeedKgPerWeek: 0,
    );
    final futureGoalStart = today.add(const Duration(days: 1));

    final saved = await container
        .read(calorieGoalControllerProvider.notifier)
        .saveCalculatedGoal(profile, goalStartDate: futureGoalStart);

    expect(saved, isFalse);
    final settings = await repository.readSettings();
    expect(settings.goalKcalForDay(today), 1900);
    expect(settings.goalHistory, hasLength(1));
    expect(settings.goalHistory.single.changedAt, today);
  });

  test(
    'saveCalculatedGoal allows a future goal start for onboarding saves',
    () async {
      final today = normalizeDiaryDay(DateTime.now());
      final futureGoalStart = today.add(const Duration(days: 2));
      final initialSettings = CalorieGoalSettings.single(
        dailyKcalGoal: 1900,
        calculatorProfile: null,
        effectiveDate: today,
      );
      final repository = FakeCalorieSettingsRepository(
        initialSettings: initialSettings,
      );
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);

      const profile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.male,
        weightKg: 80,
        heightCm: 180,
        ageYears: 30,
        activityLevel: 1.2,
        goalMode: CalorieGoalMode.maintain,
        goalSpeedKgPerWeek: 0,
      );

      final saved = await container
          .read(calorieGoalControllerProvider.notifier)
          .saveCalculatedGoal(
            profile,
            goalStartDate: futureGoalStart,
            allowFutureGoalStart: true,
          );

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.goalHistory, hasLength(1));
      expect(settings.goalHistory.single.effectiveDate, today);
      expect(
        settings.goalHistory.single.effectiveCountingStartDate,
        futureGoalStart,
      );
      expect(settings.goalKcalForDay(today), 2136);
      expect(settings.goalKcalForDay(futureGoalStart), 2136);
      expect(settings.nextGoalStartAfterDay(today), futureGoalStart);
    },
  );

  test(
    'saveCalculatedGoal seeds initial calculator weight '
    'into weight history',
    () async {
      final repository = FakeCalorieSettingsRepository();
      final manualRepository = FakeManualHealthWeightRepository(
        <ManualHealthWeightEntry>[],
      );
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
          healthConnectionServiceProvider.overrideWithValue(
            FakeHealthConnectionService(
              const HealthConnectionStatus.unsupported(),
            ),
          ),
          manualHealthWeightRepositoryProvider.overrideWithValue(
            manualRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);

      const profile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.male,
        weightKg: 80,
        heightCm: 180,
        ageYears: 30,
        activityLevel: 1.2,
        goalMode: CalorieGoalMode.maintain,
        goalSpeedKgPerWeek: 0,
      );
      final goalStartDate = DateTime(2026, 4, 8, 16, 30);

      final saved = await container
          .read(calorieGoalControllerProvider.notifier)
          .saveCalculatedGoal(profile, goalStartDate: goalStartDate);

      expect(saved, isTrue);
      expect(manualRepository.entries, hasLength(1));
      expect(manualRepository.entries.single.day, DateTime(2026, 4, 8));
      expect(manualRepository.entries.single.weightKg, 80);
    },
  );

  test(
    'saveCalculatedGoal skips seed when Health already has start weight',
    () async {
      final repository = FakeCalorieSettingsRepository();
      final manualRepository = FakeManualHealthWeightRepository(
        <ManualHealthWeightEntry>[],
      );
      final healthWeightService = FakeHealthWeightService(
        <HealthWeightSample>[
          HealthWeightSample(recordedAt: DateTime(2026, 4, 8, 7), weightKg: 80),
        ],
      );
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
          healthConnectionServiceProvider.overrideWithValue(
            FakeHealthConnectionService(
              const HealthConnectionStatus(
                platform: HealthPlatform.android,
                healthConnectAvailability: HealthConnectAvailability.available,
                permissionState: HealthPermissionState.granted,
                historyAccess: HealthHistoryAccess.granted,
              ),
            ),
          ),
          healthWeightServiceProvider.overrideWithValue(healthWeightService),
          manualHealthWeightRepositoryProvider.overrideWithValue(
            manualRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);

      const profile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.male,
        weightKg: 80,
        heightCm: 180,
        ageYears: 30,
        activityLevel: 1.2,
        goalMode: CalorieGoalMode.maintain,
        goalSpeedKgPerWeek: 0,
      );

      final saved = await container
          .read(calorieGoalControllerProvider.notifier)
          .saveCalculatedGoal(
            profile,
            goalStartDate: DateTime(2026, 4, 8, 16),
          );

      expect(saved, isTrue);
      expect(manualRepository.entries, isEmpty);
    },
  );

  test(
    'saveCalculatedGoal with unchanged date updates window only '
    'and preserves pending dismissal',
    () async {
      final today = normalizeDiaryDay(DateTime.now());
      final dismissedAt = today.add(const Duration(hours: 9));
      final pending = PendingCalorieGoalWeeklyCheckIn(
        windowStartDate: today.subtract(
          const Duration(days: weeklyCheckInWindowLengthDays),
        ),
        windowEndDate: today.subtract(const Duration(days: 1)),
        dueDate: today,
        dismissedAt: dismissedAt,
      );
      const profile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.male,
        weightKg: 80,
        heightCm: 180,
        ageYears: 30,
        activityLevel: 1.2,
        goalMode: CalorieGoalMode.maintain,
        goalSpeedKgPerWeek: 0,
      );
      final calculatedGoal = CalorieGoalCalculator.calculate(
        profile,
      ).finalGoalKcal;
      final repository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: calculatedGoal,
          calculatorProfile: profile.copyWith(),
          effectiveDate: today,
          source: CalorieGoalSource.calculator,
        ).copyWithPendingWeeklyCheckIn(pending),
      );
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);

      final saved = await container
          .read(calorieGoalControllerProvider.notifier)
          .saveCalculatedGoal(
            profile,
            goalStartDate: today,
          );

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.goalHistory, hasLength(1));
      expect(settings.pendingWeeklyCheckIn?.windowKey, pending.windowKey);
      expect(settings.pendingWeeklyCheckIn?.dismissedAt, dismissedAt);
    },
  );

  test(
    'saveCalculatedGoal refreshes expected activity when profile unchanged',
    () async {
      final today = normalizeDiaryDay(DateTime.now());
      const profile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.male,
        weightKg: 80,
        heightCm: 180,
        ageYears: 30,
        activityLevel: 1.6,
        goalMode: CalorieGoalMode.maintain,
        goalSpeedKgPerWeek: 0,
      );
      final calculation = CalorieGoalCalculator.calculate(profile);
      final repository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: calculation.finalGoalKcal,
          calculatorProfile: profile.copyWith(),
          effectiveDate: today,
          expectedActivityKcal: calculation.expectedActivityKcal + 25,
          source: CalorieGoalSource.calculator,
        ),
      );
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);

      final saved = await container
          .read(calorieGoalControllerProvider.notifier)
          .saveCalculatedGoal(profile, goalStartDate: today);

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.goalHistory, hasLength(1));
      expect(
        settings.latestGoalEntry?.expectedActivityKcal,
        calculation.expectedActivityKcal,
      );
    },
  );

  test(
    'saveCalculatedGoal preserves learned snapshot '
    'on same-day calculator edits',
    () async {
      final today = normalizeDiaryDay(DateTime.now());
      final learnedSnapshot = CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: DateTime(2026, 4, 8),
        windowEndDate: DateTime(2026, 4, 14),
        trendWeightChangePerDay: -0.08,
        calculatedTrueTdeeKcal: 2450,
        averageActiveKcal: 210,
        lowConfidence: false,
      );
      const initialProfile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.female,
        weightKg: 65,
        heightCm: 170,
        ageYears: 28,
        activityLevel: 1.7,
        goalMode: CalorieGoalMode.maintain,
        goalSpeedKgPerWeek: 0,
      );
      const updatedProfile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.female,
        weightKg: 65,
        heightCm: 170,
        ageYears: 28,
        activityLevel: 1.7,
        goalMode: CalorieGoalMode.lose,
        goalSpeedKgPerWeek: 0.5,
      );
      final repository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: learnedSnapshot.calculatedTrueTdeeKcal,
          calculatorProfile: initialProfile,
          effectiveDate: today,
          source: CalorieGoalSource.calculator,
          weeklyCheckInSnapshot: learnedSnapshot,
        ),
      );
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);

      final saved = await container
          .read(calorieGoalControllerProvider.notifier)
          .saveCalculatedGoal(
            updatedProfile,
            goalStartDate: today,
          );

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.goalHistory, hasLength(1));
      expect(settings.latestGoalEntry?.source, CalorieGoalSource.calculator);
      expect(settings.latestGoalEntry?.weeklyCheckInSnapshot, learnedSnapshot);
      expect(settings.hasLearnedTdee, isTrue);
      expect(settings.latestLearnedTdeeKcal, 2450);
    },
  );

  test('saveCalculatedGoal can count same-day start as tracked', () async {
    final today = normalizeDiaryDay(DateTime.now());
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);

    const profile = CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.male,
      weightKg: 80,
      heightCm: 180,
      ageYears: 30,
      activityLevel: 1.2,
      goalMode: CalorieGoalMode.maintain,
      goalSpeedKgPerWeek: 0,
    );

    final saved = await container
        .read(calorieGoalControllerProvider.notifier)
        .saveCalculatedGoal(
          profile,
          goalStartDate: today,
          countGoalStartDayForLearning: true,
        );

    expect(saved, isTrue);
    final settings = await repository.readSettings();
    expect(settings.goalHistory.single.changedAt, today);
    expect(settings.goalHistory.single.effectiveCountingStartDate, today);
  });

  test('saveCalculatedGoal can keep same-day start as starter day', () async {
    final today = normalizeDiaryDay(DateTime.now());
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);

    const profile = CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.male,
      weightKg: 80,
      heightCm: 180,
      ageYears: 30,
      activityLevel: 1.2,
      goalMode: CalorieGoalMode.maintain,
      goalSpeedKgPerWeek: 0,
    );

    final saved = await container
        .read(calorieGoalControllerProvider.notifier)
        .saveCalculatedGoal(
          profile,
          goalStartDate: today,
          countGoalStartDayForLearning: false,
        );

    expect(saved, isTrue);
    final settings = await repository.readSettings();
    expect(settings.goalHistory.single.effectiveDate, today);
    expect(settings.goalHistory.single.effectiveCountingStartDate, today);
    expect(settings.goalHistory.single.changedAt, isNot(today));
    expect(isSameDiaryDay(settings.goalHistory.single.changedAt!, today), true);
  });

  test(
    'saveCalculatedGoal does not reattach stale learned snapshot '
    'from older history',
    () async {
      final today = normalizeDiaryDay(DateTime.now());
      final learnedSnapshot = CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: DateTime(2026, 4, 8),
        windowEndDate: DateTime(2026, 4, 14),
        trendWeightChangePerDay: -0.08,
        calculatedTrueTdeeKcal: 2450,
        averageActiveKcal: 210,
        lowConfidence: false,
      );
      const profile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.female,
        weightKg: 65,
        heightCm: 170,
        ageYears: 28,
        activityLevel: 1.7,
        goalMode: CalorieGoalMode.lose,
        goalSpeedKgPerWeek: 0.5,
      );
      final initialSettings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: today.subtract(const Duration(days: 7)),
            dailyKcalGoal: learnedSnapshot.calculatedTrueTdeeKcal,
            calculatorProfile: profile,
            source: CalorieGoalSource.calculator,
            weeklyCheckInSnapshot: learnedSnapshot,
          )
          .applyGoalChange(
            changedAt: today,
            dailyKcalGoal: 2100,
            calculatorProfile: null,
          );
      final repository = FakeCalorieSettingsRepository(
        initialSettings: initialSettings,
      );
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);

      final saved = await container
          .read(calorieGoalControllerProvider.notifier)
          .saveCalculatedGoal(
            profile,
            goalStartDate: today,
          );

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.goalHistory, hasLength(2));
      expect(settings.latestGoalEntry?.source, CalorieGoalSource.calculator);
      expect(settings.latestGoalEntry?.weeklyCheckInSnapshot, isNull);
    },
  );

  test(
    'shiftGoalStart moves the active goal start and keeps the goal',
    () async {
      final initialSettings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: DateTime(2026, 4, 1, 9),
            dailyKcalGoal: 2100,
            calculatorProfile: null,
          )
          .applyGoalChange(
            changedAt: DateTime(2026, 4, 5, 10),
            dailyKcalGoal: 1900,
            calculatorProfile: null,
          );
      final repository = FakeCalorieSettingsRepository(
        initialSettings: initialSettings,
      );
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);

      final saved = await container
          .read(calorieGoalControllerProvider.notifier)
          .shiftGoalStart(goalStartDate: DateTime(2026, 4, 3, 6));

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.dailyKcalGoal, 1900);
      expect(settings.goalHistory, hasLength(2));
      expect(settings.goalHistory.last.changedAt, DateTime(2026, 4, 3));
      expect(settings.goalKcalForDay(DateTime(2026, 4, 2)), 2100);
      expect(settings.goalKcalForDay(DateTime(2026, 4, 4)), 1900);
    },
  );

  test('shiftGoalStart allows a future official counting start', () async {
    final today = DateTime.now();
    final initialSettings = CalorieGoalSettings.single(
      dailyKcalGoal: 1900,
      calculatorProfile: null,
      effectiveDate: today,
    );
    final repository = FakeCalorieSettingsRepository(
      initialSettings: initialSettings,
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);

    final futureGoalStart = DateTime.now().add(const Duration(days: 2));
    final saved = await container
        .read(calorieGoalControllerProvider.notifier)
        .shiftGoalStart(goalStartDate: futureGoalStart);

    expect(saved, isTrue);
    final settings = await repository.readSettings();
    expect(settings.goalKcalForDay(today), 1900);
    expect(settings.goalHistory.single.effectiveDate, normalizeDiaryDay(today));
    expect(
      settings.goalHistory.single.effectiveCountingStartDate,
      normalizeDiaryDay(futureGoalStart),
    );
    expect(
      settings.nextGoalStartAfterDay(today),
      normalizeDiaryDay(futureGoalStart),
    );
    expect(settings.goalHistory, hasLength(1));
    expect(
      isSameDiaryDay(settings.goalHistory.single.changedAt!, today),
      isTrue,
    );
  });

  test(
    'shiftGoalStart allows future counting start',
    () async {
      final today = DateTime.now();
      final initialSettings = CalorieGoalSettings.single(
        dailyKcalGoal: 1900,
        calculatorProfile: null,
        effectiveDate: today,
      );
      final repository = FakeCalorieSettingsRepository(
        initialSettings: initialSettings,
      );
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);

      final futureGoalStart = today.add(const Duration(days: 2));
      final saved = await container
          .read(calorieGoalControllerProvider.notifier)
          .shiftGoalStart(
            goalStartDate: futureGoalStart,
          );

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.goalHistory, hasLength(1));
      expect(
        isSameDiaryDay(settings.goalHistory.single.changedAt!, today),
        isTrue,
      );
      expect(
        settings.goalHistory.single.effectiveCountingStartDate,
        normalizeDiaryDay(futureGoalStart),
      );
      expect(
        settings.nextGoalStartAfterDay(today),
        normalizeDiaryDay(futureGoalStart),
      );
    },
  );

  test(
    'shiftGoalStart preserves weekly check in goal metadata',
    () async {
      final today = DateTime.now();
      final weeklyCheckInSnapshot = CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: today.subtract(const Duration(days: 7)),
        windowEndDate: today.subtract(const Duration(days: 1)),
        trendWeightChangePerDay: -0.08,
        calculatedTrueTdeeKcal: 2315,
        averageActiveKcal: 220,
        lowConfidence: false,
      );
      final initialSettings = const CalorieGoalSettings.empty()
          .applyGoalChange(
            changedAt: today.subtract(const Duration(days: 14)),
            dailyKcalGoal: 2200,
            calculatorProfile: null,
          )
          .applyGoalChange(
            changedAt: today.subtract(const Duration(days: 1)),
            dailyKcalGoal: 2300,
            calculatorProfile: const CalorieCalculatorProfile(
              sex: CalorieCalculatorSex.female,
              weightKg: 65,
              heightCm: 170,
              ageYears: 28,
              activityLevel: 1.7,
              goalMode: CalorieGoalMode.maintain,
              goalSpeedKgPerWeek: 0,
            ),
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: weeklyCheckInSnapshot,
          );
      final repository = FakeCalorieSettingsRepository(
        initialSettings: initialSettings,
      );
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);

      final saved = await container
          .read(calorieGoalControllerProvider.notifier)
          .shiftGoalStart(
            goalStartDate: today.subtract(const Duration(days: 2)),
          );

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.latestGoalEntry?.dailyKcalGoal, 2200);
      expect(settings.latestGoalEntry?.source, CalorieGoalSource.manual);
      expect(settings.latestGoalEntry?.weeklyCheckInSnapshot, isNotNull);
      expect(settings.hasLearnedTdee, isTrue);
      expect(settings.latestLearnedTdeeKcal, 2315);
      expect(
        settings.goalKcalForDay(today.subtract(const Duration(days: 3))),
        2200,
      );
      expect(settings.goalKcalForDay(today), 2200);
    },
  );

  test('shiftGoalStart returns false without a goal', () async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);

    final saved = await container
        .read(calorieGoalControllerProvider.notifier)
        .shiftGoalStart(goalStartDate: DateTime(2026, 4, 8));

    expect(saved, isFalse);
  });

  test('shiftGoalStart keeps unchanged start as success', () async {
    final startDate = DateTime(2026, 4, 8);
    final repository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2100,
        calculatorProfile: null,
        effectiveDate: startDate,
      ),
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);

    final saved = await container
        .read(calorieGoalControllerProvider.notifier)
        .shiftGoalStart(goalStartDate: startDate);

    expect(saved, isTrue);
    final settings = await repository.readSettings();
    expect(settings.goalHistory, hasLength(1));
  });

  test('setSkippedIntakeDay rejects days that already have entries', () async {
    final skippedDay = DateTime(2026, 4, 10);
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 4, 8, 9),
      ),
    );
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry('tracked-day', DateTime(2026, 4, 10, 8)),
      ],
    );
    addTearDown(settingsRepository.dispose);
    addTearDown(logRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);

    final saved = await container
        .read(calorieGoalControllerProvider.notifier)
        .setSkippedIntakeDay(day: skippedDay, isSkipped: true);

    expect(saved, isFalse);
    final settings = await settingsRepository.readSettings();
    expect(settings.isSkippedIntakeDay(skippedDay), isFalse);
  });

  test('clearSkippedIntakeDay removes skipped day', () async {
    final skippedDay = DateTime(2026, 4, 10);
    final repository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 4, 8),
      ).setSkippedIntakeDay(day: skippedDay, isSkipped: true),
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);

    final saved = await container
        .read(calorieGoalControllerProvider.notifier)
        .clearSkippedIntakeDay(skippedDay);

    expect(saved, isTrue);
    final settings = await repository.readSettings();
    expect(settings.isSkippedIntakeDay(skippedDay), isFalse);
  });

  test('markActivityTrackingStarted stores tracking backfill day', () async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);

    final controller = container.read(calorieGoalControllerProvider.notifier);
    final saved = await controller.markActivityTrackingStarted(
      startedAt: DateTime(2026, 4, 8, 10),
    );
    final savedAgain = await controller.markActivityTrackingStarted(
      startedAt: DateTime(2026, 4, 8, 12),
    );
    final savedLater = await controller.markActivityTrackingStarted(
      startedAt: DateTime(2026, 4, 10, 12),
    );

    expect(saved, isTrue);
    expect(savedAgain, isTrue);
    expect(savedLater, isTrue);
    final settings = await repository.readSettings();
    expect(settings.activityTrackingStartDate, DateTime(2026, 4, 10));
  });

  test(
    'dismissPendingWeeklyCheckIn succeeds when nothing is pending',
    () async {
      final repository = FakeCalorieSettingsRepository();
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);

      final dismissed = await container
          .read(calorieGoalControllerProvider.notifier)
          .dismissPendingWeeklyCheckIn();

      expect(dismissed, isTrue);
      final settings = await repository.readSettings();
      expect(settings.pendingWeeklyCheckIn, isNull);
    },
  );

  test(
    'dismissPendingWeeklyCheckIn keeps pending window and stores dismissal',
    () async {
      final repository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2200,
          calculatorProfile: null,
          effectiveDate: DateTime(2026, 4, 8, 9),
        ),
      );
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);

      final pending = PendingCalorieGoalWeeklyCheckIn(
        windowStartDate: DateTime(2026, 4, 8),
        windowEndDate: DateTime(2026, 4, 14),
        dueDate: DateTime(2026, 4, 15),
      );
      final setPending = await container
          .read(calorieGoalControllerProvider.notifier)
          .setPendingWeeklyCheckIn(pending);
      final dismissed = await container
          .read(calorieGoalControllerProvider.notifier)
          .dismissPendingWeeklyCheckIn(dismissedAt: DateTime(2026, 4, 15, 10));

      expect(setPending, isTrue);
      expect(dismissed, isTrue);
      final settings = await repository.readSettings();
      expect(settings.pendingWeeklyCheckIn?.windowKey, pending.windowKey);
      expect(
        settings.pendingWeeklyCheckIn?.dismissedAt,
        DateTime(2026, 4, 15, 10),
      );
    },
  );

  test('saveWeeklyCheckInGoal persists learned TDEE snapshot', () async {
    final repository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: const CalorieCalculatorProfile(
          sex: CalorieCalculatorSex.male,
          weightKg: 80,
          heightCm: 180,
          ageYears: 30,
          activityLevel: 1.2,
          goalMode: CalorieGoalMode.maintain,
          goalSpeedKgPerWeek: 0,
        ),
        effectiveDate: DateTime(2026, 4, 8, 9),
      ),
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);

    final saved = await container
        .read(calorieGoalControllerProvider.notifier)
        .saveWeeklyCheckInGoal(
          completedAt: DateTime(2026, 4, 15, 10),
          dailyKcalGoal: 2300,
          weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
            windowStartDate: DateTime(2026, 4, 8),
            windowEndDate: DateTime(2026, 4, 14),
            trendWeightChangePerDay: -0.08,
            calculatedTrueTdeeKcal: 2315,
            averageActiveKcal: 220,
            lowConfidence: false,
          ),
        );

    expect(saved, isTrue);
    final settings = await repository.readSettings();
    expect(settings.dailyKcalGoal, 2200);
    expect(settings.calculatorProfile?.weightKg, 80);
    expect(settings.hasLearnedTdee, isTrue);
    expect(settings.latestLearnedTdeeKcal, 2315);
    expect(settings.latestLearnedTdeeEntry?.calculatorProfile, isNull);
    expect(settings.latestGoalEntry?.source, CalorieGoalSource.manual);
    expect(settings.goalKcalForDay(DateTime(2026, 4, 14)), 2200);
    expect(settings.goalKcalForDay(DateTime(2026, 4, 15)), 2200);
    expect(
      settings.latestLearnedTdeeEntry?.weeklyCheckInSnapshot?.windowEndDate,
      DateTime(2026, 4, 14),
    );
  });

  test('saveWeeklyCheckInGoal refreshes copied calculator snapshot', () async {
    final oldSnapshot = CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: DateTime(2026, 4, 8),
      windowEndDate: DateTime(2026, 4, 14),
      trendWeightChangePerDay: -0.08,
      calculatedTrueTdeeKcal: 2315,
      averageActiveKcal: 220,
      lowConfidence: false,
      inputHash: 'v1:old',
    );
    final newSnapshot = CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: DateTime(2026, 4, 8),
      windowEndDate: DateTime(2026, 4, 14),
      trendWeightChangePerDay: -0.04,
      calculatedTrueTdeeKcal: 2340,
      averageActiveKcal: 230,
      lowConfidence: false,
      inputHash: 'v1:new',
    );
    final repository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: const CalorieCalculatorProfile.defaults(),
        effectiveDate: DateTime(2026, 4, 15, 9),
        source: CalorieGoalSource.calculator,
        weeklyCheckInSnapshot: oldSnapshot,
      ),
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);

    final saved = await container
        .read(calorieGoalControllerProvider.notifier)
        .saveWeeklyCheckInGoal(
          completedAt: DateTime(2026, 4, 15, 10),
          dailyKcalGoal: 2300,
          weeklyCheckInSnapshot: newSnapshot,
        );

    expect(saved, isTrue);
    final settings = await repository.readSettings();
    final calculatorEntry = settings.goalHistory.firstWhere(
      (entry) => !entry.isWeeklyCheckIn,
    );
    expect(calculatorEntry.weeklyCheckInSnapshot?.inputHash, 'v1:new');
    expect(
      calculatorEntry.weeklyCheckInSnapshot?.calculatedTrueTdeeKcal,
      2340,
    );
  });

  test('saveWeeklyCheckInGoal keeps same-day overdue snapshots', () async {
    final repository = FakeCalorieSettingsRepository(
      initialSettings: const CalorieGoalSettings.empty().applyGoalChange(
        changedAt: DateTime(2026, 4, 8),
        dailyKcalGoal: 2200,
        calculatorProfile: null,
      ),
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);

    final controller = container.read(calorieGoalControllerProvider.notifier);
    final firstSaved = await controller.saveWeeklyCheckInGoal(
      completedAt: DateTime(2026, 4, 25, 10),
      dailyKcalGoal: 2300,
      weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: DateTime(2026, 4, 8),
        windowEndDate: DateTime(2026, 4, 14),
        trendWeightChangePerDay: -0.08,
        calculatedTrueTdeeKcal: 2315,
        averageActiveKcal: 220,
        lowConfidence: false,
      ),
    );
    final secondSaved = await controller.saveWeeklyCheckInGoal(
      completedAt: DateTime(2026, 4, 25, 11),
      dailyKcalGoal: 2250,
      weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: DateTime(2026, 4, 15),
        windowEndDate: DateTime(2026, 4, 21),
        trendWeightChangePerDay: -0.04,
        calculatedTrueTdeeKcal: 2280,
        averageActiveKcal: 210,
        lowConfidence: true,
      ),
    );

    expect(firstSaved, isTrue);
    expect(secondSaved, isTrue);
    final settings = await repository.readSettings();
    final snapshots = settings.goalHistory
        .map((entry) => entry.weeklyCheckInSnapshot)
        .whereType<CalorieGoalWeeklyCheckInSnapshot>()
        .toList(growable: false);
    expect(snapshots, hasLength(2));
    expect(snapshots.first.windowStartDate, DateTime(2026, 4, 8));
    expect(snapshots.last.windowStartDate, DateTime(2026, 4, 15));
    expect(
      settings.goalHistory
          .where((entry) => entry.isWeeklyCheckIn)
          .every((entry) => entry.calculatorProfile == null),
      isTrue,
    );
    expect(settings.latestGoalEntry?.dailyKcalGoal, 2200);
    expect(settings.latestLearnedTdeeEntry?.dailyKcalGoal, 2250);
  });

  test(
    'invalidateWeeklyCheckInSnapshotsFromDay dirties affected snapshots',
    () async {
      final repository = FakeCalorieSettingsRepository(
        initialSettings: const CalorieGoalSettings.empty()
            .applyGoalChange(
              changedAt: DateTime(2026, 4, 8),
              dailyKcalGoal: 2200,
              calculatorProfile: null,
            )
            .applyGoalChange(
              changedAt: DateTime(2026, 4, 15),
              dailyKcalGoal: 2300,
              calculatorProfile: null,
              source: CalorieGoalSource.weeklyCheckIn,
              weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
                windowStartDate: DateTime(2026, 4, 8),
                windowEndDate: DateTime(2026, 4, 14),
                trendWeightChangePerDay: 0,
                calculatedTrueTdeeKcal: 2300,
                averageActiveKcal: 0,
                lowConfidence: false,
                inputHash: 'v1:first',
              ),
            )
            .applyGoalChange(
              changedAt: DateTime(2026, 4, 22),
              dailyKcalGoal: 2350,
              calculatorProfile: null,
              source: CalorieGoalSource.weeklyCheckIn,
              weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
                windowStartDate: DateTime(2026, 4, 15),
                windowEndDate: DateTime(2026, 4, 21),
                trendWeightChangePerDay: 0,
                calculatedTrueTdeeKcal: 2350,
                averageActiveKcal: 0,
                lowConfidence: false,
                inputHash: 'v1:second',
              ),
            ),
      );
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);

      final saved = await container
          .read(calorieGoalControllerProvider.notifier)
          .invalidateWeeklyCheckInSnapshotsFromDay(DateTime(2026, 4, 16));

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      final snapshots = settings.goalHistory
          .map((entry) => entry.weeklyCheckInSnapshot)
          .whereType<CalorieGoalWeeklyCheckInSnapshot>()
          .toList(growable: false);
      expect(snapshots, hasLength(2));
      expect(snapshots.first.inputHash, 'v1:first');
      expect(snapshots.first.invalidatedAt, isNull);
      expect(snapshots.last.inputHash, isNull);
      expect(snapshots.last.invalidatedAt, isNotNull);
      expect(settings.latestLearnedTdeeKcal, 2300);
      expect(
        settings
            .learnedTdeeEntryForDay(DateTime(2026, 4, 23))
            ?.weeklyCheckInSnapshot
            ?.windowEndDate,
        DateTime(2026, 4, 14),
      );
    },
  );

  test(
    'invalidateWeeklyCheckInSnapshotsFromDay ignores days before snapshot',
    () {
      final settings = const CalorieGoalSettings.empty().applyGoalChange(
        changedAt: DateTime(2026, 4, 15),
        dailyKcalGoal: 2300,
        calculatorProfile: null,
        source: CalorieGoalSource.weeklyCheckIn,
        weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
          windowStartDate: DateTime(2026, 4, 8),
          windowEndDate: DateTime(2026, 4, 14),
          trendWeightChangePerDay: 0,
          calculatedTrueTdeeKcal: 2300,
          averageActiveKcal: 0,
          lowConfidence: false,
          inputHash: 'v1:first',
        ),
      );

      final nextSettings = settings.invalidateWeeklyCheckInSnapshotsFromDay(
        day: DateTime(2026, 4, 7),
        invalidatedAt: DateTime(2026, 4, 20),
      );

      expect(identical(nextSettings, settings), isTrue);
      expect(
        nextSettings.goalHistory.single.weeklyCheckInSnapshot?.inputHash,
        'v1:first',
      );
    },
  );

  test('saveLearnedTdeeGoal uses learned TDEE and goal speed', () async {
    final initialSettings = const CalorieGoalSettings.empty()
        .applyGoalChange(
          changedAt: DateTime(2026, 4, 8, 9),
          dailyKcalGoal: 2200,
          calculatorProfile: const CalorieCalculatorProfile(
            sex: CalorieCalculatorSex.female,
            weightKg: 65,
            heightCm: 170,
            ageYears: 28,
            activityLevel: 1.7,
            goalMode: CalorieGoalMode.maintain,
            goalSpeedKgPerWeek: 0,
          ),
        )
        .applyGoalChange(
          changedAt: DateTime(2026, 4, 15, 9),
          dailyKcalGoal: 2300,
          calculatorProfile: const CalorieCalculatorProfile(
            sex: CalorieCalculatorSex.female,
            weightKg: 65,
            heightCm: 170,
            ageYears: 28,
            activityLevel: 1.7,
            goalMode: CalorieGoalMode.maintain,
            goalSpeedKgPerWeek: 0,
          ),
          source: CalorieGoalSource.weeklyCheckIn,
          weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
            windowStartDate: DateTime(2026, 4, 8),
            windowEndDate: DateTime(2026, 4, 14),
            trendWeightChangePerDay: -0.08,
            calculatedTrueTdeeKcal: 2450,
            averageActiveKcal: 210,
            lowConfidence: false,
          ),
        );
    final repository = FakeCalorieSettingsRepository(
      initialSettings: initialSettings,
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);

    final saved = await container
        .read(calorieGoalControllerProvider.notifier)
        .saveLearnedTdeeGoal(
          goalMode: CalorieGoalMode.lose,
          goalSpeedKgPerWeek: 0.5,
          goalStartDate: DateTime(2026, 4, 20, 8),
        );

    expect(saved, isTrue);
    final settings = await repository.readSettings();
    expect(settings.dailyKcalGoal, closeTo(1950, 0.01));
    expect(settings.calculatorProfile?.goalMode, CalorieGoalMode.lose);
    expect(settings.calculatorProfile?.goalSpeedKgPerWeek, 0.5);
    expect(settings.calculatorProfile?.activityLevel, 1.7);
    expect(settings.latestGoalEntry?.source, CalorieGoalSource.calculator);
  });

  test('saveLearnedTdeeGoal allows a future official counting start', () async {
    final today = DateTime.now();
    final initialSettings = const CalorieGoalSettings.empty()
        .applyGoalChange(
          changedAt: today.subtract(const Duration(days: 2)),
          dailyKcalGoal: 2200,
          calculatorProfile: const CalorieCalculatorProfile(
            sex: CalorieCalculatorSex.female,
            weightKg: 65,
            heightCm: 170,
            ageYears: 28,
            activityLevel: 1.7,
            goalMode: CalorieGoalMode.maintain,
            goalSpeedKgPerWeek: 0,
          ),
        )
        .applyGoalChange(
          changedAt: today.subtract(const Duration(days: 1)),
          dailyKcalGoal: 2300,
          calculatorProfile: const CalorieCalculatorProfile(
            sex: CalorieCalculatorSex.female,
            weightKg: 65,
            heightCm: 170,
            ageYears: 28,
            activityLevel: 1.7,
            goalMode: CalorieGoalMode.maintain,
            goalSpeedKgPerWeek: 0,
          ),
          source: CalorieGoalSource.weeklyCheckIn,
          weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
            windowStartDate: DateTime(2026, 4, 8),
            windowEndDate: DateTime(2026, 4, 14),
            trendWeightChangePerDay: -0.08,
            calculatedTrueTdeeKcal: 2450,
            averageActiveKcal: 210,
            lowConfidence: false,
          ),
        );
    final repository = FakeCalorieSettingsRepository(
      initialSettings: initialSettings,
    );
    addTearDown(repository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(calorieGoalControllerProvider.future);

    final saved = await container
        .read(calorieGoalControllerProvider.notifier)
        .saveLearnedTdeeGoal(
          goalMode: CalorieGoalMode.lose,
          goalSpeedKgPerWeek: 0.5,
          goalStartDate: today.add(const Duration(days: 1)),
        );

    expect(saved, isTrue);
    final settings = await repository.readSettings();
    expect(settings.dailyKcalGoal, isNotNull);
    expect(settings.latestGoalEntry?.effectiveDate, normalizeDiaryDay(today));
    expect(
      settings.latestGoalEntry?.effectiveCountingStartDate,
      normalizeDiaryDay(today.add(const Duration(days: 1))),
    );
    expect(
      settings.nextGoalStartAfterDay(today),
      normalizeDiaryDay(today.add(const Duration(days: 1))),
    );
    expect(settings.latestLearnedTdeeKcal, 2450);
  });

  test(
    'saveLearnedTdeeGoal preserves learned snapshot on same-day goal edits',
    () async {
      final today = normalizeDiaryDay(DateTime.now());
      final learnedSnapshot = CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: DateTime(2026, 4, 8),
        windowEndDate: DateTime(2026, 4, 14),
        trendWeightChangePerDay: -0.08,
        calculatedTrueTdeeKcal: 2450,
        averageActiveKcal: 210,
        lowConfidence: false,
      );
      const initialProfile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.female,
        weightKg: 65,
        heightCm: 170,
        ageYears: 28,
        activityLevel: 1.7,
        goalMode: CalorieGoalMode.maintain,
        goalSpeedKgPerWeek: 0,
      );
      final repository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: learnedSnapshot.calculatedTrueTdeeKcal,
          calculatorProfile: initialProfile,
          effectiveDate: today,
          source: CalorieGoalSource.calculator,
          weeklyCheckInSnapshot: learnedSnapshot,
        ),
      );
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);

      final saved = await container
          .read(calorieGoalControllerProvider.notifier)
          .saveLearnedTdeeGoal(
            goalMode: CalorieGoalMode.lose,
            goalSpeedKgPerWeek: 0.5,
            goalStartDate: today,
          );

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.goalHistory, hasLength(1));
      expect(settings.latestGoalEntry?.source, CalorieGoalSource.calculator);
      expect(settings.latestGoalEntry?.weeklyCheckInSnapshot, learnedSnapshot);
      expect(settings.hasLearnedTdee, isTrue);
      expect(settings.latestLearnedTdeeKcal, 2450);
    },
  );

  test(
    'saveLearnedTdeeGoal with unchanged date updates window only '
    'and preserves pending dismissal',
    () async {
      final today = normalizeDiaryDay(DateTime.now());
      final dismissedAt = today.add(const Duration(hours: 9));
      final pending = PendingCalorieGoalWeeklyCheckIn(
        windowStartDate: today.subtract(
          const Duration(days: weeklyCheckInWindowLengthDays),
        ),
        windowEndDate: today.subtract(const Duration(days: 1)),
        dueDate: today,
        dismissedAt: dismissedAt,
      );
      final learnedSnapshot = CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: DateTime(2026, 4, 8),
        windowEndDate: DateTime(2026, 4, 14),
        trendWeightChangePerDay: -0.08,
        calculatedTrueTdeeKcal: 2450,
        averageActiveKcal: 210,
        lowConfidence: false,
      );
      const profile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.female,
        weightKg: 65,
        heightCm: 170,
        ageYears: 28,
        activityLevel: 1.7,
        goalMode: CalorieGoalMode.lose,
        goalSpeedKgPerWeek: 0.5,
      );
      final repository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal:
              CalorieWeeklyCheckInCalculator.calculateGoalFromLearnedTdee(
                learnedTdeeKcal: learnedSnapshot.calculatedTrueTdeeKcal,
                goalSpeedKgPerWeek: 0.5,
                isLosing: true,
                isGaining: false,
              ),
          calculatorProfile: profile,
          effectiveDate: today,
          source: CalorieGoalSource.calculator,
          weeklyCheckInSnapshot: learnedSnapshot,
        ).copyWithPendingWeeklyCheckIn(pending),
      );
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(calorieGoalControllerProvider.future);

      final saved = await container
          .read(calorieGoalControllerProvider.notifier)
          .saveLearnedTdeeGoal(
            goalMode: CalorieGoalMode.lose,
            goalSpeedKgPerWeek: 0.5,
            goalStartDate: today,
          );

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.goalHistory, hasLength(1));
      expect(settings.pendingWeeklyCheckIn?.windowKey, pending.windowKey);
      expect(settings.pendingWeeklyCheckIn?.dismissedAt, dismissedAt);
    },
  );
}
