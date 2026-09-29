import 'package:flutter_riverpod/misc.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

import '../features/calories/support/fake_calories_repositories.dart';
import 'profile_summary_source_overrides.dart';

/// Today of the Fortschritt examples: Thursday, 24 September 2026.
final progressNow = DateTime(2026, 9, 24, 10);

/// Goal of the Fortschritt examples: lose from 84 kg to 78 kg.
const progressProfile = CalorieCalculatorProfile(
  sex: CalorieCalculatorSex.male,
  weightKg: 84,
  heightCm: 180,
  ageYears: 35,
  activityLevel: 1.4,
  goalMode: CalorieGoalMode.lose,
  goalSpeedKgPerWeek: 0.5,
  targetWeightKg: 78,
  trainingWeekdays: [DateTime.monday, DateTime.wednesday],
);

/// Backs the Fortschritt tab with a goal, two weeks of meals, and weigh-ins.
List<Override> progressSourceOverrides({
  required FakeCalorieSettingsRepository settingsRepository,
  required FakeCalorieLogRepository calorieLog,
}) {
  return [
    ...profileSummarySourceOverrides(
      settingsRepository: settingsRepository,
      now: progressNow,
      weighIns: [
        for (var offset = 0; offset < 20; offset += 2)
          ManualHealthWeightEntry(
            day: DateTime(2026, 9, 24 - offset),
            weightKg: 82 + offset * 0.05,
          ),
      ],
    ),
    calorieLogRepositoryProvider.overrideWithValue(calorieLog),
  ];
}

/// Goal settings of the Fortschritt examples, started on 7 September 2026.
CalorieGoalSettings progressSettings() {
  return CalorieGoalSettings.single(
    dailyKcalGoal: 2200,
    calculatorProfile: progressProfile,
    effectiveDate: DateTime(2026, 9, 7),
  );
}

/// One meal per day from 1 to 24 September 2026.
List<CalorieEntry> progressEntries() {
  return [
    for (var day = 1; day <= 24; day++)
      CalorieEntry.placeholder(
        id: 'meal-$day',
        name: 'Meal $day',
        mealType: MealType.lunch,
        totalKcal: 1800 + (day % 4) * 200,
        loggedAt: DateTime(2026, 9, day, 12),
      ),
  ];
}
