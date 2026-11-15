import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_view_preferences.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_sort_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_item_picker_sheet.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

import '../../../helpers/memory_app_preferences.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_sheet_pump.dart';

KochmodusOffer _offer(
  String id, {
  String? name,
  int available = 800,
  int? needed,
  DateTime? added,
  String? receiptId,
  DateTime? receiptDate,
}) {
  final item = stockItem(id, available).copyWith(
    name: name ?? 'Item $id',
    entryDate: added ?? DateTime.utc(2026, 10),
    receiptId: receiptId,
    receiptDate: receiptDate,
    storeName: 'Laden',
  );
  return (
    item: item,
    available: available,
    reserved: 0,
    needed: needed,
    missing: needed == null ? 0 : (needed - available).clamp(0, needed),
    held: false,
  );
}

const _need = TemplateIngredientRequirement(
  amount: 750,
  unit: TemplateIngredientUnit.gram,
  name: 'Hack',
);

void main() {
  Future<void> openPicker(
    WidgetTester tester,
    List<List<String>?> results, {
    required KochmodusPickerOffers offers,
    TemplateIngredientRequirement? need = _need,
    List<String> picked = const [],
    double width = 800,
    double height = 1200,
    double keyboard = 0,
    double textScale = 1,
    MemoryAppPreferences? preferences,
  }) => pumpSheet<List<String>>(
    tester,
    (context) => KochmodusItemPickerSheet.show(
      context,
      title: '750 g Hack',
      need: need,
      offers: offers,
      picked: picked,
    ).then((result) => result?.ids),
    results,
    width: width,
    height: height,
    keyboard: keyboard,
    textScale: textScale,
    preferences: preferences,
  );

  Finder number(String id, String n) => find.descendant(
    of: find.byKey(KochmodusItemPickerSheet.rowKey(id)),
    matching: find.text(n),
  );

  Finder row(String id) => find.byKey(KochmodusItemPickerSheet.rowKey(id));

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(
      find.byKey(KochmodusItemPickerSheet.searchKey),
      query,
    );
    await tester.pumpAndSettle();
  }

  // The ids of the rows from top to bottom.
  List<String> order(WidgetTester tester, List<String> ids) =>
      ([...ids]..removeWhere((id) => row(id).evaluate().isEmpty))..sort(
        (a, b) => tester
            .getTopLeft(row(a))
            .dy
            .compareTo(tester.getTopLeft(row(b)).dy),
      );

  group('rows', () {
    testWidgets('are numbered in the order they are tapped', (tester) async {
      final results = <List<String>?>[];
      await openPicker(
        tester,
        results,
        offers: (
          matches: const [],
          rest: [_offer('a'), _offer('b'), _offer('c')],
        ),
      );
      // The line is the kicker, the question the title.
      expect(find.text('750 G HACK'), findsOneWidget);
      expect(find.text(sheetL10n(tester).kochmodusPickerTitle), findsOne);
      expect(find.text(sheetL10n(tester).cookPickerHint), findsOneWidget);

      await tapKey(tester, KochmodusItemPickerSheet.rowKey('c'));
      await tapKey(tester, KochmodusItemPickerSheet.rowKey('a'));
      expect(number('c', '1'), findsOneWidget);
      expect(number('a', '2'), findsOneWidget);
      expect(number('b', '1'), findsNothing);
      expect(number('b', '2'), findsNothing);

      // Taking the first away moves the second up.
      await tapKey(tester, KochmodusItemPickerSheet.rowKey('c'));
      expect(number('a', '1'), findsOneWidget);
      expect(number('c', '1'), findsNothing);

      await tapKey(tester, KochmodusItemPickerSheet.rowKey('b'));
      await tapKey(tester, KochmodusItemPickerSheet.keepKey);
      expect(results, [
        ['a', 'b'],
      ]);
    });

    testWidgets('the items the line takes start tapped, in their order', (
      tester,
    ) async {
      final results = <List<String>?>[];
      await openPicker(
        tester,
        results,
        offers: (
          matches: const [],
          rest: [_offer('a'), _offer('b'), _offer('c')],
        ),
        picked: const ['c', 'a', 'gone'],
      );

      expect(number('c', '1'), findsOneWidget);
      expect(number('a', '2'), findsOneWidget);
      await tapKey(tester, KochmodusItemPickerSheet.keepKey);
      expect(results, [
        ['c', 'a'],
      ]);
    });

    testWidgets(
      'a suggestion shows both titles and every Vorrat food at once',
      (tester) async {
        await openPicker(
          tester,
          [],
          offers: (matches: [_offer('a')], rest: [_offer('x'), _offer('y')]),
        );
        final l10n = sheetL10n(tester);

        expect(find.byKey(KochmodusItemPickerSheet.suggestedKey), findsOne);
        expect(find.byKey(KochmodusItemPickerSheet.allKey), findsOne);
        expect(
          find.text(l10n.kochmodusPickerSuggested.toUpperCase()),
          findsOneWidget,
        );
        expect(
          find.text(l10n.kochmodusPickerAll.toUpperCase()),
          findsOneWidget,
        );
        expect(row('a'), findsOneWidget);
        expect(row('x'), findsOneWidget);
        expect(row('y'), findsOneWidget);
        expect(
          order(tester, ['a', 'x', 'y']).first,
          'a',
          reason: 'the suggestion stands above the rest',
        );
      },
    );

    testWidgets('without a suggestion only the Vorrat shows, without a title', (
      tester,
    ) async {
      await openPicker(
        tester,
        [],
        offers: (matches: const [], rest: [_offer('x')]),
      );

      expect(row('x'), findsOneWidget);
      expect(find.byKey(KochmodusItemPickerSheet.suggestedKey), findsNothing);
      expect(find.byKey(KochmodusItemPickerSheet.allKey), findsNothing);
    });

    testWidgets('a taken item outside the suggestions keeps its number', (
      tester,
    ) async {
      await openPicker(
        tester,
        [],
        offers: (matches: [_offer('a')], rest: [_offer('x')]),
        picked: const ['x'],
      );

      expect(row('x'), findsOneWidget);
      expect(number('x', '1'), findsOneWidget);
    });

    testWidgets('"So lassen" shows only once a row is tapped', (tester) async {
      await openPicker(
        tester,
        [],
        offers: (matches: const [], rest: [_offer('a')]),
      );

      final keep = find.byKey(KochmodusItemPickerSheet.keepKey);
      expect(keep, findsNothing);
      await tapKey(tester, KochmodusItemPickerSheet.rowKey('a'));
      expect(keep, findsOneWidget);
      await tapKey(tester, KochmodusItemPickerSheet.rowKey('a'));
      expect(keep, findsNothing);
    });

    testWidgets('closing the sheet returns nothing', (tester) async {
      final results = <List<String>?>[];
      await openPicker(
        tester,
        results,
        offers: (matches: const [], rest: [_offer('a')]),
      );

      await tapKey(tester, KochmodusItemPickerSheet.rowKey('a'));
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(results, [null]);
    });
  });

  group('covering the line', () {
    testWidgets('a tap on a food that covers the need closes the sheet with '
        'it', (tester) async {
      final results = <List<String>?>[];
      await openPicker(
        tester,
        results,
        offers: (
          matches: [_offer('big', needed: 750)],
          rest: [_offer('small', available: 300, needed: 750)],
        ),
      );

      await tapKey(tester, KochmodusItemPickerSheet.rowKey('big'));

      expect(results, [
        ['big'],
      ]);
      expect(find.byKey(KochmodusItemPickerSheet.rowKey('big')), findsNothing);
    });

    testWidgets('a food that does not cover keeps the sheet open with what '
        'is missing, "Nur N nehmen" and "N kaufen"', (tester) async {
      final results = <List<String>?>[];
      await openPicker(
        tester,
        results,
        offers: (
          matches: [_offer('big', needed: 750)],
          rest: [_offer('small', available: 300, needed: 750)],
        ),
      );

      await tapKey(tester, KochmodusItemPickerSheet.rowKey('small'));

      expect(results, isEmpty);
      expect(find.byKey(KochmodusItemPickerSheet.missingKey), findsOneWidget);
      expect(
        find.text(sheetL10n(tester).kochmodusPickerStillMissing('450 g')),
        findsOneWidget,
      );
      expect(
        find.text(sheetL10n(tester).kochmodusAmountTakeOnly('300 g')),
        findsOneWidget,
      );
      expect(
        find.text(sheetL10n(tester).kochmodusAmountBuyRest('450 g')),
        findsOneWidget,
      );
      expect(find.byKey(KochmodusItemPickerSheet.keepKey), findsNothing);
    });

    testWidgets('"Nur N nehmen" returns the picks in the order tapped', (
      tester,
    ) async {
      final results = <List<String>?>[];
      await openPicker(
        tester,
        results,
        offers: (
          matches: const [],
          rest: [
            _offer('a', available: 200, needed: 750),
            _offer('b', available: 100, needed: 750),
          ],
        ),
      );

      await tapKey(tester, KochmodusItemPickerSheet.rowKey('b'));
      await tapKey(tester, KochmodusItemPickerSheet.rowKey('a'));
      await tapKey(tester, KochmodusItemPickerSheet.takeOnlyKey);

      expect(results, [
        ['b', 'a'],
      ]);
    });

    testWidgets('two foods that cover the need together close the sheet', (
      tester,
    ) async {
      final results = <List<String>?>[];
      await openPicker(
        tester,
        results,
        offers: (
          matches: const [],
          rest: [
            _offer('a', available: 375, needed: 750),
            _offer('b', available: 375, needed: 750),
          ],
        ),
      );

      await tapKey(tester, KochmodusItemPickerSheet.rowKey('a'));
      expect(results, isEmpty);
      await tapKey(tester, KochmodusItemPickerSheet.rowKey('b'));

      expect(results, [
        ['a', 'b'],
      ]);
    });

    testWidgets('a line without an amount closes on the first tap', (
      tester,
    ) async {
      final results = <List<String>?>[];
      await openPicker(
        tester,
        results,
        need: null,
        offers: (matches: [_offer('a')], rest: const []),
      );

      await tapKey(tester, KochmodusItemPickerSheet.rowKey('a'));

      expect(results, [
        ['a'],
      ]);
    });
  });

  group('the search', () {
    final offers = (
      matches: [_offer('m', name: 'Basmati Reis')],
      rest: [
        _offer('o', name: 'Reisnudeln'),
        _offer('p', name: 'Mehl'),
        _offer('r', name: 'REIS Milch'),
        _offer('s', name: 'Salz'),
      ],
    );

    testWidgets('has no autofocus and the keyboard stays closed', (
      tester,
    ) async {
      await openPicker(tester, [], offers: offers);

      final field = tester.widget<TextField>(
        find.byKey(KochmodusItemPickerSheet.searchKey),
      );
      expect(field.autofocus, isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('filters both groups by name and ignores case', (tester) async {
      await openPicker(tester, [], offers: offers);

      await search(tester, 'rEiS');

      expect(row('m'), findsOneWidget);
      expect(row('o'), findsOneWidget);
      expect(row('r'), findsOneWidget);
      expect(row('p'), findsNothing);
      expect(row('s'), findsNothing);
    });

    testWidgets('shows every Vorrat food without a search', (tester) async {
      await openPicker(tester, [], offers: offers);

      for (final id in ['m', 'o', 'p', 'r', 's']) {
        expect(row(id), findsOneWidget, reason: id);
      }
    });

    testWidgets('clearing the query brings the list back', (tester) async {
      await openPicker(tester, [], offers: offers);

      await search(tester, 'salz');
      expect(row('s'), findsOneWidget);
      expect(row('m'), findsNothing);

      await search(tester, '');
      expect(row('m'), findsOneWidget);
      expect(row('p'), findsOneWidget);
      expect(row('s'), findsOneWidget);
    });

    testWidgets('the name matches stay on top of what is found', (
      tester,
    ) async {
      await openPicker(tester, [], offers: offers);

      await search(tester, 'reis');

      expect(order(tester, ['m', 'o', 'r']).first, 'm');
    });

    testWidgets('a query without a hit leaves no rows and says so', (
      tester,
    ) async {
      await openPicker(tester, [], offers: offers);
      final l10n = sheetL10n(tester);
      expect(find.text(l10n.kochmodusPickerNoHits), findsNothing);

      await search(tester, 'zzz');

      for (final id in ['m', 'o', 'p', 'r', 's']) {
        expect(row(id), findsNothing);
      }
      expect(find.text(l10n.kochmodusPickerNoHits), findsOneWidget);

      await search(tester, 'salz');

      expect(find.text(l10n.kochmodusPickerNoHits), findsNothing);
    });

    testWidgets('a food of the rest tapped during the search stays after it', (
      tester,
    ) async {
      final results = <List<String>?>[];
      await openPicker(tester, results, offers: offers);
      await search(tester, 'salz');
      expect(row('s'), findsOneWidget);

      await tapKey(tester, KochmodusItemPickerSheet.rowKey('s'));
      await search(tester, '');

      // The tapped item of the rest is still there, with its number.
      expect(number('s', '1'), findsOneWidget);
      expect(row('r'), findsOneWidget);
      await tapKey(tester, KochmodusItemPickerSheet.keepKey);
      expect(results, [
        ['s'],
      ]);
    });

    testWidgets('tapped rows keep their numbers while filtered out', (
      tester,
    ) async {
      final results = <List<String>?>[];
      await openPicker(
        tester,
        results,
        offers: (
          matches: const [],
          rest: [
            _offer('a', name: 'Apfel'),
            _offer('b', name: 'Birne'),
            _offer('c', name: 'Chili'),
          ],
        ),
      );
      await tapKey(tester, KochmodusItemPickerSheet.rowKey('b'));
      await tapKey(tester, KochmodusItemPickerSheet.rowKey('a'));

      await search(tester, 'chili');
      expect(row('a'), findsNothing);
      expect(row('b'), findsNothing);
      // Tapped while the others are filtered out: it comes third.
      await tapKey(tester, KochmodusItemPickerSheet.rowKey('c'));
      expect(number('c', '3'), findsOneWidget);

      await search(tester, '');

      expect(number('b', '1'), findsOneWidget);
      expect(number('a', '2'), findsOneWidget);
      expect(number('c', '3'), findsOneWidget);
      await tapKey(tester, KochmodusItemPickerSheet.keepKey);
      expect(results, [
        ['b', 'a', 'c'],
      ]);
    });

    testWidgets('"So lassen" stays while the tapped rows are hidden', (
      tester,
    ) async {
      await openPicker(
        tester,
        [],
        offers: (
          matches: const [],
          rest: [
            _offer('a', name: 'Apfel'),
            _offer('b', name: 'Birne'),
          ],
        ),
        picked: const ['a'],
      );

      await search(tester, 'birne');

      expect(find.byKey(KochmodusItemPickerSheet.keepKey), findsOneWidget);
    });
  });

  group('the order', () {
    final offers = (
      matches: [_offer('z', name: 'Zucker', added: DateTime.utc(2026, 10, 2))],
      rest: [
        _offer('a', name: 'Apfel', added: DateTime.utc(2026, 10)),
        _offer('m', name: 'Mehl', added: DateTime.utc(2026, 10, 3)),
        _offer('n', name: 'Nudeln', added: DateTime.utc(2026, 10, 4)),
      ],
    );
    const ids = ['z', 'a', 'm', 'n'];

    testWidgets('has no sort button of its own', (tester) async {
      await openPicker(tester, [], offers: offers);

      expect(find.byType(InventorySortSheet), findsNothing);
      expect(
        find.byTooltip(sheetL10n(tester).inventorySortAction),
        findsNothing,
      );
    });

    testWidgets('follows the saved order of the Vorrat, matches on top', (
      tester,
    ) async {
      await openPicker(tester, [], offers: offers);

      // Nothing eaten yet: the Vorrat falls back to the name.
      expect(order(tester, ids), ['z', 'a', 'm', 'n']);
    });

    testWidgets('opens in the order the Vorrat saved', (tester) async {
      final preferences = MemoryAppPreferences();
      await const InventoryListViewPreferencesStore().save(
        preferences,
        const InventoryListViewPreferences(
          sortMode: InventoryItemSortMode.alphabeticalDescending,
        ),
      );
      await openPicker(tester, [], offers: offers, preferences: preferences);

      expect(order(tester, ids), ['z', 'n', 'm', 'a']);
    });
  });

  group('"Etwas anderes suchen"', () {
    testWidgets('closes the picker with an empty list', (tester) async {
      final results = <List<String>?>[];
      await openPicker(
        tester,
        results,
        offers: (matches: const [], rest: [_offer('a')]),
      );
      final l10n = sheetL10n(tester);

      expect(
        find.descendant(
          of: find.byKey(KochmodusItemPickerSheet.searchOtherKey),
          matching: find.text(l10n.kochmodusPickerSearchOther),
        ),
        findsOneWidget,
      );
      await tapKey(tester, KochmodusItemPickerSheet.searchOtherKey);

      expect(results, [<String>[]]);
    });

    testWidgets('closes it even with an item tapped', (tester) async {
      final results = <List<String>?>[];
      await openPicker(
        tester,
        results,
        offers: (matches: const [], rest: [_offer('a')]),
      );

      await tapKey(tester, KochmodusItemPickerSheet.rowKey('a'));
      await tapKey(tester, KochmodusItemPickerSheet.searchOtherKey);

      expect(results, [<String>[]]);
    });
  });

  group('"Etwas anderes suchen" stays in sight', () {
    final many = (
      matches: [_offer('m', name: 'Reis')],
      rest: [for (var i = 0; i < 40; i++) _offer('o$i', name: 'Reis $i')],
    );

    testWidgets('with 40 foods it is on screen without scrolling', (
      tester,
    ) async {
      await openPicker(tester, [], offers: many, width: 360, height: 640);

      expect(tester.takeException(), isNull);
      final button = find.byKey(KochmodusItemPickerSheet.searchOtherKey);
      expect(button, findsOneWidget);
      expect(tester.getBottomLeft(button).dy, lessThanOrEqualTo(640));
      expect(button.hitTestable(), findsOneWidget);
    });

    testWidgets('it stays above the keyboard while the search is used', (
      tester,
    ) async {
      await openPicker(
        tester,
        [],
        offers: many,
        width: 360,
        height: 640,
        keyboard: 300,
      );
      await search(tester, 'reis');

      final button = find.byKey(KochmodusItemPickerSheet.searchOtherKey);
      expect(tester.takeException(), isNull);
      expect(tester.getBottomLeft(button).dy, lessThanOrEqualTo(640 - 300));
      expect(button.hitTestable(), findsOneWidget);
    });

    testWidgets('it is still the way out at text scale 2', (tester) async {
      final results = <List<String>?>[];
      await openPicker(
        tester,
        results,
        offers: many,
        width: 360,
        height: 640,
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      await tapKey(tester, KochmodusItemPickerSheet.searchOtherKey);
      expect(results, [<String>[]]);
    });
  });

  group('held foods', () {
    // A food that another cooking holds completely.
    KochmodusOffer held(String id) => (
      item: stockItem(id, 800).copyWith(name: 'Item $id'),
      available: 0,
      reserved: 800,
      needed: 750,
      missing: 750,
      held: true,
    );

    testWidgets('every one says "verplant", also one that is no suggestion', (
      tester,
    ) async {
      await openPicker(
        tester,
        [],
        offers: (
          matches: [held('suggested')],
          rest: [held('other'), _offer('free')],
        ),
      );
      final l10n = sheetL10n(tester);

      for (final id in ['suggested', 'other']) {
        expect(
          find.descendant(
            of: row(id),
            matching: find.text(l10n.kochmodusPickerHeld),
          ),
          findsOneWidget,
          reason: id,
        );
      }
      expect(
        find.descendant(
          of: row('free'),
          matching: find.text(l10n.kochmodusPickerHeld),
        ),
        findsNothing,
      );
    });
  });

  group('small phone, big text, open keyboard', () {
    final offers = (
      matches: [_offer('m', name: 'Reis')],
      rest: [for (var i = 0; i < 12; i++) _offer('o$i', name: 'Reis $i')],
    );

    for (final scale in [1.0, 1.3]) {
      testWidgets('keep a row to tap and "Übernehmen" at text scale $scale', (
        tester,
      ) async {
        final results = <List<String>?>[];
        await openPicker(
          tester,
          results,
          offers: offers,
          width: 360,
          height: 640,
          keyboard: 300,
          textScale: scale,
        );
        await search(tester, 'reis');

        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(KochmodusItemPickerSheet.rowKey('m')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(KochmodusItemPickerSheet.keepKey),
        );
        await tester.tap(find.byKey(KochmodusItemPickerSheet.keepKey));
        await tester.pumpAndSettle();
        expect(results, [
          ['m'],
        ]);
      });
    }

    testWidgets('does not overflow without a keyboard either', (tester) async {
      await openPicker(
        tester,
        [],
        offers: offers,
        width: 320,
        height: 568,
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
