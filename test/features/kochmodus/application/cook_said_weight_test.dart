import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/application/cook_said_weight.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';

import '../kochmodus_fixtures.dart';

CookRunLine _line(
  String id,
  String text, {
  Map<String, int> takes = const {'x': 10},
  int? weighed,
  LineSettlement? settlement,
}) => textLine(
  id,
  text,
  settlement: settlement ?? assigned(takes),
  weighed: weighed,
);

InventoryItem _item(String id, String name, {int amount = 500}) =>
    stockItem(id, amount).copyWith(name: name);

CookRunLine? _match(
  String name,
  List<CookRunLine> lines, {
  List<InventoryItem> items = const [],
  String locale = 'de',
}) =>
    cookLineForFood(name, lines: lines, items: byId(items), localeCode: locale);

void main() {
  group('parseCookSaidWeight', () {
    final cases = <String, ({int grams, String name})>{
      '30 g Öl': (grams: 30, name: 'Öl'),
      'Öl 30 g': (grams: 30, name: 'Öl'),
      'eine 400 g Dose Tomaten': (grams: 400, name: 'Tomaten'),
      'zwei 200 g Becher Schmand': (grams: 400, name: 'Schmand'),
      '30 Gramm Öl': (grams: 30, name: 'Öl'),
      '150 g Crème fraîche': (grams: 150, name: 'Crème fraîche'),
      '50 g Pâté': (grams: 50, name: 'Pâté'),
      'Öl 30 Gramm': (grams: 30, name: 'Öl'),
      '30g Öl': (grams: 30, name: 'Öl'),
      'Öl 30g': (grams: 30, name: 'Öl'),
      '50 ml Milch': (grams: 50, name: 'Milch'),
      'Milch 50 ml': (grams: 50, name: 'Milch'),
      '1,5 kg Mehl': (grams: 1500, name: 'Mehl'),
      'Mehl 1,5 kg': (grams: 1500, name: 'Mehl'),
      '0,5 l Milch': (grams: 500, name: 'Milch'),
      '2 kg Kartoffeln': (grams: 2000, name: 'Kartoffeln'),
      '30 grams oil': (grams: 30, name: 'oil'),
      'oil 30 g': (grams: 30, name: 'oil'),
      'rice 200 gram': (grams: 200, name: 'rice'),
      '200 g Reis': (grams: 200, name: 'Reis'),
      '1 Kilo Mehl': (grams: 1000, name: 'Mehl'),
      '2 Kilos Mehl': (grams: 2000, name: 'Mehl'),
      'Mehl 1 Kilo': (grams: 1000, name: 'Mehl'),
      'ein Kilo Mehl': (grams: 1000, name: 'Mehl'),
      'ein Liter Milch': (grams: 1000, name: 'Milch'),
      'Milch 500 Milliliter': (grams: 500, name: 'Milch'),
      '1 Pfund Hack': (grams: 500, name: 'Hack'),
      'ein Pfund Hack': (grams: 500, name: 'Hack'),
      'Hack 1 Pfund': (grams: 500, name: 'Hack'),
      '1,250 kg Mehl': (grams: 1250, name: 'Mehl'),
      '0,250 kg Hack': (grams: 250, name: 'Hack'),
      'Mehl 1,250 kg': (grams: 1250, name: 'Mehl'),
      '0,250 l Milch': (grams: 250, name: 'Milch'),
      '½ Liter Milch': (grams: 500, name: 'Milch'),
      'halbes Kilo Mehl': (grams: 500, name: 'Mehl'),
      '2 Dosen Tomaten à 400 g': (grams: 800, name: 'Tomaten'),
    };
    for (final MapEntry(key: said, value: expected) in cases.entries) {
      test('"$said"', () {
        expect(parseCookSaidWeight(said), expected);
      });
    }

    test('"oil 30 grams" (English plural after the food)', () {
      expect(parseCookSaidWeight('oil 30 grams'), (grams: 30, name: 'oil'));
    });

    final none = [
      'Salz',
      '2 EL Öl',
      '2 Zwiebeln',
      '30 g',
      '2 Dosen Tomaten 400 g',
      '',
      '   ',
    ];
    for (final said in none) {
      test('"$said" names no weight of a food', () {
        expect(parseCookSaidWeight(said), isNull);
      });
    }
  });

  group('cookLineForFood', () {
    test('matches the food of a line by name', () {
      final oil = _line('oil', 'Öl');
      final rice = _line('rice', '200 g Reis');

      expect(_match('Öl', [rice, oil]), same(oil));
      expect(_match('Reis', [rice, oil]), same(rice));
    });

    test('matches a line with an amount and a unit', () {
      final oil = _line('oil', '2 EL Öl');

      expect(_match('Öl', [oil]), same(oil));
    });

    test('matches the end of a compound, not the other way round', () {
      final olive = _line('olive', 'Olivenöl');
      final plain = _line('plain', 'Öl');

      expect(_match('Öl', [olive]), same(olive));
      expect(_match('Olivenöl', [plain]), isNull);
    });

    test('matches by the name of the item the line takes from', () {
      final line = _line('oil', 'Öl', takes: {'rapeseed': 20});
      final other = _line('rice', '200 g Reis', takes: {'rice': 200});

      final found = _match(
        'Rapsöl',
        [other, line],
        items: [_item('rapeseed', 'Rapsöl'), _item('rice', 'Reis')],
      );

      expect(found, same(line));
    });

    test('matches a plural and a singular', () {
      final onions = _line('onions', '2 Zwiebeln');

      expect(_match('Zwiebel', [onions]), same(onions));
      expect(_match('Zwiebeln', [onions]), same(onions));
    });

    test('the best score wins over the first line', () {
      final olive = _line('olive', 'Olivenöl');
      final exact = _line('exact', 'Öl');

      expect(_match('Öl', [olive, exact]), same(exact));
    });

    test('a tie goes to the first line still to weigh', () {
      final weighed = _line('a', 'Öl', weighed: 20);
      final open = _line('b', 'Öl');

      // The item of the open line is gone from the Vorrat: weight missing.
      expect(_match('Öl', [weighed, open]), same(open));
    });

    test('a tie of lines all weighed goes to the first line', () {
      final first = _line('a', 'Öl', weighed: 20);
      final second = _line('b', 'Öl', weighed: 30);

      expect(_match('Öl', [first, second]), same(first));
    });

    test('a tie of lines all to weigh goes to the first line', () {
      final first = _line('a', 'Öl');
      final second = _line('b', 'Öl');

      expect(_match('Öl', [first, second]), same(first));
    });

    test('ignored, shopping and open lines never match', () {
      final lines = [
        _line('ignored', 'Öl', settlement: const LineIgnored()),
        _line('shop', 'Öl', settlement: const LineShopping()),
        _line('open', 'Öl', settlement: const LineOpen()),
      ];

      expect(_match('Öl', lines), isNull);
    });

    group('a typo of the food', () {
      test('finds its line', () {
        final corn = _line('corn', '140 g Mais (halbe Dose)');
        final beans = _line('beans', '1 Dose Kidneybohnen');

        expect(_match('meis', [beans, corn]), same(corn));
        expect(_match('Kidneybohen', [corn, beans]), same(beans));
        expect(_match('Kidneybohnenn', [corn, beans]), same(beans));
      });

      test('loses to a line that is the food itself', () {
        final corn = _line('corn', 'Mais');
        final rice = _line('rice', 'Reis');

        expect(_match('Reis', [corn, rice]), same(rice));
      });

      test('not in a short word, nor in its first letter', () {
        final ice = _line('ice', 'Eis');
        final rice = _line('rice', 'Reis');
        final corn = _line('corn', 'Mais');

        expect(_match('Reis', [ice]), isNull);
        expect(_match('Eis', [rice]), isNull);
        expect(_match('Gais', [corn]), isNull);
        expect(_match('Mus', [corn]), isNull);
      });
    });

    test('a weak match does not count', () {
      final waffles = _line('waffles', 'Reiswaffeln');

      expect(_match('Reis', [waffles]), isNull);
    });

    group('the said food must be the food of the line', () {
      test('not a word inside another one', () {
        final pork = _line('pork', '500 g Schweinefilet');
        final rice = _line('rice', '200 g Reis');
        final mince = _line('mince', '500 g Hackfleisch');

        expect(_match('Wein', [pork]), isNull);
        expect(_match('Ei', [rice, mince]), isNull);
        expect(_match('Eier', [rice, mince]), isNull);
      });

      test('nor inside the name of its item', () {
        final line = _line('meat', 'Fleisch', takes: {'pork': 500});
        final pork = _item('pork', 'Schweinefilet');

        expect(_match('Wein', [line], items: [pork]), isNull);
      });

      test('nor the name of an item that waits with 0 next to a take', () {
        final line = _line('rice', '200 g Reis', takes: {'a': 200, 'b': 0});
        final items = [_item('a', 'Reis A'), _item('b', 'Nudeln')];

        expect(_match('Nudeln', [line], items: items), isNull);
      });

      test('the name of an item with 0 counts when nothing takes more', () {
        final line = _line('oil', '1 EL Öl', takes: {'a': 0});

        expect(
          _match('Rapsöl', [line], items: [_item('a', 'Rapsöl')]),
          same(line),
        );
      });

      test('not the singular of a longer word', () {
        final rice = _line('rice', '200 g Basmatireis');
        final wine = _line('wine', '100 ml Weißwein');

        expect(_match('Ei', [rice, wine]), isNull);
        expect(_match('Eier', [rice, wine]), isNull);
      });

      test('nor the word after an accent', () {
        final chicken = _line('chicken', '500 g Hähnchen');
        final cherries = _line('cherries', '300 g Kirschen');

        expect(_match('Crème fraîche', [chicken, cherries]), isNull);
      });

      test('nor pork in any compound for wine', () {
        final pork = _line('pork', '500 g Bio-Schweinefilet');

        expect(_match('Wein', [pork]), isNull);
        expect(_match('Wein', [_line('a', '500 g Schwein')]), isNull);
      });

      test('the end of a compound counts, also by chance', () {
        final garlic = _line('garlic', '2 Zehen Knoblauch');

        expect(_match('Lauch', [garlic]), same(garlic));
      });

      test('a plural and a singular still count', () {
        final tomato = _line('tomato', '2 Kirschtomaten');
        final eggs = _line('eggs', '2 Eier');
        final mushrooms = _line('mushrooms', '200 g Pilze');

        expect(_match('Tomate', [tomato]), same(tomato));
        expect(_match('Tomaten', [tomato]), same(tomato));
        expect(_match('Ei', [eggs]), same(eggs));
        expect(_match('Eier', [eggs]), same(eggs));
        expect(_match('Pilz', [mushrooms]), same(mushrooms));
        expect(_match('Apfel', [_line('a', '2 Äpfel')]), isNotNull);
      });

      test('a word for an amount behind the food still counts', () {
        final garlic = _line('garlic', '4 Knoblauchzehen');
        final tomatoes = _line('tomatoes', '400 g Tomatenstücke');

        expect(_match('Knoblauch', [garlic]), same(garlic));
        expect(_match('Tomaten', [tomatoes]), same(tomatoes));
        expect(_match('Knoblauchzehen', [_line('a', 'Knoblauch')]), isNotNull);
      });

      test('the last word of a food said in two counts', () {
        final onion = _line('onion', '2 Zwiebeln');

        expect(_match('rote Zwiebel', [onion]), same(onion));
        expect(_match('Zwiebel rot', [onion]), isNull);
      });

      test('an alias counts', () {
        final carrot = _line('carrot', '2 Möhren');

        expect(_match('Karotte', [carrot]), same(carrot));
        expect(_match('Möhre', [carrot]), same(carrot));
      });
    });

    group('a bundled line reads up to its first comma or "oder"', () {
      test('another food of the bundle gets no weight', () {
        final oil = _line('oil', '1 EL Öl, Salz, Pfeffer', takes: {'oil': 0});
        final items = [_item('oil', 'Rapsöl')];

        expect(_match('Salz', [oil], items: items), isNull);
        expect(_match('Pfeffer', [oil], items: items), isNull);
        expect(_match('Öl', [oil], items: items), same(oil));
        expect(_match('Rapsöl', [oil], items: items), same(oil));
      });

      test('nor does the food behind "oder"', () {
        final maggi = _line(
          'maggi',
          'Maggi oder Sojasoße, 1 TL Paprikapulver',
          takes: {'maggi': 0},
        );
        final items = [_item('maggi', 'Maggi')];

        expect(_match('Paprikapulver', [maggi], items: items), isNull);
        expect(_match('Sojasoße', [maggi], items: items), isNull);
        expect(_match('Maggi', [maggi], items: items), same(maggi));
      });

      test('nor the food behind "und"', () {
        final salt = _line('salt', 'Salz und Pfeffer');

        expect(_match('Pfeffer', [salt]), isNull);
        expect(_match('Salz', [salt]), same(salt));
      });

      test('a decimal comma is no bundle', () {
        final flour = _line('flour', '1,5 cups Mehl');

        expect(_match('Mehl', [flour]), same(flour));
      });
    });

    group('a short everyday name counts for the long one', () {
      test('on the line', () {
        final mince = _line('mince', '500 g Hackfleisch');
        final breast = _line('breast', '300 g Hähnchenbrust');

        expect(_match('Hack', [mince]), same(mince));
        expect(_match('Hähnchen', [breast]), same(breast));
      });

      test('on the item', () {
        final line = _line('meat', '500 g Fleisch', takes: {'mince': 500});
        final fillet = _line('fillet', 'Fleisch', takes: {'fillet': 500});

        expect(
          _match(
            'Hack',
            [line],
            items: [_item('mince', 'Hackfleisch gemischt')],
          ),
          same(line),
        );
        expect(
          _match(
            'Hähnchen',
            [fillet],
            items: [_item('fillet', 'Hähnchenbrustfilet')],
          ),
          same(fillet),
        );
      });

      test('with a link and for each part of the same food', () {
        expect(_match('Pute', [_line('a', 'Putenbrust')]), isNotNull);
        expect(_match('Schwein', [_line('a', 'Schweinefilet')]), isNotNull);
        expect(_match('Hähnchen', [_line('a', 'Hähnchenkeulen')]), isNotNull);
        expect(_match('Hähnchen', [_line('a', 'Hähnchenschenkel')]), isNotNull);
        expect(_match('Chili', [_line('a', '2 Chilischoten')]), isNotNull);
      });

      test('also behind another word for the meat', () {
        final mince = _line('mince', '500 g Rinderhackfleisch');
        final breast = _line('breast', '300 g Bio-Hähnchenbrust');
        final corn = _line('corn', '300 g Maishähnchenbrust');

        expect(_match('Hack', [mince]), same(mince));
        expect(_match('Hähnchen', [breast]), same(breast));
        expect(_match('Hähnchen', [corn]), same(corn));
      });

      test('also behind another word on the item', () {
        final line = _line('meat', '500 g Fleisch', takes: {'mince': 500});

        expect(
          _match(
            'Hack',
            [line],
            items: [_item('mince', 'Schweinehackfleisch')],
          ),
          same(line),
        );
      });

      test('also said the long way on a line named the short way', () {
        final mince = _line('mince', '500 g Hack');

        expect(_match('Hackfleisch', [mince]), same(mince));
      });

      test('but not for another part of the animal', () {
        final leg = _line('leg', 'Hähnchenkeule');

        expect(_match('Hähnchenbrust', [leg]), isNull);
      });
    });

    group('a food with accents is the same food without them', () {
      test('said on the line', () {
        final cream = _line('cream', '200 g Crème fraîche');

        expect(_match('Creme fraiche', [cream]), same(cream));
        expect(_match('Crème fraîche', [cream]), same(cream));
      });

      test('on the line without them', () {
        final cream = _line('cream', '200 g Creme fraiche');

        expect(_match('Crème fraîche', [cream]), same(cream));
      });

      test('said on the item', () {
        final line = _line('dairy', '200 g Schmand', takes: {'cream': 200});
        final items = [_item('cream', 'Crème fraîche')];

        expect(_match('Creme fraiche', [line], items: items), same(line));
      });
    });

    test('a name no line has gives no line', () {
      expect(_match('Zucker', [_line('oil', 'Öl')]), isNull);
      expect(_match('Öl', const []), isNull);
    });
  });
}
