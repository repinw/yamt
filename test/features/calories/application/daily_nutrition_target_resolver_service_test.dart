import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/daily_nutrition_target_resolver_service.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';

void main() {
  group('DailyNutritionTargetResolverService', () {
    test('measures protein and fat against the reference weight', () {
      const profile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.male,
        weightKg: 130,
        heightCm: 180,
        ageYears: 35,
        activityLevel: 1.375,
        goalMode: CalorieGoalMode.lose,
        goalSpeedKgPerWeek: 0.5,
        trainingWeekdays: [1, 4],
      );
      final service = DailyNutritionTargetResolverService(
        macroSettings: const MacroGoalSettings(),
        goalSettings: const CalorieGoalSettings.empty().copyWith(
          dailyKcalGoal: 2600,
          calculatorProfile: profile,
        ),
      );

      final target = service.resolveTarget(
        day: DateTime(2026, 9, 14),
        goalKcal: 2600,
      );

      // Reference weight: 81 kg at BMI 25 + 0.4 * 49 kg = 100.6 kg.
      expect(target.proteinGrams, closeTo(100.6 * 1.6, 0.001));
      expect(target.fatGrams, closeTo(100.6 * 0.8, 0.001));
    });

    test('resolves 1526 kcal profile guaranteeing 100g carbs floor', () {
      const macroSettings = MacroGoalSettings();
      const profile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.male,
        weightKg: 80,
        heightCm: 180,
        ageYears: 30,
        activityLevel: 1.2,
        goalMode: CalorieGoalMode.lose,
        goalSpeedKgPerWeek: 0.5,
        trainingWeekdays: [1, 3, 5],
      );
      final goalSettings = const CalorieGoalSettings.empty().copyWith(
        dailyKcalGoal: 1526,
        calculatorProfile: profile,
      );

      final service = DailyNutritionTargetResolverService(
        macroSettings: macroSettings,
        goalSettings: goalSettings,
      );

      final target = service.resolveTarget(
        day: DateTime(2026, 9, 14),
        goalKcal: 1526,
      );

      // Training days: 128g protein and 64g fat leave 109.5g carbs.
      expect(target.goalKcal, 1526.0);
      expect(target.proteinGrams, closeTo(128, 0.001));
      expect(target.fatGrams, closeTo(64, 0.001));
      expect(target.carbsGrams, closeTo(109.5, 0.001));
    });

    test('resolves cycling training day and pause day flags', () {
      const macroSettings = MacroGoalSettings();
      final goalSettings = const CalorieGoalSettings.empty().copyWith(
        dailyKcalGoal: 2000,
        trainingWeekdays: const <int>[1, 3, 5],
        trainingDayKcalOffset: 200,
      );

      final service = DailyNutritionTargetResolverService(
        macroSettings: macroSettings,
        goalSettings: goalSettings,
      );

      // Monday (weekday 1) = training day
      final mondayTarget = service.resolveTarget(
        day: DateTime(2026, 9, 14), // Monday
        goalKcal: 2200,
      );
      expect(mondayTarget.isTrainingDay, isTrue);
      expect(mondayTarget.isPauseDay, isFalse);

      // Tuesday (weekday 2) = rest day
      final tuesdayTarget = service.resolveTarget(
        day: DateTime(2026, 9, 15), // Tuesday
        goalKcal: 1900,
      );
      expect(tuesdayTarget.isTrainingDay, isFalse);
      expect(tuesdayTarget.isPauseDay, isFalse);
    });

    test('resolveBaseTarget ignores carryover', () {
      const macroSettings = MacroGoalSettings();
      final service = DailyNutritionTargetResolverService(
        macroSettings: macroSettings,
        goalSettings: const CalorieGoalSettings.empty().copyWith(
          dailyKcalGoal: 2400,
        ),
      );

      final target = service.resolveBaseTarget(
        day: DateTime(2026, 9, 14),
        goalKcal: 2400,
      );

      // 80kg male without training days: 96g protein, 64g fat, 360g carbs
      expect(target.goalKcal, 2400.0);
      expect(target.proteinGrams, closeTo(96, 0.001));
      expect(target.fatGrams, closeTo(64, 0.001));
      expect(target.carbsGrams, closeTo(360, 0.001));
    });
  });
}
