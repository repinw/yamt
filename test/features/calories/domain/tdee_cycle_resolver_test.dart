import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/tdee_cycle_resolver.dart';

void main() {
  group('TdeeCycleResolver', () {
    test('resolves default cycle when goal history is empty', () {
      const settings = CalorieGoalSettings.empty();
      final cycles = TdeeCycleResolver.resolveGoalCycles(settings);

      expect(cycles.length, 2);
      expect(cycles.first.id, 'default');
      expect(cycles.last.isAllGoals, isTrue);
    });

    test('resolves multiple anchor cycles and all-goals aggregate', () {
      final now = DateTime(2025);
      final profile1 = const CalorieCalculatorProfile.defaults().copyWith(
        goalMode: CalorieGoalMode.lose,
        weightKg: 85,
        targetWeightKg: 75,
      );
      final profile2 = const CalorieCalculatorProfile.defaults().copyWith(
        goalMode: CalorieGoalMode.maintain,
        weightKg: 75,
      );

      final settings =
          CalorieGoalSettings.single(
            dailyKcalGoal: 2000,
            calculatorProfile: profile1,
            effectiveDate: now,
          ).applyGoalChange(
            changedAt: DateTime(2025, 2),
            dailyKcalGoal: 2500,
            calculatorProfile: profile2,
          );

      final cycles = TdeeCycleResolver.resolveGoalCycles(settings);

      // Should have: "all", latest ("maintain"), previous ("lose")
      expect(cycles.length, 3);
      expect(cycles.first.isAllGoals, isTrue);
      expect(cycles[1].goalMode, CalorieGoalMode.maintain);
      expect(cycles[1].isActive, isTrue);
      expect(cycles[2].goalMode, CalorieGoalMode.lose);
      expect(cycles[2].isActive, isFalse);
      expect(cycles[2].endDate, DateTime(2025, 1, 31));
    });

    test('derives estimates and preserves an explicit same-day end', () {
      final profile = const CalorieCalculatorProfile.defaults().copyWith(
        weightKg: 80,
        targetWeightKg: 78,
        goalMode: CalorieGoalMode.lose,
        goalSpeedKgPerWeek: 0.5,
      );
      final settings = CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: profile,
        effectiveDate: DateTime(2026, 6),
      ).markActiveGoalEnded(DateTime(2026, 6, 4), weightKg: 78.4);

      final cycle = TdeeCycleResolver.resolveGoalCycles(
        settings,
      ).firstWhere((cycle) => !cycle.isAllGoals);

      expect(cycle.estimatedEndDate, DateTime(2026, 6, 29));
      expect(cycle.endDate, DateTime(2026, 6, 4));
      expect(cycle.startWeightKg, 80);
      expect(cycle.endWeightKg, 78.4);
    });

    test('uses optional maintain end date', () {
      final profile = const CalorieCalculatorProfile.defaults().copyWith(
        maintainUntil: DateTime(2026, 12, 31),
      );
      final settings = CalorieGoalSettings.single(
        dailyKcalGoal: 2400,
        calculatorProfile: profile,
        effectiveDate: DateTime(2026, 6),
      );

      final cycle = TdeeCycleResolver.resolveGoalCycles(
        settings,
      ).firstWhere((cycle) => !cycle.isAllGoals);

      expect(cycle.estimatedEndDate, DateTime(2026, 12, 31));
    });
  });
}
