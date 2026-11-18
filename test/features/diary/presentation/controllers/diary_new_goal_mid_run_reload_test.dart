// K47 and K48 of lib/features/diary/CRITERIA.md (#911): a new goal set while
// the diary is open starts a new run at once, on the shown day and on a day
// of the old run that was loaded before.
//
// `diaryDashboardGoalSignatures` compares only goal kcal, training and pause
// days, so a new goal with the same kcal changes no signature. These tests
// check that the diary still shows the new run then, and that a day of the
// old run loaded before the new goal does not keep its seven fields.
import 'package:flutter_test/flutter_test.dart';

import '../../acceptance/acceptance_harness.dart';

final DateTime _thursday = runDay(3);

/// K47's account without the new goal: today is Thursday; Mo 2.200,
/// Tu 1.900, We 3.000 eaten.
DiaryAcceptanceHarness _account() => DiaryAcceptanceHarness(
  now: morningOf(_thursday),
  eaten: {runDay(0): 2200, runDay(1): 1900, runDay(2): 3000},
);

int _fieldCount() {
  var count = 0;
  while (find.byKey(WeekCardKeys.day(count)).evaluate().isNotEmpty) {
    count += 1;
  }
  return count;
}

void main() {
  testWidgets('K47: a new goal with the same kcal from today starts the new '
      'run on the shown day at once', (tester) async {
    final harness = _account();
    await harness.pumpDiary(tester);
    await chooseModeInDiary(tester, WeekBalanceMode.carryover);
    expect(
      budgetKcalText(tester),
      '2.075',
      reason: 'before the new goal: 2.200 − 500 ÷ 4 from the old run',
    );
    expect(dayNameText(tester, 3), 'Heute');

    await harness.setNewGoal(tester, (from: _thursday, kcal: 2200));

    expect(
      dayNameText(tester, 0),
      'Heute',
      reason: 'the strip shows the new run from Thursday',
    );
    expect(
      budgetKcalText(tester),
      '2.200',
      reason: "the old run's balance never reaches the new run",
    );
  });

  for (final kcal in [2200.0, 2000.0]) {
    testWidgets('K47/K48: Tuesday, loaded before a new goal of ${de(kcal)} '
        'from Thursday, then shows only "Mo", "Di", "Mi" and keeps its '
        'budget', (tester) async {
      final harness = _account();
      await harness.pumpDiary(tester);
      await chooseModeInDiary(tester, WeekBalanceMode.carryover);
      await previousDay(tester, times: 2);
      expect(_fieldCount(), 7, reason: 'before the new goal: the full run');
      await nextDay(tester, times: 2);

      await harness.setNewGoal(tester, (from: _thursday, kcal: kcal));
      await previousDay(tester, times: 2);

      expect(_fieldCount(), 3, reason: 'the old run has only its own days');
      expect(
        [for (var index = 0; index < 3; index += 1) dayNameText(tester, index)],
        ['Mo', 'Di', 'Mi'],
      );
      expect(
        budgetKcalText(tester),
        '300',
        reason: 'Tuesday keeps its budget of 2.200 (K48): 1.900 eaten',
      );
      expect(budgetUnitText(tester), startsWith('kcal übrig'));
    });
  }
}
