// K19 and K20 of lib/features/diary/CRITERIA.md (#911): the numbers under
// the days of the week card.
import 'package:flutter_test/flutter_test.dart';

import 'acceptance_harness.dart';

/// One row of the K20 table.
class _Row {
  const new(
    this.mode, {
    required this.budget,
    required this.eaten,
    required this.shown,
    this.pause = false,
  });

  final WeekBalanceMode mode;

  /// That day's budget, as the table names it.
  final String budget;

  /// Kcal eaten that day; null is a day without entries.
  final double? eaten;

  /// Whether the day was a pause day.
  final bool pause;

  /// Expected text under the day; empty for "nothing".
  final String shown;
}

const _rows = <_Row>[
  _Row(WeekBalanceMode.show, budget: '2.200', eaten: 3000, shown: '+800'),
  _Row(WeekBalanceMode.show, budget: '2.200', eaten: 6750, shown: '+4.550'),
  _Row(WeekBalanceMode.show, budget: '2.200', eaten: 1900, shown: '−300'),
  _Row(WeekBalanceMode.show, budget: '2.200', eaten: 2250, shown: '+50'),
  _Row(WeekBalanceMode.show, budget: '2.200', eaten: 2150, shown: '−50'),
  _Row(WeekBalanceMode.show, budget: '2.200', eaten: 2230, shown: ''),
  _Row(WeekBalanceMode.show, budget: '2.200', eaten: 2200, shown: ''),
  _Row(
    WeekBalanceMode.show,
    budget: '—',
    eaten: 3000,
    pause: true,
    shown: 'Pause',
  ),
  _Row(WeekBalanceMode.show, budget: '—', eaten: null, shown: 'leer'),
  _Row(WeekBalanceMode.carryover, budget: '2.260', eaten: 3000, shown: '+740'),
  _Row(WeekBalanceMode.carryover, budget: '1.850', eaten: 1850, shown: ''),
  _Row(WeekBalanceMode.carryover, budget: '1.850', eaten: 2200, shown: '+350'),
];

/// The run up to the row's day, which is Wednesday (index 2); today is
/// Thursday. In "Mit Übertrag", Wednesday's budget comes from Monday and
/// Tuesday: 2.200 · 1.900 gives +60 (2.260), 2.200 · 6.750 gives −350
/// (1.850). In "Anzeigen", Monday and Tuesday eat the goal.
DiaryAcceptanceHarness _harnessOf(_Row row) {
  final tuesday = switch (row.budget) {
    '2.260' => 1900.0,
    '1.850' => 6750.0,
    _ => 2200.0,
  };
  return DiaryAcceptanceHarness(
    now: morningOf(runDay(3)),
    pauseDays: row.pause ? {runDay(2)} : const {},
    eaten: {
      runDay(0): 2200,
      runDay(1): tuesday,
      if (row.eaten != null) runDay(2): row.eaten!,
    },
  );
}

void main() {
  group('K19', () {
    testWidgets('K19: "Details" shows numbers under the finished days only, '
        'and takes them away again', (tester) async {
      await DiaryAcceptanceHarness(
        now: morningOf(runDay(3)),
        eaten: {
          runDay(0): 1900,
          runDay(1): 3000,
          runDay(2): 1900,
          runDay(3): 800,
        },
      ).pumpDiary(tester);
      expect(find.byKey(WeekCardKeys.card), findsOneWidget);
      for (var index = 0; index < 7; index += 1) {
        expect(dayNumberText(tester, index), isEmpty, reason: 'closed');
      }

      await toggleDetails(tester);

      for (var index = 0; index < 3; index += 1) {
        expect(dayNumberText(tester, index), isNotEmpty, reason: 'finished');
      }
      for (var index = 3; index < 7; index += 1) {
        expect(dayNumberText(tester, index), isEmpty, reason: 'not finished');
      }

      await toggleDetails(tester);

      for (var index = 0; index < 7; index += 1) {
        expect(dayNumberText(tester, index), isEmpty, reason: 'closed again');
      }
    });
  });

  group('K20', () {
    for (final row in _rows) {
      final eaten = row.pause
          ? 'pause day, any amount'
          : row.eaten == null
          ? 'no entries'
          : de(row.eaten!);
      final shown = row.shown.isEmpty ? 'nothing' : row.shown;
      testWidgets('K20: ${row.mode.label}, budget ${row.budget}, eaten '
          '$eaten → $shown', (tester) async {
        await _harnessOf(row).pumpDiary(tester);
        if (row.mode != WeekBalanceMode.show) {
          await chooseModeInDiary(tester, row.mode);
        }
        expect(find.byKey(WeekCardKeys.card), findsOneWidget);

        await toggleDetails(tester);

        expect(dayNumberText(tester, 2), row.shown);
      });
    }
  });
}
