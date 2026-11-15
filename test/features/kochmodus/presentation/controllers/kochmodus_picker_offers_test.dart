import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_content.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_entry.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_view_preferences.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_picker_offers.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_view_builder.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

import '../../../recipes/cook_run_fixtures.dart';
import '../../kochmodus_fixtures.dart';

final _pots = CookPotsChosen(pots: const [cookPotA, cookPotB], inCans: false);

KochmodusView _view(
  CookRun run, {
  List<InventoryItem> items = const [],
  Map<String, int> others = const {},
}) => buildKochmodusView(
  run: run,
  saved: true,
  ended: false,
  busy: false,
  reopened: false,
  finished: null,
  tab: null,
  items: items,
  otherReservations: others,
  utensils: const [],
  parser: const TemplateIngredientParser(),
);

List<String> _ids(List<KochmodusOffer> offers) => [
  for (final offer in offers) offer.item.id,
];

List<String> _rowIds(List<KochmodusPickerRow> rows) => [
  for (final row in rows)
    switch (row) {
      KochmodusPickerOfferRow(:final offer) => offer.item.id,
      KochmodusPickerReceiptRow(:final group) => '#${group.key}',
    },
];

void main() {
  final run = buildCookRun(pots: _pots, lines: [textLine('a', '300 g Reis')]);

  test('with a name match the other fitting items wait in rest', () {
    final view = _view(
      run,
      items: [
        stockItem('i1', 500).copyWith(name: 'Nudeln'),
        stockItem('i2', 500).copyWith(name: 'Reis'),
      ],
    );

    final offers = kochmodusPickerOffers(view, 'a', localeCode: 'de');

    expect(_ids(offers.matches), ['i2']);
    expect(_ids(offers.rest), ['i1']);
  });

  test('items in a unit that cannot supply the line go to rest', () {
    final view = _view(
      run,
      items: [
        stockItem('i1', 500).copyWith(name: 'Reis'),
        stockItem('i2', 5000, unit: InventoryAmountUnit.piece, scale: 1000),
        packItem('i3', 2),
      ],
    );

    final offers = kochmodusPickerOffers(view, 'a', localeCode: 'de');

    expect(_ids(offers.matches), ['i1']);
    expect(_ids(offers.rest), ['i2', 'i3']);
  });

  test('an item in the other of g and ml that fits by name is a match', () {
    final milk = buildCookRun(
      pots: _pots,
      lines: [textLine('a', '100 g Milch')],
    );
    final view = _view(
      milk,
      items: [
        stockItem(
          'i1',
          500,
          unit: InventoryAmountUnit.milliliter,
        ).copyWith(name: 'Milch'),
        stockItem('i2', 500).copyWith(name: 'Nudeln'),
      ],
    );

    final offers = kochmodusPickerOffers(view, 'a', localeCode: 'de');

    expect(_ids(offers.matches), ['i1']);
    expect(_ids(offers.rest), ['i2']);
  });

  group('kochmodusPickerStillMissing', () {
    TemplateIngredientRequirement need(int grams) =>
        TemplateIngredientRequirement(
          amount: grams,
          unit: TemplateIngredientUnit.gram,
          name: 'Reis',
        );
    KochmodusOffer offer(String id, {required int available, int? needed}) => (
      item: stockItem(id, 500),
      available: available,
      reserved: 0,
      needed: needed,
      missing: needed == null ? 0 : (needed - available).clamp(0, needed),
      held: false,
    );

    test('one pick that covers the need leaves nothing missing', () {
      expect(
        kochmodusPickerStillMissing([
          offer('a', available: 500, needed: 300),
        ], need(300)),
        0,
      );
    });

    test('two picks cover the need together', () {
      expect(
        kochmodusPickerStillMissing([
          offer('a', available: 150, needed: 300),
          offer('b', available: 150, needed: 300),
        ], need(300)),
        0,
      );
    });

    test('two picks of thirds cover the need together without a rest', () {
      expect(
        kochmodusPickerStillMissing([
          offer('a', available: 100, needed: 300),
          offer('b', available: 200, needed: 300),
        ], need(300)),
        0,
      );
    });

    test('a pick that holds too little leaves the rest missing', () {
      expect(
        kochmodusPickerStillMissing([
          offer('a', available: 150, needed: 300),
        ], need(300)),
        150,
      );
    });

    test('a third of the need leaves exactly two thirds missing', () {
      expect(
        kochmodusPickerStillMissing([
          offer('a', available: 100, needed: 300),
        ], need(300)),
        200,
      );
    });

    test('a pick whose unit cannot supply the line covers nothing', () {
      expect(
        kochmodusPickerStillMissing([offer('pack', available: 5)], need(300)),
        300,
      );
    });

    test('no pick leaves the whole need missing', () {
      expect(kochmodusPickerStillMissing(const [], need(300)), 300);
    });

    test('no need gives 0', () {
      expect(
        kochmodusPickerStillMissing([
          offer('a', available: 100, needed: 300),
        ], null),
        0,
      );
      expect(kochmodusPickerStillMissing(const [], null), 0);
    });
  });

  test('a food that only fits by unit is no name match, the food of the '
      'name is', () {
    KochmodusPickerOffers offers(String text, List<InventoryItem> items) =>
        kochmodusPickerOffers(
          _view(
            buildCookRun(pots: _pots, lines: [textLine('a', text)]),
            items: items,
          ),
          'a',
          localeCode: 'de',
        );
    final flour = stockItem('flour', 500).copyWith(name: 'Mehl');
    final eggs = stockItem(
      'eggs',
      6000,
      unit: InventoryAmountUnit.piece,
      scale: 1000,
    ).copyWith(name: 'Eier');
    final milk = stockItem(
      'milk',
      1000,
      unit: InventoryAmountUnit.milliliter,
    ).copyWith(name: 'H-Milch');

    expect(_ids(offers('3 Eier', [flour, eggs]).matches), ['eggs']);
    expect(offers('3 Eier', [flour]).matches, isEmpty);
    expect(offers('Butter zum Braten', [milk, flour]).matches, isEmpty);
  });

  group('name matches stay on top without an amount to fit', () {
    KochmodusPickerOffers offers(String text, List<InventoryItem> items) =>
        kochmodusPickerOffers(
          _view(
            buildCookRun(pots: _pots, lines: [textLine('a', text)]),
            items: items,
          ),
          'a',
          localeCode: 'de',
        );

    final noodles = stockItem('noodles', 500).copyWith(name: 'Nudeln');
    final oil = stockItem(
      'oil',
      500,
      unit: InventoryAmountUnit.milliliter,
    ).copyWith(name: 'Rapsöl');

    test('a spoon keeps a food in g or ml on top', () {
      final found = offers('1 EL Öl', [noodles, oil]);

      expect(_ids(found.matches), ['oil']);
      expect(_ids(found.rest), ['noodles']);
    });

    test('a teaspoon keeps a food in g on top', () {
      final powder = stockItem('powder', 100).copyWith(name: 'Paprikapulver');

      expect(_ids(offers('1 TL Paprikapulver', [noodles, powder]).matches), [
        'powder',
      ]);
    });

    test('an unread amount keeps any food of its name on top', () {
      final pack = packItem('pack', 1).copyWith(name: 'Öl');

      expect(_ids(offers('etwas Öl', [noodles, oil, pack]).matches), [
        'pack',
        'oil',
      ]);
      expect(_ids(offers('1 Prise Salz', [noodles, pack]).matches), isEmpty);
    });

    test('pieces keep a food kept in grams on top', () {
      final onion = stockItem('onion', 500).copyWith(name: 'Zwiebeln');
      final found = offers('2 Zwiebeln', [noodles, onion]);

      expect(_ids(found.matches), ['onion']);
      expect(_ids(found.rest), ['noodles']);
    });

    test('a spoon keeps a food in whole packs and one in g, which a standard '
        'spoon fits, out of the matches: both wait in the rest', () {
      final mustard = packItem('mustard', 1).copyWith(name: 'Senf');
      final found = offers('1 EL Senf', [noodles, mustard]);

      expect(found.matches, isEmpty);
      expect(_ids(found.rest), ['noodles', 'mustard']);
    });

    test('a line in black pepper does not offer a black tea', () {
      final tea = stockItem('tea', 100).copyWith(name: 'Schwarzer Tee');
      final pepper = stockItem(
        'pepper',
        100,
      ).copyWith(name: 'Schwarzer Pfeffer');

      final found = offers('1/2 TL Schwarzer Pfeffer', [tea, pepper]);

      expect(_ids(found.matches), ['pepper']);
      expect(_ids(found.matches), isNot(contains('tea')));
    });

    test('a weak match stays off the top', () {
      final waffles = stockItem('waffles', 500).copyWith(name: 'Reiswaffeln');

      expect(offers('1 EL Reis', [waffles]).matches, isEmpty);
    });

    test('a food only inside another word stays off the top', () {
      final rice = stockItem('rice', 500).copyWith(name: 'Reis');
      final mince = stockItem('mince', 500).copyWith(name: 'Hackfleisch');
      final flakes = stockItem(
        'flakes',
        500,
      ).copyWith(name: 'Haferflocken', brand: 'Kölln');

      expect(offers('1 Ei', [rice, mince]).matches, isEmpty);
      expect(offers('2 Eier', [rice, mince]).matches, isEmpty);
      expect(offers('1 EL Öl', [flakes]).matches, isEmpty);
    });

    test('a food in a word that is another food stays off the top', () {
      final pork = stockItem('pork', 500).copyWith(name: 'Bio-Schweinefilet');

      expect(offers('1 EL Wein', [pork]).matches, isEmpty);
    });

    test('a short name before a part of the same food stays on top', () {
      final breast = stockItem(
        'breast',
        500,
      ).copyWith(name: 'Bio-Hähnchenbrust');

      expect(_ids(offers('2 Hähnchen', [breast]).matches), ['breast']);
    });

    test('a stronger and a weaker name both stay on top', () {
      final plain = stockItem('plain', 500).copyWith(name: 'Reis');
      final basmati = stockItem('basmati', 500).copyWith(name: 'Basmatireis');

      expect(_ids(offers('300 g Reis', [basmati, plain]).matches), [
        'plain',
        'basmati',
      ]);
    });
  });

  group('milk of several words and a line in pudding rice', () {
    final milk = stockItem(
      'milk',
      1000,
      unit: InventoryAmountUnit.milliliter,
    ).copyWith(name: 'Fettarme H-Milch');

    KochmodusPickerOffers offers(
      String lineText,
      List<InventoryItem> items, {
      Map<String, int> others = const {},
    }) => kochmodusPickerOffers(
      _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('milk', '1 l Milch'),
            textLine('rice', '250 g Milchreis'),
          ],
        ),
        items: items,
        others: others,
      ),
      lineText == 'milk' ? 'milk' : 'rice',
      localeCode: 'de',
    );

    test('the milk line takes it as a match', () {
      final found = offers('milk', [milk]);

      expect(_ids(found.matches), ['milk']);
    });

    test('the rice line offers it under all, not among the matches', () {
      final found = offers('rice', [milk]);

      expect(found.matches, isEmpty);
      expect(_ids(found.rest), ['milk']);
    });

    test('all of it held by another cooking leaves the rice line no match, so '
        'its hint is not the held one', () {
      final found = offers('rice', [milk], others: const {'milk': 1000});

      expect(found.matches, isEmpty);
    });

    test('"Vollmilch" is no name match of the pudding rice line', () {
      final whole = stockItem(
        'whole',
        1000,
        unit: InventoryAmountUnit.milliliter,
      ).copyWith(name: 'Vollmilch');

      final found = offers('rice', [whole]);

      expect(found.matches, isEmpty);
      expect(_ids(found.rest), ['whole']);
    });
  });

  group('the offers read the line as the page does', () {
    final onion = stockItem(
      'onion',
      4000,
      unit: InventoryAmountUnit.piece,
      scale: 1000,
    ).copyWith(name: 'Zwiebel');
    final salt = stockItem('salt', 500).copyWith(name: 'Salz');
    final beans = stockItem('beans', 500).copyWith(name: 'Bohnen');

    KochmodusPickerOffers offers(String text, {int portions = 4}) =>
        kochmodusPickerOffers(
          _view(
            buildCookRun(
              pots: _pots,
              portions: portions,
              lines: [textLine('a', text)],
            ),
            items: [onion, salt, beans],
          ),
          'a',
          localeCode: 'de',
        );

    test('a number word fits the item counted in pieces', () {
      expect(_ids(offers('eine Zwiebel').matches), ['onion']);
    });

    test('a part of a piece asks for that part', () {
      final found = offers('1 Zwiebel', portions: 1).matches.single;
      expect(found.needed, 250);
    });

    test('a half asks for half a piece', () {
      expect(offers('halbe Zwiebel').matches.single.needed, 500);
    });

    test('a pinch offers the food of its name', () {
      expect(_ids(offers('eine Prise Salz').matches), ['salt']);
      expect(_ids(offers('1 Prise Salz').matches), ['salt']);
    });
  });

  test('the pieces the cook typed keep asking for pieces without an item', () {
    final eggs = stockItem(
      'egg',
      6000,
      unit: InventoryAmountUnit.piece,
      scale: 1000,
    ).copyWith(name: 'Eier');
    final view = _view(
      buildCookRun(
        pots: _pots,
        lines: [
          textLine(
            'a',
            'Eier',
            amount: 3,
            amountUnit: TemplateIngredientUnit.piece,
            settlement: const LineShopping(),
          ),
        ],
      ),
      items: [
        eggs,
        stockItem('flour', 500).copyWith(name: 'Mehl'),
      ],
    );

    final offers = kochmodusPickerOffers(view, 'a', localeCode: 'de');

    expect(_ids(offers.matches), ['egg']);
    expect(_ids(offers.rest), ['flour']);
  });

  test('a word ahead of a size finds the food by its name', () {
    final view = _view(
      buildCookRun(
        pots: _pots,
        lines: [textLine('a', 'eine 400 g Dose Tomaten')],
      ),
      items: [
        stockItem('tin', 800).copyWith(name: 'Tomaten'),
        stockItem('flour', 500).copyWith(name: 'Mehl'),
      ],
    );

    final offers = kochmodusPickerOffers(view, 'a', localeCode: 'de');

    expect(_ids(offers.matches), ['tin']);
    expect(_ids(offers.rest), ['flour']);
  });

  test('a line that is gone has nothing to offer', () {
    final view = _view(run, items: [stockItem('i1', 500)]);

    final offers = kochmodusPickerOffers(view, 'nope', localeCode: 'de');

    expect(offers.matches, isEmpty);
    expect(offers.rest, isEmpty);
  });

  group('reservations of other runs', () {
    test('the picker offers what is free after other runs and own lines', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '300 g Reis'),
            textLine('b', '100 g Reis', settlement: assigned({'i1': 100})),
          ],
        ),
        items: [stockItem('i1', 500), stockItem('i2', 200)],
        others: const {'i1': 150},
      );

      final offers = kochmodusOffers(view, 'a');
      final first = offers.singleWhere((offer) => offer.item.id == 'i1');
      final second = offers.singleWhere((offer) => offer.item.id == 'i2');

      expect(first.reserved, 250);
      expect(first.available, 250);
      expect(first.needed, 300);
      expect(first.missing, 50);
      expect(second.reserved, 0);
      expect(second.available, 200);
      expect(second.missing, 100);
      expect(view.otherReservations, {'i1': 150});
    });

    test('the own take of the line does not count against it', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '300 g Reis', settlement: assigned({'i1': 300})),
          ],
        ),
        items: [stockItem('i1', 500)],
        others: const {'i1': 100},
      );

      final offer = kochmodusOffers(view, 'a').single;

      expect(offer.reserved, 100);
      expect(offer.available, 400);
      expect(offer.missing, 0);
    });

    test('the picker skips used up items except those the line takes', () {
      final view = _view(
        buildCookRun(
          pots: _pots,
          lines: [
            textLine('a', '300 g Reis', settlement: assigned({'i1': 0})),
          ],
        ),
        items: [
          stockItem('i1', 0, initial: 500),
          stockItem('i2', 0, initial: 500),
          stockItem('i3', 50),
        ],
      );

      expect(
        kochmodusOffers(view, 'a').map((offer) => offer.item.id),
        unorderedEquals(['i1', 'i3']),
      );
    });

    test('a line that is gone has no offers', () {
      final view = _view(buildCookRun(), items: [stockItem('i1', 500)]);

      expect(kochmodusOffers(view, 'nope'), isEmpty);
    });
  });

  group('kochmodusPickerRows', () {
    const byName = InventoryListViewPreferences(
      sortMode: InventoryItemSortMode.alphabeticalAscending,
    );

    KochmodusOffer offer(InventoryItem item) => (
      item: item,
      available: item.currentAmount,
      reserved: 0,
      needed: null,
      missing: 0,
      held: false,
    );

    InventoryItem item(
      String id,
      String name, {
      int amount = 500,
      int initial = 500,
      DateTime? added,
      DateTime? eaten,
      String? receiptId,
      DateTime? receiptDate,
      String store = 'Laden',
    }) => stockItem(id, amount, initial: initial).copyWith(
      name: name,
      entryDate: added ?? DateTime.utc(2026, 10),
      lastConsumedAt: eaten,
      receiptId: receiptId,
      receiptDate: receiptDate,
      storeName: store,
    );

    KochmodusPickerOffers offersOf({
      List<InventoryItem> matches = const [],
      List<InventoryItem> rest = const [],
    }) => (
      matches: [for (final item in matches) offer(item)],
      rest: [for (final item in rest) offer(item)],
    );

    List<String> rows(
      KochmodusPickerOffers offers, {
      InventoryListViewPreferences preferences = byName,
      String query = '',
    }) {
      final found = kochmodusPickerRows(
        offers,
        preferences: preferences,
        query: query,
      );
      return [..._rowIds(found.suggested), ..._rowIds(found.all)];
    }

    test('no offers give no rows', () {
      expect(rows(offersOf()), isEmpty);
    });

    test('the suggestions and all the other foods are two lists', () {
      final offers = kochmodusPickerRows(
        offersOf(
          matches: [item('a', 'Apfel')],
          rest: [item('x', 'Xylit'), item('y', 'Birne')],
        ),
        preferences: byName,
        query: '',
      );

      expect(_rowIds(offers.suggested), ['a']);
      expect(_rowIds(offers.all), ['y', 'x']);
    });

    test('without a suggestion the first list is empty', () {
      final offers = kochmodusPickerRows(
        offersOf(rest: [item('x', 'Xylit')]),
        preferences: byName,
        query: '',
      );

      expect(offers.suggested, isEmpty);
      expect(_rowIds(offers.all), ['x']);
    });

    test('the search filters both lists', () {
      final offers = kochmodusPickerRows(
        offersOf(
          matches: [item('a', 'Apfelmus'), item('b', 'Birne')],
          rest: [item('c', 'Apfelsaft'), item('d', 'Mehl')],
        ),
        preferences: byName,
        query: 'apfel',
      );

      expect(_rowIds(offers.suggested), ['a']);
      expect(_rowIds(offers.all), ['c']);
    });

    group('matches stay on top', () {
      final matches = [item('m2', 'Zucker'), item('m1', 'Reis')];
      final rest = [
        item(
          'o1',
          'Aal',
          amount: 100,
          added: DateTime.utc(2026, 10, 5),
          eaten: DateTime.utc(2026, 10, 9),
        ),
        item(
          'o2',
          'Bohnen',
          amount: 400,
          added: DateTime.utc(2026, 10, 3),
          eaten: DateTime.utc(2026, 10, 7),
        ),
        item(
          'o3',
          'Cola',
          amount: 250,
          added: DateTime.utc(2026, 10, 4),
          eaten: DateTime.utc(2026, 10, 8),
        ),
      ];

      for (final mode in InventoryItemSortMode.values) {
        test('under ${mode.name}', () {
          final result = rows(
            offersOf(matches: matches, rest: rest),
            preferences: InventoryListViewPreferences(sortMode: mode),
          );

          // The matches keep the order of the matching, whatever the sort.
          expect(result.take(2), ['m2', 'm1']);
          expect(result.skip(2), hasLength(3));
        });
      }
    });

    group('the rows below follow the sort mode', () {
      final rest = [
        item(
          'b',
          'Bohnen',
          amount: 400,
          added: DateTime.utc(2026, 10, 3),
          eaten: DateTime.utc(2026, 10, 7),
        ),
        item(
          'a',
          'aal',
          amount: 100,
          added: DateTime.utc(2026, 10, 5),
          eaten: DateTime.utc(2026, 10, 9),
        ),
        item('c', 'Cola', amount: 250, added: DateTime.utc(2026, 10, 4)),
      ];
      final offers = offersOf(rest: rest);

      List<String> by(InventoryItemSortMode mode) => rows(
        offers,
        preferences: InventoryListViewPreferences(sortMode: mode),
      );

      test('added', () {
        expect(by(InventoryItemSortMode.recentlyAddedDescending), [
          'a',
          'c',
          'b',
        ]);
        expect(by(InventoryItemSortMode.recentlyAddedAscending), [
          'b',
          'c',
          'a',
        ]);
      });

      test('eaten, never eaten last', () {
        expect(by(InventoryItemSortMode.recentlyEatenDescending), [
          'a',
          'b',
          'c',
        ]);
        expect(by(InventoryItemSortMode.recentlyEatenAscending), [
          'b',
          'a',
          'c',
        ]);
      });

      test('name, ignoring case', () {
        expect(by(InventoryItemSortMode.alphabeticalAscending), [
          'a',
          'b',
          'c',
        ]);
        expect(by(InventoryItemSortMode.alphabeticalDescending), [
          'c',
          'b',
          'a',
        ]);
      });

      test('amount left', () {
        expect(by(InventoryItemSortMode.availableAmountAscending), [
          'a',
          'c',
          'b',
        ]);
        expect(by(InventoryItemSortMode.availableAmountDescending), [
          'b',
          'c',
          'a',
        ]);
      });

      test('the Vorrat orders them the same way', () {
        // The same comparator: the picker adds no order of its own.
        for (final mode in InventoryItemSortMode.values) {
          final expected = [...rest]
            ..sort(
              (x, y) => compareInventoryEntries(
                InventoryFoodEntry(x),
                InventoryFoodEntry(y),
                mode,
              ),
            );

          expect(by(mode), [for (final item in expected) item.id]);
        }
      });
    });

    group('the search', () {
      final offers = offersOf(
        matches: [item('m', 'Basmati Reis')],
        rest: [
          item('o', 'Reisnudeln'),
          item('p', 'Mehl'),
          item('r', 'REIS Milch'),
          item('s', 'Salz'),
        ],
      );

      test('filters all offers, the rest included, ignoring case', () {
        expect(rows(offers, query: 'reis'), ['m', 'r', 'o']);
        expect(rows(offers, query: 'REIS'), ['m', 'r', 'o']);
      });

      test('reaches the rest without showAll', () {
        expect(rows(offers, query: 'salz'), ['s']);
      });

      test('a blank query is no search', () {
        expect(rows(offers, query: '  '), ['m', 'p', 'r', 'o', 's']);
      });

      test('a query that matches nothing leaves no rows', () {
        expect(rows(offers, query: 'zzz'), isEmpty);
      });

      test('the matches stay on top of the found rows', () {
        expect(rows(offers, query: 'reis').first, 'm');
        expect(rows(offers, query: 'mehl'), ['p']);
      });
    });

    group('Nach Beleg', () {
      const grouped = InventoryListViewPreferences(
        sortMode: InventoryItemSortMode.alphabeticalAscending,
        groupByReceipt: true,
      );
      final first = DateTime.utc(2026, 10);
      final second = DateTime.utc(2026, 10, 8);

      test('headers sit above the items of their receipt', () {
        final offers = offersOf(
          rest: [
            item('a', 'Apfel', receiptId: 'r1', receiptDate: first),
            item('b', 'Birne', receiptId: 'r2', receiptDate: second),
            item('c', 'Chili', receiptId: 'r1', receiptDate: first),
          ],
        );

        expect(rows(offers, preferences: grouped), [
          '#receipt:r2',
          'b',
          '#receipt:r1',
          'a',
          'c',
        ]);
      });

      test('items without a receipt form the no-receipt group, last', () {
        final offers = offersOf(
          rest: [
            item('a', 'Apfel'),
            item('b', 'Birne', receiptId: 'r1', receiptDate: first),
          ],
        );

        expect(rows(offers, preferences: grouped), [
          '#receipt:r1',
          'b',
          '#store:laden',
          'a',
        ]);
      });

      test('the matches stay on top, above every header', () {
        final offers = offersOf(
          matches: [item('m', 'Reis', receiptId: 'r1', receiptDate: first)],
          rest: [item('b', 'Birne', receiptId: 'r1', receiptDate: first)],
        );

        expect(rows(offers, preferences: grouped), ['m', '#receipt:r1', 'b']);
      });

      test('the sort mode orders the items inside a receipt', () {
        final offers = offersOf(
          rest: [
            item('a', 'Apfel', receiptId: 'r1', receiptDate: first),
            item('c', 'Chili', receiptId: 'r1', receiptDate: first),
          ],
        );

        expect(
          rows(
            offers,
            preferences: grouped.copyWith(
              sortMode: InventoryItemSortMode.alphabeticalDescending,
            ),
          ),
          ['#receipt:r1', 'c', 'a'],
        );
      });

      test('the search drops headers of receipts with no hit', () {
        final offers = offersOf(
          rest: [
            item('a', 'Apfel', receiptId: 'r1', receiptDate: first),
            item('b', 'Birne', receiptId: 'r2', receiptDate: second),
          ],
        );

        expect(rows(offers, preferences: grouped, query: 'birne'), [
          '#receipt:r2',
          'b',
        ]);
      });

      test('without the switch there are no headers', () {
        final offers = offersOf(
          rest: [item('a', 'Apfel', receiptId: 'r1', receiptDate: first)],
        );

        expect(rows(offers), ['a']);
      });
    });
  });
}
