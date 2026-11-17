// K16, K17, K18, K25, K21 of lib/features/diary/CRITERIA.md (#911): what
// the field of a day in the week card shows. Proportions and how they read
// are "Phone only"; these tests check which parts a field has.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'acceptance_harness.dart';

void _expectPart(int day, Key part, Matcher matcher, String reason) =>
    expect(partOfDay(day, part), matcher, reason: reason);

void main() {
  group('K16', () {
    testWidgets("K16: a finished day's field is its kcal bar: over the "
        'budget only the part above it is red, under it an empty tip stays', (
      tester,
    ) async {
      // Monday 6.750, Tuesday 1.900; today Wednesday; Thursday is a training
      // day with a higher goal.
      await DiaryAcceptanceHarness(
        now: morningOf(runDay(2)),
        eaten: {runDay(0): 6750, runDay(1): 1900},
        trainingDays: {runDay(3)},
      ).pumpDiary(tester);
      final red = redOf(tester);

      // Over: the whole day shows, the eaten part up to the budget is not
      // red, the part above it is red, and it stays inside its own field.
      _expectPart(0, WeekCardKeys.eatenPart, findsOneWidget, 'Mo eaten part');
      _expectPart(0, WeekCardKeys.overPart, findsOneWidget, 'Mo over part');
      expect(
        fillColorOf(tester, partOfDay(0, WeekCardKeys.overPart)),
        red,
        reason: 'the part above the budget is red',
      );
      expect(
        fillColorOf(tester, partOfDay(0, WeekCardKeys.eatenPart)),
        isNot(red),
        reason: 'the part up to the budget is not red',
      );
      final monday = tester.getRect(find.byKey(WeekCardKeys.day(0)));
      for (final part in [WeekCardKeys.eatenPart, WeekCardKeys.overPart]) {
        final rect = tester.getRect(partOfDay(0, part));
        expect(rect.left, greaterThanOrEqualTo(monday.left - 0.5));
        expect(rect.right, lessThanOrEqualTo(monday.right + 0.5));
      }

      // Under: no red, and the fill ends before the end of the field.
      _expectPart(1, WeekCardKeys.overPart, findsNothing, 'Di is not over');
      final tuesday = tester.getRect(find.byKey(WeekCardKeys.day(1)));
      final tuesdayFill = tester.getRect(partOfDay(1, WeekCardKeys.eatenPart));
      expect(
        tuesdayFill.right,
        lessThan(tuesday.right),
        reason: 'an empty tip stays at the end',
      );

      // All seven fields are equally wide, the training day too.
      final widths = {
        for (var index = 0; index < 7; index += 1)
          tester.getSize(find.byKey(WeekCardKeys.day(index))).width,
      };
      expect(widths, hasLength(1));
    });
  });

  group('K17', () {
    testWidgets('K17: in "Anzeigen" the coming days are empty dashed '
        'outlines', (tester) async {
      await DiaryAcceptanceHarness(
        now: morningOf(runDay(3)),
        eaten: {runDay(0): 2200, runDay(1): 1900, runDay(2): 3000},
      ).pumpDiary(tester);

      for (final day in [4, 5, 6]) {
        _expectPart(day, WeekCardKeys.comingOutline, findsOneWidget, '$day');
        _expectPart(day, WeekCardKeys.eatenPart, findsNothing, '$day empty');
        _expectPart(day, WeekCardKeys.overPart, findsNothing, '$day empty');
      }
    });
  });

  group('K18', () {
    testWidgets('K18: a pause day is hatched, has no red part and is '
        'labelled "Pause"', (tester) async {
      await DiaryAcceptanceHarness(
        now: morningOf(runDay(3)),
        eaten: {runDay(0): 2200, runDay(1): 3000, runDay(2): 3000},
        pauseDays: {runDay(1)},
      ).pumpDiary(tester);

      _expectPart(1, WeekCardKeys.pauseHatch, findsOneWidget, 'hatched');
      _expectPart(1, WeekCardKeys.eatenPart, findsNothing, 'no kcal bar');
      _expectPart(1, WeekCardKeys.overPart, findsNothing, 'no red part');
      expect(
        fillColorsUnder(tester, find.byKey(WeekCardKeys.day(1))),
        isNot(contains(redOf(tester))),
      );

      await toggleDetails(tester);

      expect(dayNumberText(tester, 1), 'Pause');
    });

    testWidgets('K18: in "Mit Übertrag" the pause day adds nothing to the '
        'balance', (tester) async {
      // Monday 2.200, Tuesday pause with 3.000, Wednesday 3.000: balance
      // −800 over 4 days.
      await DiaryAcceptanceHarness(
        now: morningOf(runDay(3)),
        eaten: {runDay(0): 2200, runDay(1): 3000, runDay(2): 3000},
        pauseDays: {runDay(1)},
      ).pumpDiary(tester);
      await chooseModeInDiary(tester, WeekBalanceMode.carryover);

      expect(budgetKcalText(tester), '2.000');
    });
  });

  group('K25', () {
    testWidgets('K25: an empty day is an empty track labelled "leer"', (
      tester,
    ) async {
      await DiaryAcceptanceHarness(
        now: morningOf(runDay(3)),
        eaten: {runDay(0): 2200, runDay(2): 3000},
      ).pumpDiary(tester);

      _expectPart(1, WeekCardKeys.emptyTrack, findsOneWidget, 'empty track');
      _expectPart(1, WeekCardKeys.eatenPart, findsNothing, 'no fill');
      _expectPart(1, WeekCardKeys.overPart, findsNothing, 'no red part');

      await toggleDetails(tester);

      expect(dayNumberText(tester, 1), 'leer');
    });

    testWidgets('K25: in "Mit Übertrag" the empty day adds nothing to the '
        'balance', (tester) async {
      await DiaryAcceptanceHarness(
        now: morningOf(runDay(3)),
        eaten: {runDay(0): 2200, runDay(2): 3000},
      ).pumpDiary(tester);
      await chooseModeInDiary(tester, WeekBalanceMode.carryover);

      expect(budgetKcalText(tester), '2.000');
    });
  });

  group('K21', () {
    testWidgets('K21: in "Mit Übertrag" today and every coming day show a '
        'dark piece for less budget; a day with more budget a dashed extra '
        'piece', (tester) async {
      // Wednesday's budget is 2.260 (+60), Thursday's and the preview of
      // Friday to Sunday 2.075 (−125).
      await DiaryAcceptanceHarness(
        now: morningOf(runDay(3)),
        eaten: {runDay(0): 2200, runDay(1): 1900, runDay(2): 3000},
      ).pumpDiary(tester);
      await chooseModeInDiary(tester, WeekBalanceMode.carryover);

      _expectPart(2, WeekCardKeys.extraPiece, findsOneWidget, 'We +60');
      _expectPart(2, WeekCardKeys.debtPiece, findsNothing, 'We has more');
      for (final day in [3, 4, 5, 6]) {
        _expectPart(day, WeekCardKeys.debtPiece, findsOneWidget, '$day −125');
        _expectPart(day, WeekCardKeys.extraPiece, findsNothing, '$day less');
      }
      // Monday has no carryover, Tuesday neither (balance 0 after Monday).
      for (final day in [0, 1]) {
        _expectPart(day, WeekCardKeys.debtPiece, findsNothing, '$day none');
        _expectPart(day, WeekCardKeys.extraPiece, findsNothing, '$day none');
      }
    });

    testWidgets('K21: in "Anzeigen" no field has such a piece', (tester) async {
      await DiaryAcceptanceHarness(
        now: morningOf(runDay(3)),
        eaten: {runDay(0): 2200, runDay(1): 1900, runDay(2): 3000},
      ).pumpDiary(tester);

      expect(find.byKey(WeekCardKeys.card), findsOneWidget);
      expect(find.byKey(WeekCardKeys.debtPiece), findsNothing);
      expect(find.byKey(WeekCardKeys.extraPiece), findsNothing);
    });
  });
}
