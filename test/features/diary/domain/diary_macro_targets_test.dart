import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';

void main() {
  group('DiaryMacroTargets.applyCarryover', () {
    const base = DiaryMacroTargets(
      protein: 160,
      fat: 80,
      carbs: 260,
    );

    test('zero carryover leaves targets unchanged', () {
      final result = base.applyCarryover(
        carryoverKcal: 0,
        weightKg: 80,
      );

      expect(result.protein, 160);
      expect(result.fat, 80);
      expect(result.carbs, 260);
    });

    test(
      'positive carryover allocates 75% to carbs (/4.1) and 25% to fat (/9.3)'
      ' with protein constant',
      () {
        // Tuesday example from user specification:
        // +300 kcal over 3 days -> +100 kcal / day.
        // Protein: +-0 g -> 160
        // Carbs: 100 * 0.75 / 4.1 = 75 / 4.1 = 18.29268... g
        // Fat: 100 * 0.25 / 9.3 = 25 / 9.3 = 2.68817... g
        final result = base.applyCarryover(
          carryoverKcal: 100,
          weightKg: 80,
        );

        expect(result.protein, 160);
        expect(result.carbs, closeTo(260 + (75.0 / 4.1), 0.001));
        expect(result.fat, closeTo(80 + (25.0 / 9.3), 0.001));

        final delta = DiaryMacroTargets.calculateCarryoverDelta(
          baseTargets: base,
          carryoverKcal: 100,
          weightKg: 80,
        );
        expect(delta.proteinGrams, 0.0);
        expect(delta.carbsGrams, closeTo(18.29, 0.01));
        expect(delta.fatGrams, closeTo(2.69, 0.01));
        expect(delta.wasFatFloorApplied, isFalse);
        expect(delta.wasCarbsFloorApplied, isFalse);
      },
    );

    test(
      'negative carryover reduces fat (25% / 9.3) and carbs (75% / 4.1)'
      ' with protein constant',
      () {
        // Overate by 600 kcal / 3 days = -200 kcal/day.
        // Protein: constant (160)
        // Fat floor: max(80 * 0.6 = 48g, (2000 - 200) * 0.20 / 9.3) = 48g
        // Planned fat reduction: 200 * 0.25 / 9.3 = 50 / 9.3 = 5.3763... g
        // 80 - 5.376 >= 48g -> OK!
        // Carbs reduction: 200 * 0.75 / 4.1 = 150 / 4.1 = 36.585... g
        // 260 - 36.585 = 223.41g >= 50g -> OK!
        final result = base.applyCarryover(
          carryoverKcal: -200,
          weightKg: 80,
          baseGoalKcal: 2000,
        );

        expect(result.protein, 160);
        expect(result.fat, closeTo(80 - (50.0 / 9.3), 0.001));
        expect(result.carbs, closeTo(260 - (150.0 / 4.1), 0.001));

        final delta = DiaryMacroTargets.calculateCarryoverDelta(
          baseTargets: base,
          carryoverKcal: -200,
          weightKg: 80,
          baseGoalKcal: 2000,
        );
        expect(delta.proteinGrams, 0.0);
        expect(delta.fatGrams, closeTo(-5.38, 0.01));
        expect(delta.carbsGrams, closeTo(-36.59, 0.01));
        expect(delta.wasFatFloorApplied, isFalse);
        expect(delta.wasCarbsFloorApplied, isFalse);
      },
    );

    test(
      'Schutzregel B: fat is capped at Fat Floor (0.6 g/kg) and remainder'
      ' redirects to carbs',
      () {
        // 80kg person with low base fat (50g). Fat floor is 80 * 0.6 = 48g.
        // -200 kcal carryover.
        // Planned fat reduction: 50 / 9.3 = 5.38g.
        // 50 - 5.38 = 44.62g < 48g floor!
        // Fat only drops by 2.0g to 48g.
        // Saved fat kcal: 2.0g * 9.3 = 18.6 kcal.
        // Remainder for carbs: 200 - 18.6 = 181.4 kcal.
        // Carbs reduction: 181.4 / 4.1 = 44.2439... g
        const lowFatBase = DiaryMacroTargets(
          protein: 160,
          fat: 50,
          carbs: 260,
        );

        final result = lowFatBase.applyCarryover(
          carryoverKcal: -200,
          weightKg: 80,
          baseGoalKcal: 2000,
        );

        expect(result.protein, 160);
        expect(result.fat, 48);
        expect(result.carbs, closeTo(260 - (181.4 / 4.1), 0.001));

        final delta = DiaryMacroTargets.calculateCarryoverDelta(
          baseTargets: lowFatBase,
          carryoverKcal: -200,
          weightKg: 80,
          baseGoalKcal: 2000,
        );
        expect(delta.proteinGrams, 0.0);
        expect(delta.fatGrams, -2);
        expect(delta.carbsGrams, closeTo(-44.24, 0.01));
        expect(delta.wasFatFloorApplied, isTrue);
        expect(delta.wasCarbsFloorApplied, isFalse);
      },
    );

    test(
      'Carbs floor: carbs never drop below 50g'
      ' (Ketose- & Unterzuckerungsschutz)',
      () {
        // Base carbs = 70g.
        // Reduction would be ~36.6g -> 33.4g < 50g!
        // Clamped to 50g!
        const lowCarbBase = DiaryMacroTargets(
          protein: 160,
          fat: 80,
          carbs: 70,
        );

        final result = lowCarbBase.applyCarryover(
          carryoverKcal: -200,
          weightKg: 80,
          baseGoalKcal: 2000,
        );

        expect(result.protein, 160);
        expect(result.fat, closeTo(80 - (50.0 / 9.3), 0.001));
        expect(result.carbs, 50);

        final delta = DiaryMacroTargets.calculateCarryoverDelta(
          baseTargets: lowCarbBase,
          carryoverKcal: -200,
          weightKg: 80,
          baseGoalKcal: 2000,
        );
        expect(delta.wasCarbsFloorApplied, isTrue);
      },
    );
  });
}
