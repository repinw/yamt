// K22 and K23 of lib/features/diary/CRITERIA.md (#911): the colours follow
// the weight goal, on the budget card and in the week card. "Red" is the
// app's error colour (see acceptance_contract.dart).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_kcal_column.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_line.dart';

import 'acceptance_harness.dart';

/// Monday 2.200, Tuesday 1.900, Wednesday 3.000, today (Thursday) [today].
DiaryAcceptanceHarness _run(CalorieGoalMode goal, {required double today}) =>
    DiaryAcceptanceHarness(
      now: morningOf(runDay(3)),
      goalMode: goal,
      eaten: {
        runDay(0): 2200,
        runDay(1): 1900,
        runDay(2): 3000,
        runDay(3): today,
      },
    );

/// The kcal line of the budget card (not the macro lines).
final Finder _kcalLine = find.descendant(
  of: find.byType(DiaryBudgetKcalColumn),
  matching: find.byType(DiaryBudgetLine),
);

/// The colours of the words "kcal drüber" and of the number above them.
List<Color?> _overLabelColors(WidgetTester tester) => [
  textColorOf(tester, find.byKey(DiaryBudgetCardKeys.kcalUnit)),
  textColorOf(tester, find.byKey(DiaryBudgetCardKeys.kcalValue)),
];

Color? _numberColor(WidgetTester tester, int day) =>
    textColorOf(tester, find.byKey(WeekCardKeys.dayNumber(day)));

void main() {
  for (final (goal, name) in [
    (CalorieGoalMode.lose, 'Abnehmen'),
    (CalorieGoalMode.maintain, 'Halten'),
  ]) {
    group('K22', () {
      testWidgets('K22: weight goal "$name": over is red on the budget card '
          'and in the week card, under is not', (tester) async {
        // Thursday 2.500 of 2.200: over.
        await _run(goal, today: 2500).pumpDiary(tester);
        await toggleDetails(tester);
        final red = redOf(tester);

        // "kcal drüber": the words, the number above them, or both are red.
        expect(budgetUnitText(tester), 'kcal drüber');
        expect(_overLabelColors(tester), contains(red));
        expect(
          fillColorsUnder(tester, _kcalLine),
          contains(red),
          reason: 'the part of the line over the budget is red',
        );

        expect(dayNumberText(tester, 2), '+800');
        expect(_numberColor(tester, 2), red);
        expect(dayNumberText(tester, 1), '−300');
        expect(_numberColor(tester, 1), isNot(red), reason: '"−300" is grey');
        expect(
          fillColorsUnder(tester, find.byKey(WeekCardKeys.day(1))),
          isNot(contains(red)),
          reason: 'the field of a day under its budget is not red',
        );
      });
    });
  }

  group('K23', () {
    testWidgets('K23: weight goal "Zunehmen": over is not red, short is red; '
        'words and signs stay', (tester) async {
      await _run(CalorieGoalMode.gain, today: 2500).pumpDiary(tester);
      await toggleDetails(tester);
      final red = redOf(tester);

      expect(
        budgetUnitText(tester),
        'kcal drüber',
        reason: 'same words as for "Abnehmen"',
      );
      expect(_overLabelColors(tester), isNot(contains(red)));
      expect(
        fillColorsUnder(tester, _kcalLine),
        isNot(contains(red)),
        reason: 'the part of the line over the budget is not red',
      );

      expect(dayNumberText(tester, 2), '+800');
      expect(_numberColor(tester, 2), isNot(red));
      expect(dayNumberText(tester, 1), '−300');
      expect(_numberColor(tester, 1), red);
      expect(
        fillColorsUnder(tester, find.byKey(WeekCardKeys.day(1))),
        contains(red),
        reason: 'the field of the day that fell short is red',
      );
    });

    testWidgets('K23: weight goal "Zunehmen": today never turns red for '
        'being under', (tester) async {
      await _run(CalorieGoalMode.gain, today: 500).pumpDiary(tester);
      await toggleDetails(tester);
      final red = redOf(tester);

      expect(find.byKey(WeekCardKeys.day(3)), findsOneWidget);
      expect(
        fillColorsUnder(tester, find.byKey(WeekCardKeys.day(3))),
        isNot(contains(red)),
      );
      expect(budgetUnitText(tester), 'kcal übrig');
      expect(
        textColorOf(tester, find.byKey(DiaryBudgetCardKeys.kcalValue)),
        isNot(red),
      );
    });
  });
}
