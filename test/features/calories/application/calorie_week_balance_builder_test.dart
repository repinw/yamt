import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/calorie_week_balance_builder.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_week_balance.dart';
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

/// [settings] with a second goal of [kcal] that counts from [from] on,
/// set after the first one (K47).
CalorieGoalSettings _withNewGoal(
  CalorieGoalSettings settings, {
  required DateTime from,
  double kcal = 2000,
}) => settings.copyWith(
  dailyKcalGoal: kcal,
  updatedAt: from,
  goalHistory: [
    ...settings.goalHistory,
    CalorieGoalHistoryEntry(
      dailyKcalGoal: kcal,
      calculatorProfile: settings.goalHistory.last.calculatorProfile,
      effectiveDate: from,
      changedAt: from,
      countingStartDate: from,
    ),
  ],
);

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

  group('a new goal in the middle of the run (K47, K48)', () {
    // K47's account: Mo 2.200, Tu 1.900, We 3.000 eaten; the new goal of
    // 2.000 counts from Thursday. Seen on Tuesday, on Thursday.
    WeekBalance tuesdayOf(CalorieGoalSettings settings) =>
        buildCalorieWeekBalance(
          settings: settings,
          overviews: _window(_day(1), const {0: 2200, 1: 1900}),
          realToday: _day(3),
          // Wednesday of the old run and Thursday of the new run: the
          // overview reads the later entries up to the uncut run end.
          laterEntries: [_entry(_day(2), 3000), _entry(_day(3), 1500)],
        )!;

    test('K47: a day of the old run holds only the days before the new '
        'goal starts', () {
      final balance = tuesdayOf(_withNewGoal(_settings(), from: _day(3)));

      expect(
        [for (final day in balance.days) day.date],
        [_day(0), _day(1), _day(2)],
      );
      expect(balance.dayOf(_day(3)), isNull);
      expect(balance.mode, WeekBalanceMode.carryover);
    });

    test('K48: the kept days keep the budgets of the full run', () {
      final cut = tuesdayOf(_withNewGoal(_settings(), from: _day(3)));
      final full = tuesdayOf(_settings());

      // Tuesday: balance 0 on that day. Wednesday: +300 ÷ 5 = +60.
      expect(cut.days[0].budgetKcal, 2200);
      expect(cut.days[1].budgetKcal, 2200);
      expect(cut.days[2].carryoverKcal, 60);
      expect(cut.days[2].budgetKcal, 2260);
      expect(cut.days[2].differenceKcal, 740);
      expect(cut.days, full.days.take(3).toList());
    });

    test('K47: a new goal on the last day of the run leaves six days', () {
      final balance = tuesdayOf(_withNewGoal(_settings(), from: _day(6)));

      expect(
        [for (final day in balance.days) day.date],
        [for (var index = 0; index < 6; index += 1) _day(index)],
      );
    });

    test('K14: a new goal that starts after the run ends cuts nothing', () {
      for (final from in [_day(7), _day(9)]) {
        final withLaterGoal = tuesdayOf(_withNewGoal(_settings(), from: from));

        expect(
          [for (final day in withLaterGoal.days) day.date],
          [for (var index = 0; index < 7; index += 1) _day(index)],
          reason: 'new goal from ${localDayKey(from)}',
        );
        expect(withLaterGoal.days, tuesdayOf(_settings()).days);
      }
    });

    test('K47: the new run starts on the new goal’s first day with its '
        'goal and nothing of the old run’s −500', () {
      final balance = buildCalorieWeekBalance(
        settings: _withNewGoal(_settings(), from: _day(3)),
        overviews: _window(_day(3), const {0: 2200, 1: 1900, 2: 3000}),
        realToday: _day(3),
        laterEntries: const [],
      )!;

      expect(
        [for (final day in balance.days) day.date],
        [for (var index = 3; index < 10; index += 1) _day(index)],
      );
      for (final day in balance.days) {
        expect(day.goalKcal, 2000, reason: localDayKey(day.date));
        expect(day.carryoverKcal, 0, reason: localDayKey(day.date));
      }
    });
  });
}
