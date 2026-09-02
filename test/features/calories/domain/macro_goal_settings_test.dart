import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';

void main() {
  group('MacroCalculationDefaults', () {
    test('male active defaults: 2.0 P, 1.0 F', () {
      expect(
        MacroCalculationDefaults.defaultProteinMultiplier(
          isMale: true,
          isSportActive: true,
        ),
        2.0,
      );
      expect(
        MacroCalculationDefaults.defaultFatMultiplier(
          isMale: true,
          isSportActive: true,
        ),
        1.0,
      );
    });

    test('female active defaults: 1.8 P, 1.2 F', () {
      expect(
        MacroCalculationDefaults.defaultProteinMultiplier(
          isMale: false,
          isSportActive: true,
        ),
        1.8,
      );
      expect(
        MacroCalculationDefaults.defaultFatMultiplier(
          isMale: false,
          isSportActive: true,
        ),
        1.2,
      );
    });

    test('male inactive defaults: 1.2 P, 0.9 F', () {
      expect(
        MacroCalculationDefaults.defaultProteinMultiplier(
          isMale: true,
          isSportActive: false,
        ),
        1.2,
      );
      expect(
        MacroCalculationDefaults.defaultFatMultiplier(
          isMale: true,
          isSportActive: false,
        ),
        0.9,
      );
    });

    test('female inactive defaults: 1.2 P, 1.0 F', () {
      expect(
        MacroCalculationDefaults.defaultProteinMultiplier(
          isMale: false,
          isSportActive: false,
        ),
        1.2,
      );
      expect(
        MacroCalculationDefaults.defaultFatMultiplier(
          isMale: false,
          isSportActive: false,
        ),
        1.0,
      );
    });
  });

  group('MacroGoalSettings', () {
    test('effective multipliers fall back to defaults when not overridden', () {
      const settings = MacroGoalSettings();
      expect(settings.effectiveProteinMultiplier(isMale: true), 2.0);
      expect(settings.effectiveFatMultiplier(isMale: true), 1.0);
      expect(settings.effectiveProteinMultiplier(isMale: false), 1.8);
      expect(settings.effectiveFatMultiplier(isMale: false), 1.2);
    });

    test('effective multipliers respect custom overrides', () {
      const settings = MacroGoalSettings(
        customProteinMultiplier: 2.3,
        customFatMultiplier: 0.8,
      );
      expect(settings.effectiveProteinMultiplier(isMale: true), 2.3);
      expect(settings.effectiveFatMultiplier(isMale: true), 0.8);
      // Custom overrides apply regardless of sex or activity
      expect(settings.effectiveProteinMultiplier(isMale: false), 2.3);
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
      expect(clearedProtein.effectiveProteinMultiplier(isMale: true), 2.0);

      final clearedBoth = settings.copyWith(
        clearCustomProtein: true,
        clearCustomFat: true,
      );
      expect(clearedBoth.customProteinMultiplier, isNull);
      expect(clearedBoth.customFatMultiplier, isNull);
      expect(clearedBoth.effectiveFatMultiplier(isMale: true), 1.0);
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

    test('clamps carbs to zero when protein + fat exceeds calorie goal', () {
      // 1000 kcal goal for 90kg person:
      // Protein: 90 * 2.0 = 180g (720 kcal)
      // Fat: 90 * 1.0 = 90g (810 kcal)
      // Total protein + fat = 1530 kcal > 1000 kcal!
      // Carbs must clamp to 0.0, NOT -132.5g!
      final targets = DiaryMacroTargets.calculate(
        goalKcal: 1000,
        weightKg: 90,
        proteinGramsPerKg: 2,
        fatGramsPerKg: 1,
      );

      expect(targets.protein, 180.0);
      expect(targets.fat, 90.0);
      expect(targets.carbs, 0.0);
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
