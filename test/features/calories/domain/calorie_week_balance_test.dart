// The week balance of #911, driven through its public entry
// `WeekBalance.resolve`. Expected values come from K11, K26 and K22/K23 of
// lib/features/diary/CRITERIA.md.
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_week_balance.dart';
import 'package:yamt/features/calories/domain/week_balance_mode.dart';

/// Monday, the first day of the run.
final DateTime _monday = DateTime(2026, 11, 16);

DateTime _day(int index) => addLocalDays(_monday, index);

/// The run with today at [todayIndex] (0 = first day). [eaten] maps a day
/// index to its kcal; a missing day has no entries. [goals] overrides the
/// goal of single days.
WeekBalance _resolve({
  required int todayIndex,
  WeekBalanceMode mode = WeekBalanceMode.carryover,
  double goal = 2200,
  Map<int, double> eaten = const {},
  Map<int, double> goals = const {},
  Set<int> pauseDays = const {},
  CalorieGoalMode weightGoal = CalorieGoalMode.lose,
}) {
  return WeekBalance.resolve(
    mode: mode,
    weightGoal: weightGoal,
    today: _day(todayIndex).add(const Duration(hours: 10)),
    days: [
      for (var index = 0; index < 7; index += 1)
        (
          date: _day(index),
          goalKcal: goals[index] ?? goal,
          eatenKcal: eaten[index] ?? 0,
          hasEntries: eaten.containsKey(index),
          isPauseDay: pauseDays.contains(index),
        ),
    ],
  );
}

/// Eaten kcal on the first [count] days.
Map<int, double> _days(int count, double kcal) => {
  for (var index = 0; index < count; index += 1) index: kcal,
};

void main() {
  group('K11: the carryover of today', () {
    // One entry per row of the K11 table, apart from the new run, which the
    // overview provider test covers.
    final rows =
        <
          ({
            String row,
            int today,
            double goal,
            Map<int, double> eaten,
            Map<int, double> goals,
            Set<int> pause,
            double carryover,
            double budget,
          })
        >[
          (
            row: '2.200, none, day 1',
            today: 0,
            goal: 2200,
            eaten: const {},
            goals: const {},
            pause: const {},
            carryover: 0,
            budget: 2200,
          ),
          (
            row: '2.200 · 1.900 · 3.000, day 4',
            today: 3,
            goal: 2200,
            eaten: const {0: 2200, 1: 1900, 2: 3000},
            goals: const {},
            pause: const {},
            carryover: -125,
            budget: 2075,
          ),
          (
            row: '2.200 three times, day 4',
            today: 3,
            goal: 2200,
            eaten: _days(3, 2200),
            goals: const {},
            pause: const {},
            carryover: 0,
            budget: 2200,
          ),
          (
            row: '2.200 · 6.750 (whole cake), day 3',
            today: 2,
            goal: 2200,
            eaten: const {0: 2200, 1: 6750},
            goals: const {},
            pause: const {},
            carryover: -350,
            budget: 1850,
          ),
          (
            row: 'six days of 1.900, day 7',
            today: 6,
            goal: 2200,
            eaten: _days(6, 1900),
            goals: const {},
            pause: const {},
            carryover: 350,
            budget: 2550,
          ),
          (
            row: '2.700, six days of 2.400, day 7',
            today: 6,
            goal: 2700,
            eaten: _days(6, 2400),
            goals: const {},
            pause: const {},
            carryover: 350,
            budget: 3050,
          ),
          (
            row: '2.300 three times (balance −300), day 4',
            today: 3,
            goal: 2200,
            eaten: _days(3, 2300),
            goals: const {},
            pause: const {},
            carryover: -75,
            budget: 2125,
          ),
          (
            row: '2.200 · empty day · 3.000, day 4',
            today: 3,
            goal: 2200,
            eaten: const {0: 2200, 2: 3000},
            goals: const {},
            pause: const {},
            carryover: -200,
            budget: 2000,
          ),
          (
            row: 'six empty days, day 7',
            today: 6,
            goal: 2200,
            eaten: const {},
            goals: const {},
            pause: const {},
            carryover: 0,
            budget: 2200,
          ),
          (
            row: '1.500, 4.500 (balance −3.000), day 2',
            today: 1,
            goal: 1500,
            eaten: const {0: 4500},
            goals: const {},
            pause: const {},
            carryover: -300,
            budget: 1200,
          ),
          (
            row: '1.500, 3.000 on a pause day, day 2',
            today: 1,
            goal: 1500,
            eaten: const {0: 3000},
            goals: const {},
            pause: const {0},
            carryover: 0,
            budget: 1500,
          ),
          (
            row: '1.500, six days of 1.300 (balance +1.200), day 7',
            today: 6,
            goal: 1500,
            eaten: _days(6, 1300),
            goals: const {},
            pause: const {},
            carryover: 300,
            budget: 1800,
          ),
          (
            row: '1.750 training day, balance −2.400, day 5',
            today: 4,
            goal: 1500,
            eaten: _days(4, 2100),
            goals: const {4: 1750},
            pause: const {},
            carryover: -350,
            budget: 1400,
          ),
          (
            row: '1.300, balance −1.300, day 7',
            today: 6,
            goal: 1300,
            eaten: {..._days(6, 1300), 0: 2600},
            goals: const {},
            pause: const {},
            carryover: -100,
            budget: 1200,
          ),
          (
            row: '1.200, balance −2.000, day 5',
            today: 4,
            goal: 1200,
            eaten: {..._days(4, 1200), 0: 3200},
            goals: const {},
            pause: const {},
            carryover: 0,
            budget: 1200,
          ),
          (
            row: '1.200, balance +600, day 6',
            today: 5,
            goal: 1200,
            eaten: {..._days(5, 1200), 0: 600},
            goals: const {},
            pause: const {},
            carryover: 240,
            budget: 1440,
          ),
        ];

    for (final row in rows) {
      test('K11: ${row.row}', () {
        final balance = _resolve(
          todayIndex: row.today,
          goal: row.goal,
          eaten: row.eaten,
          goals: row.goals,
          pauseDays: row.pause,
        );
        final today = balance.days[row.today];

        expect(today.carryoverKcal, row.carryover);
        expect(today.budgetKcal, row.budget);
      });
    }
  });

  group('K26: the preview of the coming days', () {
    final rows =
        <
          ({
            String row,
            int today,
            Map<int, double> eaten,
            double budgetToday,
            List<double> preview,
          })
        >[
          (
            row: 'Thursday, 900 eaten',
            today: 3,
            eaten: const {0: 2200, 1: 1900, 2: 3000, 3: 900},
            budgetToday: 2075,
            preview: const [-125, -125, -125],
          ),
          (
            row: 'Thursday, 2.075 eaten',
            today: 3,
            eaten: const {0: 2200, 1: 1900, 2: 3000, 3: 2075},
            budgetToday: 2075,
            preview: const [-125, -125, -125],
          ),
          (
            row: 'Thursday, 3.075 eaten',
            today: 3,
            eaten: const {0: 2200, 1: 1900, 2: 3000, 3: 3075},
            budgetToday: 2075,
            preview: const [-350, -350, -350],
          ),
          (
            row: 'Tuesday, 6.750 eaten',
            today: 1,
            eaten: const {0: 2200, 1: 6750},
            budgetToday: 2200,
            preview: const [-350, -350, -350, -350, -350],
          ),
          (
            row: 'Tuesday, 1.000 eaten',
            today: 1,
            eaten: const {0: 2200, 1: 1000},
            budgetToday: 2200,
            preview: const [0, 0, 0, 0, 0],
          ),
          (
            row: 'Saturday after five days of 1.900, 1.900 eaten',
            today: 5,
            eaten: {..._days(5, 1900), 5: 1900},
            budgetToday: 2550,
            preview: const [350],
          ),
          (
            row: 'Monday, 2.800 eaten',
            today: 0,
            eaten: const {0: 2800},
            budgetToday: 2200,
            preview: const [-100, -100, -100, -100, -100, -100],
          ),
        ];

    for (final row in rows) {
      test('K26: ${row.row}', () {
        final balance = _resolve(todayIndex: row.today, eaten: row.eaten);

        expect(balance.days[row.today].budgetKcal, row.budgetToday);
        expect([
          for (final day in balance.days.skip(row.today + 1)) day.carryoverKcal,
        ], row.preview);
      });
    }
  });

  test('K6/K21: without the carryover no day of the run moves', () {
    for (final mode in [WeekBalanceMode.off, WeekBalanceMode.show]) {
      final balance = _resolve(
        mode: mode,
        todayIndex: 3,
        eaten: const {0: 2200, 1: 1900, 2: 3000, 3: 3075},
      );

      expect(
        [for (final day in balance.days) day.carryoverKcal],
        everyElement(0),
        reason: mode.name,
      );
      expect(
        [for (final day in balance.days) day.budgetKcal],
        everyElement(2200),
        reason: mode.name,
      );
    }
  });

  test('K18/K25: a pause day and an empty day add nothing, whatever was '
      'eaten', () {
    final withPause = _resolve(
      todayIndex: 3,
      eaten: const {0: 2200, 1: 3000, 2: 2200},
      pauseDays: const {1},
    );
    final withEmptyDay = _resolve(
      todayIndex: 3,
      eaten: const {0: 2200, 2: 2200},
    );

    expect(withPause.days[3].carryoverKcal, 0);
    expect(withEmptyDay.days[3].carryoverKcal, 0);
  });

  test('K20: a finished day keeps what was eaten and its budget', () {
    final balance = _resolve(
      todayIndex: 3,
      eaten: const {0: 2200, 1: 1900, 2: 3000},
    );

    // Wednesday's budget was 2.260 (K30), so +740 is shown under it.
    expect(balance.days[2].budgetKcal, 2260);
    expect(balance.days[2].eatenKcal - balance.days[2].budgetKcal, 740);
    expect(balance.days[1].hasEntries, isTrue);
    expect(balance.days[4].hasEntries, isFalse);
  });

  test('K22/K23: over is the miss for losing and holding, not for gaining', () {
    expect(_resolve(todayIndex: 0).overIsMiss, isTrue);
    expect(
      _resolve(todayIndex: 0, weightGoal: CalorieGoalMode.maintain).overIsMiss,
      isTrue,
    );
    expect(
      _resolve(todayIndex: 0, weightGoal: CalorieGoalMode.gain).overIsMiss,
      isFalse,
    );
  });

  test('dayOf finds a day of the run and nothing outside it', () {
    final balance = _resolve(todayIndex: 0);

    expect(
      balance.dayOf(_day(3).add(const Duration(hours: 20)))?.date,
      _day(3),
    );
    expect(balance.dayOf(_day(7)), isNull);
    expect(balance.dayOf(_day(-1)), isNull);
  });

  test('survives the JSON of the dashboard cache', () {
    final balance = _resolve(
      todayIndex: 3,
      eaten: const {0: 2200, 1: 1900, 2: 3000},
      pauseDays: const {1},
      weightGoal: CalorieGoalMode.gain,
    );

    final copy = WeekBalance.fromJson(balance.toJson());

    expect(copy.mode, WeekBalanceMode.carryover);
    expect(copy.weightGoal, CalorieGoalMode.gain);
    expect(
      [for (final day in copy.days) day.toJson()],
      [for (final day in balance.days) day.toJson()],
    );
  });

  group('isTodayClosed', () {
    WeekBalance thursday({
      required bool closed,
      double? eatenToday = 1400,
      WeekBalanceMode mode = WeekBalanceMode.carryover,
    }) => WeekBalance.resolve(
      mode: mode,
      weightGoal: CalorieGoalMode.lose,
      today: _day(3).add(const Duration(hours: 10)),
      isTodayClosed: closed,
      days: [
        for (var index = 0; index < 7; index += 1)
          (
            date: _day(index),
            goalKcal: 2200,
            eatenKcal:
                const {0: 2200.0, 1: 1900.0, 2: 3000.0}[index] ??
                (index == 3 ? eatenToday ?? 0 : 0),
            hasEntries: index < 3 || (index == 3 && eatenToday != null),
            isPauseDay: false,
          ),
      ],
    );

    List<double> carryovers(WeekBalance balance) => [
      for (final day in balance.days) day.carryoverKcal,
    ];

    test('K39: a closed today counts what it saved for the days after it', () {
      // Balance −500 before Thursday; open, Thursday counts as hitting
      // 2.075; closed, it adds 2.200 − 1.400 = +800.
      expect(carryovers(thursday(closed: false)), [
        0,
        0,
        60,
        -125,
        -125,
        -125,
        -125,
      ]);
      expect(carryovers(thursday(closed: true)), [
        0,
        0,
        60,
        -125,
        100,
        100,
        100,
      ]);
    });

    test('a closed today without entries adds 0 to the balance', () {
      // −500 over the three days after Thursday: −166,67 → −167; then
      // −333 over two → −167 (half away from zero); then −166 on Sunday.
      expect(carryovers(thursday(closed: true, eatenToday: null)).sublist(4), [
        -167,
        -167,
        -166,
      ]);
      // Open, the empty today still counts as hitting its budget.
      expect(carryovers(thursday(closed: false, eatenToday: null)).sublist(4), [
        -125,
        -125,
        -125,
      ]);
    });

    test('K9: without the carryover a closed today moves no day', () {
      for (final mode in [WeekBalanceMode.off, WeekBalanceMode.show]) {
        expect(
          carryovers(thursday(closed: true, mode: mode)),
          everyElement(0),
          reason: mode.name,
        );
      }
    });
  });

  group('isOffBudget and isMiss', () {
    WeekBalanceDay dayEating(
      double eaten, {
      bool hasEntries = true,
      bool isPauseDay = false,
    }) => WeekBalanceDay(
      date: _day(0),
      goalKcal: 2000,
      eatenKcal: eaten,
      hasEntries: hasEntries,
      isPauseDay: isPauseDay,
      carryoverKcal: 0,
    );

    test('a day is off its budget from 50 kcal on, in both directions', () {
      const rows = [
        (2049.0, false),
        (2050.0, true),
        (2051.0, true),
        (1951.0, false),
        (1950.0, true),
        (1949.0, true),
      ];
      for (final (eaten, off) in rows) {
        expect(dayEating(eaten).isOffBudget, off, reason: '$eaten');
      }
    });

    test('K22/K23: the miss side follows the weight goal', () {
      const rows = [
        (CalorieGoalMode.lose, 2050.0, true),
        (CalorieGoalMode.lose, 1950.0, false),
        (CalorieGoalMode.lose, 2049.0, false),
        (CalorieGoalMode.maintain, 2050.0, true),
        (CalorieGoalMode.maintain, 1950.0, false),
        (CalorieGoalMode.gain, 2050.0, false),
        (CalorieGoalMode.gain, 1950.0, true),
        (CalorieGoalMode.gain, 1951.0, false),
      ];
      for (final (goal, eaten, miss) in rows) {
        final balance = WeekBalance(
          mode: WeekBalanceMode.show,
          weightGoal: goal,
          days: [dayEating(eaten)],
        );
        expect(
          balance.isMiss(balance.days.single),
          miss,
          reason: '${goal.name} $eaten',
        );
      }
    });

    test('a pause day and a day without entries are never a miss', () {
      final balance = WeekBalance(
        mode: WeekBalanceMode.show,
        weightGoal: CalorieGoalMode.gain,
        days: [
          dayEating(3000, isPauseDay: true),
          dayEating(0, hasEntries: false),
        ],
      );

      expect(balance.isMiss(balance.days[0]), isFalse);
      expect(balance.isMiss(balance.days[1]), isFalse);
    });
  });

  group('equality', () {
    WeekBalanceDay day({double carryover = 0}) => WeekBalanceDay(
      date: _day(0),
      goalKcal: 2200,
      eatenKcal: 1900,
      hasEntries: true,
      isPauseDay: false,
      carryoverKcal: carryover,
    );

    test('WeekBalanceDay compares by value', () {
      expect(day(), day());
      expect(day().hashCode, day().hashCode);
      expect(day(), isNot(day(carryover: 60)));
    });

    test('WeekBalance compares mode, weight goal and days', () {
      WeekBalance balance({
        WeekBalanceMode mode = WeekBalanceMode.carryover,
        CalorieGoalMode goal = CalorieGoalMode.lose,
        double carryover = 0,
      }) => WeekBalance(
        mode: mode,
        weightGoal: goal,
        days: [day(carryover: carryover)],
      );

      expect(balance(), balance());
      expect(balance().hashCode, balance().hashCode);
      expect(balance(), isNot(balance(mode: WeekBalanceMode.show)));
      expect(balance(), isNot(balance(goal: CalorieGoalMode.gain)));
      expect(balance(), isNot(balance(carryover: 60)));
    });
  });
}
