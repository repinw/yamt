import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/daily_nutrition_target_resolver_service.dart';
import 'package:yamt/features/calories/application/macro_goal_settings_controller.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/diary/application/diary_macro_targets_resolver.dart';

import '../../../helpers/memory_app_preferences.dart';

final _day = DateTime(2026, 5, 24);

void main() {
  group('resolveDiaryMacroTargets', () {
    test(
      'resolves default targets for active male profile (80kg at 2400 kcal)',
      () {
        final preferences = MemoryAppPreferences();
        final container = ProviderContainer(
          overrides: [
            appPreferencesProvider.overrideWithValue(preferences),
            calorieGoalControllerProvider.overrideWith(
              () => _FakeCalorieGoalController(
                const CalorieGoalSettings.empty().copyWith(
                  dailyKcalGoal: 2400,
                  calculatorProfile: const CalorieCalculatorProfile(
                    sex: CalorieCalculatorSex.male,
                    weightKg: 80,
                    heightCm: 180,
                    ageYears: 30,
                    activityLevel: 1.55,
                    goalMode: CalorieGoalMode.maintain,
                    goalSpeedKgPerWeek: 0,
                    trainingWeekdays: [1, 3, 5],
                  ),
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final targets = container
            .listen(
              Provider(
                (ref) =>
                    resolveDiaryMacroTargets(ref, day: _day, goalKcal: 2400),
              ),
              (_, _) {},
            )
            .read();

        // Male active: 1.6 P, 0.8 F
        // 80 * 1.6 = 128g protein (512 kcal)
        // 80 * 0.8 = 64g fat (576 kcal)
        // (2400 - 1088) / 4 = 328g carbs, capped at 40 % = 240g.
        // The 352 kcal excess raises protein to 2.0 g/kg (+128 kcal), the
        // rest goes to fat.
        expect(targets.protein, closeTo(160, 0.001));
        expect(targets.fat, closeTo(64 + 224 / 9, 0.001));
        expect(targets.carbs, closeTo(240, 0.001));
      },
    );

    test(
      'resolves targets for inactive female profile (60kg at 1800 kcal)',
      () async {
        final preferences = MemoryAppPreferences();
        final container = ProviderContainer(
          overrides: [
            appPreferencesProvider.overrideWithValue(preferences),
            calorieGoalControllerProvider.overrideWith(
              () => _FakeCalorieGoalController(
                const CalorieGoalSettings.empty().copyWith(
                  dailyKcalGoal: 1800,
                  calculatorProfile: const CalorieCalculatorProfile(
                    sex: CalorieCalculatorSex.female,
                    weightKg: 60,
                    heightCm: 165,
                    ageYears: 28,
                    activityLevel: 1.2,
                    goalMode: CalorieGoalMode.maintain,
                    goalSpeedKgPerWeek: 0,
                  ),
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Set inactive in macro settings
        await container
            .read(macroGoalSettingsControllerProvider.notifier)
            .setSportActive(isSportActive: false);

        final targets = container
            .listen(
              Provider(
                (ref) =>
                    resolveDiaryMacroTargets(ref, day: _day, goalKcal: 1800),
              ),
              (_, _) {},
            )
            .read();

        // Female inactive: 1.6 P, 0.9 F
        // 60 * 1.6 = 96g protein (384 kcal)
        // 60 * 0.9 = 54g fat (486 kcal)
        // (1800 - 870) / 4 = 232.5g carbs, capped at 40 % = 180g.
        // The 210 kcal excess raises protein to 2.0 g/kg (+96 kcal), the
        // rest goes to fat.
        expect(targets.protein, closeTo(120, 0.001));
        expect(targets.fat, closeTo(54 + 114 / 9, 0.001));
        expect(targets.carbs, closeTo(180, 0.001));
      },
    );

    test('respects custom multiplier overrides from macro settings', () async {
      final preferences = MemoryAppPreferences();
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(preferences),
          calorieGoalControllerProvider.overrideWith(
            () => _FakeCalorieGoalController(
              const CalorieGoalSettings.empty().copyWith(
                dailyKcalGoal: 2000,
                calculatorProfile: const CalorieCalculatorProfile(
                  sex: CalorieCalculatorSex.male,
                  weightKg: 75,
                  heightCm: 175,
                  ageYears: 25,
                  activityLevel: 1.55,
                  goalMode: CalorieGoalMode.maintain,
                  goalSpeedKgPerWeek: 0,
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Custom 2.2 P, 0.8 F
      await container
          .read(macroGoalSettingsControllerProvider.notifier)
          .setCustomMultipliers(proteinMultiplier: 2.2, fatMultiplier: 0.8);

      final targets = container
          .listen(
            Provider(
              (ref) => resolveDiaryMacroTargets(ref, day: _day, goalKcal: 2000),
            ),
            (_, _) {},
          )
          .read();

      // 75 * 2.2 = 165g protein (660 kcal)
      // 75 * 0.8 = 60g fat (540 kcal)
      // (2000 - 1200) / 4 = 200g carbs
      expect(targets.protein, 165.0);
      expect(targets.fat, 60.0);
      expect(targets.carbs, 200.0);
    });

    test('falls back safely when goal settings and profile are absent', () {
      final preferences = MemoryAppPreferences();
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      final targets = container
          .listen(
            Provider(
              (ref) => resolveDiaryMacroTargets(ref, day: _day, goalKcal: 2200),
            ),
            (_, _) {},
          )
          .read();

      // Fallback defaults: male (1.6 P, 0.8 F), 80kg
      // 80 * 1.6 = 128g protein, 80 * 0.8 = 64g fat
      // (2200 - 512 - 576) / 4 = 278g carbs, capped at 40 % = 220g.
      // The 232 kcal excess raises protein to 160g, the rest goes to fat.
      expect(targets.protein, closeTo(160, 0.001));
      expect(targets.fat, closeTo(64 + 104 / 9, 0.001));
      expect(targets.carbs, closeTo(220, 0.001));
    });

    test('applies positive carryover up to the carb cap', () {
      final preferences = MemoryAppPreferences();
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      final targets = container
          .listen(
            Provider(
              (ref) => resolveDiaryMacroTargets(
                ref,
                day: _day,
                goalKcal: 2400,
                carryoverKcal: 100,
              ),
            ),
            (_, _) {},
          )
          .read();

      // Base: 80kg male, 2400 kcal: 160g protein, 64 + 224 / 9 g fat,
      // 240g carbs.
      // Carryover +100 kcal:
      // Protein: unchanged (160.0)
      // Carbs: 40 % of 2500 kcal allow 250g, so only +10g.
      // Fat: base + the other 60 kcal.
      expect(targets.protein, closeTo(160, 0.001));
      expect(targets.carbs, closeTo(250, 0.01));
      expect(targets.fat, closeTo(64.0 + 224 / 9 + (60 / 9), 0.01));
    });

    test('resolves the carryover delta from the same rule', () {
      final preferences = MemoryAppPreferences();
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      final delta = container
          .listen(
            Provider(
              (ref) => resolveDiaryCarryoverMacroDelta(
                ref.watch(dailyNutritionTargetResolverProvider),
                day: _day,
                goalKcal: 2400,
                carryoverKcal: 100,
              ),
            ),
            (_, _) {},
          )
          .read();

      // Same case as the positive carryover test: carbs +10g up to the cap,
      // the other 60 kcal go to fat, protein stays.
      expect(delta.protein, closeTo(0, 0.001));
      expect(delta.carbs, closeTo(10, 0.01));
      expect(delta.fat, closeTo(60 / 9, 0.01));
    });

    test('applies a negative carryover like a smaller day goal', () {
      final preferences = MemoryAppPreferences();
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      final targets = container
          .listen(
            Provider(
              (ref) => resolveDiaryMacroTargets(
                ref,
                day: _day,
                goalKcal: 2000,
                carryoverKcal: -200,
              ),
            ),
            (_, _) {},
          )
          .read();

      // The day counts like a 1800 kcal day: protein 156 g and fat 64 g
      // stay, carbs get the rest (150 g), below the 40 % cap of 180 g.
      expect(targets.protein, closeTo(156, 0.001));
      expect(targets.fat, closeTo(64, 0.01));
      expect(targets.carbs, closeTo(150, 0.01));
    });

    test('a negative carryover below the floors cuts protein', () {
      final preferences = MemoryAppPreferences();
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      final targets = container
          .listen(
            Provider(
              (ref) => resolveDiaryMacroTargets(
                ref,
                day: _day,
                goalKcal: 1400,
                carryoverKcal: -300,
              ),
            ),
            (_, _) {},
          )
          .read();

      // The day counts like a 1100 kcal day, as in the base budget: carbs
      // keep their 100 g floor, fat drops to its floor of 80 kg * 0.6 = 48 g,
      // and protein gets the rest.
      expect(targets.carbs, closeTo(100, 0.01));
      expect(targets.fat, closeTo(48, 0.01));
      expect(targets.protein, closeTo((1100 - 400 - 48 * 9) / 4, 0.01));
    });

    test('a large negative carryover keeps the protein floor', () {
      final preferences = MemoryAppPreferences();
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      final targets = container
          .listen(
            Provider(
              (ref) => resolveDiaryMacroTargets(
                ref,
                day: _day,
                goalKcal: 1400,
                carryoverKcal: -550,
              ),
            ),
            (_, _) {},
          )
          .read();

      // The day counts like an 850 kcal day: fat stays at 48 g, protein at
      // its floor of 80 kg * 0.8 = 64 g, and carbs get the rest below 100 g.
      expect(targets.fat, closeTo(48, 0.01));
      expect(targets.protein, closeTo(64, 0.01));
      expect(targets.carbs, closeTo((850 - 48 * 9 - 64 * 4) / 4, 0.01));
    });
  });
}

class _FakeCalorieGoalController extends CalorieGoalController {
  new(this._settings);

  final CalorieGoalSettings _settings;

  @override
  CalorieGoalSettings build() {
    return _settings;
  }
}
