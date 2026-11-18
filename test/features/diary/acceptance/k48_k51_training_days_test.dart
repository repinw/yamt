// The training example of K48 and K51 of lib/features/diary/CRITERIA.md
// (#911): a run cut short by a new goal with other training days keeps the
// day goals of its own training days, and the strip "Tagesarten im Run" in
// the budget card's details shows only that run's days.
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';

import 'acceptance_harness.dart';

/// Thursday, the day the new goal is set and starts.
final DateTime _thursday = runDay(3);

/// The setup of K48's training example: the old goal from Monday averages
/// 2.200 with 350 kcal per session and trains on Monday and Wednesday; on
/// Thursday a new goal from Thursday with the same average and session
/// trains on Thursday, Friday and Saturday. Mode "Anzeigen".
DiaryAcceptanceHarness _account({bool withNewGoal = true}) =>
    DiaryAcceptanceHarness(
      now: morningOf(_thursday),
      trainingSessionKcal: 350,
      trainingWeekdays: const [DateTime.monday, DateTime.wednesday],
      goalChange: withNewGoal ? _newGoal : null,
    );

final GoalChange _newGoal = GoalChange(
  setOn: _thursday,
  countsFrom: _thursday,
  kcal: 2200,
  trainingWeekdays: const [
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
  ],
);

/// The goals of Monday, Tuesday and Wednesday in K48's example.
const _oldRunGoals = {
  'Monday': '2.450',
  'Tuesday': '2.100',
  'Wednesday': '2.450',
};

/// Pages from Thursday back to Monday and reads the budget card of Monday,
/// Tuesday and Wednesday.
Future<Map<String, String>> _oldRunBudgets(WidgetTester tester) async {
  await previousDay(tester, times: 3);
  final budgets = <String, String>{};
  for (final day in _oldRunGoals.keys) {
    if (day != 'Monday') await nextDay(tester);
    budgets[day] = budgetKcalText(tester);
  }
  return budgets;
}

/// The keyed fields of the strip "Tagesarten im Run", from index 0 on.
int _dayTypeFieldCount(WidgetTester tester) {
  var count = 0;
  while (find.byKey(DiaryBudgetCardKeys.weekDay(count)).evaluate().isNotEmpty) {
    count += 1;
  }
  return count;
}

void main() {
  group('K48', () {
    testWidgets('K48: before the new goal, Monday to Wednesday have the goals '
        '2.450, 2.100 and 2.450', (tester) async {
      await _account(withNewGoal: false).pumpDiary(tester);

      expect(await _oldRunBudgets(tester), _oldRunGoals);
    });

    testWidgets('K48: a new goal with other training days leaves Monday to '
        'Wednesday at 2.450, 2.100 and 2.450 (not 2.300, 1.950, 2.300)', (
      tester,
    ) async {
      await _account().pumpDiary(tester);

      expect(await _oldRunBudgets(tester), _oldRunGoals);
    });

    testWidgets('K48: the goals stay when the new goal is set while the '
        'diary is open', (tester) async {
      final harness = _account(withNewGoal: false);
      await harness.pumpDiary(tester);

      await harness.setGoalChange(tester, _newGoal);

      expect(await _oldRunBudgets(tester), _oldRunGoals);
    });
  });

  group('K51', () {
    testWidgets('K51: on Tuesday, "Tagesarten im Run" shows only Monday, '
        'Tuesday and Wednesday', (tester) async {
      await _account().pumpDiary(tester);
      await previousDay(tester, times: 2);
      await toggleDetails(tester);

      final strip = find.byKey(DiaryBudgetCardKeys.weekStrip);
      expect(strip, findsOneWidget);
      expect(textUnder(tester, strip), contains('Tagesarten im Run'));
      expect(
        _dayTypeFieldCount(tester),
        3,
        reason: 'only the days of the cut run, Monday to Wednesday',
      );
      expect(find.byKey(DiaryBudgetCardKeys.weekDay(3)), findsNothing);
      expect(
        find.descendant(of: strip, matching: find.text('Do')),
        findsNothing,
        reason: 'no day from Thursday on is in the strip',
      );
    });

    testWidgets('K51: its count of training days is 2, not 5', (tester) async {
      await _account().pumpDiary(tester);
      await previousDay(tester, times: 2);
      await toggleDetails(tester);

      final text = textUnder(tester, find.byKey(DiaryBudgetCardKeys.weekStrip));
      // The count is the one number in the strip: its other texts are the
      // title and the weekday names.
      final numbers = [
        for (final match in RegExp(r'\d+').allMatches(text))
          int.parse(match.group(0)!),
      ];
      expect(numbers, [2], reason: 'the strip text was "$text"');
    });
  });
}
