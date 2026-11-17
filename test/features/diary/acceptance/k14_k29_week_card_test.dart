// K14, K37, K15, K28, K29 of lib/features/diary/CRITERIA.md (#911): the
// week card, its place, its fields and their names.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_steps_card/diary_steps_card.dart';

import 'acceptance_harness.dart';

/// Monday 2.200, Tuesday 1.900, Wednesday 3.000; today is Thursday.
DiaryAcceptanceHarness thursdayRun({DateTime? goalStart}) =>
    DiaryAcceptanceHarness(
      now: morningOf(runDay(3)),
      goalStart: goalStart,
      eaten: {runDay(0): 2200, runDay(1): 1900, runDay(2): 3000},
    );

List<String> _dayNames(WidgetTester tester) => [
  for (var index = 0; index < 7; index += 1) dayNameText(tester, index),
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

Rect _rectOf(WidgetTester tester, Finder finder) => tester.getRect(finder);

void main() {
  group('K14', () {
    for (final mode in [WeekBalanceMode.show, WeekBalanceMode.carryover]) {
      testWidgets('K14: in "${mode.label}" a card of seven fields stands '
          'between the budget card and the steps card, without title or '
          'total', (tester) async {
        await thursdayRun().pumpDiary(tester);
        if (mode != WeekBalanceMode.show) {
          await chooseModeInDiary(tester, mode);
        }

        final card = find.byKey(WeekCardKeys.card);
        expect(card, findsOneWidget);
        final budget = _rectOf(tester, find.byKey(DiaryBudgetCardKeys.card));
        final week = _rectOf(tester, card);
        final steps = _rectOf(tester, find.byType(DiaryStepsCard));
        expect(week.top, greaterThanOrEqualTo(budget.bottom));
        expect(steps.top, greaterThanOrEqualTo(week.bottom));

        for (var index = 0; index < 7; index += 1) {
          expect(find.byKey(WeekCardKeys.day(index)), findsOneWidget);
        }
        expect(find.byKey(WeekCardKeys.day(7)), findsNothing);
        final lefts = [
          for (var index = 0; index < 7; index += 1)
            _rectOf(tester, find.byKey(WeekCardKeys.day(index))).left,
        ];
        expect(lefts, orderedEquals([...lefts]..sort()), reason: 'in order');

        final names = _dayNames(tester).toSet();
        final texts = textUnder(
          tester,
          card,
        ).split(' ').where((word) => word.isNotEmpty);
        expect(
          texts.where((word) => !names.contains(word)),
          isEmpty,
          reason: 'no title and no week total, only the day names',
        );
      });
    }
  });

  group('K37', () {
    testWidgets('K37: without a goal there is no week card; the steps card '
        'follows the budget card', (tester) async {
      await DiaryAcceptanceHarness(
        now: morningOf(runDay(3)),
        hasGoal: false,
      ).pumpDiary(tester);

      expect(find.byKey(DiaryBudgetCardKeys.card), findsOneWidget);
      expect(find.byKey(WeekCardKeys.card), findsNothing);
      expect(find.byType(DiaryStepsCard), findsOneWidget);
    });

    testWidgets('K37: on a day after the run has ended there is no week '
        'card', (tester) async {
      await DiaryAcceptanceHarness(
        now: morningOf(runDay(8)),
        eaten: {runDay(0): 2200},
        runState: const BurnWeekRunState(
          currentWeekStartDayKey: '2026-11-30',
          runWeekNumber: 2,
          starCount: 0,
          starBrokeThisWeek: false,
          missedTrackingThisWeek: false,
        ),
      ).pumpDiary(tester);

      expect(find.byKey(WeekCardKeys.card), findsNothing);
      expect(find.byType(DiaryStepsCard), findsOneWidget);
    });
  });

  group('K15', () {
    testWidgets('K15: on the 4th day of a run from Monday the fields are '
        'named "Mo", "Di", "Mi", "Heute", "Fr", "Sa", "So"; "Heute" is bold '
        'and framed', (tester) async {
      await thursdayRun().pumpDiary(tester);

      expect(_dayNames(tester), ['Mo', 'Di', 'Mi', 'Heute', 'Fr', 'Sa', 'So']);
      expect(_framedDay(tester), 3);
      final today = textWeightOf(tester, find.byKey(WeekCardKeys.dayName(3)));
      expect(today.value, greaterThanOrEqualTo(FontWeight.w600.value));
      for (final index in [0, 1, 2, 4, 5, 6]) {
        expect(
          textWeightOf(tester, find.byKey(WeekCardKeys.dayName(index))).value,
          lessThan(today.value),
          reason: 'only "Heute" is bold',
        );
      }
    });

    testWidgets('K15: a run that starts on a Wednesday names its fields '
        'from Wednesday on', (tester) async {
      await DiaryAcceptanceHarness(
        now: morningOf(runDay(3)),
        goalStart: runDay(2),
        eaten: {runDay(2): 2200},
      ).pumpDiary(tester);

      expect(_dayNames(tester), ['Mi', 'Heute', 'Fr', 'Sa', 'So', 'Mo', 'Di']);
      expect(_framedDay(tester), 1);
    });
  });

  group('K28', () {
    testWidgets('K28: paged to Tuesday, the strip shows the same run with '
        'the frame on Tuesday; "Heute" stays at the real today', (
      tester,
    ) async {
      await thursdayRun().pumpDiary(tester);

      await previousDay(tester, times: 2);

      expect(_framedDay(tester), 1);
      expect(_dayNames(tester), ['Mo', 'Di', 'Mi', 'Heute', 'Fr', 'Sa', 'So']);
    });

    testWidgets('K28: paged to a day of the previous run, the strip shows '
        'that run with the frame on the shown day and no "Heute"', (
      tester,
    ) async {
      // Runs from Monday 9 and Monday 16 November; today is Thursday 19.
      await thursdayRun(goalStart: runDay(-7)).pumpDiary(tester);

      // Friday 13 November, the 5th day of the previous run.
      await previousDay(tester, times: 6);

      expect(_framedDay(tester), 4);
      expect(_dayNames(tester), ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']);
    });
  });

  group('K29', () {
    testWidgets('K29: a plain tap on the week card does nothing', (
      tester,
    ) async {
      await thursdayRun().pumpDiary(tester);
      final card = find.byKey(WeekCardKeys.card);
      expect(card, findsOneWidget);
      final before = allTexts(tester);

      await tester.tap(card);
      await settle(tester);

      expect(find.byKey(WeekCardKeys.menu), findsNothing);
      expect(allTexts(tester), before);
    });
  });
}
