// K47 and K48 of lib/features/diary/CRITERIA.md (#911), with the lines of
// K14 and K28 that point to them: a new goal in the middle of a run starts a
// new run on its start day; the old run ends the day before, shows only its
// own days, passes nothing on, and keeps its past budgets.
//
// The layout of a strip with fewer than seven fields is "Phone only" (K47):
// these tests check the number and the names of the fields, not where they
// stand.
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';

import 'acceptance_harness.dart';

/// Thursday of the run from Monday, the start day of the new goal.
final DateTime _thursday = runDay(3);

/// The new goal of K47: 2.000 from Thursday on.
final NewGoal _newGoal = (from: _thursday, kcal: 2000);

/// K47's account: a run from Monday with goal 2.200; Mo 2.200, Tu 1.900,
/// We 3.000 eaten; today is Thursday, nothing eaten yet. With
/// [withNewGoal] the goal of 2.000 from Thursday is already set.
DiaryAcceptanceHarness _k47Account({bool withNewGoal = true}) =>
    DiaryAcceptanceHarness(
      now: morningOf(_thursday),
      newGoal: withNewGoal ? _newGoal : null,
      eaten: {runDay(0): 2200, runDay(1): 1900, runDay(2): 3000},
    );

/// Opens the diary on Thursday in [mode].
Future<void> _open(
  WidgetTester tester,
  DiaryAcceptanceHarness harness,
  WeekBalanceMode mode,
) async {
  await harness.pumpDiary(tester);
  if (mode != WeekBalanceMode.show) {
    await chooseModeInDiary(tester, mode);
  }
}

/// The indices of the week card's fields, from 0 on, as long as they follow
/// each other.
int _fieldCount(WidgetTester tester) {
  var count = 0;
  while (find.byKey(WeekCardKeys.day(count)).evaluate().isNotEmpty) {
    count += 1;
  }
  return count;
}

/// The names under the week card's fields, in their order.
List<String> _dayNames(WidgetTester tester) => [
  for (var index = 0; index < _fieldCount(tester); index += 1)
    dayNameText(tester, index),
];

/// The index of the one field that has the frame.
int? _framedDay(WidgetTester tester) {
  expect(find.byKey(WeekCardKeys.frame), findsOneWidget);
  for (var index = 0; index < 7; index += 1) {
    if (partOfDay(index, WeekCardKeys.frame).evaluate().isNotEmpty) {
      return index;
    }
  }
  return null;
}

/// Expects the old run's strip, shown on Tuesday: only "Mo", "Di", "Mi",
/// the frame on Tuesday, no "Heute", no field for Thursday or later.
void _expectOldRunOnTuesday(WidgetTester tester) {
  expect(find.byKey(WeekCardKeys.card), findsOneWidget);
  expect(
    _fieldCount(tester),
    3,
    reason: 'the old run has only its own days, Monday to Wednesday',
  );
  expect(find.byKey(WeekCardKeys.day(3)), findsNothing);
  expect(_dayNames(tester), ['Mo', 'Di', 'Mi']);
  expect(_dayNames(tester), isNot(contains('Heute')));
  expect(_framedDay(tester), 1, reason: 'the frame is on Tuesday');
}

void main() {
  group('K14', () {
    for (final mode in [WeekBalanceMode.show, WeekBalanceMode.carryover]) {
      testWidgets('K14: in "${mode.label}" a run cut short by a new goal has '
          'only its own days, so fewer than seven fields', (tester) async {
        await _open(tester, _k47Account(), mode);

        await previousDay(tester, times: 2);

        expect(find.byKey(WeekCardKeys.card), findsOneWidget);
        expect(_fieldCount(tester), 3);
        expect(find.byKey(WeekCardKeys.day(3)), findsNothing);
        expect(find.byKey(WeekCardKeys.day(6)), findsNothing);
      });
    }
  });

  group('K28', () {
    testWidgets('K28: paged to a day of a run cut short by a new goal, the '
        'strip shows that run’s days with the frame on the shown day and '
        'no "Heute"', (tester) async {
      await _open(tester, _k47Account(), WeekBalanceMode.carryover);

      await previousDay(tester, times: 2);

      _expectOldRunOnTuesday(tester);
    });
  });

  group('K47', () {
    testWidgets('K47: on Thursday the strip shows the new run "Heute", "Fr", '
        '"Sa", "So", "Mo", "Di", "Mi" and no day of the old run', (
      tester,
    ) async {
      await _open(tester, _k47Account(), WeekBalanceMode.carryover);

      expect(find.byKey(WeekCardKeys.card), findsOneWidget);
      expect(_fieldCount(tester), 7);
      expect(_dayNames(tester), ['Heute', 'Fr', 'Sa', 'So', 'Mo', 'Di', 'Mi']);
      expect(_framedDay(tester), 0, reason: 'today is the first day');
    });

    testWidgets('K47: the budget card shows "2.000" "kcal übrig" without a '
        'chip "… aus der Woche"', (tester) async {
      await _open(tester, _k47Account(), WeekBalanceMode.carryover);

      expect(budgetKcalText(tester), '2.000');
      expect(budgetUnitText(tester), startsWith('kcal übrig'));
      expect(
        budgetCardText(tester),
        isNot(contains('aus der Woche')),
        reason: 'no chip "… aus der Woche"',
      );
      await toggleDetails(tester);
      expect(
        ledgerText(tester),
        isNot(contains('Übertrag aus der Woche')),
        reason: "the old run's balance never reaches the new run",
      );
    });

    testWidgets('K47: Friday to next Wednesday carry no piece of the old '
        'run’s −500: no dark piece, budget cards "2.000"', (tester) async {
      await _open(tester, _k47Account(), WeekBalanceMode.carryover);

      for (var index = 1; index < 7; index += 1) {
        expect(
          partOfDay(index, WeekCardKeys.debtPiece),
          findsNothing,
          reason: 'no dark piece in field $index',
        );
      }
      const coming = ['Fr', 'Sa', 'So', 'Mo', 'Di', 'Mi'];
      for (final day in coming) {
        await nextDay(tester);
        expect(budgetKcalText(tester), '2.000', reason: day);
        expect(budgetUnitText(tester), startsWith('kcal übrig'), reason: day);
      }
    });

    testWidgets('K47: paged to Tuesday, the strip shows the old run with '
        'only "Mo", "Di", "Mi", the frame on Tuesday and no "Heute"', (
      tester,
    ) async {
      await _open(tester, _k47Account(), WeekBalanceMode.carryover);

      await previousDay(tester, times: 2);

      _expectOldRunOnTuesday(tester);
    });

    testWidgets('K47: in "Anzeigen" the fields and names are the same, and '
        'no field has a piece', (tester) async {
      await _open(tester, _k47Account(), WeekBalanceMode.show);

      void expectNoPieces(String day) {
        expect(
          find.descendant(
            of: find.byKey(WeekCardKeys.card),
            matching: find.byKey(WeekCardKeys.debtPiece),
          ),
          findsNothing,
          reason: 'no dark piece on $day',
        );
        expect(
          find.descendant(
            of: find.byKey(WeekCardKeys.card),
            matching: find.byKey(WeekCardKeys.extraPiece),
          ),
          findsNothing,
          reason: 'no extra piece on $day',
        );
      }

      expect(_dayNames(tester), ['Heute', 'Fr', 'Sa', 'So', 'Mo', 'Di', 'Mi']);
      expectNoPieces('Thursday');

      await previousDay(tester, times: 2);

      _expectOldRunOnTuesday(tester);
      expectNoPieces('Tuesday');
    });
  });

  group('K48', () {
    testWidgets('K48: after the new goal from Thursday, Wednesday still '
        'counts against 2.260 with "+740" under it; Tuesday keeps 2.200', (
      tester,
    ) async {
      final harness = _k47Account(withNewGoal: false);
      await _open(tester, harness, WeekBalanceMode.carryover);
      await previousDay(tester);
      if (find.byKey(DiaryBudgetCardKeys.ledger).evaluate().isEmpty) {
        await toggleDetails(tester);
      }
      expect(
        ledgerText(tester),
        contains('Übertrag aus der Woche +60'),
        reason: "Wednesday's budget before the new goal: 2.200 + 300 ÷ 5",
      );

      await harness.setNewGoal(tester, _newGoal);

      if (find.byKey(DiaryBudgetCardKeys.ledger).evaluate().isEmpty) {
        await toggleDetails(tester);
      }
      expect(
        ledgerText(tester),
        contains('Übertrag aus der Woche +60'),
        reason: 'Wednesday still counts against 2.260',
      );
      expect(
        ledgerText(tester),
        isNot(contains('+300')),
        reason: 'not +300 ÷ 1 day of the shorter run (2.500)',
      );
      expect(dayNumberText(tester, 2), '+740', reason: '3.000 against 2.260');

      await previousDay(tester);
      if (find.byKey(DiaryBudgetCardKeys.ledger).evaluate().isEmpty) {
        await toggleDetails(tester);
      }
      expect(
        ledgerText(tester),
        isNot(contains('Übertrag aus der Woche')),
        reason: 'Tuesday keeps its budget of 2.200 (balance 0 on that day)',
      );
      expect(dayNumberText(tester, 1), '−300', reason: '1.900 against 2.200');
    });
  });
}
