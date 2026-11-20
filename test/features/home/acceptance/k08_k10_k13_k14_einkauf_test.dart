import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';

import 'acceptance_harness.dart';

void main() {
  final einkauf = headerTool('Einkauf');

  group('K8: where Einkauf shows', () {
    // tab, open items on the list, expected Einkauf
    const rows = [
      (AcceptanceTab.tagebuch, 3, 0, true),
      (AcceptanceTab.tagebuch, 0, 0, false),
      (AcceptanceTab.vorrat, 3, 0, true),
      (AcceptanceTab.vorrat, 0, 0, true),
      (AcceptanceTab.kochbuch, 3, 0, true),
      (AcceptanceTab.kochbuch, 0, 0, false),
      (AcceptanceTab.fortschritt, 3, 0, false),
      (AcceptanceTab.fortschritt, 0, 0, false),
      (AcceptanceTab.tagebuch, 0, 3, false),
      (AcceptanceTab.kochbuch, 0, 3, false),
      (AcceptanceTab.vorrat, 0, 3, true),
    ];
    for (final (tab, open, done, shows) in rows) {
      testWidgets('K8: ${tab.name}, $open open and $done ticked off: '
          '${shows ? 'Einkauf shows' : 'no Einkauf'}', (tester) async {
        await pumpHomeShell(
          tester,
          tab: tab,
          shopping: shoppingItems(open: open, done: done),
        );

        expect(einkauf, shows ? findsOneWidget : findsNothing);
      });
    }

    // Vorrat holding no food at all (no items, no meals).
    for (final (open, done, number) in [
      (3, 0, '3'),
      (0, 0, null),
      (0, 3, null),
    ]) {
      testWidgets(
        'K8: empty Vorrat, $open open and $done ticked off: '
        'Einkauf shows${number == null ? ' without number' : ' with $number'}',
        (tester) async {
          await pumpHomeShell(
            tester,
            tab: AcceptanceTab.vorrat,
            emptyVorrat: true,
            shopping: shoppingItems(open: open, done: done),
          );

          expect(einkauf, findsOneWidget);
          expect(
            toolTexts(tester, einkauf),
            unorderedEquals(['Einkauf', ?number]),
          );
        },
      );
    }

    testWidgets('K8: Vorrat with 3 items all ticked off shows no number', (
      tester,
    ) async {
      await pumpHomeShell(
        tester,
        tab: AcceptanceTab.vorrat,
        shopping: shoppingItems(done: 3),
      );

      expect(toolTexts(tester, einkauf), ['Einkauf']);
    });
  });

  for (final tab in [
    AcceptanceTab.tagebuch,
    AcceptanceTab.vorrat,
    AcceptanceTab.kochbuch,
  ]) {
    testWidgets('K9: Einkauf in ${tab.name} opens the shopping list', (
      tester,
    ) async {
      await pumpHomeShell(tester, tab: tab, shopping: shoppingItems(open: 2));

      await tapAndSettle(tester, einkauf);

      expect(find.byKey(shoppingRouteMarker), findsOneWidget);
    });

    testWidgets('K10: Einkauf stands rightmost in ${tab.name}', (tester) async {
      await pumpHomeShell(tester, tab: tab, shopping: shoppingItems(open: 2));

      final einkaufX = tester.getCenter(einkauf).dx;
      final others = find
          .byType(HomeHeaderTool)
          .evaluate()
          .map((element) => tester.getCenter(find.byWidget(element.widget)).dx)
          .where((x) => x != einkaufX);
      expect(others, isNotEmpty);
      for (final x in others) {
        expect(einkaufX, greaterThan(x));
      }
    });

    testWidgets('K14: Einkauf in ${tab.name} carries icon and word', (
      tester,
    ) async {
      await pumpHomeShell(tester, tab: tab, shopping: shoppingItems(open: 2));

      final icon = find.descendant(of: einkauf, matching: find.byType(Icon));
      final word = find.descendant(of: einkauf, matching: find.text('Einkauf'));
      expect(icon, findsOneWidget);
      expect(word, findsOneWidget);
      expect(
        tester.getCenter(icon).dy,
        lessThan(tester.getCenter(word).dy),
        reason: 'the word stands under the icon',
      );
    });
  }

  testWidgets('K10: in Vorrat Einkauf stands after Verlauf', (tester) async {
    await pumpHomeShell(
      tester,
      tab: AcceptanceTab.vorrat,
      shopping: shoppingItems(open: 2),
    );

    final verlauf = headerTool('Verlauf');
    expect(verlauf, findsOneWidget);
    expect(
      tester.getCenter(einkauf).dx,
      greaterThan(tester.getCenter(verlauf).dx),
    );
  });

  group('K13: tool names in normal case', () {
    const words = {
      AcceptanceTab.vorrat: ['Verlauf', 'Einkauf'],
      AcceptanceTab.kochbuch: ['Neu', 'Einkauf'],
    };
    for (final entry in words.entries) {
      testWidgets('K13: ${entry.key.name} reads ${entry.value.join(', ')}', (
        tester,
      ) async {
        await pumpHomeShell(
          tester,
          tab: entry.key,
          shopping: shoppingItems(open: 2),
        );

        // No word under any header tool is written in capitals.
        for (final text
            in tester
                .widgetList<HomeHeaderTool>(find.byType(HomeHeaderTool))
                .expand((tool) => toolTexts(tester, find.byWidget(tool)))) {
          if (RegExp('[A-Za-zÄÖÜäöü]{2}').hasMatch(text)) {
            expect(text, isNot(text.toUpperCase()), reason: text);
          }
        }
        for (final word in entry.value) {
          expect(headerTool(word), findsOneWidget, reason: word);
          expect(headerTool(word.toUpperCase()), findsNothing, reason: word);
        }
      });
    }
  });
}
