import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

import 'acceptance_harness.dart';

/// The words in the Einkauf tool of Vorrat.
Future<List<String>> _einkaufTexts(
  WidgetTester tester,
  List<ShoppingListItem> shopping,
) async {
  await pumpHomeShell(tester, tab: AcceptanceTab.vorrat, shopping: shopping);
  return toolTexts(tester, headerTool('Einkauf'));
}

void main() {
  group('K11: the badge shows the number of open items', () {
    const rows = [
      (0, null),
      (1, '1'),
      (7, '7'),
      (99, '99'),
      (100, '99+'),
      (250, '99+'),
    ];
    for (final (open, badge) in rows) {
      testWidgets('K11: $open open items give ${badge ?? 'no badge'}', (
        tester,
      ) async {
        final texts = await _einkaufTexts(tester, shoppingItems(open: open));

        expect(
          texts,
          unorderedEquals(['Einkauf', ?badge]),
          reason: 'a badge is never "0"',
        );
      });
    }

    testWidgets('K11: 3 ticked-off items give no badge', (tester) async {
      final texts = await _einkaufTexts(tester, shoppingItems(done: 3));

      expect(texts, ['Einkauf']);
    });
  });

  group('K12: the count adds up both lists', () {
    // household open, household ticked off, private open, private ticked off
    const rows = [
      (0, 0, 7, 0, '7', 'no household, private 7 open'),
      (3, 0, 4, 0, '7', 'household 3 open, private 4 open'),
      (3, 0, 0, 0, '3', 'household 3 open, private 0 open'),
      (0, 0, 1, 0, '1', 'household 0 open, private 1 open'),
      (0, 0, 3, 2, '3', 'private 5 items, 2 of them ticked off'),
      (60, 0, 40, 0, '99+', 'household 60 open, private 40 open'),
      (0, 2, 0, 0, null, 'household 2 ticked off, private 0'),
    ];
    for (final (hOpen, hDone, pOpen, pDone, number, name) in rows) {
      testWidgets('K12: $name give ${number ?? 'no number'}', (tester) async {
        final texts = await _einkaufTexts(tester, [
          ...shoppingItems(open: hOpen, done: hDone),
          ...shoppingItems(open: pOpen, done: pDone, isPrivate: true),
        ]);

        expect(texts, unorderedEquals(['Einkauf', ?number]));
      });
    }
  });
}
