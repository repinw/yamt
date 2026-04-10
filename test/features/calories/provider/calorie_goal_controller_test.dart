import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

import '../support/fake_calories_repositories.dart';

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
      final goalStartAt = DateTime(2026, 4, 10, 16, 30);

      final saved = await container
          .read(calorieGoalControllerProvider.notifier)
          .saveCalculatedGoal(profile, goalStartAt: goalStartAt);

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.dailyKcalGoal, 2136);
      expect(settings.calculatorProfile?.goalMode, CalorieGoalMode.maintain);
      expect(settings.calculatorProfile?.weightKg, 80);
      expect(settings.goalHistory.single.changedAt, goalStartAt);
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
          .saveCalculatedGoal(profile, goalStartAt: DateTime(2026, 4, 10, 18));

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
      final goalStartAt = DateTime(2026, 4, 3, 16);

      final saved = await container
          .read(calorieGoalControllerProvider.notifier)
          .saveCalculatedGoal(profile, goalStartAt: goalStartAt);

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.goalHistory, hasLength(2));
      expect(settings.goalHistory.last.changedAt, goalStartAt);
      expect(settings.goalKcalForDay(DateTime(2026, 4, 2)), 2100);
      expect(settings.goalKcalForDay(DateTime(2026, 4, 6)), 2136);
    },
  );

  test(
    'saveCalculatedGoal with a future start no longer keeps the current goal active',
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
          .saveCalculatedGoal(profile, goalStartAt: futureGoalStart);

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.goalKcalForDay(today), 0);
      expect(settings.goalKcalForDay(futureGoalStart), 2136);
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
          .shiftGoalStart(goalStartAt: DateTime(2026, 4, 3, 6));

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.dailyKcalGoal, 1900);
      expect(settings.goalHistory, hasLength(2));
      expect(settings.goalHistory.last.changedAt, DateTime(2026, 4, 3, 6));
      expect(settings.goalKcalForDay(DateTime(2026, 4, 2)), 2100);
      expect(settings.goalKcalForDay(DateTime(2026, 4, 4)), 1900);
    },
  );

  test('shiftGoalStart also allows moving the goal into the future', () async {
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
        .shiftGoalStart(goalStartAt: futureGoalStart);

    expect(saved, isTrue);
    final settings = await repository.readSettings();
    expect(settings.goalKcalForDay(today), 0);
    expect(settings.goalHistory.last.changedAt, futureGoalStart);
    expect(
      settings.goalKcalForDay(futureGoalStart.add(const Duration(days: 1))),
      1900,
    );
  });
}
