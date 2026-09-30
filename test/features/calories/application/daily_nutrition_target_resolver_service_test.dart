import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/daily_nutrition_target_resolver_service.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
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
          dailyKcalGoal: 2500,
          calculatorProfile: profile,
          goalHistory: [_calculatorEntry(2500, profile)],
        ),
      );

      final target = service.resolveTarget(
        day: DateTime(2026, 9, 14),
        goalKcal: 2500,
      );

      // Reference weight: 81 kg at BMI 25 + 0.4 * 49 kg = 100.6 kg. Losing
      // weight with training: 2.0 g/kg, inside 30-35 % of 2500 kcal. Carbs
      // stay below the 40 % cap.
      expect(target.proteinGrams, closeTo(100.6 * 2.0, 0.001));
      expect(target.fatGrams, closeTo(100.6 * 0.8, 0.001));
    });

    test('measures protein and fat against the weight of the latest '
        'check-in', () {
      const profile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.male,
        weightKg: 95,
        heightCm: 200,
        ageYears: 35,
        activityLevel: 1.375,
        goalMode: CalorieGoalMode.maintain,
        goalSpeedKgPerWeek: 0,
        trainingWeekdays: [1, 4],
      );
      final service = DailyNutritionTargetResolverService(
        macroSettings: const MacroGoalSettings(),
        goalSettings: const CalorieGoalSettings.empty().copyWith(
          dailyKcalGoal: 2000,
          calculatorProfile: profile,
          goalHistory: [
            CalorieGoalHistoryEntry(
              dailyKcalGoal: 2000,
              calculatorProfile: profile,
              effectiveDate: DateTime(2026, 9),
              changedAt: DateTime(2026, 9),
              source: CalorieGoalSource.calculator,
            ),
            CalorieGoalHistoryEntry(
              dailyKcalGoal: 2000,
              calculatorProfile: null,
              effectiveDate: DateTime(2026, 9, 8),
              changedAt: DateTime(2026, 9, 8),
              source: CalorieGoalSource.weeklyCheckIn,
              weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
                windowStartDate: DateTime(2026, 9),
                windowEndDate: DateTime(2026, 9, 7),
                trendWeightChangePerDay: -0.1,
                lowConfidence: false,
                macroWeightKg: 93,
              ),
            ),
          ],
        ),
      );

      final beforeCheckIn = service.resolveTarget(
        day: DateTime(2026, 9, 7),
        goalKcal: 2000,
      );
      final afterCheckIn = service.resolveTarget(
        day: DateTime(2026, 9, 14),
        goalKcal: 2000,
      );

      // Below BMI 25 at 2 m, so the weights count in full. Carbs stay below
      // the 40 % cap.
      expect(beforeCheckIn.proteinGrams, closeTo(95 * 1.6, 0.001));
      expect(afterCheckIn.proteinGrams, closeTo(93 * 1.6, 0.001));
      expect(afterCheckIn.fatGrams, closeTo(93 * 0.8, 0.001));
    });

    test('caps protein at 35 % of a 1526 kcal diet so carbs stay above '
        'the floor', () {
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
        goalHistory: [_calculatorEntry(1526, profile)],
      );

      final service = DailyNutritionTargetResolverService(
        macroSettings: macroSettings,
        goalSettings: goalSettings,
      );

      final target = service.resolveTarget(
        day: DateTime(2026, 9, 14),
        goalKcal: 1526,
      );

      // 2.0 g/kg x 80 kg = 160 g is above 35 % of 1526 kcal (133.5 g).
      // 133.5 g protein and 64 g fat leave 104 g carbs.
      expect(target.goalKcal, 1526.0);
      expect(target.proteinGrams, closeTo(1526 * 0.35 / 4, 0.001));
      expect(target.fatGrams, closeTo(64, 0.001));
      expect(target.carbsGrams, closeTo((1526 * 0.65 - 64 * 9) / 4, 0.001));
    });

    test('gives a training day set only for that day the sport protein', () {
      const profile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.male,
        weightKg: 70,
        heightCm: 180,
        ageYears: 30,
        activityLevel: 1.2,
        goalMode: CalorieGoalMode.lose,
        goalSpeedKgPerWeek: 0.5,
      );
      final restDay = DateTime(2026, 9, 14);
      final trainingDay = DateTime(2026, 9, 15);
      final service = DailyNutritionTargetResolverService(
        macroSettings: const MacroGoalSettings(),
        goalSettings: const CalorieGoalSettings.empty().copyWith(
          dailyKcalGoal: 1600,
          calculatorProfile: profile,
          goalHistory: [_calculatorEntry(1600, profile)],
          trainingDayOverrides: {diaryDayKey(trainingDay): true},
        ),
      );

      // Rest day: 70 * 1.6 = 112 g, raised to 30 % of 1600 kcal = 120 g.
      expect(
        service.resolveTarget(day: restDay, goalKcal: 1600).proteinGrams,
        closeTo(120, 0.001),
      );
      expect(
        service.resolveTarget(day: trainingDay, goalKcal: 1600).proteinGrams,
        closeTo(70 * 2.0, 0.001),
      );
    });

    test('keeps protein the same on training and rest days', () {
      const profile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.male,
        weightKg: 80,
        heightCm: 180,
        ageYears: 30,
        activityLevel: 1.375,
        goalMode: CalorieGoalMode.maintain,
        goalSpeedKgPerWeek: 0,
        trainingWeekdays: [1],
      );
      final service = DailyNutritionTargetResolverService(
        macroSettings: const MacroGoalSettings(),
        goalSettings: const CalorieGoalSettings.empty().copyWith(
          dailyKcalGoal: 2000,
          calculatorProfile: profile,
          goalHistory: [_calculatorEntry(2000, profile)],
        ),
      );

      final trainingDay = service.resolveTarget(
        day: DateTime(2026, 9, 14),
        goalKcal: 2400,
      );
      final restDay = service.resolveTarget(
        day: DateTime(2026, 9, 15),
        goalKcal: 1800,
      );

      // The 2000 kcal average leaves 228 g carbs; the 28 g above the cap
      // raise protein to 156 g on every day. The day's kcal move carbs and
      // fat only.
      expect(trainingDay.proteinGrams, closeTo(156, 0.001));
      expect(restDay.proteinGrams, closeTo(156, 0.001));
      expect(trainingDay.carbsGrams, closeTo(240, 0.001));
      expect(
        trainingDay.fatGrams,
        closeTo(64 + (2400 - 624 - 576 - 960) / 9, 0.001),
      );
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

      // 80kg male: 128g protein and 64g fat leave 328g carbs. Carbs stop at
      // 40 % (240g); the excess raises protein to 2.0 g/kg, the rest goes to
      // fat.
      expect(target.goalKcal, 2400.0);
      expect(target.proteinGrams, closeTo(160, 0.001));
      expect(target.fatGrams, closeTo(64 + 224 / 9, 0.001));
      expect(target.carbsGrams, closeTo(240, 0.001));
    });
  });
}

CalorieGoalHistoryEntry _calculatorEntry(
  double dailyKcalGoal,
  CalorieCalculatorProfile profile,
) {
  return CalorieGoalHistoryEntry(
    dailyKcalGoal: dailyKcalGoal,
    calculatorProfile: profile,
    effectiveDate: DateTime(2026, 9),
    changedAt: DateTime(2026, 9),
    source: CalorieGoalSource.calculator,
  );
}
