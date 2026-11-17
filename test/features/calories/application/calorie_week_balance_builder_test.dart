import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/calorie_week_balance_builder.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/week_balance_mode.dart';

/// Monday, the first day of the run.
final DateTime _monday = DateTime(2026, 11, 16);

DateTime _day(int index) => addLocalDays(_monday, index);

CalorieGoalSettings _settings({DateTime? goalStart}) =>
    CalorieGoalSettings.single(
      dailyKcalGoal: 2200,
      calculatorProfile: const CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.male,
        weightKg: 80,
        heightCm: 180,
        ageYears: 30,
        activityLevel: 1.2,
        goalMode: CalorieGoalMode.gain,
        goalSpeedKgPerWeek: 0.25,
      ),
      effectiveDate: goalStart ?? _monday,
      countingStartDate: goalStart ?? _monday,
    ).copyWith(weekBalanceMode: WeekBalanceMode.carryover);

/// The rolling window that ends on [day], with [eaten] kcal by day index.
List<CalorieWeekDayOverview> _window(DateTime day, Map<int, double> eaten) => [
  for (final date in buildRollingLocalDays(anchorDay: day))
    CalorieWeekDayOverview(
      date: date,
      totalKcal: eaten[date.difference(_monday).inDays] ?? 0,
      goalKcal: date.isBefore(_monday) ? 0 : 2200,
      entryCount: eaten.containsKey(date.difference(_monday).inDays) ? 1 : 0,
    ),
];

CalorieEntry _entry(DateTime day, double kcal) {
  final loggedAt = day.add(const Duration(hours: 12));
  return CalorieEntry.create(
    id: 'entry-${localDayKey(day)}',
    userId: 'user-1',
    name: 'Item',
    mealType: MealType.lunch,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: kcal,
    per100Protein: 0,
    per100Carbs: 0,
    per100Fat: 0,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

void main() {
  test('K37: a day without a counting goal has no run and no balance', () {
    final balance = buildCalorieWeekBalance(
      settings: _settings(goalStart: _day(7)),
      overviews: _window(_day(3), const {}),
      realToday: _day(3),
      laterEntries: const [],
    );

    expect(balance, isNull);
  });

  test('K14: the balance holds the seven days of the run, in their order', () {
    final balance = buildCalorieWeekBalance(
      settings: _settings(),
      overviews: _window(_day(3), const {0: 2200, 1: 1900, 2: 3000}),
      realToday: _day(3),
      laterEntries: const [],
    )!;

    expect(
      [for (final day in balance.days) day.date],
      [for (var index = 0; index < 7; index += 1) _day(index)],
    );
    expect(balance.mode, WeekBalanceMode.carryover);
    expect(balance.days[3].carryoverKcal, -125);
  });

  test('K23: the weight goal of the run tells which side is the miss', () {
    final balance = buildCalorieWeekBalance(
      settings: _settings(),
      overviews: _window(_day(3), const {}),
      realToday: _day(3),
      laterEntries: const [],
    )!;

    expect(balance.overIsMiss, isFalse);
  });

  test('K28: a day of a run that is over takes its later days from the '
      'later entries', () {
    // Thursday of the run, seen a week later: Friday and Saturday are
    // finished, Sunday stayed empty.
    final balance = buildCalorieWeekBalance(
      settings: _settings(),
      overviews: _window(_day(3), const {0: 2200, 1: 1900, 2: 3000, 3: 2200}),
      realToday: _day(9),
      laterEntries: [_entry(_day(4), 3000), _entry(_day(5), 1900)],
    )!;

    expect(balance.days[4].eatenKcal, 3000);
    expect(balance.days[4].hasEntries, isTrue);
    expect(balance.days[5].eatenKcal, 1900);
    expect(balance.days[6].hasEntries, isFalse);
    // Balance before Saturday: +300 − 800 + 0 − 800 = −1.300 over two days,
    // so the limit of 350 holds (K11).
    expect(balance.days[5].carryoverKcal, -350);
    // Sunday: −1.300 + 300 = −1.000, again the limit.
    expect(balance.days[6].carryoverKcal, -350);
  });
}
