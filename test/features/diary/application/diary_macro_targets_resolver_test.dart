import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/macro_goal_settings_controller.dart';
import 'package:yamt/features/diary/application/diary_macro_targets_resolver.dart';

import '../../../helpers/memory_app_preferences.dart';

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
                  ),
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final targets = container
            .listen(
              Provider((ref) => resolveDiaryMacroTargets(ref, goalKcal: 2400)),
              (_, _) {},
            )
            .read();

        // Male active: 2.0 P, 1.0 F
        // 80 * 2.0 = 160g protein (640 kcal)
        // 80 * 1.0 = 80g fat (720 kcal)
        // (2400 - 1360) / 4 = 260g carbs
        expect(targets.protein, 160.0);
        expect(targets.fat, 80.0);
        expect(targets.carbs, 260.0);
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
              Provider((ref) => resolveDiaryMacroTargets(ref, goalKcal: 1800)),
              (_, _) {},
            )
            .read();

        // Female inactive: 1.2 P, 1.0 F
        // 60 * 1.2 = 72g protein (288 kcal)
        // 60 * 1.0 = 60g fat (540 kcal)
        // (1800 - 828) / 4 = 243g carbs
        expect(targets.protein, 72.0);
        expect(targets.fat, 60.0);
        expect(targets.carbs, 243.0);
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
          .setCustomMultipliers(
            proteinMultiplier: 2.2,
            fatMultiplier: 0.8,
          );

      final targets = container
          .listen(
            Provider((ref) => resolveDiaryMacroTargets(ref, goalKcal: 2000)),
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
        overrides: [
          appPreferencesProvider.overrideWithValue(preferences),
        ],
      );
      addTearDown(container.dispose);

      final targets = container
          .listen(
            Provider((ref) => resolveDiaryMacroTargets(ref, goalKcal: 2200)),
            (_, _) {},
          )
          .read();

      // Fallback defaults: male (2.0 P, 1.0 F), 80kg
      // 80 * 2.0 = 160g protein, 80 * 1.0 = 80g fat
      expect(targets.protein, 160.0);
      expect(targets.fat, 80.0);
      expect(targets.carbs, 210.0); // (2200 - 640 - 720) / 4 = 840 / 4 = 210g
    });

    test('applies positive carryover (75% carbs / 25% fat split, protein untouched)', () {
      final preferences = MemoryAppPreferences();
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(preferences),
        ],
      );
      addTearDown(container.dispose);

      final targets = container
          .listen(
            Provider(
              (ref) => resolveDiaryMacroTargets(
                ref,
                goalKcal: 2400,
                carryoverKcal: 100,
              ),
            ),
            (_, _) {},
          )
          .read();

      // Base: 80kg male: 160g protein, 80g fat, 260g carbs.
      // Carryover +100 kcal:
      // Protein: unchanged (160.0)
      // Carbs: 260 + (75 / 4.1) = 278.29g
      // Fat: 80 + (25 / 9.3) = 82.69g
      expect(targets.protein, 160.0);
      expect(targets.carbs, closeTo(260.0 + (75.0 / 4.1), 0.01));
      expect(targets.fat, closeTo(80.0 + (25.0 / 9.3), 0.01));
    });

    test('applies negative carryover (Schutzregeln A & B)', () {
      final preferences = MemoryAppPreferences();
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(preferences),
        ],
      );
      addTearDown(container.dispose);

      final targets = container
          .listen(
            Provider(
              (ref) => resolveDiaryMacroTargets(
                ref,
                goalKcal: 2000,
                carryoverKcal: -200,
              ),
            ),
            (_, _) {},
          )
          .read();

      // Base: 80kg male, 2000 kcal: 160g protein, 80g fat, 160g carbs.
      // Carryover -200 kcal:
      // Protein: unchanged (160.0)
      // Fat: 80 - (50 / 9.3) = 74.62g
      // Carbs: 160 - (150 / 4.1) = 123.41g
      expect(targets.protein, 160.0);
      expect(targets.fat, closeTo(80.0 - (50.0 / 9.3), 0.01));
      expect(targets.carbs, closeTo(160.0 - (150.0 / 4.1), 0.01));
    });
  });
}

class _FakeCalorieGoalController extends CalorieGoalController {
  _FakeCalorieGoalController(this._settings);

  final CalorieGoalSettings _settings;

  @override
  CalorieGoalSettings build() {
    return _settings;
  }
}
