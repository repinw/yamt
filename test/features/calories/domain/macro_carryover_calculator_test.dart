import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/macro_carryover_calculator.dart';

void main() {
  group('MacroCarryoverCalculator', () {
    const baseCarbs = 260.0;
    const baseFat = 80.0;
    const weightKg = 80.0;

    test('zero carryover returns zero delta', () {
      final delta = MacroCarryoverCalculator.calculateCarryoverDelta(
        baseCarbs: baseCarbs,
        baseFat: baseFat,
        carryoverKcal: 0,
        weightKg: weightKg,
      );

      expect(delta.proteinGrams, 0.0);
      expect(delta.carbsGrams, 0.0);
      expect(delta.fatGrams, 0.0);
      expect(delta.wasFatFloorApplied, isFalse);
      expect(delta.wasCarbsFloorApplied, isFalse);
    });

    test('positive carryover allocates 75% to carbs and 25% to fat', () {
      final delta = MacroCarryoverCalculator.calculateCarryoverDelta(
        baseCarbs: baseCarbs,
        baseFat: baseFat,
        carryoverKcal: 100,
        weightKg: weightKg,
      );

      expect(delta.proteinGrams, 0.0);
      expect(delta.carbsGrams, closeTo(75.0 / 4, 0.01));
      expect(delta.fatGrams, closeTo(25.0 / 9, 0.01));
      expect(delta.wasFatFloorApplied, isFalse);
      expect(delta.wasCarbsFloorApplied, isFalse);
    });

    test('positive carryover keeps the 75/25 split below the carb cap', () {
      // 2500 + 100 kcal allow 260 g carbs; 200 g + 18.75 g stay below.
      final delta = MacroCarryoverCalculator.calculateCarryoverDelta(
        baseCarbs: 200,
        baseFat: baseFat,
        carryoverKcal: 100,
        weightKg: weightKg,
        baseGoalKcal: 2500,
      );

      expect(delta.carbsGrams, closeTo(75.0 / 4, 0.001));
      expect(delta.fatGrams, closeTo(25.0 / 9, 0.001));
    });

    test('positive carryover gives fat the kcal above the carb cap', () {
      // 2500 + 600 kcal allow 310 g carbs, so carbs grow by 60 g only.
      final delta = MacroCarryoverCalculator.calculateCarryoverDelta(
        baseCarbs: 250,
        baseFat: baseFat,
        carryoverKcal: 600,
        weightKg: weightKg,
        baseGoalKcal: 2500,
      );

      expect(delta.proteinGrams, 0.0);
      expect(delta.carbsGrams, closeTo(60, 0.001));
      expect(delta.fatGrams, closeTo((600 - 60 * 4) / 9, 0.001));
    });

    test('negative carryover respects fat floor and carbs floor', () {
      final delta = MacroCarryoverCalculator.calculateCarryoverDelta(
        baseCarbs: baseCarbs,
        baseFat: baseFat,
        carryoverKcal: -200,
        weightKg: weightKg,
        baseGoalKcal: 2000,
      );

      // 25 % of 200 kcal from fat, 75 % from carbs, at 9 and 4 kcal/g.
      expect(delta.proteinGrams, 0.0);
      expect(delta.fatGrams, closeTo(-50 / 9, 0.001));
      expect(delta.carbsGrams, closeTo(-37.5, 0.001));
      expect(delta.wasFatFloorApplied, isFalse);
      expect(delta.wasCarbsFloorApplied, isFalse);
    });

    test('positive carryover of 200 kcal adds 37.5 g carbs and 5.6 g fat', () {
      final delta = MacroCarryoverCalculator.calculateCarryoverDelta(
        baseCarbs: baseCarbs,
        baseFat: baseFat,
        carryoverKcal: 200,
        weightKg: weightKg,
      );

      expect(delta.carbsGrams, closeTo(37.5, 0.001));
      expect(delta.fatGrams, closeTo(50 / 9, 0.001));
    });

    test('fat floor uses the same rule as the base budget', () {
      // Fat floor: max(80 kg * 0.6, 20 % of 1800 kcal / 9) = 48 g.
      final delta = MacroCarryoverCalculator.calculateCarryoverDelta(
        baseCarbs: baseCarbs,
        baseFat: 50,
        carryoverKcal: -200,
        weightKg: weightKg,
        baseGoalKcal: 2000,
      );

      expect(delta.fatGrams, closeTo(-2, 0.001));
      expect(delta.wasFatFloorApplied, isTrue);
      // The other 182 kcal come from carbs.
      expect(delta.carbsGrams, closeTo(-182 / 4, 0.001));
      expect(delta.wasCarbsFloorApplied, isFalse);
    });

    test('negative carryover never raises fat that is below its floor', () {
      // Fat floor 48 g; 40 g of fat stay, carbs take the whole 200 kcal.
      final delta = MacroCarryoverCalculator.calculateCarryoverDelta(
        baseCarbs: baseCarbs,
        baseFat: 40,
        carryoverKcal: -200,
        weightKg: weightKg,
      );

      expect(delta.fatGrams, 0.0);
      expect(delta.wasFatFloorApplied, isTrue);
      expect(delta.carbsGrams, closeTo(-50, 0.001));
    });

    test('carbs floor flag is set only when it limits the reduction', () {
      final limited = MacroCarryoverCalculator.calculateCarryoverDelta(
        baseCarbs: 110,
        baseFat: 48,
        carryoverKcal: -200,
        weightKg: weightKg,
      );
      expect(limited.carbsGrams, closeTo(-10, 0.001));
      expect(limited.wasCarbsFloorApplied, isTrue);

      // Fat above its floor takes the whole 50 kcal share; carbs at 100 g
      // lose nothing, which the floor did not cause.
      final reachedExactly = MacroCarryoverCalculator.calculateCarryoverDelta(
        baseCarbs: 137.5,
        baseFat: baseFat,
        carryoverKcal: -200,
        weightKg: weightKg,
      );
      expect(reachedExactly.carbsGrams, closeTo(-37.5, 0.001));
      expect(reachedExactly.wasCarbsFloorApplied, isFalse);
    });
  });
}
