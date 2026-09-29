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
      expect(delta.carbsGrams, closeTo(75.0 / 4.1, 0.01));
      expect(delta.fatGrams, closeTo(25.0 / 9.3, 0.01));
      expect(delta.wasFatFloorApplied, isFalse);
      expect(delta.wasCarbsFloorApplied, isFalse);
    });

    test('positive carryover keeps the 75/25 split below the carb cap', () {
      // 2500 + 100 kcal allow 260 g carbs; 200 g + 18 g stay below.
      final delta = MacroCarryoverCalculator.calculateCarryoverDelta(
        baseCarbs: 200,
        baseFat: baseFat,
        carryoverKcal: 100,
        weightKg: weightKg,
        baseGoalKcal: 2500,
      );

      expect(delta.carbsGrams, closeTo(75.0 / 4.1, 0.001));
      expect(delta.fatGrams, closeTo(25.0 / 9.3, 0.001));
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
      expect(delta.fatGrams, closeTo((600 - 60 * 4.1) / 9.3, 0.001));
    });

    test('negative carryover respects fat floor and carbs floor', () {
      final delta = MacroCarryoverCalculator.calculateCarryoverDelta(
        baseCarbs: baseCarbs,
        baseFat: baseFat,
        carryoverKcal: -200,
        weightKg: weightKg,
        baseGoalKcal: 2000,
      );

      expect(delta.proteinGrams, 0.0);
      expect(delta.fatGrams, lessThan(0.0));
      expect(delta.carbsGrams, lessThan(0.0));
    });
  });
}
