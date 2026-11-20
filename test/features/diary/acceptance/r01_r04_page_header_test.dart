import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/home_shell_menu_button.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_navigator.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_today_button.dart';

import '../../home/acceptance/acceptance_harness.dart';

/// The two lines of the day label: the small line and the date line.
List<String> _dayLabelLines(WidgetTester tester) {
  return [
    for (final text in tester.widgetList<Text>(
      find.descendant(
        of: find.byKey(DiaryDayNavigatorKeys.label),
        matching: find.byType(Text),
      ),
    ))
      text.data ?? '',
  ];
}

void main() {
  group('R1: the date reads calmly, without capitals', () {
    // Today is Thursday, 19 November 2026.
    final rows = [
      (DateTime(2026, 11, 11), 'vor 8 Tagen', 'Mi, 11. Nov.'),
      (DateTime(2026, 11, 17), 'vor 2 Tagen', 'Di, 17. Nov.'),
      (DateTime(2026, 11, 18), 'Gestern', 'Mi, 18. Nov.'),
      (DateTime(2026, 11, 19), 'Heute', 'Do, 19. Nov.'),
      (DateTime(2026, 11, 20), 'Morgen', 'Fr, 20. Nov.'),
      (DateTime(2026, 11, 21), 'Übermorgen', 'Sa, 21. Nov.'),
      (DateTime(2026, 11, 22), 'in 3 Tagen', 'So, 22. Nov.'),
    ];
    for (final (day, small, date) in rows) {
      testWidgets('R1: ${day.day}. Nov. reads "$small" over "$date"', (
        tester,
      ) async {
        final shell = await pumpHomeShell(tester);
        shell.selectDiaryDay(day);
        await settle(tester);

        expect(_dayLabelLines(tester), [small, date]);
      });
    }
  });

  testWidgets('R2: the arrows go to the previous and the next day', (
    tester,
  ) async {
    await pumpHomeShell(tester);
    expect(_dayLabelLines(tester), ['Heute', 'Do, 19. Nov.']);

    await tapAndSettle(tester, find.byKey(DiaryDayNavigatorKeys.previous));
    expect(_dayLabelLines(tester), ['Gestern', 'Mi, 18. Nov.']);

    await tapAndSettle(tester, find.byKey(DiaryDayNavigatorKeys.next));
    await tapAndSettle(tester, find.byKey(DiaryDayNavigatorKeys.next));
    expect(_dayLabelLines(tester), ['Morgen', 'Fr, 20. Nov.']);
  });

  testWidgets('R3: "Menü" stands under the menu icon in the diary', (
    tester,
  ) async {
    await pumpHomeShell(tester);

    final menu = find.byKey(HomeShellMenuButton.buttonKey);
    final icon = find.descendant(of: menu, matching: find.byType(Icon));
    final word = find.descendant(of: menu, matching: find.text('Menü'));
    expect(icon, findsOneWidget);
    expect(word, findsOneWidget);
    expect(tester.getCenter(icon).dy, lessThan(tester.getCenter(word).dy));
    expect(
      find.descendant(of: menu, matching: find.text('MENÜ')),
      findsNothing,
    );
  });

  group('R4: on another day the Heute button replaces Einkauf', () {
    final todayButton = find.byKey(DiaryTodayButton.buttonKey);
    final einkauf = headerTool('Einkauf');
    final days = {
      'yesterday': DateTime(2026, 11, 18),
      'tomorrow': DateTime(2026, 11, 20),
      '8 days ago': DateTime(2026, 11, 11),
    };

    for (final hasOpenItems in [true, false]) {
      final list = hasOpenItems ? 'open items' : 'an empty list';

      testWidgets('R4: today with $list', (tester) async {
        await pumpHomeShell(
          tester,
          shopping: shoppingItems(open: hasOpenItems ? 3 : 0),
        );

        expect(todayButton, findsNothing);
        expect(einkauf, hasOpenItems ? findsOneWidget : findsNothing);
      });

      for (final entry in days.entries) {
        testWidgets('R4: ${entry.key} with $list', (tester) async {
          final shell = await pumpHomeShell(
            tester,
            shopping: shoppingItems(open: hasOpenItems ? 3 : 0),
          );
          shell.selectDiaryDay(entry.value);
          await settle(tester);

          expect(todayButton, findsOneWidget);
          expect(
            find.descendant(of: todayButton, matching: find.text('Heute')),
            findsOneWidget,
          );
          expect(einkauf, findsNothing);
        });
      }
    }

    testWidgets('R4: today with 3 items all ticked off shows neither', (
      tester,
    ) async {
      await pumpHomeShell(tester, shopping: shoppingItems(done: 3));

      expect(todayButton, findsNothing);
      expect(einkauf, findsNothing);
    });
  });
}
