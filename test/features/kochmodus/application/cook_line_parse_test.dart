import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/application/cook_line_amount.dart';
import 'package:yamt/features/kochmodus/application/cook_line_parse.dart';
import 'package:yamt/features/kochmodus/application/cook_recipe_line.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_view_builder.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';

const _parser = TemplateIngredientParser();

// The view of [line] in a run of [portions] of the 4 the recipe is for.
KochmodusLineView _view(
  CookRunLine line, {
  int portions = 4,
  List<InventoryItem> items = const [],
}) => buildKochmodusView(
  run: buildCookRun(portions: portions, lines: [line]),
  saved: true,
  ended: false,
  busy: false,
  reopened: false,
  finished: null,
  tab: null,
  items: items,
  otherReservations: const {},
  utensils: const [],
  parser: _parser,
).lines.single;

// What [line] takes from [items] once they are assigned to it.
Map<String, int> _takes(
  CookRunLine line, {
  required List<InventoryItem> items,
  int portions = 4,
}) {
  final run = refillKochmodusTakes(
    buildCookRun(portions: portions, lines: [line]),
    line.id,
    [for (final item in items) item.id],
    items: items,
    otherReservations: const {},
    parser: _parser,
  );
  return {
    for (final take in (run.lineOf(line.id)!.settlement as LineAssigned).takes)
      take.itemId: take.amount,
  };
}

CookRunLine _typed(String text, {int? amount, int? amountPortions}) => textLine(
  'l',
  text,
  origin: CookLineOrigin.added,
  amount: amount,
  amountPortions: amountPortions,
);

const _perPiece100g = CookLineConversion(
  amountPerPiece: 100,
  unit: TemplateIngredientUnit.gram,
);

final InventoryItem _pieces = stockItem(
  'piece',
  5000,
  unit: InventoryAmountUnit.piece,
  scale: 1000,
);
final InventoryItem _grams = stockItem('g', 5000);

void main() {
  group('a line the cook typed or said counts as written', () {
    for (final origin in [CookLineOrigin.added, CookLineOrigin.cooking]) {
      test('$origin at fewer portions', () {
        final line = textLine('l', '100 g Feta', origin: origin);
        expect(_view(line, portions: 2).text, '100 g Feta');
        expect(_takes(line, portions: 2, items: [_grams]), {'g': 100});
      });

      test('$origin at more portions', () {
        final line = textLine('l', '2 Zwiebeln', origin: origin);
        expect(_view(line, portions: 8).text, '2 Zwiebeln');
        expect(_takes(line, portions: 8, items: [_pieces]), {'piece': 2000});
      });
    }

    test('whatever the portions do later, its own amount stays', () {
      final line = _typed('100 g Feta', amount: 150, amountPortions: 4);
      expect(_view(line, portions: 8).text, '150 g Feta');
      expect(_takes(line, portions: 8, items: [_grams]), {'g': 150});
    });

    test('the amount sheet offers what was typed as its "Rezept"', () {
      expect(_view(_typed('100 g Feta'), portions: 8).parsed?.amount, 100);
    });

    test('a recipe line still scales', () {
      final line = textLine('l', '100 g Feta');
      expect(_view(line, portions: 2).text, '50 g Feta');
      expect(_takes(line, portions: 2, items: [_grams]), {'g': 50});
    });

    test('takes nothing is read at the amount as written', () {
      // 1 at 1 of 4 used to round to nothing for a typed line.
      final line = textLine(
        'l',
        '1 Möhre',
        origin: CookLineOrigin.added,
        settlement: assigned({'g': 0}),
      );
      expect(
        cookLineTakesNothing(buildCookRun(portions: 1, lines: [line]), line),
        isTrue,
      );
    });
  });

  group('a line is read in the words people say', () {
    // The amount and name the line is read as, at the recipe's portions.
    final reads = <String, (int, TemplateIngredientUnit, String)>{
      'eine Zwiebel': (1, TemplateIngredientUnit.piece, 'Zwiebel'),
      'Eine Zwiebel': (1, TemplateIngredientUnit.piece, 'Zwiebel'),
      'ein Ei': (1, TemplateIngredientUnit.piece, 'Ei'),
      'einen Apfel': (1, TemplateIngredientUnit.piece, 'Apfel'),
      'einem Apfel': (1, TemplateIngredientUnit.piece, 'Apfel'),
      'einer Zitrone': (1, TemplateIngredientUnit.piece, 'Zitrone'),
      'zwei Eier': (2, TemplateIngredientUnit.piece, 'Eier'),
      'Zwölf Eier': (12, TemplateIngredientUnit.piece, 'Eier'),
      'ein Liter Milch': (1000, TemplateIngredientUnit.milliliter, 'Milch'),
      '1 Kilo Mehl': (1000, TemplateIngredientUnit.gram, 'Mehl'),
      '2 Kilos Mehl': (2000, TemplateIngredientUnit.gram, 'Mehl'),
      'Mehl 2 Kilo': (2000, TemplateIngredientUnit.gram, 'Mehl'),
      '500 Milliliter Milch': (500, TemplateIngredientUnit.milliliter, 'Milch'),
      'Milch 500 Milliliter': (500, TemplateIngredientUnit.milliliter, 'Milch'),
      '1 Pfund Hack': (500, TemplateIngredientUnit.gram, 'Hack'),
      'ein Pfund Hack': (500, TemplateIngredientUnit.gram, 'Hack'),
      '1/2 Pfund Butter': (250, TemplateIngredientUnit.gram, 'Butter'),
      '1,5 Pfund Hack': (750, TemplateIngredientUnit.gram, 'Hack'),
      'Hack 1 Pfund': (500, TemplateIngredientUnit.gram, 'Hack'),
      '2 Liter Wasser': (2000, TemplateIngredientUnit.milliliter, 'Wasser'),
      '¼ l Milch': (250, TemplateIngredientUnit.milliliter, 'Milch'),
      'Milch ½ l': (500, TemplateIngredientUnit.milliliter, 'Milch'),
      'Öl, 30 g': (30, TemplateIngredientUnit.gram, 'Öl'),
      'Öl, 30': (30, TemplateIngredientUnit.gram, 'Öl'),
      'Öl, 2 EL': (2, TemplateIngredientUnit.piece, 'Öl'),
      '½ Liter Milch': (500, TemplateIngredientUnit.milliliter, 'Milch'),
      '1½ kg Mehl': (1500, TemplateIngredientUnit.gram, 'Mehl'),
      '1,250 kg Mehl': (1250, TemplateIngredientUnit.gram, 'Mehl'),
      '1.250 kg Mehl': (1250, TemplateIngredientUnit.gram, 'Mehl'),
      '0,250 kg Hack': (250, TemplateIngredientUnit.gram, 'Hack'),
      '0,250 l Milch': (250, TemplateIngredientUnit.milliliter, 'Milch'),
      'Mehl 1,250 kg': (1250, TemplateIngredientUnit.gram, 'Mehl'),
      '1,250 Kilo Mehl': (1250, TemplateIngredientUnit.gram, 'Mehl'),
      '1,250 g Mehl': (1250, TemplateIngredientUnit.gram, 'Mehl'),
    };
    for (final MapEntry(key: text, value: (amount, unit, name))
        in reads.entries) {
      test('"$text"', () {
        final need = _view(textLine('l', text)).need;
        expect((need?.amount, need?.unit, need?.name), (amount, unit, name));
      });
    }

    final halves = {
      'halbe Zitrone': '1/2 Zitrone',
      'eine halbe Zitrone': '1/2 Zitrone',
      'Eine halbe Zitrone': '1/2 Zitrone',
      'ein halbes Kilo Mehl': '500 g Mehl',
      'einen halben Liter Milch': '500 ml Milch',
      '½ Zwiebel': '1/2 Zwiebel',
      '¾ Zwiebel': '3/4 Zwiebel',
      '¼ Zwiebel': '1/4 Zwiebel',
    };
    for (final MapEntry(key: text, value: shown) in halves.entries) {
      test('"$text" shows "$shown"', () {
        expect(_view(textLine('l', text)).text, shown);
      });
    }

    for (final vague in [
      'ein paar Tomaten',
      'ein wenig Öl',
      'ein bisschen Salz',
      'ein kleines bisschen Salz',
      'etwas Öl',
      'Saft einer Zitrone',
      'nach Geschmack',
      'Salz',
      'Einkorn Mehl',
      'Halbfettmargarine',
    ]) {
      test('"$vague" names no amount it could read', () {
        final view = _view(textLine('l', vague));
        expect(view.need, isNull);
        expect(view.text, vague);
      });
    }

    test(
      'a word ahead of a size counts packs of it, it merges with nothing',
      () {
        final reads = {
          'eine 400 g Dose Tomaten': (400, 'g', 'Tomaten'),
          'zwei 200 g Becher Schmand': (400, 'g', 'Schmand'),
          'eine 0,5 l Flasche Öl': (500, 'ml', 'Flasche Öl'),
          'eine 400-g-Dose Tomaten': (400, 'g', 'Tomaten'),
          'zwei 400-g-Dosen Tomaten': (800, 'g', 'Tomaten'),
          'eine halbe 400 g Dose Tomaten': (200, 'g', 'Tomaten'),
          'eine 1,250 kg Packung Mehl': (1250, 'g', 'Mehl'),
          '2 200 g Becher Schmand': (400, 'g', 'Schmand'),
          '1 400 g Dose Tomaten': (400, 'g', 'Tomaten'),
          '2 400-g-Dosen Tomaten': (800, 'g', 'Tomaten'),
        };
        for (final MapEntry(key: text, value: (amount, unit, name))
            in reads.entries) {
          final view = _view(textLine('l', text));
          expect(
            (view.need?.amount, view.need?.unit.code, view.need?.name),
            (amount, unit, name),
            reason: text,
          );
          expect(view.text, '$amount $unit $name', reason: text);
        }
      },
    );

    test('such a size scales with the portions and takes that much', () {
      final line = textLine('l', 'zwei 200 g Becher Schmand');
      expect(_view(line, portions: 2).text, '200 g Schmand');
      expect(_takes(line, portions: 2, items: [_grams]), {'g': 200});
      final typed = textLine(
        'l',
        'eine 400 g Dose Tomaten',
        origin: CookLineOrigin.cooking,
      );
      expect(_takes(typed, portions: 2, items: [_grams]), {'g': 400});
    });

    test('a number with a space stays a number without a pack behind it', () {
      expect(_view(textLine('l', '1 400 g Mehl')).text, '1400 g Mehl');
    });

    test('reading leaves the stored text as it is', () {
      final line = textLine('l', 'eine halbe Zitrone');
      expect(_view(line).line.text, 'eine halbe Zitrone');
    });

    test('a word for an amount scales with the portions', () {
      final line = textLine('l', 'zwei Eier');
      expect(_view(line, portions: 8).text, '4 Eier');
    });
  });

  group('fractions and small amounts', () {
    test('"1/2 Zitrone" on an item counted in pieces takes half a piece', () {
      final line = textLine('l', '1/2 Zitrone');
      expect(_view(line).text, '1/2 Zitrone');
      expect(_takes(line, items: [_pieces]), {'piece': 500});
    });

    test('"1 Zwiebel" at 1 of 4 portions takes a quarter of a piece', () {
      final line = textLine('l', '1 Zwiebel');
      expect(_view(line, portions: 1).text, '1/4 Zwiebel');
      expect(_takes(line, portions: 1, items: [_pieces]), {'piece': 250});
    });

    test('a gram item with a piece weight takes that part of the weight', () {
      final line = textLine('l', '1/2 Zwiebel', conversion: _perPiece100g);
      expect(_takes(line, items: [_grams]), {'g': 50});
      final quarter = textLine('l', '1 Zwiebel', conversion: _perPiece100g);
      expect(_takes(quarter, portions: 1, items: [_grams]), {'g': 25});
    });

    test('an item counted whole takes at least 1, and the row says so', () {
      final line = textLine('l', '1/2 Zitrone', settlement: assigned({'w': 1}));
      final item = packItem('w', 5);
      expect(_takes(line, items: [item]), {'w': 1});
      expect(_view(line, items: [item]).text, '1 Zitrone');
    });

    test('an item counted whole rounds 1,5 up, as the row says', () {
      final line = textLine(
        'l',
        '1,5 Zwiebeln',
        settlement: assigned({'w': 2}),
      );
      final item = packItem('w', 5);
      expect(_takes(line, items: [item]), {'w': 2});
      expect(_view(line, items: [item]).text, '2 Zwiebeln');
    });

    test('a spoon measure shows and takes the exact amount', () {
      final line = textLine(
        'l',
        '1,5 EL Öl',
        conversion: const CookLineConversion(
          amountPerPiece: 10,
          unit: TemplateIngredientUnit.gram,
        ),
      );
      expect(_view(line).text, '1,5 EL Öl');
      expect(_takes(line, items: [_grams]), {'g': 15});
    });

    test('a spoon measure at 1 of 4 portions still names its amount', () {
      final line = textLine('l', '1 EL Öl', settlement: assigned({'g': 0}));
      expect(_view(line, portions: 1, items: [_grams]).text, '1/4 EL Öl');
      expect(
        cookLineTakesNothing(buildCookRun(portions: 1, lines: [line]), line),
        isTrue,
      );
    });

    test('a weight below 1 g reads as 1 g', () {
      final line = textLine('l', '1 g Safran');
      expect(_view(line, portions: 1).text, '1 g Safran');
      expect(_takes(line, portions: 1, items: [_grams]), {'g': 1});
    });

    test('whole amounts stay whole', () {
      expect(_view(textLine('l', '2 Zwiebeln')).text, '2 Zwiebeln');
      expect(_view(textLine('l', '2 EL Öl')).text, '2 EL Öl');
    });

    test('a third shows as a fraction and takes its exact part', () {
      final line = textLine('l', '1/3 Zwiebel');
      expect(_view(line).text, '1/3 Zwiebel');
      expect(_takes(line, items: [_pieces]), {'piece': 333});
    });

    test('the cook amount at fewer portions takes the exact part too', () {
      final line = textLine('l', '1 Zwiebel', amount: 3, amountPortions: 4);
      expect(_view(line, portions: 2).text, '1,5 Zwiebel');
      expect(_takes(line, portions: 2, items: [_pieces]), {'piece': 1500});
    });
  });

  group('what waits', () {
    final run = buildCookRun();

    bool waits(String text) => cookLineTakesNothing(
      run,
      textLine('l', text, settlement: assigned({'g': 0})),
    );

    for (final counted in [
      '2 Tassen Reis',
      '1 Becher Sahne',
      '2 cups Mehl',
      'eine Tasse Reis',
      'eine Dose Tomaten',
      'ein Löffel Öl',
      '½ Zwiebel',
      'halbe Zwiebel',
    ]) {
      test('"$counted" waits', () => expect(waits(counted), isTrue));
    }

    for (final pinch in [
      '1 Prise Salz',
      '2 Prisen Salz',
      'eine Prise Salz',
      'zwei Prisen Salz',
      '1 Messerspitze Zimt',
      'eine Messerspitze Zimt',
      '1 Msp Zimt',
      '1 Msp. Zimt',
      '2 Spritzer Zitrone',
      '1 Schuss Milch',
      'ein Schuss Milch',
      '3 Tropfen Öl',
    ]) {
      test('"$pinch" takes nothing on purpose', () {
        expect(waits(pinch), isFalse);
      });
    }

    for (final pinch in [
      'ein guter Schuss Öl',
      'eine große Prise Zucker',
      '1 kräftige Prise Salz',
      '1 Schuß Milch',
    ]) {
      test('"$pinch" takes nothing on purpose', () {
        expect(waits(pinch), isFalse);
        final line = textLine('l', pinch);
        expect(_takes(line, items: [_pieces]), {'piece': 0});
        expect(_takes(line, items: [_grams]), {'g': 0});
      });
    }

    for (final none in [
      'Salz',
      'etwas Öl',
      'Saft einer Zitrone',
      'nach Geschmack',
      'ein paar Tomaten',
      'Saft von 2 Zitronen',
    ]) {
      test('"$none" takes nothing on purpose', () {
        expect(waits(none), isFalse);
      });
    }

    test('a pinch that names a piece count takes nothing from pieces', () {
      expect(_takes(textLine('l', '1 Msp Zimt'), items: [_pieces]), {
        'piece': 0,
      });
    });
  });

  group('a scoop out of a pack', () {
    // [line] once [items] are assigned to it, through the real refill.
    CookRunLine filled(CookRunLine line, List<InventoryItem> items) {
      final run = refillKochmodusTakes(
        buildCookRun(lines: [line]),
        line.id,
        [for (final item in items) item.id],
        items: items,
        otherReservations: const {},
        parser: _parser,
      );
      return run.lineOf(line.id)!;
    }

    bool waitsOn(CookRunLine line) =>
        cookLineTakesNothing(buildCookRun(lines: [line]), line);

    for (final scoop in [
      '2 Tassen Reis',
      'eine Tasse Reis',
      'ein Löffel Öl',
      'eine Handvoll Nüsse',
      '2 Hand voll Nüsse',
      '2 große Tassen Reis',
    ]) {
      test('"$scoop" takes no whole pack, it waits', () {
        for (final item in [_pieces, packItem('w', 5), _grams]) {
          final line = filled(textLine('l', scoop), [item]);
          expect(
            (line.settlement as LineAssigned).takes.single.amount,
            0,
            reason: item.id,
          );
          expect(waitsOn(line), isTrue, reason: item.id);
        }
      });
    }

    for (final (spoons, grams) in [
      ('2 Eßlöffel Zucker', 30),
      ('1 gehäufter EL Mehl', 15),
    ]) {
      test('"$spoons" takes $grams g from a food kept in grams', () {
        final line = filled(textLine('l', spoons), [_grams]);

        expect((line.settlement as LineAssigned).takes.single.amount, grams);
        expect(waitsOn(line), isFalse);
      });

      test('"$spoons" still takes no whole pack or piece', () {
        for (final item in [_pieces, packItem('w', 5)]) {
          final line = filled(textLine('l', spoons), [item]);

          expect(
            (line.settlement as LineAssigned).takes.single.amount,
            0,
            reason: item.id,
          );
          expect(waitsOn(line), isTrue, reason: item.id);
        }
      });
    }

    test('it shows its measure and scales with the portions', () {
      final line = textLine('l', '2 Tassen Reis');
      expect(_view(line).text, '2 Tassen Reis');
      expect(_view(line).need?.name, 'Reis');
      expect(_view(line, portions: 8).text, '4 Tassen Reis');
    });

    test('a piece weight of the recipe says what it takes', () {
      final line = textLine('l', '2 Tassen Reis', conversion: _perPiece100g);
      expect(_takes(line, items: [_grams]), {'g': 200});
    });

    test('a size in the line says what it takes', () {
      final line = textLine('l', '2 Tassen Reis (400 g)');
      expect(_view(line).text, '400 g Reis');
      expect(_takes(line, items: [_grams]), {'g': 400});
    });

    test('the cook can type it while it waits, the unit stays the measure', () {
      final line = textLine('l', '2 Tassen Reis', amount: 3);
      expect(_view(line).text, '3 Tassen Reis');
      expect(_takes(line, items: [_pieces]), {'piece': 0});
    });

    for (final (text, whole) in [
      ('1 Becher Sahne', 1),
      ('1 Dose Tomaten', 1),
      ('2 Löffelbiskuits', 2),
      ('2 Zwiebeln', 2),
    ]) {
      test('"$text" names what the stock counts, it takes that', () {
        final line = filled(textLine('l', text), [packItem('w', 5)]);
        expect((line.settlement as LineAssigned).takes.single.amount, whole);
        expect(waitsOn(line), isFalse);
      });
    }
  });

  group('packs of a size', () {
    final totals = {
      '2 Dosen Tomaten (à 400 g)': (800, 'Tomaten'),
      '2 Dose/n Tomaten (à 400 g)': (800, 'Tomaten'),
      '2 Dosen Tomaten à 400 g': (800, 'Tomaten'),
      '2 Dosen Tomaten je 400 g': (800, 'Tomaten'),
      '2 Dosen Tomaten, je 400 g': (800, 'Tomaten'),
      'zwei Dosen Tomaten (à 400 g)': (800, 'Tomaten'),
      '2 Dosen Tomaten (800 g)': (800, 'Tomaten'),
      '1 Dose Tomaten (400 g)': (400, 'Tomaten'),
    };
    for (final MapEntry(key: text, value: (amount, name)) in totals.entries) {
      test('"$text" shows the plain total', () {
        final view = _view(textLine('l', text));
        expect(view.text, '$amount g $name');
        expect(_takes(textLine('l', text), items: [_grams]), {'g': amount});
      });
    }

    test('the total scales with the portions, without "2x"', () {
      final perPack = textLine('l', '2 Dosen Tomaten (à 400 g)');
      expect(_view(perPack, portions: 8).text, '1600 g Tomaten');
      expect(_takes(perPack, portions: 8, items: [_grams]), {'g': 1600});
      final total = textLine('l', '1 Dose Tomaten (400 g)');
      expect(_view(total, portions: 8).text, '800 g Tomaten');
    });
  });

  group('a line without an amount on an item counted in pieces', () {
    final eggs = stockItem(
      'egg',
      6000,
      unit: InventoryAmountUnit.piece,
      scale: 1000,
    );

    CookRunLine own({int? amount, String item = 'egg'}) =>
        textLine('l', 'Eier', amount: amount, settlement: assigned({item: 0}));

    CookRunLine typedPieces(LineSettlement settlement) => textLine(
      'l',
      'Eier',
      amount: 3,
      amountUnit: TemplateIngredientUnit.piece,
      settlement: settlement,
    );

    test('the cook amount counts in pieces', () {
      final view = _view(own(amount: 3), items: [eggs]);
      expect(view.need?.unit, TemplateIngredientUnit.piece);
      expect(view.text, '3 Eier');
      expect(_takes(own(amount: 3), items: [eggs]), {'egg': 3000});
    });

    test('and so on an item counted whole', () {
      final item = packItem('egg', 6);
      expect(_takes(own(amount: 3), items: [item]), {'egg': 3});
    });

    test('it does not wait then', () {
      final run = refillKochmodusTakes(
        buildCookRun(lines: [own(amount: 3)]),
        'l',
        ['egg'],
        items: [eggs],
        otherReservations: const {},
        parser: _parser,
      );
      expect(cookLineTakesNothing(run, run.lineOf('l')!), isFalse);
    });

    test('"Vorhandenes" counts in pieces', () {
      expect(_view(own(), items: [eggs]).availableForLine, 6);
    });

    test('its pieces stay pieces when the line leaves its item', () {
      for (final settlement in const <LineSettlement>[
        LineShopping(),
        LineOpen(),
      ]) {
        final view = _view(typedPieces(settlement));
        expect(view.need?.unit, TemplateIngredientUnit.piece);
        expect(view.text, '3 Eier');
      }
    });

    test('its pieces stay pieces when the item is gone', () {
      final view = _view(typedPieces(assigned({'gone': 3000})));
      expect(view.need?.unit, TemplateIngredientUnit.piece);
      expect(view.text, '3 Eier');
    });

    test(
      'its pieces do not turn into grams on another item, the line waits',
      () {
        final line = typedPieces(assigned({'egg': 3000}));
        final run = refillKochmodusTakes(
          buildCookRun(lines: [line]),
          'l',
          ['g'],
          items: [_grams],
          otherReservations: const {},
          parser: _parser,
        );
        final moved = run.lineOf('l')!;
        expect(moved.settlement, assigned({'g': 0}));
        expect(cookLineTakesNothing(run, moved), isTrue);
        expect(_view(moved, items: [_grams]).text, '3 Eier');
      },
    );

    test('its grams do not turn into pieces on another item', () {
      final line = textLine(
        'l',
        'Reis',
        amount: 200,
        amountUnit: TemplateIngredientUnit.gram,
        settlement: assigned({'g': 200}),
      );
      expect(_takes(line, items: [_pieces]), {'piece': 0});
    });

    test('an item kept in ml counts ml', () {
      final milk = stockItem('m', 500, unit: InventoryAmountUnit.milliliter);
      final line = textLine(
        'l',
        'Milch',
        amount: 200,
        settlement: assigned({'m': 0}),
      );
      final view = _view(line, items: [milk]);
      expect(view.need?.unit, TemplateIngredientUnit.milliliter);
      expect(view.text, '200 ml Milch');
    });

    test('an item kept in grams still counts grams', () {
      final line = textLine(
        'l',
        'Reis',
        amount: 200,
        settlement: assigned({'g': 0}),
      );
      expect(_view(line, items: [_grams]).text, '200 g Reis');
    });
  });

  test('the free run reads at its own portions', () {
    final run = freeRun([textLine('l', '1/2 Zitrone')]);
    expect(run.kind, CookRunKind.free);
    expect(cookRecipeLineText(run, run.lines.single, const {}), '1/2 Zitrone');
  });

  group('cookLineTextParts', () {
    const parts = <(String, String?, String)>[
      ('1000 ml Milch', '1000 ml', 'Milch'),
      ('1/2 Zitrone', '1/2', 'Zitrone'),
      ('1 Prise Salz', '1 Prise', 'Salz'),
      ('Salz', null, 'Salz'),
      (
        '100 g Frischkäse (Doppelrahmstufe)',
        '100 g',
        'Frischkäse (Doppelrahmstufe)',
      ),
      ('2 Zwiebeln, fein gewürfelt', '2', 'Zwiebeln, fein gewürfelt'),
      ('etwas Öl', 'etwas', 'Öl'),
      // The food comes first: no amount to split off.
      ('Butter 100 g', null, 'Butter 100 g'),
    ];
    for (final (text, amount, food) in parts) {
      test('"$text" is ${amount ?? 'no amount'} and "$food"', () {
        final result = cookLineTextParts(text);

        expect(result.amount, amount);
        expect(result.food, food);
      });
    }
  });
}
