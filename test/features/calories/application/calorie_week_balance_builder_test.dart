import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/calorie_week_balance_builder.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
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

/// [settings] with a second goal of [kcal] set on [setOn] (default [from])
/// at 10:00 that counts from [from] on (K47, K49), stored as the app's goal
/// save stores it: effective from the day it is set, counting from [from].
CalorieGoalSettings _withNewGoal(
  CalorieGoalSettings settings, {
  required DateTime from,
  DateTime? setOn,
  double kcal = 2000,
}) {
  final day = setOn ?? from;
  assert(!from.isBefore(day), 'a goal set on a day counts from it or later');
  final next = settings.applyGoalChange(
    changedAt: DateTime(day.year, day.month, day.day, 10),
    dailyKcalGoal: kcal,
    calculatorProfile: settings.goalHistory.last.calculatorProfile,
    countingStartDate: from,
    source: CalorieGoalSource.calculator,
    replaceFutureHistory: true,
  );
  final added = next.goalHistory.last;
  expect(next.goalHistory, hasLength(settings.goalHistory.length + 1));
  expect(added.effectiveDate, normalizeLocalDay(day));
  expect(added.effectiveCountingStartDate, normalizeLocalDay(from));
  return next;
}

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
    WeekBalance tuesdayOf(
      CalorieGoalSettings settings, {
      DateTime? realToday,
    }) => buildCalorieWeekBalance(
      settings: settings,
      overviews: _window(_day(1), const {0: 2200, 1: 1900}),
      realToday: realToday ?? _day(3),
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

    test('K14: a new goal set after the run ended cuts nothing', () {
      // Set on the Monday after the run, counting from that day or later.
      for (final from in [_day(7), _day(9)]) {
        final withLaterGoal = tuesdayOf(
          _withNewGoal(_settings(), setOn: _day(7), from: from),
          realToday: _day(9),
        );

        expect(
          [for (final day in withLaterGoal.days) day.date],
          [for (var index = 0; index < 7; index += 1) _day(index)],
          reason: 'new goal from ${localDayKey(from)}',
        );
        expect(
          withLaterGoal.days,
          tuesdayOf(_settings(), realToday: _day(9)).days,
        );
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

  group('a goal set mid-run that counts from a later day (K49)', () {
    // K49's account: Mo 2.200, Tu 1.900, We 3.000 eaten; on Thursday a new
    // goal of 2.000 is set that counts from Saturday (or from the Monday
    // after the run). It takes effect on Thursday.
    CalorieGoalSettings setThursday({required DateTime from}) =>
        _withNewGoal(_settings(), setOn: _day(3), from: from);

    WeekBalance? balanceOf(CalorieGoalSettings settings, DateTime day) =>
        buildCalorieWeekBalance(
          settings: settings,
          overviews: _window(day, const {0: 2200, 1: 1900, 2: 3000}),
          realToday: _day(3),
          laterEntries: const [],
        );

    for (final from in [_day(5), _day(7)]) {
      final start = localDayKey(from);

      test('K49: counting from $start, the old run ends on Wednesday, the '
          'day before the new goal takes effect', () {
        final tuesday = buildCalorieWeekBalance(
          settings: setThursday(from: from),
          overviews: _window(_day(1), const {0: 2200, 1: 1900}),
          realToday: _day(3),
          laterEntries: [_entry(_day(2), 3000)],
        )!;

        expect(
          [for (final day in tuesday.days) day.date],
          [_day(0), _day(1), _day(2)],
        );
      });

      test('K49: counting from $start, the old run keeps the budgets of the '
          'full run (K48)', () {
        WeekBalance tuesdayOf(CalorieGoalSettings settings) =>
            buildCalorieWeekBalance(
              settings: settings,
              overviews: _window(_day(1), const {0: 2200, 1: 1900}),
              realToday: _day(3),
              laterEntries: [_entry(_day(2), 3000)],
            )!;

        final cut = tuesdayOf(setThursday(from: from));

        expect(cut.days, tuesdayOf(_settings()).days.take(3).toList());
        expect(cut.days[2].budgetKcal, 2260);
      });

      test('K49: counting from $start, the practice days from Thursday to '
          'the day before are in no balance', () {
        final settings = setThursday(from: from);
        for (
          var day = _day(3);
          day.isBefore(from);
          day = addLocalDays(day, 1)
        ) {
          expect(
            balanceOf(settings, day),
            isNull,
            reason: '${localDayKey(day)} is a practice day of no run',
          );
        }
      });
    }

    test('K49: the new run starts on Saturday with the new goal and nothing '
        'of the old run’s −500', () {
      final balance = balanceOf(setThursday(from: _day(5)), _day(5))!;

      expect(
        [for (final day in balance.days) day.date],
        [for (var index = 5; index < 12; index += 1) _day(index)],
      );
      for (final day in balance.days) {
        expect(day.goalKcal, 2000, reason: localDayKey(day.date));
        expect(day.carryoverKcal, 0, reason: localDayKey(day.date));
      }
    });
  });
}
