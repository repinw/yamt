// K6, K7, K8, K9, K34 of lib/features/diary/CRITERIA.md (#911): the fixed
// daily budget in the modes "Aus" and "Anzeigen".
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';

import 'acceptance_harness.dart';

/// Monday 2.200, Tuesday 1.900, Wednesday [wednesday]; today is Thursday.
DiaryAcceptanceHarness thursdayRun({double wednesday = 3000}) =>
    DiaryAcceptanceHarness(
      now: morningOf(runDay(3)),
      eaten: {runDay(0): 2200, runDay(1): 1900, runDay(2): wednesday},
    );

/// Puts the diary in [mode]; "Anzeigen" is where every account starts (K31).
Future<void> enterMode(WidgetTester tester, WeekBalanceMode mode) async {
  if (mode != WeekBalanceMode.show) {
    await chooseModeInDiary(tester, mode);
  }
}

/// Opens "Details" on the shown day's budget card unless it is open.
Future<void> ensureDetails(WidgetTester tester) async {
  if (find.byKey(DiaryBudgetCardKeys.ledger).evaluate().isEmpty) {
    await toggleDetails(tester);
  }
}

const List<WeekBalanceMode> _fixedModes = [
  WeekBalanceMode.off,
  WeekBalanceMode.show,
];

void main() {
  group('K6', () {
    for (final mode in _fixedModes) {
      testWidgets('K6: in "${mode.label}" Thursday shows "2.200" "kcal übrig" '
          'and every day of the run counts against 2.200', (tester) async {
        await thursdayRun().pumpDiary(tester);
        await enterMode(tester, mode);

        expect(budgetKcalText(tester), '2.200');
        expect(budgetUnitText(tester), 'kcal übrig');

        // Against 2.200, Monday (2.200 eaten) has 0 left, Tuesday (1.900)
        // 300 left, Wednesday (3.000) 800 over, and every coming day 2.200.
        const days = <(String, String)>[
          ('0', 'kcal übrig'),
          ('300', 'kcal übrig'),
          ('800', 'kcal drüber'),
          ('2.200', 'kcal übrig'),
          ('2.200', 'kcal übrig'),
          ('2.200', 'kcal übrig'),
          ('2.200', 'kcal übrig'),
        ];
        await previousDay(tester, times: 3);
        for (final (index, (number, unit)) in days.indexed) {
          final day = 'day ${index + 1} of the run counts against 2.200';
          final shown = budgetKcalText(tester)
              .replaceFirst(RegExp('^[+\u2212-]'), '');
          expect(shown, number, reason: day);
          expect(budgetUnitText(tester), startsWith(unit), reason: day);
          if (index < 6) await nextDay(tester);
        }
      });
    }
  });

  group('K7', () {
    for (final mode in _fixedModes) {
      testWidgets('K7: in "${mode.label}" the budget card names no week', (
        tester,
      ) async {
        await thursdayRun().pumpDiary(tester);
        await enterMode(tester, mode);

        await toggleDetails(tester);

        expect(ledgerText(tester), isNot(contains('Übertrag aus der Woche')));
        final card = budgetCardText(tester);
        expect(card, isNot(contains('aus der Woche')));
        expect(card, isNot(contains('Woche')));
      });
    }
  });

  group('K8', () {
    for (final mode in _fixedModes) {
      testWidgets('K8: in "${mode.label}" Thursday\'s macro targets are those '
          'of a run without anything over or under', (tester) async {
        Future<List<String>> thursdayMacros(double wednesday) async {
          await thursdayRun(wednesday: wednesday).pumpDiary(tester);
          await enterMode(tester, mode);
          return [
            for (final kind in DiaryBudgetMacroKind.values)
              textUnder(
                tester,
                find.byKey(DiaryBudgetCardKeys.macroValue(kind)),
              ),
          ];
        }

        final even = await thursdayMacros(2200);
        await tester.pumpWidget(const SizedBox.shrink());
        final afterOver = await thursdayMacros(3000);

        expect(even.every((text) => text.isNotEmpty), isTrue);
        expect(afterOver, even);
      });
    }
  });

  group('K9', () {
    for (final mode in _fixedModes) {
      testWidgets('K9: in "${mode.label}" tomorrow\'s budget card has no '
          '"<Wochentag> abschließen" and no "<Wochentag> abgeschlossen"', (
        tester,
      ) async {
        await thursdayRun().pumpDiary(tester);
        await enterMode(tester, mode);

        await nextDay(tester);
        await ensureDetails(tester);

        final card = find.byKey(DiaryBudgetCardKeys.card);
        expect(closeDayButton, findsNothing);
        expect(reopenDayButton, findsNothing);
        expect(
          find.descendant(
            of: card,
            matching: find.textContaining('abschließen'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: card,
            matching: find.textContaining('abgeschlossen'),
          ),
          findsNothing,
        );
      });
    }
  });

  group('K34', () {
    for (final mode in WeekBalanceMode.values) {
      final shown = mode == WeekBalanceMode.carryover;
      testWidgets('K34: in "${mode.label}" the sheet "Alle Tage" '
          '${shown ? 'has' : 'has no'} section "Übertrag aus den Vortagen"', (
        tester,
      ) async {
        await thursdayRun().pumpDiary(tester);
        await enterMode(tester, mode);
        await toggleDetails(tester);

        await tester.tap(find.byKey(DiaryBudgetCardKeys.allDaysLink));
        await settle(tester);

        expect(
          find.text('Übertrag aus den Vortagen'),
          shown ? findsOneWidget : findsNothing,
        );
      });
    }
  });
}
