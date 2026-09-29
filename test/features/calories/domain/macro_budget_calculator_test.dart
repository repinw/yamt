import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/macro_budget_calculator.dart';

void main() {
  group('MacroBudgetCalculator.calculate', () {
    test('moves the excess above the cap to protein', () {
      final result = MacroBudgetCalculator.calculate(
        goalKcal: 2000,
        weightKg: 80,
        proteinGramsPerKg: 1.6,
        fatGramsPerKg: 0.8,
      );

      // 2000 - 512 - 576 = 912 kcal of carbs, 112 kcal above the cap.
      expect(result.carbs, closeTo(200, 0.001));
      expect(result.protein, closeTo(156, 0.001));
      expect(result.fat, closeTo(64, 0.001));
    });

    test('caps carbs at 40 % and moves the excess to protein first', () {
      final result = MacroBudgetCalculator.calculate(
        goalKcal: 2500,
        weightKg: 80,
        proteinGramsPerKg: 1.6,
        fatGramsPerKg: 0.8,
      );

      expect(result.carbs, closeTo(250, 0.001));
      // Protein grows to 2.0 g/kg, the rest goes to fat.
      expect(result.protein, closeTo(160, 0.001));
      expect(result.fat, closeTo(64 + 284 / 9, 0.001));
    });

    test('gives carbs the rest when they stay below the cap', () {
      final result = MacroBudgetCalculator.calculate(
        goalKcal: 1800,
        weightKg: 80,
        proteinGramsPerKg: 1.6,
        fatGramsPerKg: 0.8,
      );

      expect(result.protein, closeTo(128, 0.001));
      expect(result.fat, closeTo(64, 0.001));
      expect(result.carbs, closeTo(178, 0.001));
    });

    test('moves all excess to fat when protein is already at the limit', () {
      final result = MacroBudgetCalculator.calculate(
        goalKcal: 3000,
        weightKg: 80,
        proteinGramsPerKg: 2.3,
        fatGramsPerKg: 0.8,
      );

      expect(result.carbs, closeTo(300, 0.001));
      expect(result.protein, closeTo(184, 0.001));
      // 3000 - 736 - 576 - 1200 = 488 kcal extra fat.
      expect(result.fat, closeTo(64 + 488 / 9, 0.001));
    });

    test('keeps the 100 g carb floor above the cap on tiny budgets', () {
      final result = MacroBudgetCalculator.calculate(
        goalKcal: 900,
        weightKg: 50,
        proteinGramsPerKg: 2,
        fatGramsPerKg: 0.2,
      );

      // The cap would be 90 g; the 100 g floor wins.
      expect(result.carbs, closeTo(100, 0.001));
      expect(result.protein, closeTo(100, 0.001));
      expect(result.fat, closeTo(10 + 10 / 9, 0.001));
    });
  });
}
