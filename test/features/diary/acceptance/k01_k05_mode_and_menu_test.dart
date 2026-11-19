// K1, K2, K35, K3, K4, K5, K31, K30, K13 of lib/features/diary/CRITERIA.md
// (#911): the mode, the week card's menu and the settings.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/application/tdee_analytics_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';

import 'acceptance_harness.dart';

/// Monday 2.200, Tuesday 1.900, Wednesday 3.000; today is Thursday.
DiaryAcceptanceHarness thursdayRun() => DiaryAcceptanceHarness(
  now: morningOf(runDay(3)),
  eaten: {runDay(0): 2200, runDay(1): 1900, runDay(2): 3000},
);

Finder _selectedMark(WeekBalanceMode mode) => find.descendant(
  of: find.byKey(WeekCardKeys.modeOption(mode)),
  matching: find.byKey(WeekCardKeys.modeSelected),
);

void _expectSelected(WeekBalanceMode mode) {
  for (final other in WeekBalanceMode.values) {
    expect(
      _selectedMark(other),
      other == mode ? findsOneWidget : findsNothing,
      reason: '"${mode.label}" is the selected mode',
    );
  }
}

void main() {
  group('K1', () {
    testWidgets('K1: holding the week card in "Anzeigen" opens the menu '
        '"Wochenzielbalance" with the mode choice', (tester) async {
      await thursdayRun().pumpDiary(tester);

      await openWeekCardMenu(tester);

      final menu = find.byKey(WeekCardKeys.menu);
      expect(menu, findsOneWidget);
      expect(
        find.descendant(of: menu, matching: find.text('Wochenzielbalance')),
        findsOneWidget,
      );
      for (final mode in WeekBalanceMode.values) {
        expect(find.byKey(WeekCardKeys.modeOption(mode)), findsOneWidget);
      }
    });

    testWidgets('K1: holding the week card in "Mit Übertrag" opens the same '
        'menu', (tester) async {
      await thursdayRun().pumpDiary(tester);
      await chooseModeInDiary(tester, WeekBalanceMode.carryover);

      await openWeekCardMenu(tester);

      expect(
        find.descendant(
          of: find.byKey(WeekCardKeys.menu),
          matching: find.text('Wochenzielbalance'),
        ),
        findsOneWidget,
      );
    });
  });

  group('K2', () {
    testWidgets('K2: the menu offers exactly "Aus", "Anzeigen" and '
        '"Mit Übertrag" with their lines, one selected', (tester) async {
      await thursdayRun().pumpDiary(tester);
      await openWeekCardMenu(tester);

      const lines = {
        WeekBalanceMode.off: 'Jeder Tag steht für sich.',
        WeekBalanceMode.show:
            'Zeigt die Woche. Dein Tagesbudget bleibt gleich.',
        WeekBalanceMode.carryover:
            'Gleicht die Woche aus, höchstens 350 kcal pro Tag.',
      };
      for (final MapEntry(key: mode, value: line) in lines.entries) {
        final option = find.byKey(WeekCardKeys.modeOption(mode));
        expect(option, findsOneWidget);
        final text = textUnder(tester, option);
        expect(text, contains(mode.label));
        expect(text, contains(line));
      }
      expect(
        find.byKey(WeekCardKeys.modeSelected),
        findsOneWidget,
        reason: 'exactly one option is selected',
      );
      final menu = find.byKey(WeekCardKeys.menu);
      expect(
        find.descendant(
          of: menu,
          matching: find.text('Später ändern: in den Einstellungen.'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: menu, matching: find.byType(Switch)),
        findsNothing,
        reason: 'no separate switch for "Übertrag" or "anzeigen"',
      );
    });
  });

  group('K35', () {
    // Goal of a normal day, goal of today when today is a training day, and
    // the line under "Mit Übertrag".
    const rows = <(double, double?, String)>[
      (2200, null, 'Gleicht die Woche aus, höchstens 350 kcal pro Tag.'),
      (1750, null, 'Gleicht die Woche aus, höchstens 350 kcal pro Tag.'),
      (1600, null, 'Gleicht die Woche aus, höchstens 320 kcal pro Tag.'),
      (1500, null, 'Gleicht die Woche aus, höchstens 300 kcal pro Tag.'),
      (1200, null, 'Gleicht die Woche aus, höchstens 240 kcal pro Tag.'),
      (1500, 1750, 'Gleicht die Woche aus, höchstens 300 kcal pro Tag.'),
    ];
    for (final (goal, trainingGoal, line) in rows) {
      final name = trainingGoal == null
          ? 'goal ${de(goal)}'
          : '${de(goal)} on normal days, ${de(trainingGoal)} on training days '
                '(today a training day)';
      testWidgets('K35: $name → "$line"', (tester) async {
        final harness = DiaryAcceptanceHarness(
          now: morningOf(runDay(3)),
          goalKcal: goal,
          trainingDays: trainingGoal == null ? const {} : {runDay(3)},
          trainingSessionKcal: trainingGoal == null ? 250 : trainingGoal - goal,
        );
        await harness.pumpDiary(tester);
        await openWeekCardMenu(tester);

        expect(
          textUnder(
            tester,
            find.byKey(WeekCardKeys.modeOption(WeekBalanceMode.carryover)),
          ),
          contains(line),
        );
      });
    }
  });

  group('K3', () {
    testWidgets('K3: picking "Aus" closes the menu and removes the week '
        'card; the budget card counts against the plain goal', (tester) async {
      await thursdayRun().pumpDiary(tester);
      await openWeekCardMenu(tester);

      await pickMode(tester, WeekBalanceMode.off);

      expect(find.byKey(WeekCardKeys.menu), findsNothing);
      expect(find.byKey(WeekCardKeys.card), findsNothing);
      expect(budgetKcalText(tester), '2.200');
      expect(budgetUnitText(tester), 'kcal übrig');
    });
  });

  group('K4', () {
    testWidgets('K4: with "Aus", the settings show one row '
        '"Wochenzielbalance" with the subtitle "Aus"; a tap opens the menu of '
        'the card; "Mit Übertrag" closes it and brings the card back', (
      tester,
    ) async {
      final harness = thursdayRun();
      await harness.pumpDiary(tester);
      await chooseModeInDiary(tester, WeekBalanceMode.off);
      expect(find.byKey(WeekCardKeys.card), findsNothing);

      await harness.push(tester, const SettingsPage());
      final tile = find.byKey(WeekCardKeys.settingsTile);
      expect(tile, findsOneWidget);
      await tester.ensureVisible(tile);
      await settle(tester);
      final steps = tester.getRect(find.byKey(SettingsPageKeys.stepsTile));
      final row = tester.getRect(tile);
      final gap = row.top >= steps.bottom
          ? row.top - steps.bottom
          : steps.top - row.bottom;
      expect(
        gap,
        lessThan(16),
        reason: 'the row stands next to "Schritte im Tagebuch"',
      );
      expect(
        find.descendant(of: tile, matching: find.text('Wochenzielbalance')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tile, matching: find.text('Aus')),
        findsOneWidget,
        reason: 'the subtitle names the chosen mode',
      );
      for (final mode in WeekBalanceMode.values) {
        expect(
          find.byKey(WeekCardKeys.modeOption(mode)),
          findsNothing,
          reason: 'the options are not shown expanded in the settings',
        );
      }

      await tester.tap(tile);
      await settle(tester);

      final menu = find.byKey(WeekCardKeys.menu);
      expect(menu, findsOneWidget, reason: "the same menu as the card's");
      expect(
        find.descendant(of: menu, matching: find.text('Wochenzielbalance')),
        findsOneWidget,
      );
      const lines = {
        WeekBalanceMode.off: 'Jeder Tag steht für sich.',
        WeekBalanceMode.show:
            'Zeigt die Woche. Dein Tagesbudget bleibt gleich.',
        WeekBalanceMode.carryover:
            'Gleicht die Woche aus, höchstens 350 kcal pro Tag.',
      };
      for (final MapEntry(key: mode, value: line) in lines.entries) {
        final option = find.descendant(
          of: menu,
          matching: find.byKey(WeekCardKeys.modeOption(mode)),
        );
        expect(option, findsOneWidget);
        final text = textUnder(tester, option);
        expect(text, contains(mode.label));
        expect(text, contains(line));
      }
      _expectSelected(WeekBalanceMode.off);
      expect(
        find.text('Später ändern: in den Einstellungen.'),
        findsNothing,
        reason:
            'opened from the settings, the menu has no hint to change it '
            'later',
      );

      await pickMode(tester, WeekBalanceMode.carryover);

      expect(find.byKey(WeekCardKeys.menu), findsNothing);
      expect(
        find.descendant(of: tile, matching: find.text('Mit Übertrag')),
        findsOneWidget,
        reason: 'the subtitle shows the new mode',
      );
      expect(
        find.descendant(of: tile, matching: find.text('Aus')),
        findsNothing,
      );

      while (find.byType(SettingsPage).evaluate().isNotEmpty) {
        await harness.pop(tester);
      }
      expect(find.byKey(WeekCardKeys.card), findsOneWidget);
      await openWeekCardMenu(tester);
      _expectSelected(WeekBalanceMode.carryover);
    });
  });

  group('K5', () {
    testWidgets('K5: "Mit Übertrag" is still picked on another phone with '
        'the same account', (tester) async {
      final firstPhone = thursdayRun();
      await firstPhone.pumpDiary(tester);
      await chooseModeInDiary(tester, WeekBalanceMode.carryover);

      final secondPhone = DiaryAcceptanceHarness.secondPhone(firstPhone);
      await tester.pumpWidget(const SizedBox.shrink());
      await secondPhone.pumpDiary(tester);

      expect(budgetKcalText(tester), '2.075');
      await openWeekCardMenu(tester);
      _expectSelected(WeekBalanceMode.carryover);
    });
  });

  group('K31', () {
    testWidgets('K31: an account that never picked a mode is on "Anzeigen": '
        'week card shown, budget against the plain goal', (tester) async {
      await thursdayRun().pumpDiary(tester);

      expect(find.byKey(WeekCardKeys.card), findsOneWidget);
      expect(budgetKcalText(tester), '2.200');
      expect(budgetUnitText(tester), 'kcal übrig');
      await openWeekCardMenu(tester);
      _expectSelected(WeekBalanceMode.show);
    });
  });

  group('K30', () {
    testWidgets('K30: switching the mode recomputes the whole running run', (
      tester,
    ) async {
      await thursdayRun().pumpDiary(tester);
      await chooseModeInDiary(tester, WeekBalanceMode.carryover);
      await toggleDetails(tester);
      expect(budgetKcalText(tester), '2.075');
      expect(dayNumberText(tester, 2), '+740');

      await chooseModeInDiary(tester, WeekBalanceMode.show);

      expect(budgetKcalText(tester), '2.200');
      expect(dayNumberText(tester, 2), '+800');

      await chooseModeInDiary(tester, WeekBalanceMode.carryover);

      expect(budgetKcalText(tester), '2.075');
      expect(dayNumberText(tester, 2), '+740');
    });
  });

  group('K13', () {
    testWidgets('K13: switching between the modes never changes the learned '
        'TDEE', (tester) async {
      final harness = thursdayRun();
      await harness.pumpDiary(tester);
      Future<List<Object?>> learnedTdee() async {
        final state = await tester.runAsync(
          () => harness.container.read(
            tdeeAnalyticsProvider(const TdeeAnalyticsQuery(cycleIds: {'all'}))
                .future,
          ),
        );
        return [
          for (final point in state!.points)
            (point.day, point.learnedBaseTdeeKcal, point.totalTdeeKcal),
        ];
      }

      final before = await learnedTdee();
      expect(before, isNotEmpty);
      for (final mode in [
        WeekBalanceMode.carryover,
        WeekBalanceMode.show,
        WeekBalanceMode.carryover,
        WeekBalanceMode.off,
      ]) {
        await chooseModeInDiary(tester, mode);
        expect(await learnedTdee(), before, reason: 'after "${mode.label}"');
      }
      expect(find.byKey(DiaryBudgetCardKeys.card), findsOneWidget);
    });
  });
}
