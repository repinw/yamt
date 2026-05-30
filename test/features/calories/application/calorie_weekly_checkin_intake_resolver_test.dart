import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_intake_resolver.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

void main() {
  test('resolves window intake when every day has entries', () {
    final start = DateTime(2026, 4, 2);
    final secondDay = nextDiaryDay(start);
    final settings = _settings(start);
    final data = resolveWeeklyWindowIntakeData(
      days: [start, secondDay],
      calorieEntriesByDay: {
        diaryDayKey(start): [_entry('a', start, 1200)],
        diaryDayKey(secondDay): [_entry('b', secondDay, 800)],
      },
      settings: settings,
      activeKcalByDay: {diaryDayKey(start): 150},
      weightByDay: {diaryDayKey(secondDay): 80},
      heartDayKeys: const <String>{},
    );

    expect(data.blockedReason, isNull);
    expect(data.missingIntakeDays, isEmpty);
    expect(data.days.map((day) => day.resolvedIntakeKcal), [1200, 800]);
    expect(data.days.first.activeKcal, 150);
    expect(data.days.last.weightKg, 80);
  });

  test('blocks when a missing day is not marked as skipped', () {
    final start = DateTime(2026, 4, 2);
    final secondDay = nextDiaryDay(start);

    final data = resolveWeeklyWindowIntakeData(
      days: [start, secondDay],
      calorieEntriesByDay: {
        diaryDayKey(start): [_entry('a', start, 1200)],
      },
      settings: _settings(start),
      activeKcalByDay: const <String, int>{},
      weightByDay: const <String, double>{},
      heartDayKeys: const <String>{},
    );

    expect(
      data.blockedReason,
      CalorieWeeklyCheckInBlockedReason.missingIntakeDays,
    );
    expect(data.missingIntakeDays, [secondDay]);
  });

  test(
    'interpolates skipped days from average of logged days in the window',
    () {
      final start = DateTime(2026, 4, 2);
      final skippedDay = nextDiaryDay(start);
      final thirdDay = nextDiaryDay(skippedDay);
      final settings = _settings(
        start,
      ).setSkippedIntakeDay(day: skippedDay, isSkipped: true);

      final data = resolveWeeklyWindowIntakeData(
        days: [start, skippedDay, thirdDay],
        calorieEntriesByDay: {
          diaryDayKey(start): [_entry('a', start, 1000)],
          diaryDayKey(thirdDay): [_entry('c', thirdDay, 2000)],
        },
        settings: settings,
        activeKcalByDay: const <String, int>{},
        weightByDay: const <String, double>{},
        heartDayKeys: const <String>{},
      );

      expect(data.blockedReason, isNull);
      expect(
        data.days.map((day) => day.resolvedIntakeKcal).toList(growable: false),
        [1000, 1500, 2000],
      );
      expect(data.days[1].hasEntries, isFalse);
    },
  );

  test('does not block when the first day of the week is skipped', () {
    final start = DateTime(2026, 4, 2);
    final secondDay = nextDiaryDay(start);
    final settings = _settings(
      start,
    ).setSkippedIntakeDay(day: start, isSkipped: true);

    final data = resolveWeeklyWindowIntakeData(
      days: [start, secondDay],
      calorieEntriesByDay: {
        diaryDayKey(secondDay): [_entry('b', secondDay, 1800)],
      },
      settings: settings,
      activeKcalByDay: const <String, int>{},
      weightByDay: const <String, double>{},
      heartDayKeys: const <String>{},
    );

    expect(data.blockedReason, isNull);
    expect(
      data.days.map((day) => day.resolvedIntakeKcal).toList(growable: false),
      [1800, 1800],
    );
    expect(data.days[0].hasEntries, isFalse);
  });

  test('learning intake ignores heart days', () {
    final start = DateTime(2026, 4, 2);
    final heartDay = nextDiaryDay(start);
    final thirdDay = nextDiaryDay(heartDay);

    final data = resolveWeeklyLearningIntakeData(
      days: [start, heartDay, thirdDay],
      calorieEntriesByDay: {
        diaryDayKey(start): [_entry('a', start, 1000)],
        diaryDayKey(thirdDay): [_entry('c', thirdDay, 2000)],
      },
      settings: _settings(start),
      heartDayKeys: {diaryDayKey(heartDay)},
    );

    expect(data.blockedReason, isNull);
    expect(data.intakeKcalByDay, [1000, 2000]);
    expect(data.missingIntakeDays, isEmpty);
  });
}

CalorieGoalSettings _settings(DateTime effectiveDate) {
  return CalorieGoalSettings.single(
    dailyKcalGoal: 2000,
    calculatorProfile: null,
    effectiveDate: effectiveDate,
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
