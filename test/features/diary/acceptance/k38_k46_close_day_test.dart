// K38 to K46 of lib/features/diary/CRITERIA.md (#911, #922): in mode
// "Mit Übertrag", tomorrow's budget card offers to close today, and a closed
// today counts as a finished day for every coming day.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';

import 'acceptance_harness.dart';

const _weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

/// Mo 2.200 · Tu 1.900 · We 3.000 (balance −500); today is Thursday with
/// [thursday] eaten (budget 2.075).
DiaryAcceptanceHarness _thursday(
  double thursday, {
  Set<DateTime> pauseDays = const <DateTime>{},
  CalorieGoalMode goalMode = CalorieGoalMode.lose,
}) => DiaryAcceptanceHarness(
  now: morningOf(runDay(3)),
  goalMode: goalMode,
  pauseDays: pauseDays,
  eaten: {
    runDay(0): 2200,
    runDay(1): 1900,
    runDay(2): 3000,
    runDay(3): thursday,
  },
);

/// Opens the diary on Thursday in "Mit Übertrag" and pages to Friday.
Future<void> _openFridayWithCarryover(
  WidgetTester tester,
  DiaryAcceptanceHarness harness,
) async {
  await harness.pumpDiary(tester);
  await chooseModeInDiary(tester, WeekBalanceMode.carryover);
  await nextDay(tester);
}

Finder _inCard(String text) => find.descendant(
  of: find.byKey(DiaryBudgetCardKeys.card),
  matching: find.textContaining(text),
);

/// Expects the budget card of the shown coming day to show [budget] before
/// anything is eaten on it, with [carryover] in its ledger.
Future<void> _expectBudget(
  WidgetTester tester,
  double budget, {
  required double carryover,
  required String day,
}) async {
  expect(budgetKcalText(tester), de(budget), reason: 'budget of $day');
  expect(budgetUnitText(tester), startsWith('kcal übrig'), reason: day);
  if (find.byKey(DiaryBudgetCardKeys.ledger).evaluate().isEmpty) {
    await toggleDetails(tester);
  }
  expect(
    ledgerText(tester),
    contains('Übertrag aus der Woche ${signed(carryover)}'),
    reason: 'carryover of $day',
  );
  await toggleDetails(tester);
}

/// From Friday, expects Friday, Saturday and Sunday to show [budget] and
/// pages back to Friday.
Future<void> _expectFridayToSunday(WidgetTester tester, double budget) async {
  for (var day = 4; day < 7; day += 1) {
    if (day > 4) await nextDay(tester);
    expect(budgetKcalText(tester), de(budget), reason: _weekdays[day]);
  }
  await previousDay(tester, times: 2);
}

void _expectPieces(int day, {required bool debt, required bool extra}) {
  expect(
    partOfDay(day, WeekCardKeys.debtPiece),
    debt ? findsOneWidget : findsNothing,
    reason: 'dark piece of ${_weekdays[day]}',
  );
  expect(
    partOfDay(day, WeekCardKeys.extraPiece),
    extra ? findsOneWidget : findsNothing,
    reason: 'dashed extra piece of ${_weekdays[day]}',
  );
}

/// One row of the K39 table.
typedef _K39Row = ({double eaten, double before, double after});

const List<_K39Row> _k39Rows = [
  (eaten: 1400, before: -125, after: 100),
  (eaten: 1475, before: -125, after: 75),
  (eaten: 650, before: -125, after: 350),
  (eaten: 500, before: -125, after: 350),
  (eaten: 2075, before: -125, after: -125),
  (eaten: 3075, before: -350, after: -350),
];

void main() {
  group('K38', () {
    testWidgets('K38: only tomorrow shows "Donnerstag abschließen", today\'s '
        'weekday in full', (tester) async {
      await _thursday(900).pumpDiary(tester);
      await chooseModeInDiary(tester, WeekBalanceMode.carryover);

      await previousDay(tester, times: 3);
      for (var day = 0; day < 7; day += 1) {
        if (day > 0) await nextDay(tester);
        final name = _weekdays[day];
        if (day == 4) {
          expect(closeDayButton, findsOneWidget, reason: 'button on $name');
          expect(textUnder(tester, closeDayButton), 'Donnerstag abschließen');
          expect(_inCard('Do abschließen'), findsNothing);
          expect(_inCard('Freitag abschließen'), findsNothing);
        } else {
          expect(closeDayButton, findsNothing, reason: 'no button on $name');
          expect(_inCard('abschließen'), findsNothing, reason: name);
        }
      }
    });
  });

  group('K39', () {
    for (final row in _k39Rows) {
      testWidgets('K39: Thursday ${de(row.eaten)} eaten → Fr, Sa, Su '
          '${de(2200 + row.before)} before closing, '
          '${de(2200 + row.after)} after', (tester) async {
        await _openFridayWithCarryover(tester, _thursday(row.eaten));

        for (var day = 4; day < 7; day += 1) {
          if (day > 4) await nextDay(tester);
          await _expectBudget(
            tester,
            2200 + row.before,
            carryover: row.before,
            day: '${_weekdays[day]} before closing',
          );
        }
        await previousDay(tester, times: 2);

        await closeToday(tester);

        for (var day = 4; day < 7; day += 1) {
          if (day > 4) await nextDay(tester);
          await _expectBudget(
            tester,
            2200 + row.after,
            carryover: row.after,
            day: '${_weekdays[day]} after closing',
          );
        }
      });
    }

    testWidgets('K39: in the week card the coming days swap the dark piece '
        "for a dashed extra piece; Thursday's own carryover stays −125", (
      tester,
    ) async {
      await _openFridayWithCarryover(tester, _thursday(1400));
      for (final day in [4, 5, 6]) {
        _expectPieces(day, debt: true, extra: false);
      }

      await closeToday(tester);

      for (final day in [4, 5, 6]) {
        _expectPieces(day, debt: false, extra: true);
      }
      await previousDay(tester);
      await toggleDetails(tester);
      expect(
        ledgerText(tester),
        contains('Übertrag aus der Woche −125'),
        reason: "Thursday's carryover comes from Monday to Wednesday only",
      );
    });
  });

  group('K40', () {
    testWidgets('K40: the closed carryover follows food logged today and '
        'edits of earlier days', (tester) async {
      final harness = _thursday(1400);
      await _openFridayWithCarryover(tester, harness);
      await closeToday(tester);
      expect(budgetKcalText(tester), '2.300');

      await harness.eat(tester, runDay(3), 75);
      expect(budgetKcalText(tester), '2.275', reason: 'Thursday 1.475');

      await harness.changeEaten(tester, runDay(2), 2700);
      await _expectFridayToSunday(tester, 2375);
    });
  });

  group('K41', () {
    /// From Friday: today is open, Friday to Sunday show the preview.
    Future<void> expectOpen(WidgetTester tester) async {
      expect(reopenDayButton, findsNothing);
      expect(closeDayButton, findsOneWidget);
      expect(textUnder(tester, closeDayButton), 'Donnerstag abschließen');
      await _expectFridayToSunday(tester, 2075);
      for (final day in [4, 5, 6]) {
        _expectPieces(day, debt: true, extra: false);
      }
    }

    testWidgets('K41: closing shows "Donnerstag abgeschlossen" with undo; '
        'undo and a tap on it open today again', (tester) async {
      await _openFridayWithCarryover(tester, _thursday(1400));

      await closeToday(tester);

      expect(reopenDayButton, findsOneWidget);
      expect(textUnder(tester, reopenDayButton), 'Donnerstag abgeschlossen');
      expect(
        find.descendant(of: reopenDayButton, matching: find.byType(Icon)),
        findsWidgets,
        reason: 'the label has a check mark',
      );
      expect(budgetKcalText(tester), '2.300');
      expect(undoAction, findsOneWidget, reason: 'a snack bar offers undo');

      await tester.tap(undoAction);
      await settle(tester);
      await expectOpen(tester);

      await closeToday(tester);
      expect(budgetKcalText(tester), '2.300');
      await reopenToday(tester);
      await expectOpen(tester);
    });
  });

  group('K42', () {
    testWidgets('K42: the close survives a restart on Thursday and ends at '
        'midnight', (tester) async {
      final harness = _thursday(1400);
      await _openFridayWithCarryover(tester, harness);
      await closeToday(tester);

      await harness.restart(tester);
      await nextDay(tester);
      expect(reopenDayButton, findsOneWidget, reason: 'still closed');
      expect(textUnder(tester, reopenDayButton), 'Donnerstag abgeschlossen');
      expect(budgetKcalText(tester), '2.300');

      harness.now = morningOf(runDay(4));
      await harness.restart(tester);
      expect(
        budgetKcalText(tester),
        '2.300',
        reason: 'Friday: balance +300 over 3 days, Thursday finished (K11)',
      );
      expect(budgetUnitText(tester), startsWith('kcal übrig'));

      await nextDay(tester);
      expect(reopenDayButton, findsNothing, reason: 'Friday is not closed');
      expect(closeDayButton, findsOneWidget);
      expect(textUnder(tester, closeDayButton), 'Freitag abschließen');
    });
  });

  group('K43', () {
    testWidgets('K43: on the 7th day, tomorrow starts a new run: no button, '
        'plain goal', (tester) async {
      await DiaryAcceptanceHarness(
        now: morningOf(runDay(6)),
        eaten: {
          for (var day = 0; day < 6; day += 1) runDay(day): 1900,
          runDay(6): 1000,
        },
      ).pumpDiary(tester);
      await chooseModeInDiary(tester, WeekBalanceMode.carryover);

      await nextDay(tester);

      expect(closeDayButton, findsNothing);
      expect(reopenDayButton, findsNothing);
      expect(_inCard('abschließen'), findsNothing);
      expect(budgetKcalText(tester), '2.200');
    });
  });

  group('K44', () {
    testWidgets('K44: no button when tomorrow is a pause day', (tester) async {
      await _openFridayWithCarryover(
        tester,
        _thursday(1400, pauseDays: {runDay(4)}),
      );

      expect(closeDayButton, findsNothing);
      expect(reopenDayButton, findsNothing);
      expect(_inCard('Donnerstag abschließen'), findsNothing);
      expect(_inCard('Donnerstag abgeschlossen'), findsNothing);
    });
  });

  group('K45', () {
    testWidgets('K45: a switch to "Anzeigen" and back keeps today closed', (
      tester,
    ) async {
      await _openFridayWithCarryover(tester, _thursday(1400));
      await closeToday(tester);

      await chooseModeInDiary(tester, WeekBalanceMode.show);
      expect(budgetKcalText(tester), '2.200');
      expect(closeDayButton, findsNothing);
      expect(reopenDayButton, findsNothing);

      await chooseModeInDiary(tester, WeekBalanceMode.carryover);
      expect(reopenDayButton, findsOneWidget);
      expect(textUnder(tester, reopenDayButton), 'Donnerstag abgeschlossen');
      await _expectFridayToSunday(tester, 2300);
    });
  });

  group('K46', () {
    testWidgets('K46: a closed today keeps its "today" look; from the next '
        'day it is a finished day', (tester) async {
      final harness = _thursday(1400, goalMode: CalorieGoalMode.gain);
      await _openFridayWithCarryover(tester, harness);
      await closeToday(tester);

      await previousDay(tester);
      await toggleDetails(tester);
      final red = redOf(tester);
      expect(dayNumberText(tester, 3), isEmpty, reason: 'nothing under today');
      expect(
        fillColorsUnder(tester, find.byKey(WeekCardKeys.day(3))),
        isNot(contains(red)),
        reason: 'today is not red for being under',
      );

      harness.now = morningOf(runDay(4));
      await harness.restart(tester);
      if (find.byKey(DiaryBudgetCardKeys.ledger).evaluate().isEmpty) {
        await toggleDetails(tester);
      }
      expect(dayNumberText(tester, 3), '−675');
      expect(
        fillColorsUnder(tester, find.byKey(WeekCardKeys.day(3))),
        contains(red),
        reason: 'Thursday fell short under "Zunehmen" (K23)',
      );
    });
  });
}
