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

      final settings = CalorieGoalSettings.single(
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
  });
}
