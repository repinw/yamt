import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/macro_goal_settings_controller.dart';
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
        // (2400 - 1088) / 4 = 328g carbs
        expect(targets.protein, closeTo(128, 0.001));
        expect(targets.fat, closeTo(64, 0.001));
        expect(targets.carbs, closeTo(328, 0.001));
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

        // Female inactive: 1.2 P, 0.9 F
        // 60 * 1.2 = 72g protein (288 kcal)
        // 60 * 0.9 = 54g fat (486 kcal)
        // (1800 - 774) / 4 = 256.5g carbs
        expect(targets.protein, closeTo(72, 0.001));
        expect(targets.fat, closeTo(54, 0.001));
        expect(targets.carbs, closeTo(256.5, 0.001));
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

      // Fallback defaults without training days: male (1.2 P, 0.8 F), 80kg
      // 80 * 1.2 = 96g protein, 80 * 0.8 = 64g fat
      expect(targets.protein, closeTo(96, 0.001));
      expect(targets.fat, closeTo(64, 0.001));
      // (2200 - 384 - 576) / 4 = 310g
      expect(targets.carbs, closeTo(310, 0.001));
    });

    test('applies positive carryover (75% carbs / 25% fat split, protein untouched)', () {
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

      // Base: 80kg male: 96g protein, 64g fat, 360g carbs.
      // Carryover +100 kcal:
      // Protein: unchanged (96.0)
      // Carbs: 360 + (75 / 4.1)
      // Fat: 64 + (25 / 9.3)
      expect(targets.protein, closeTo(96, 0.001));
      expect(targets.carbs, closeTo(360.0 + (75.0 / 4.1), 0.01));
      expect(targets.fat, closeTo(64.0 + (25.0 / 9.3), 0.01));
    });

    test('applies negative carryover (Schutzregeln A & B)', () {
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

      // Base: 80kg male, 2000 kcal: 96g protein, 64g fat, 260g carbs.
      // Carryover -200 kcal:
      // Protein: unchanged (96.0)
      // Fat: 64 - (50 / 9.3)
      // Carbs: 260 - (150 / 4.1)
      expect(targets.protein, closeTo(96, 0.001));
      expect(targets.fat, closeTo(64.0 - (50.0 / 9.3), 0.01));
      expect(targets.carbs, closeTo(260.0 - (150.0 / 4.1), 0.01));
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
