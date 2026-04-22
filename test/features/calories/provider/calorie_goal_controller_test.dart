import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/provider/health_connection_service_provider.dart';
import 'package:yamt/features/health/provider/manual_health_weight_repository_provider.dart';

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
            eatingWindowStartMinuteOfDay: 8 * 60,
            eatingWindowEndMinuteOfDay: (20 * 60) + 30,
          );

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.dailyKcalGoal, 2136);
      expect(settings.calculatorProfile?.goalMode, CalorieGoalMode.maintain);
      expect(settings.calculatorProfile?.weightKg, 80);
      expect(settings.goalHistory.single.changedAt, DateTime(2026, 4, 10));
      expect(settings.normalizedEatingWindowStartMinuteOfDay, 8 * 60);
      expect(settings.normalizedEatingWindowEndMinuteOfDay, (20 * 60) + 30);
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
          eatingWindowStartMinuteOfDay: 8 * 60,
          eatingWindowEndMinuteOfDay: 20 * 60,
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
            eatingWindowStartMinuteOfDay: (7 * 60) + 15,
            eatingWindowEndMinuteOfDay: (21 * 60) + 45,
          );

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.goalHistory, hasLength(1));
      expect(settings.normalizedEatingWindowStartMinuteOfDay, (7 * 60) + 15);
      expect(settings.normalizedEatingWindowEndMinuteOfDay, (21 * 60) + 45);
      expect(settings.pendingWeeklyCheckIn?.windowKey, pending.windowKey);
      expect(settings.pendingWeeklyCheckIn?.dismissedAt, dismissedAt);
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

  test('shiftGoalStart rejects a future goal start', () async {
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

    expect(saved, isFalse);
    final settings = await repository.readSettings();
    expect(settings.goalKcalForDay(today), 1900);
    expect(settings.goalHistory, hasLength(1));
    expect(settings.goalHistory.single.changedAt, today);
  });

  test('shiftGoalStart can move the eating window with the goal', () async {
    final initialSettings = CalorieGoalSettings.single(
      dailyKcalGoal: 1900,
      calculatorProfile: null,
      effectiveDate: DateTime(2026, 4, 1, 8),
      eatingWindowStartMinuteOfDay: 8 * 60,
      eatingWindowEndMinuteOfDay: 20 * 60,
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
          goalStartDate: DateTime(2026, 4, 3, 6),
          eatingWindowStartMinuteOfDay: (7 * 60) + 15,
          eatingWindowEndMinuteOfDay: (21 * 60) + 45,
        );

    expect(saved, isTrue);
    final settings = await repository.readSettings();
    expect(settings.goalHistory.last.changedAt, DateTime(2026, 4, 3));
    expect(settings.normalizedEatingWindowStartMinuteOfDay, (7 * 60) + 15);
    expect(settings.normalizedEatingWindowEndMinuteOfDay, (21 * 60) + 45);
  });

  test(
    'shiftGoalStart with unchanged date updates window only '
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
      final initialSettings = CalorieGoalSettings.single(
        dailyKcalGoal: 1900,
        calculatorProfile: null,
        effectiveDate: today,
        eatingWindowStartMinuteOfDay: 8 * 60,
        eatingWindowEndMinuteOfDay: 20 * 60,
      ).copyWithPendingWeeklyCheckIn(pending);
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
            goalStartDate: today,
            eatingWindowStartMinuteOfDay: (7 * 60) + 15,
            eatingWindowEndMinuteOfDay: (21 * 60) + 45,
          );

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.goalHistory, hasLength(1));
      expect(settings.normalizedEatingWindowStartMinuteOfDay, (7 * 60) + 15);
      expect(settings.normalizedEatingWindowEndMinuteOfDay, (21 * 60) + 45);
      expect(settings.pendingWeeklyCheckIn?.windowKey, pending.windowKey);
      expect(settings.pendingWeeklyCheckIn?.dismissedAt, dismissedAt);
    },
  );

  test(
    'shiftGoalStart rejects future goal dates with eating window edits',
    () async {
      final today = DateTime.now();
      final initialSettings = CalorieGoalSettings.single(
        dailyKcalGoal: 1900,
        calculatorProfile: null,
        effectiveDate: today,
        eatingWindowStartMinuteOfDay: 8 * 60,
        eatingWindowEndMinuteOfDay: 20 * 60,
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
            eatingWindowStartMinuteOfDay: (7 * 60) + 15,
            eatingWindowEndMinuteOfDay: (21 * 60) + 45,
          );

      expect(saved, isFalse);
      final settings = await repository.readSettings();
      expect(settings.goalHistory, hasLength(1));
      expect(settings.goalHistory.single.changedAt, today);
      expect(settings.normalizedEatingWindowStartMinuteOfDay, 8 * 60);
      expect(settings.normalizedEatingWindowEndMinuteOfDay, 20 * 60);
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
      expect(settings.latestGoalEntry?.dailyKcalGoal, 2300);
      expect(settings.latestGoalEntry?.source, CalorieGoalSource.weeklyCheckIn);
      expect(settings.latestGoalEntry?.weeklyCheckInSnapshot, isNotNull);
      expect(settings.hasLearnedTdee, isTrue);
      expect(settings.latestLearnedTdeeKcal, 2315);
      expect(
        settings.goalKcalForDay(today.subtract(const Duration(days: 3))),
        2200,
      );
      expect(settings.goalKcalForDay(today), 2300);
    },
  );

  test('setEatingWindow persists the selected diary pacing window', () async {
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
        .setEatingWindow(
          startMinuteOfDay: (7 * 60) + 15,
          endMinuteOfDay: (21 * 60) + 45,
        );

    expect(saved, isTrue);
    final settings = await repository.readSettings();
    expect(settings.normalizedEatingWindowStartMinuteOfDay, (7 * 60) + 15);
    expect(settings.normalizedEatingWindowEndMinuteOfDay, (21 * 60) + 45);
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
    expect(settings.dailyKcalGoal, 2300);
    expect(settings.hasLearnedTdee, isTrue);
    expect(settings.latestLearnedTdeeKcal, 2315);
    expect(settings.latestGoalEntry?.source, CalorieGoalSource.weeklyCheckIn);
    expect(settings.goalKcalForDay(DateTime(2026, 4, 14)), 2200);
    expect(settings.goalKcalForDay(DateTime(2026, 4, 15)), 2300);
    expect(
      settings.latestGoalEntry?.weeklyCheckInSnapshot?.windowEndDate,
      DateTime(2026, 4, 14),
    );
  });

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

  test('saveLearnedTdeeGoal rejects a future goal start', () async {
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

    expect(saved, isFalse);
    final settings = await repository.readSettings();
    expect(settings.dailyKcalGoal, 2300);
    expect(settings.latestGoalEntry?.source, CalorieGoalSource.weeklyCheckIn);
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
          eatingWindowStartMinuteOfDay: 8 * 60,
          eatingWindowEndMinuteOfDay: 20 * 60,
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
            eatingWindowStartMinuteOfDay: (7 * 60) + 15,
            eatingWindowEndMinuteOfDay: (21 * 60) + 45,
          );

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.goalHistory, hasLength(1));
      expect(settings.normalizedEatingWindowStartMinuteOfDay, (7 * 60) + 15);
      expect(settings.normalizedEatingWindowEndMinuteOfDay, (21 * 60) + 45);
      expect(settings.pendingWeeklyCheckIn?.windowKey, pending.windowKey);
      expect(settings.pendingWeeklyCheckIn?.dismissedAt, dismissedAt);
    },
  );
}
