import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/macro_budget_calculator.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';

void main() {
  group('MacroCalculationDefaults', () {
    test('protein is 1.6 g/kg with and without sport', () {
      expect(
        MacroCalculationDefaults.defaultProteinMultiplier(
          isSportActive: true,
          isLosingWeight: false,
        ),
        1.6,
      );
      expect(
        MacroCalculationDefaults.defaultProteinMultiplier(
          isSportActive: false,
          isLosingWeight: false,
        ),
        1.6,
      );
    });

    test('protein goes up to 2.0 and 1.6 g/kg while losing weight', () {
      expect(
        MacroCalculationDefaults.defaultProteinMultiplier(
          isSportActive: true,
          isLosingWeight: true,
        ),
        2.0,
      );
      expect(
        MacroCalculationDefaults.defaultProteinMultiplier(
          isSportActive: false,
          isLosingWeight: true,
        ),
        1.6,
      );
    });

    test('fat is 0.8 g/kg for men and 0.9 g/kg for women', () {
      expect(MacroCalculationDefaults.defaultFatMultiplier(isMale: true), 0.8);
      expect(MacroCalculationDefaults.defaultFatMultiplier(isMale: false), 0.9);
    });
  });

  group('MacroGoalSettings', () {
    test('follows the training days until the user sets sport', () {
      const auto = MacroGoalSettings();
      expect(auto.resolveSportActive(hasTrainingDays: true), isTrue);
      expect(auto.resolveSportActive(hasTrainingDays: false), isFalse);

      const explicit = MacroGoalSettings(isSportActive: false);
      expect(explicit.resolveSportActive(hasTrainingDays: true), isFalse);
    });

    test('effective multipliers fall back to defaults when not overridden', () {
      const settings = MacroGoalSettings();
      expect(
        settings.effectiveProteinMultiplier(
          hasTrainingDays: true,
          isLosingWeight: false,
        ),
        1.6,
      );
      expect(
        settings.effectiveProteinMultiplier(
          hasTrainingDays: false,
          isLosingWeight: false,
        ),
        1.6,
      );
      expect(settings.effectiveFatMultiplier(isMale: true), 0.8);
      expect(settings.effectiveFatMultiplier(isMale: false), 0.9);
    });

    test('effective multipliers respect custom overrides', () {
      const settings = MacroGoalSettings(
        customProteinMultiplier: 2.3,
        customFatMultiplier: 0.8,
      );
      expect(
        settings.effectiveProteinMultiplier(
          hasTrainingDays: false,
          isLosingWeight: true,
        ),
        2.3,
      );
      // Custom overrides apply regardless of sex or activity
      expect(settings.effectiveFatMultiplier(isMale: true), 0.8);
      expect(settings.effectiveFatMultiplier(isMale: false), 0.8);
    });

    group('resolveProteinGrams', () {
      test('uses the g/kg rule when not losing weight', () {
        const settings = MacroGoalSettings();
        expect(
          settings.resolveProteinGrams(
            referenceWeightKg: 80,
            baseGoalKcal: 1500,
            fatGrams: 80 * 0.8,
            hasTrainingDays: true,
            isLosingWeight: false,
          ),
          closeTo(128, 1e-9),
        );
      });

      test('caps protein at 35 % of the base goal while losing weight', () {
        // 2.0 g/kg x 75.66 kg = 151 g, but 35 % of 1614 kcal is 141 g.
        const settings = MacroGoalSettings();
        expect(
          settings.resolveProteinGrams(
            referenceWeightKg: 75.66,
            baseGoalKcal: 1614,
            fatGrams: 75.66 * 0.8,
            hasTrainingDays: true,
            isLosingWeight: true,
          ),
          closeTo(1614 * 0.35 / 4, 1e-9),
        );
      });

      test('lifts protein to 30 % of the base goal while losing weight', () {
        // 1.6 g/kg x 75.5 kg = 121 g, but 30 % of 2099 kcal is 157 g.
        const settings = MacroGoalSettings();
        expect(
          settings.resolveProteinGrams(
            referenceWeightKg: 75.5,
            baseGoalKcal: 2099,
            fatGrams: 75.5 * 0.8,
            hasTrainingDays: false,
            isLosingWeight: true,
          ),
          closeTo(2099 * 0.30 / 4, 1e-9),
        );
      });

      test('keeps the g/kg rule inside the band while losing weight', () {
        // 2.0 g/kg x 70 kg = 140 g, between 30 % (135 g) and 35 % (158 g).
        const settings = MacroGoalSettings();
        expect(
          settings.resolveProteinGrams(
            referenceWeightKg: 70,
            baseGoalKcal: 1800,
            fatGrams: 70 * 0.8,
            hasTrainingDays: true,
            isLosingWeight: true,
          ),
          closeTo(140, 1e-9),
        );
      });

      test('gives protein the kcal above the carb cap up to 2.0 g/kg', () {
        // 128 g protein and 64 g fat leave 328 g carbs at 2400 kcal. The cap
        // allows 240 g, so protein takes 352 kcal but stops at 160 g.
        const settings = MacroGoalSettings();
        expect(
          settings.resolveProteinGrams(
            referenceWeightKg: 80,
            baseGoalKcal: 2400,
            fatGrams: 64,
            hasTrainingDays: false,
            isLosingWeight: false,
          ),
          closeTo(160, 1e-9),
        );
      });

      test('gives protein only part of the room when the excess is small', () {
        // 128 g protein and 64 g fat leave 228 g carbs at 2000 kcal; the
        // 28 g above the 200 g cap go to protein.
        const settings = MacroGoalSettings();
        expect(
          settings.resolveProteinGrams(
            referenceWeightKg: 80,
            baseGoalKcal: 2000,
            fatGrams: 64,
            hasTrainingDays: false,
            isLosingWeight: false,
          ),
          closeTo(156, 1e-9),
        );
      });

      test('keeps a custom multiplier above the carb cap', () {
        const settings = MacroGoalSettings(customProteinMultiplier: 1.2);
        expect(
          settings.resolveProteinGrams(
            referenceWeightKg: 80,
            baseGoalKcal: 3000,
            fatGrams: 64,
            hasTrainingDays: false,
            isLosingWeight: false,
          ),
          closeTo(96, 1e-9),
        );
      });

      test('uses a custom multiplier as it is while losing weight', () {
        const settings = MacroGoalSettings(customProteinMultiplier: 1.2);
        expect(
          settings.resolveProteinGrams(
            referenceWeightKg: 80,
            baseGoalKcal: 2000,
            fatGrams: 80 * 0.8,
            hasTrainingDays: true,
            isLosingWeight: true,
          ),
          closeTo(96, 1e-9),
        );
      });
    });

    test('copyWith can clear custom overrides back to defaults', () {
      const settings = MacroGoalSettings(
        customProteinMultiplier: 2.5,
        customFatMultiplier: 1.5,
      );
      final clearedProtein = settings.copyWith(clearCustomProtein: true);
      expect(clearedProtein.customProteinMultiplier, isNull);
      expect(clearedProtein.customFatMultiplier, 1.5);
      expect(
        clearedProtein.effectiveProteinMultiplier(
          hasTrainingDays: true,
          isLosingWeight: false,
        ),
        1.6,
      );

      final clearedBoth = settings.copyWith(
        clearCustomProtein: true,
        clearCustomFat: true,
      );
      expect(clearedBoth.customProteinMultiplier, isNull);
      expect(clearedBoth.customFatMultiplier, isNull);
      expect(clearedBoth.effectiveFatMultiplier(isMale: true), 0.8);
    });

    test('serialization round-trip preserves all properties', () {
      const settings = MacroGoalSettings(
        isSportActive: false,
        customProteinMultiplier: 1.5,
        customFatMultiplier: 1.1,
      );
      final json = settings.toJson();
      final parsed = MacroGoalSettings.fromJson(json);
      expect(parsed, equals(settings));

      final jsonString = settings.toJsonString();
      final fromString = MacroGoalSettings.fromJsonString(jsonString);
      expect(fromString, equals(settings));
    });

    test('fromJsonString handles null, empty, and invalid json gracefully', () {
      expect(MacroGoalSettings.fromJsonString(null), isNull);
      expect(MacroGoalSettings.fromJsonString(''), isNull);
      expect(MacroGoalSettings.fromJsonString('{invalid json}'), isNull);
      expect(MacroGoalSettings.fromJsonString('[]'), isNull);
      expect(MacroGoalSettings.fromJsonString('"string"'), isNull);
    });

    test('equality and hashCode distinguish different configurations', () {
      const a = MacroGoalSettings();
      const b = MacroGoalSettings(isSportActive: false);
      const c = MacroGoalSettings(customProteinMultiplier: 2);
      const d = MacroGoalSettings(customProteinMultiplier: 2);

      expect(a == b, isFalse);
      expect(a == c, isFalse);
      expect(c == d, isTrue);
      expect(c.hashCode, equals(d.hashCode));
    });
  });

  group('MacroBudgetCalculator.calculate', () {
    test('calculates correct macros for 80kg male active at 2400 kcal', () {
      final targets = MacroBudgetCalculator.calculate(
        goalKcal: 2400,
        weightKg: 80,
        proteinGramsPerKg: 2,
        fatGramsPerKg: 1,
      );

      // Protein: 80 * 2.0 = 160g (640 kcal)
      // Fat: 80 * 1.0 = 80g (720 kcal)
      // Carbs: (2400 - 640 - 720) / 4 = 260g, capped at 40 % = 240g.
      // The 80 kcal excess goes to fat.
      expect(targets.protein, 160.0);
      expect(targets.fat, closeTo(80 + 80 / 9, 0.001));
      expect(targets.carbs, 240.0);
    });

    test('calculates correct macros for 65kg female active at 2000 kcal', () {
      final targets = MacroBudgetCalculator.calculate(
        goalKcal: 2000,
        weightKg: 65,
        proteinGramsPerKg: 1.8,
        fatGramsPerKg: 1.2,
      );

      // Protein: 65 * 1.8 = 117g (468 kcal)
      // Fat: 65 * 1.2 = 78g (702 kcal)
      // Carbs: (2000 - 468 - 702) / 4 = 207.5g, capped at 40 % = 200g.
      // The 30 kcal excess goes to fat.
      expect(targets.protein, 117.0);
      expect(targets.fat, closeTo(78 + 30 / 9, 0.001));
      expect(targets.carbs, 200.0);
    });

    test(
      'balances fat and protein to guarantee 100g carbs floor at 1526 kcal',
      () {
        // 80kg male at 1526 kcal (2.0 P, 1.0 F):
        // Unadjusted: 160g P (640 kcal), 80g F (720 kcal) -> 1360 kcal.
        // Remaining = 166 kcal -> 41.5g carbs (< 100g).
        // Fat floor for 80kg: 80 * 0.6 = 48g.
        // Deficit to reach 100g carbs (400 kcal) = 400 - 166 = 234 kcal.
        // Fat reduction = 234 / 9 = 26g -> Fat = 80 - 26 = 54g (486 kcal).
        // Protein stays at 160g (640 kcal).
        // Carbs = (1526 - 640 - 486) / 4 = 400 / 4 = 100g.
        final targets = MacroBudgetCalculator.calculate(
          goalKcal: 1526,
          weightKg: 80,
          proteinGramsPerKg: 2,
          fatGramsPerKg: 1,
        );

        expect(targets.protein, 160.0);
        expect(targets.fat, 54.0);
        expect(targets.carbs, 100.0);
      },
    );

    test('cuts protein for the carbs floor down to its own floor', () {
      // 1300 kcal goal for 90kg person (2.0 P, 1.0 F):
      // Fat floor: 90 * 0.6 = 54g (486 kcal).
      // Carbs floor: 100g (400 kcal).
      // Remainder for protein: 1300 - 486 - 400 = 414 kcal -> 103.5g,
      // above the protein floor of 90 * 0.8 = 72g.
      final targets = MacroBudgetCalculator.calculate(
        goalKcal: 1300,
        weightKg: 90,
        proteinGramsPerKg: 2,
        fatGramsPerKg: 1,
      );

      expect(targets.protein, 103.5);
      expect(targets.fat, 54.0);
      expect(targets.carbs, 100.0);
    });

    test('keeps the protein floor before the carbs floor', () {
      // 1000 kcal goal for 90kg person (2.0 P, 1.0 F):
      // Fat floor 54g (486 kcal), protein floor 90 * 0.8 = 72g (288 kcal).
      // Carbs get the rest: (1000 - 486 - 288) / 4 = 56.5g.
      final targets = MacroBudgetCalculator.calculate(
        goalKcal: 1000,
        weightKg: 90,
        proteinGramsPerKg: 2,
        fatGramsPerKg: 1,
      );

      expect(targets.protein, 72.0);
      expect(targets.fat, 54.0);
      expect(targets.carbs, 56.5);
    });

    test('never raises protein that is below its floor', () {
      // 0.5 g/kg protein at 80kg is 40g, below the 64g floor; it stays.
      // Fat floor 48g (432 kcal), carbs get (900 - 160 - 432) / 4 = 77g.
      final targets = MacroBudgetCalculator.calculate(
        goalKcal: 900,
        weightKg: 80,
        proteinGramsPerKg: 0.5,
        fatGramsPerKg: 1,
      );

      expect(targets.protein, 40.0);
      expect(targets.fat, 48.0);
      expect(targets.carbs, 77.0);
    });

    test('clamps all macros to zero when goalKcal <= 0', () {
      final zeroTarget = MacroBudgetCalculator.calculate(
        goalKcal: 0,
        weightKg: 80,
        proteinGramsPerKg: 2,
        fatGramsPerKg: 1,
      );
      expect(zeroTarget.protein, 0.0);
      expect(zeroTarget.fat, 0.0);
      expect(zeroTarget.carbs, 0.0);

      final negativeTarget = MacroBudgetCalculator.calculate(
        goalKcal: -500,
        weightKg: 80,
        proteinGramsPerKg: 2,
        fatGramsPerKg: 1,
      );
      expect(negativeTarget.protein, 0.0);
      expect(negativeTarget.fat, 0.0);
      expect(negativeTarget.carbs, 0.0);
    });

    test('falls back to safe default weight when weightKg <= 0', () {
      // When weight is 0 or negative, should use safe weight fallback (70kg)
      final targets = MacroBudgetCalculator.calculate(
        goalKcal: 1900,
        weightKg: 0,
        proteinGramsPerKg: 2,
        fatGramsPerKg: 1,
      );
      // 70kg * 2.0 = 140g protein (560 kcal)
      // 70kg * 1.0 = 70g fat (630 kcal)
      // (1900 - 1190) / 4 = 177.5g carbs
      expect(targets.protein, 140.0);
      expect(targets.fat, 70.0);
      expect(targets.carbs, 177.5);

      final negativeWeightTargets = MacroBudgetCalculator.calculate(
        goalKcal: 1900,
        weightKg: -75,
        proteinGramsPerKg: 2,
        fatGramsPerKg: 1,
      );
      expect(negativeWeightTargets.protein, 140.0);
      expect(negativeWeightTargets.fat, 70.0);
      expect(negativeWeightTargets.carbs, 177.5);
    });

    test('handles zero multipliers by attributing all calories to carbs', () {
      final targets = MacroBudgetCalculator.calculate(
        goalKcal: 2000,
        weightKg: 80,
        proteinGramsPerKg: 0,
        fatGramsPerKg: 0,
      );

      expect(targets.protein, 0.0);
      expect(targets.fat, 0.0);
      expect(targets.carbs, 500.0); // 2000 / 4 = 500g
    });
  });
}
