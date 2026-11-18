// K49 of lib/features/diary/CRITERIA.md (#911): a goal set on Thursday that
// counts from Saturday. The old run ends on Wednesday, the day before the new
// goal takes effect; Thursday and Friday are practice days that belong to no
// run; Saturday starts the new run.
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';

import 'acceptance_harness.dart';

/// Thursday, the day the new goal is set and takes effect.
final DateTime _thursday = runDay(3);

/// K49's account: a run from Monday with goal 2.200; Mo 2.200, Tu 1.900,
/// We 3.000 eaten; today is Thursday; the new goal of 2.000 was set today
/// and counts from Saturday.
DiaryAcceptanceHarness _k49Account() => DiaryAcceptanceHarness(
  now: morningOf(_thursday),
  goalChange: GoalChange(setOn: _thursday, countsFrom: runDay(5), kcal: 2000),
  eaten: {runDay(0): 2200, runDay(1): 1900, runDay(2): 3000},
);

/// Opens the diary on Thursday in [mode]. Thursday has no week card to hold
/// for the menu, so the mode is picked on Monday, a day of the old run.
Future<void> _open(WidgetTester tester, WeekBalanceMode mode) async {
  await _k49Account().pumpDiary(tester);
  if (mode != WeekBalanceMode.show) {
    await previousDay(tester, times: 3);
    await chooseModeInDiary(tester, mode);
    await nextDay(tester, times: 3);
  }
}

/// Expects the shown practice day to have no week card.
void _expectNoWeekCard(String day) {
  expect(
    find.byKey(WeekCardKeys.card),
    findsNothing,
    reason: '$day is a practice day of no run, so it has no week card (K37)',
  );
}

const List<WeekBalanceMode> _modes = [
  WeekBalanceMode.carryover,
  WeekBalanceMode.show,
];

void main() {
  group('K49', () {
    for (final mode in _modes) {
      testWidgets('K49: in "${mode.label}", paged to Tuesday, the old run ends '
          'on Wednesday: only "Mo", "Di", "Mi"', (tester) async {
        await _open(tester, mode);

        await previousDay(tester, times: 2);

        expect(find.byKey(WeekCardKeys.card), findsOneWidget);
        expect(weekDayNames(tester), [
          'Mo',
          'Di',
          'Mi',
        ], reason: 'the old run ends the day before the new goal takes effect');
        expect(find.byKey(WeekCardKeys.day(3)), findsNothing);
        expect(framedWeekDay(tester), 1, reason: 'the frame is on Tuesday');
      });

      testWidgets('K49: in "${mode.label}", Thursday (today) and Friday show '
          'no week card', (tester) async {
        await _open(tester, mode);

        _expectNoWeekCard('Thursday');
        await nextDay(tester);
        _expectNoWeekCard('Friday');
      });

      testWidgets('K49: in "${mode.label}", Saturday shows the new run "Sa", '
          '"So", "Mo", "Di", "Mi", "Do", "Fr"', (tester) async {
        await _open(tester, mode);

        await nextDay(tester, times: 2);

        expect(find.byKey(WeekCardKeys.card), findsOneWidget);
        expect(weekDayNames(tester), [
          'Sa',
          'So',
          'Mo',
          'Di',
          'Mi',
          'Do',
          'Fr',
        ], reason: 'Thursday and Friday appear in no strip');
        expect(framedWeekDay(tester), 0, reason: 'the frame is on Saturday');
      });
    }

    testWidgets('K49: Thursday and Friday count against the plain new goal '
        '"2.000", with no carryover of the old run’s −500', (tester) async {
      await _open(tester, WeekBalanceMode.carryover);

      for (final day in ['Thursday', 'Friday']) {
        if (day == 'Friday') await nextDay(tester);
        expect(budgetKcalText(tester), '2.000', reason: day);
        expect(
          budgetCardText(tester),
          isNot(contains('aus der Woche')),
          reason: '$day has no chip "… aus der Woche"',
        );
        if (find.byKey(DiaryBudgetCardKeys.ledger).evaluate().isEmpty) {
          await toggleDetails(tester);
        }
        expect(
          ledgerText(tester),
          isNot(contains('Übertrag aus der Woche')),
          reason: "the old run's balance does not reach $day",
        );
        await toggleDetails(tester);
      }
    });

    testWidgets('K49: Saturday, the first day of the new run, has carryover 0 '
        'and shows "2.000"', (tester) async {
      await _open(tester, WeekBalanceMode.carryover);

      await nextDay(tester, times: 2);

      expect(budgetKcalText(tester), '2.000');
      expect(budgetCardText(tester), isNot(contains('aus der Woche')));
      await toggleDetails(tester);
      expect(
        ledgerText(tester),
        isNot(contains('Übertrag aus der Woche')),
        reason: 'carryover 0 on the first day of a new run (K11)',
      );
    });
  });
}
