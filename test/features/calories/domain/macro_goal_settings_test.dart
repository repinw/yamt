import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';

void main() {
  group('MacroCalculationDefaults', () {
    test('protein is 1.6 g/kg with sport and 1.2 g/kg without', () {
      expect(
        MacroCalculationDefaults.defaultProteinMultiplier(isSportActive: true),
        1.6,
      );
      expect(
        MacroCalculationDefaults.defaultProteinMultiplier(isSportActive: false),
        1.2,
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
      expect(settings.effectiveProteinMultiplier(hasTrainingDays: true), 1.6);
      expect(settings.effectiveProteinMultiplier(hasTrainingDays: false), 1.2);
      expect(settings.effectiveFatMultiplier(isMale: true), 0.8);
      expect(settings.effectiveFatMultiplier(isMale: false), 0.9);
    });

    test('effective multipliers respect custom overrides', () {
      const settings = MacroGoalSettings(
        customProteinMultiplier: 2.3,
        customFatMultiplier: 0.8,
      );
      expect(settings.effectiveProteinMultiplier(hasTrainingDays: false), 2.3);
      // Custom overrides apply regardless of sex or activity
      expect(settings.effectiveFatMultiplier(isMale: true), 0.8);
      expect(settings.effectiveFatMultiplier(isMale: false), 0.8);
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
        clearedProtein.effectiveProteinMultiplier(hasTrainingDays: true),
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

  group('DiaryMacroTargets.calculate', () {
    test('calculates correct macros for 80kg male active at 2400 kcal', () {
      final targets = DiaryMacroTargets.calculate(
        goalKcal: 2400,
        weightKg: 80,
        proteinGramsPerKg: 2,
        fatGramsPerKg: 1,
      );

      // Protein: 80 * 2.0 = 160g (640 kcal)
      // Fat: 80 * 1.0 = 80g (720 kcal)
      // Carbs: (2400 - 640 - 720) / 4 = 1040 / 4 = 260g (1040 kcal)
      expect(targets.protein, 160.0);
      expect(targets.fat, 80.0);
      expect(targets.carbs, 260.0);
    });

    test('calculates correct macros for 65kg female active at 2000 kcal', () {
      final targets = DiaryMacroTargets.calculate(
        goalKcal: 2000,
        weightKg: 65,
        proteinGramsPerKg: 1.8,
        fatGramsPerKg: 1.2,
      );

      // Protein: 65 * 1.8 = 117g (468 kcal)
      // Fat: 65 * 1.2 = 78g (702 kcal)
      // Carbs: (2000 - 468 - 702) / 4 = 830 / 4 = 207.5g
      expect(targets.protein, 117.0);
      expect(targets.fat, 78.0);
      expect(targets.carbs, 207.5);
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
        final targets = DiaryMacroTargets.calculate(
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

    test('reduces protein when fat reaches floor to guarantee carbs floor', () {
      // 1000 kcal goal for 90kg person (2.0 P, 1.0 F):
      // Fat floor: 90 * 0.6 = 54g (486 kcal).
      // Carbs floor: 100g (400 kcal).
      // Remainder for protein: 1000 - 486 - 400 = 114 kcal -> 28.5g protein.
      final targets = DiaryMacroTargets.calculate(
        goalKcal: 1000,
        weightKg: 90,
        proteinGramsPerKg: 2,
        fatGramsPerKg: 1,
      );

      expect(targets.protein, 28.5);
      expect(targets.fat, 54.0);
      expect(targets.carbs, 100.0);
    });

    test('clamps all macros to zero when goalKcal <= 0', () {
      final zeroTarget = DiaryMacroTargets.calculate(
        goalKcal: 0,
        weightKg: 80,
        proteinGramsPerKg: 2,
        fatGramsPerKg: 1,
      );
      expect(zeroTarget.protein, 0.0);
      expect(zeroTarget.fat, 0.0);
      expect(zeroTarget.carbs, 0.0);

      final negativeTarget = DiaryMacroTargets.calculate(
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
      final targets = DiaryMacroTargets.calculate(
        goalKcal: 2000,
        weightKg: 0,
        proteinGramsPerKg: 2,
        fatGramsPerKg: 1,
      );
      // 70kg * 2.0 = 140g protein (560 kcal)
      // 70kg * 1.0 = 70g fat (630 kcal)
      // (2000 - 1190) / 4 = 202.5g carbs
      expect(targets.protein, 140.0);
      expect(targets.fat, 70.0);
      expect(targets.carbs, 202.5);

      final negativeWeightTargets = DiaryMacroTargets.calculate(
        goalKcal: 2000,
        weightKg: -75,
        proteinGramsPerKg: 2,
        fatGramsPerKg: 1,
      );
      expect(negativeWeightTargets.protein, 140.0);
      expect(negativeWeightTargets.fat, 70.0);
      expect(negativeWeightTargets.carbs, 202.5);
    });

    test('handles zero multipliers by attributing all calories to carbs', () {
      final targets = DiaryMacroTargets.calculate(
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
