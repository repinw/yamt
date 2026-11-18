// K11 of lib/features/diary/CRITERIA.md (#911): the carryover of a day,
// one test per row of its table, driven through the diary in "Mit Übertrag":
// the budget card's big number before eating is the budget, and the ledger
// row "Übertrag aus der Woche" names the carryover (none when it is 0, K10).
import 'package:flutter_test/flutter_test.dart';

import 'acceptance_harness.dart';

/// One row of the K11 table.
class _Row {
  const new(
    this.name, {
    required this.goal,
    required this.runDay,
    required this.carryover,
    required this.budget,
    this.finished = const [],
    this.pauseOffsets = const {},
    this.trainingToday = false,
    this.normalGoal,
    this.previousRun = const [],
    this.oldGoal,
  });

  /// The row as the table writes it.
  final String name;

  /// Goal today.
  final double goal;

  /// Goal of the other days, when today is a training day.
  final double? normalGoal;

  /// Kcal eaten on the finished days of the run, from its first day; null is
  /// a day without entries.
  final List<double?> finished;

  /// Finished days (by index) that were pause days.
  final Set<int> pauseOffsets;

  /// Whether today is a training day.
  final bool trainingToday;

  /// Kcal eaten on the 7 days of the run before, when the row starts a new
  /// run.
  final List<double> previousRun;

  /// Goal of the run that a new goal of [goal], counting from today, cut
  /// short; null when the goal did not change. [finished] and [runDay] then
  /// count from the old run's first day.
  final double? oldGoal;

  /// Today's day of the run, 1 to 7.
  final int runDay;

  /// Expected carryover.
  final double carryover;

  /// Expected budget.
  final double budget;
}

const _rows = <_Row>[
  _Row('2.200, none, day 1', goal: 2200, runDay: 1, carryover: 0, budget: 2200),
  _Row(
    '2.200, 2.200 · 1.900 · 3.000, day 4',
    goal: 2200,
    finished: [2200, 1900, 3000],
    runDay: 4,
    carryover: -125,
    budget: 2075,
  ),
  _Row(
    '2.200, 2.200 · 2.200 · 2.200, day 4',
    goal: 2200,
    finished: [2200, 2200, 2200],
    runDay: 4,
    carryover: 0,
    budget: 2200,
  ),
  _Row(
    '2.200, 2.200 · 6.750 (whole cake), day 3',
    goal: 2200,
    finished: [2200, 6750],
    runDay: 3,
    carryover: -350,
    budget: 1850,
  ),
  _Row(
    '2.200, six days of 1.900, day 7',
    goal: 2200,
    finished: [1900, 1900, 1900, 1900, 1900, 1900],
    runDay: 7,
    carryover: 350,
    budget: 2550,
  ),
  _Row(
    '2.700, six days of 2.400, day 7',
    goal: 2700,
    finished: [2400, 2400, 2400, 2400, 2400, 2400],
    runDay: 7,
    carryover: 350,
    budget: 3050,
  ),
  _Row(
    '2.200, 2.300 · 2.300 · 2.300 (balance −300), day 4',
    goal: 2200,
    finished: [2300, 2300, 2300],
    runDay: 4,
    carryover: -75,
    budget: 2125,
  ),
  _Row(
    '2.200, 2.200 · empty day · 3.000, day 4',
    goal: 2200,
    finished: [2200, null, 3000],
    runDay: 4,
    carryover: -200,
    budget: 2000,
  ),
  _Row(
    '2.200, six empty days, day 7',
    goal: 2200,
    finished: [null, null, null, null, null, null],
    runDay: 7,
    carryover: 0,
    budget: 2200,
  ),
  _Row(
    '1.500, 4.500 (balance −3.000), day 2',
    goal: 1500,
    finished: [4500],
    runDay: 2,
    carryover: -300,
    budget: 1200,
  ),
  _Row(
    '1.500, 3.000 on a day that was a pause day (balance 0), day 2',
    goal: 1500,
    finished: [3000],
    pauseOffsets: {0},
    runDay: 2,
    carryover: 0,
    budget: 1500,
  ),
  _Row(
    '1.500, six days of 1.300 (balance +1.200), day 7',
    goal: 1500,
    finished: [1300, 1300, 1300, 1300, 1300, 1300],
    runDay: 7,
    carryover: 300,
    budget: 1800,
  ),
  // Balance −2.400 over four normal days of 1.500.
  _Row(
    '1.750 (training day), balance −2.400, day 5',
    goal: 1750,
    normalGoal: 1500,
    trainingToday: true,
    finished: [2100, 2100, 2100, 2100],
    runDay: 5,
    carryover: -350,
    budget: 1400,
  ),
  // Balance −1.300 over six days of 1.300.
  _Row(
    '1.300, balance −1.300, day 7',
    goal: 1300,
    finished: [2600, 1300, 1300, 1300, 1300, 1300],
    runDay: 7,
    carryover: -100,
    budget: 1200,
  ),
  // Balance −2.000 over four days of 1.200.
  _Row(
    '1.200, balance −2.000, day 5',
    goal: 1200,
    finished: [1700, 1700, 1700, 1700],
    runDay: 5,
    carryover: 0,
    budget: 1200,
  ),
  // Balance +600 over five days of 1.200.
  _Row(
    '1.200, balance +600, day 6',
    goal: 1200,
    finished: [1080, 1080, 1080, 1080, 1080],
    runDay: 6,
    carryover: 240,
    budget: 1440,
  ),
  // The run before ended with balance −2.000: 4.200 on its first day.
  _Row(
    '2.200, previous run ended with balance −2.000, day 1 of a new run',
    goal: 2200,
    previousRun: [4200, 2200, 2200, 2200, 2200, 2200, 2200],
    runDay: 1,
    carryover: 0,
    budget: 2200,
  ),
  _Row(
    '2.000 (new goal from today, Thursday), old run Mo 2.200 · Tu 1.900 · '
    'We 3.000 (balance −500) cut short by the new goal, day 1 of a new run',
    goal: 2000,
    oldGoal: 2200,
    finished: [2200, 1900, 3000],
    runDay: 4,
    carryover: 0,
    budget: 2000,
  ),
];

DiaryAcceptanceHarness _harnessOf(_Row row) {
  final normalGoal = row.normalGoal ?? row.goal;
  final today = runDay(row.runDay - 1);
  final previousRunStart = runDay(-7);
  return DiaryAcceptanceHarness(
    now: morningOf(today),
    goalStart: row.previousRun.isEmpty ? runMonday : previousRunStart,
    goalKcal: row.oldGoal ?? normalGoal,
    newGoal: row.oldGoal == null ? null : (from: today, kcal: row.goal),
    trainingDays: row.trainingToday ? {today} : const {},
    trainingSessionKcal: row.trainingToday ? row.goal - normalGoal : 250,
    pauseDays: {for (final offset in row.pauseOffsets) runDay(offset)},
    eaten: {
      for (final (index, kcal) in row.previousRun.indexed)
        addDays(previousRunStart, index): kcal,
      for (final (index, kcal) in row.finished.indexed) runDay(index): ?kcal,
    },
  );
}

DateTime addDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);

void main() {
  group('K11', () {
    for (final row in _rows) {
      testWidgets('K11: ${row.name} → carryover ${signed(row.carryover)}, '
          'budget ${de(row.budget)}', (tester) async {
        await _harnessOf(row).pumpDiary(tester);
        await chooseModeInDiary(tester, WeekBalanceMode.carryover);

        expect(budgetKcalText(tester), de(row.budget));
        expect(budgetUnitText(tester), 'kcal übrig');
        await toggleDetails(tester);
        if (row.carryover == 0) {
          expect(ledgerText(tester), isNot(contains('Übertrag aus der Woche')));
        } else {
          expect(
            ledgerText(tester),
            contains('Übertrag aus der Woche ${signed(row.carryover)}'),
          );
        }
      });
    }
  });
}
