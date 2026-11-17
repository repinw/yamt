// K26 and K27 of lib/features/diary/CRITERIA.md (#911): the preview of the
// carryover on the coming days of the run. K26 is read where K27 shows it:
// the budget card of each coming day (nothing eaten there yet, so its big
// number is its budget, and its ledger names the carryover).
import 'package:flutter_test/flutter_test.dart';

import 'acceptance_harness.dart';

/// One row of the K26 table; mode "Mit Übertrag", goal 2.200, run from
/// Monday.
class _Row {
  const new(
    this.name, {
    required this.finished,
    required this.today,
    required this.budgetToday,
    required this.eatenToday,
    required this.preview,
  });

  final String name;

  /// Kcal of the finished days from Monday.
  final List<double> finished;

  /// Today's day of the run, 1 to 7.
  final int today;

  final double budgetToday;

  final double eatenToday;

  /// Expected carryover of each coming day, from tomorrow on.
  final List<double> preview;
}

const _rows = <_Row>[
  _Row(
    'Mo 2.200 · Tu 1.900 · We 3.000, Thursday, 900 eaten',
    finished: [2200, 1900, 3000],
    today: 4,
    budgetToday: 2075,
    eatenToday: 900,
    preview: [-125, -125, -125],
  ),
  _Row(
    'Mo 2.200 · Tu 1.900 · We 3.000, Thursday, 2.075 eaten',
    finished: [2200, 1900, 3000],
    today: 4,
    budgetToday: 2075,
    eatenToday: 2075,
    preview: [-125, -125, -125],
  ),
  _Row(
    'Mo 2.200 · Tu 1.900 · We 3.000, Thursday, 3.075 eaten',
    finished: [2200, 1900, 3000],
    today: 4,
    budgetToday: 2075,
    eatenToday: 3075,
    preview: [-350, -350, -350],
  ),
  _Row(
    'Mo 2.200, Tuesday, 6.750 eaten',
    finished: [2200],
    today: 2,
    budgetToday: 2200,
    eatenToday: 6750,
    preview: [-350, -350, -350, -350, -350],
  ),
  _Row(
    'Mo 2.200, Tuesday, 1.000 eaten',
    finished: [2200],
    today: 2,
    budgetToday: 2200,
    eatenToday: 1000,
    preview: [0, 0, 0, 0, 0],
  ),
  _Row(
    'Mo–Fr 1.900 each, Saturday, 1.900 eaten',
    finished: [1900, 1900, 1900, 1900, 1900],
    today: 6,
    budgetToday: 2550,
    eatenToday: 1900,
    preview: [350],
  ),
  _Row(
    'none, Monday, 2.800 eaten',
    finished: [],
    today: 1,
    budgetToday: 2200,
    eatenToday: 2800,
    preview: [-100, -100, -100, -100, -100, -100],
  ),
];

const _weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

/// Expects the shown coming day to have [carryover] on top of 2.200.
Future<void> _expectComingDay(
  WidgetTester tester,
  double carryover, {
  required String day,
}) async {
  expect(
    budgetKcalText(tester),
    de(2200 + carryover),
    reason: 'budget of $day',
  );
  await toggleDetails(tester);
  if (carryover == 0) {
    expect(
      ledgerText(tester),
      isNot(contains('Übertrag aus der Woche')),
      reason: 'no carryover on $day',
    );
  } else {
    expect(
      ledgerText(tester),
      contains('Übertrag aus der Woche ${signed(carryover)}'),
      reason: 'carryover of $day',
    );
  }
  await toggleDetails(tester);
}

void main() {
  group('K26', () {
    for (final row in _rows) {
      testWidgets('K26: ${row.name} → '
          '${row.preview.map(signed).join(' · ')}', (tester) async {
        final today = runDay(row.today - 1);
        await DiaryAcceptanceHarness(
          now: morningOf(today),
          eaten: {
            for (final (index, kcal) in row.finished.indexed)
              runDay(index): kcal,
            today: row.eatenToday,
          },
        ).pumpDiary(tester);
        await chooseModeInDiary(tester, WeekBalanceMode.carryover);

        for (final (index, carryover) in row.preview.indexed) {
          await nextDay(tester);
          await _expectComingDay(
            tester,
            carryover,
            day: _weekdays[row.today + index],
          );
        }
      });
    }
  });

  group('K27', () {
    testWidgets("K27: every coming day's budget card shows the preview, "
        'also after more is eaten today', (tester) async {
      final harness = DiaryAcceptanceHarness(
        now: morningOf(runDay(3)),
        eaten: {
          runDay(0): 2200,
          runDay(1): 1900,
          runDay(2): 3000,
          runDay(3): 900,
        },
      );
      await harness.pumpDiary(tester);
      await chooseModeInDiary(tester, WeekBalanceMode.carryover);

      for (var day = 4; day < 7; day += 1) {
        await nextDay(tester);
        expect(budgetKcalText(tester), '2.075', reason: _weekdays[day]);
        expect(budgetUnitText(tester), startsWith('kcal übrig'));
      }

      await previousDay(tester, times: 3);
      await harness.eat(tester, runDay(3), 2175);

      for (var day = 4; day < 7; day += 1) {
        await nextDay(tester);
        expect(budgetKcalText(tester), '1.850', reason: _weekdays[day]);
      }
    });

    for (final mode in [WeekBalanceMode.off, WeekBalanceMode.show]) {
      testWidgets('K27: in "${mode.label}" every coming day\'s budget card '
          'shows the plain goal "2.200"', (tester) async {
        await DiaryAcceptanceHarness(
          now: morningOf(runDay(3)),
          eaten: {
            runDay(0): 2200,
            runDay(1): 1900,
            runDay(2): 3000,
            runDay(3): 900,
          },
        ).pumpDiary(tester);
        if (mode != WeekBalanceMode.show) {
          await chooseModeInDiary(tester, mode);
        }

        for (var day = 4; day < 7; day += 1) {
          await nextDay(tester);
          expect(budgetKcalText(tester), '2.200', reason: _weekdays[day]);
        }
      });
    }
  });
}
