// K50 of lib/features/diary/CRITERIA.md (#911): a close of today does not
// count while tomorrow is a pause day, and counts again once tomorrow is a
// normal day again.
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';

import 'acceptance_harness.dart';

/// First row of K39: Mo 2.200 · Tu 1.900 · We 3.000 (balance −500); today
/// is Thursday with 1.400 eaten. Mode "Mit Übertrag", opened on Friday.
Future<void> _openFriday(WidgetTester tester) async {
  await DiaryAcceptanceHarness(
    now: morningOf(runDay(3)),
    eaten: {runDay(0): 2200, runDay(1): 1900, runDay(2): 3000, runDay(3): 1400},
  ).pumpDiary(tester);
  await chooseModeInDiary(tester, WeekBalanceMode.carryover);
  await nextDay(tester);
}

/// Taps the pause button on the shown day's budget card: a normal day
/// becomes a pause day, a pause day a normal day again.
Future<void> _togglePause(WidgetTester tester) async {
  final button = find.descendant(
    of: find.byKey(DiaryBudgetCardKeys.card),
    matching: find.byKey(DiaryBudgetCardKeys.dayTypeButton(DiaryDayType.pause)),
  );
  expect(button, findsOneWidget, reason: 'the pause button of the day');
  await waitForSnackBarToPass(tester);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await settle(tester);
}

/// What Saturday or Sunday shows: its budget card's big number and the
/// pieces of its field in the week card.
typedef _DayView = ({String budget, bool debtPiece, bool extraPiece});

/// From Friday, reads Saturday and Sunday and pages back to Friday.
Future<Map<String, _DayView>> _weekend(WidgetTester tester) async {
  final views = <String, _DayView>{};
  for (final (index, day) in [(5, 'Saturday'), (6, 'Sunday')]) {
    await nextDay(tester);
    views[day] = (
      budget: budgetKcalText(tester),
      debtPiece: partOfDay(index, WeekCardKeys.debtPiece).evaluate().isNotEmpty,
      extraPiece: partOfDay(
        index,
        WeekCardKeys.extraPiece,
      ).evaluate().isNotEmpty,
    );
  }
  await previousDay(tester, times: 2);
  return views;
}

void main() {
  group('K50', () {
    testWidgets('K50: once Friday is a pause day, Friday shows neither '
        '"Donnerstag abgeschlossen" nor "Donnerstag abschließen"', (
      tester,
    ) async {
      await _openFriday(tester);
      await closeToday(tester);

      await _togglePause(tester);

      expect(reopenDayButton, findsNothing);
      expect(closeDayButton, findsNothing);
      expect(
        find.descendant(
          of: find.byKey(DiaryBudgetCardKeys.card),
          matching: find.textContaining('Donnerstag'),
        ),
        findsNothing,
      );
    });

    testWidgets('K50: with Friday a pause day, Saturday and Sunday show the '
        'same as if Thursday had never been closed', (tester) async {
      await _openFriday(tester);
      // Without the close: Friday a pause day, then a normal day again.
      await _togglePause(tester);
      final neverClosed = await _weekend(tester);
      await _togglePause(tester);

      await closeToday(tester);
      await _togglePause(tester);

      expect(await _weekend(tester), neverClosed);
    });

    testWidgets('K50: Friday a normal day again, the close counts again: '
        '"Donnerstag abgeschlossen" and "2.300" on Friday to Sunday', (
      tester,
    ) async {
      await _openFriday(tester);
      await closeToday(tester);
      await _togglePause(tester);

      await _togglePause(tester);

      expect(reopenDayButton, findsOneWidget);
      expect(textUnder(tester, reopenDayButton), 'Donnerstag abgeschlossen');
      expect(budgetKcalText(tester), '2.300', reason: 'Friday');
      final weekend = await _weekend(tester);
      expect(weekend['Saturday']!.budget, '2.300');
      expect(weekend['Sunday']!.budget, '2.300');
    });
  });
}
