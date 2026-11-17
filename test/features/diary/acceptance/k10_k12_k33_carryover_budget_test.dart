// K10, K12, K33 of lib/features/diary/CRITERIA.md (#911): the budget card
// with the carryover ("Mit Übertrag").
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/holo_foil_card.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section.dart';

import 'acceptance_harness.dart';

/// Monday 2.200, Tuesday 1.900, Wednesday 3.000 and [today] eaten on
/// Thursday; today is Thursday.
DiaryAcceptanceHarness thursdayRun({double today = 0}) =>
    DiaryAcceptanceHarness(
      now: morningOf(runDay(3)),
      eaten: {
        runDay(0): 2200,
        runDay(1): 1900,
        runDay(2): 3000,
        if (today > 0) runDay(3): today,
      },
    );

Finder _inCard(Finder finder) =>
    find.descendant(of: find.byKey(DiaryBudgetCardKeys.card), matching: finder);

List<String> _macroTargets(WidgetTester tester) => [
  for (final kind in DiaryBudgetMacroKind.values)
    textUnder(tester, find.byKey(DiaryBudgetCardKeys.macroValue(kind))),
];

/// Whether the gold foil around or inside the budget card is on.
bool _foil(WidgetTester tester) {
  final card = find.byKey(DiaryBudgetCardKeys.card);
  final foil = [
    ...find.ancestor(of: card, matching: find.byType(HoloFoilCard)).evaluate(),
    ...find
        .descendant(of: card, matching: find.byType(HoloFoilCard))
        .evaluate(),
  ];
  expect(foil, isNotEmpty, reason: 'the budget card has its foil');
  return (foil.first.widget as HoloFoilCard).enabled;
}

void main() {
  group('K10', () {
    testWidgets('K10: Thursday shows "2.075" "kcal übrig"; the details show '
        'the chip "2.200 − 125 aus der Woche" and the row "−125"', (
      tester,
    ) async {
      await thursdayRun().pumpDiary(tester);
      await chooseModeInDiary(tester, WeekBalanceMode.carryover);

      expect(budgetKcalText(tester), '2.075');
      expect(budgetUnitText(tester), 'kcal übrig');

      await toggleDetails(tester);

      expect(_inCard(find.text('2.200 − 125 aus der Woche')), findsOneWidget);
      expect(ledgerText(tester), contains('Übertrag aus der Woche −125'));

      await toggleDetails(tester);

      expect(_inCard(find.textContaining('aus der Woche')), findsNothing);
    });

    testWidgets('K10: Sunday after six days of 1.900 shows the chip '
        '"2.200 + 350 aus der Woche" and the row "+350"', (tester) async {
      await DiaryAcceptanceHarness(
        now: morningOf(runDay(6)),
        eaten: {for (var i = 0; i < 6; i += 1) runDay(i): 1900},
      ).pumpDiary(tester);
      await chooseModeInDiary(tester, WeekBalanceMode.carryover);

      await toggleDetails(tester);

      expect(_inCard(find.text('2.200 + 350 aus der Woche')), findsOneWidget);
      expect(ledgerText(tester), contains('Übertrag aus der Woche +350'));
    });

    testWidgets('K10: a day with carryover 0 has neither chip nor row', (
      tester,
    ) async {
      await DiaryAcceptanceHarness(
        now: morningOf(runDay(3)),
        eaten: {for (var i = 0; i < 3; i += 1) runDay(i): 2200},
      ).pumpDiary(tester);
      await chooseModeInDiary(tester, WeekBalanceMode.carryover);

      await toggleDetails(tester);

      expect(budgetKcalText(tester), '2.200');
      expect(_inCard(find.textContaining('aus der Woche')), findsNothing);
      expect(ledgerText(tester), isNot(contains('Übertrag aus der Woche')));
    });
  });

  group('K12', () {
    // Whether "those of a 2.075 kcal day" also moves protein is a question
    // for the criteria (see the report); this test checks only that the
    // targets are not those of the plain 2.200 kcal day.
    testWidgets('K12: with a budget of 2.075 the macro targets are not those '
        'of a 2.200 kcal day', (tester) async {
      await DiaryAcceptanceHarness(
        now: morningOf(runDay(3)),
        eaten: {for (var i = 0; i < 3; i += 1) runDay(i): 2200},
      ).pumpDiary(tester);
      final day2200 = _macroTargets(tester);
      await tester.pumpWidget(const SizedBox.shrink());

      await thursdayRun().pumpDiary(tester);
      await chooseModeInDiary(tester, WeekBalanceMode.carryover);

      expect(budgetKcalText(tester), '2.075');
      expect(_macroTargets(tester), isNot(day2200));
    });
  });

  group('K33', () {
    testWidgets('K33: "Mit Übertrag", budget 2.075, 2.000 eaten: "75" '
        '"kcal übrig", gold foil, meal targets from 2.075', (tester) async {
      // The meal targets of a plain 2.075 kcal day with the same food.
      await DiaryAcceptanceHarness(
        now: morningOf(runDay(3)),
        goalKcal: 2075,
        eaten: {
          for (var i = 0; i < 3; i += 1) runDay(i): 2075,
          runDay(3): 2000,
        },
      ).pumpDiary(tester);
      final mealsOf2075 = textUnder(tester, find.byType(DiaryMealsSection));
      await tester.pumpWidget(const SizedBox.shrink());

      await thursdayRun(today: 2000).pumpDiary(tester);
      await chooseModeInDiary(tester, WeekBalanceMode.carryover);

      expect(budgetKcalText(tester), '75');
      expect(budgetUnitText(tester), 'kcal übrig');
      expect(_foil(tester), isTrue, reason: '2.000 is within 5 % of 2.075');
      expect(
        textUnder(tester, find.byType(DiaryMealsSection)),
        mealsOf2075,
        reason: 'the meal targets are worked out from 2.075',
      );
    });

    testWidgets('K33: "Anzeigen", budget 2.200, 2.000 eaten: "200" '
        '"kcal übrig" and no gold foil', (tester) async {
      await thursdayRun(today: 2000).pumpDiary(tester);

      expect(budgetKcalText(tester), '200');
      expect(budgetUnitText(tester), 'kcal übrig');
      expect(
        _foil(tester),
        isFalse,
        reason: '2.000 is more than 5 % under 2.200',
      );
    });
  });
}
