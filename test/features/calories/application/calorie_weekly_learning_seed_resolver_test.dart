import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_window_resolver.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_learning_seed_resolver.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

void main() {
  test('uses base seed when there is no anchor entry', () {
    final start = DateTime(2026, 4, 2);
    const settings = CalorieGoalSettings.empty();

    final seed = baseLearningSeedForWindow(
      settings: settings,
      windowStartDate: start,
      windowEndDate: addDiaryDays(start, 6),
      anchorEntry: null,
    );

    expect(seed.previousGoalKcal, defaultDailyCalorieGoalKcal);
    expect(seed.previousLearnedTdeeKcal, defaultDailyCalorieGoalKcal);
  });

  test('replays completed prior weekly windows into next seed', () {
    final firstStart = DateTime(2026, 4, 2);
    final secondStart = DateTime(2026, 4, 9);
    final pending = PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: secondStart,
      windowEndDate: addDiaryDays(secondStart, 6),
      dueDate: addDiaryDays(secondStart, 7),
    );
    final settings = _settings(firstStart);
    final dates = resolveCalorieWeeklyCheckInWindowDates(
      settings: settings,
      pendingWeeklyCheckIn: pending,
    );
    final entriesByDay = <String, List<CalorieEntry>>{
      for (var index = 0; index < 7; index += 1)
        diaryDayKey(addDiaryDays(firstStart, index)): [
          _entry('day-$index', addDiaryDays(firstStart, index), 2000),
        ],
    };
    final previousLearnedTdee = CalorieGoalCalculator.calculate(
      const CalorieCalculatorProfile.defaults(),
    ).tdeeKcal;
    final expected = CalorieWeeklyCheckInCalculator.calculateLearnedGoal(
      previousGoalKcal: 2000,
      previousLearnedTdeeKcal: previousLearnedTdee,
      goalSpeedKgPerWeek: 0,
      isLosing: false,
      isGaining: false,
      intakeKcalByDay: const [2000, 2000, 2000, 2000, 2000, 2000, 2000],
      rawActivityKcalByDay: const [0, 0, 0, 0, 0, 0, 0],
      weightPoints: const [
        CalorieWeeklyCheckInWeightPoint(dayIndex: 0, weightKg: 80),
        CalorieWeeklyCheckInWeightPoint(dayIndex: 7, weightKg: 79),
      ],
    );

    final seed = resolveCascadedPreviousLearningSeedForWindow(
      settings: settings,
      pendingWeeklyCheckIn: pending,
      dates: dates,
      calorieEntriesByDay: entriesByDay,
      manualWeightByDay: {diaryDayKey(addDiaryDays(firstStart, 7)): 79},
      representativeWeightByDay: const <String, double>{},
      activeKcalByDay: const <String, int>{},
      heartDayKeys: const <String>{},
    );

    expect(seed.previousGoalKcal, expected.newGoalKcal);
    expect(
      seed.previousLearnedTdeeKcal,
      expected.calculatedBaseTdeeKcal,
    );
  });

  test('keeps current seed when prior window lacks intake data', () {
    final firstStart = DateTime(2026, 4, 2);
    final secondStart = DateTime(2026, 4, 9);
    final pending = PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: secondStart,
      windowEndDate: addDiaryDays(secondStart, 6),
      dueDate: addDiaryDays(secondStart, 7),
    );
    final settings = _settings(firstStart);
    final dates = resolveCalorieWeeklyCheckInWindowDates(
      settings: settings,
      pendingWeeklyCheckIn: pending,
    );
    final expectedPreviousTdee = CalorieGoalCalculator.calculate(
      const CalorieCalculatorProfile.defaults(),
    ).tdeeKcal;

    final seed = resolveCascadedPreviousLearningSeedForWindow(
      settings: settings,
      pendingWeeklyCheckIn: pending,
      dates: dates,
      calorieEntriesByDay: const <String, List<CalorieEntry>>{},
      manualWeightByDay: {diaryDayKey(addDiaryDays(firstStart, 7)): 79},
      representativeWeightByDay: const <String, double>{},
      activeKcalByDay: const <String, int>{},
      heartDayKeys: const <String>{},
    );

    expect(seed.previousGoalKcal, 2000);
    expect(seed.previousLearnedTdeeKcal, expectedPreviousTdee);
  });
}

CalorieGoalSettings _settings(DateTime start) {
  return CalorieGoalSettings.single(
    dailyKcalGoal: 2000,
    calculatorProfile: const CalorieCalculatorProfile.defaults(),
    effectiveDate: start,
    countingStartDate: start,
  );
}

CalorieEntry _entry(String id, DateTime day, double kcal) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Entry $id',
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: kcal,
    per100Protein: 0,
    per100Carbs: 0,
    per100Fat: 0,
    loggedAt: day.add(const Duration(hours: 8)),
    createdAt: day,
    updatedAt: day,
  );
}
