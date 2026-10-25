import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_intake_resolver.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';

void main() {
  test('resolves window intake when every day has entries', () {
    final start = DateTime(2026, 4, 2);
    final secondDay = nextLocalDay(start);
    final settings = _settings(start);
    final data = resolveWeeklyWindowIntakeData(
      days: [start, secondDay],
      calorieEntriesByDay: {
        localDayKey(start): [_entry('a', start, 1200)],
        localDayKey(secondDay): [_entry('b', secondDay, 800)],
      },
      settings: settings,
      weightByDay: {localDayKey(secondDay): 80},
    );

    expect(data.blockedReason, isNull);
    expect(data.missingIntakeDays, isEmpty);
    expect(data.days.map((day) => day.resolvedIntakeKcal), [1200, 800]);
    expect(data.days.last.weightKg, 80);
  });

  test('blocks when >= 3 missing days are present', () {
    final day1 = DateTime(2026, 4, 2);
    final day2 = nextLocalDay(day1);
    final day3 = nextLocalDay(day2);
    final day4 = nextLocalDay(day3);

    final data = resolveWeeklyWindowIntakeData(
      days: [day1, day2, day3, day4],
      calorieEntriesByDay: {
        localDayKey(day1): [_entry('a', day1, 1200)],
      },
      settings: _settings(day1),
      weightByDay: const <String, double>{},
    );

    expect(
      data.blockedReason,
      CalorieWeeklyCheckInBlockedReason.tooManyMissingIntakeDays,
    );
    expect(data.missingIntakeDays, [day2, day3, day4]);
  });

  test(
    'interpolates skipped days from average of logged days in the window',
    () {
      final start = DateTime(2026, 4, 2);
      final skippedDay = nextLocalDay(start);
      final thirdDay = nextLocalDay(skippedDay);
      final settings = _settings(start)
          .setSkippedIntakeDay(day: skippedDay, isSkipped: true);

      final data = resolveWeeklyWindowIntakeData(
        days: [start, skippedDay, thirdDay],
        calorieEntriesByDay: {
          localDayKey(start): [_entry('a', start, 1000)],
          localDayKey(thirdDay): [_entry('c', thirdDay, 2000)],
        },
        settings: settings,
        weightByDay: const <String, double>{},
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
    final secondDay = nextLocalDay(start);
    final settings = _settings(start)
        .setSkippedIntakeDay(day: start, isSkipped: true);

    final data = resolveWeeklyWindowIntakeData(
      days: [start, secondDay],
      calorieEntriesByDay: {
        localDayKey(secondDay): [_entry('b', secondDay, 1800)],
      },
      settings: settings,
      weightByDay: const <String, double>{},
    );

    expect(data.blockedReason, isNull);
    expect(
      data.days.map((day) => day.resolvedIntakeKcal).toList(growable: false),
      [1800, 1800],
    );
    expect(data.days[0].hasEntries, isFalse);
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
