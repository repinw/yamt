import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/application/cook_line_amount.dart';
import 'package:yamt/features/kochmodus/application/cook_recipe_line.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';

TemplateIngredientRequirement _need(
  int amount,
  TemplateIngredientUnit unit, {
  String name = 'Zutat',
  bool direct = true,
}) => TemplateIngredientRequirement(
  amount: amount,
  unit: unit,
  name: name,
  allowsDirectPieceInventoryMatch: direct,
);

void main() {
  group('cookLineNeed', () {
    final parsed = _need(200, TemplateIngredientUnit.gram, name: 'Mehl');
    final run = buildCookRun();

    test('without an override it is what the text says', () {
      expect(
        cookLineNeed(run, textLine('l', '200 g Mehl'), parsed),
        same(parsed),
      );
    });

    test('a line without amount and override needs nothing', () {
      expect(cookLineNeed(run, textLine('l', 'Salz'), null), isNull);
    });

    const butter = CookRoughWeight(
      amount: 20,
      unit: TemplateIngredientUnit.gram,
    );

    test('a rough weight is the need of a line without amount', () {
      final need = cookLineNeed(
        run,
        textLine('l', 'Butter zum Braten', roughWeight: butter),
        null,
      )!;

      expect(need.amount, 20);
      expect(need.unit, TemplateIngredientUnit.gram);
      expect(need.name, 'Butter zum Braten');
    });

    test('a rough weight scales with the portions', () {
      final double = buildCookRun().copyWith(portions: 8);
      final half = buildCookRun().copyWith(portions: 2);
      final line = textLine('l', 'Butter zum Braten', roughWeight: butter);

      expect(cookLineNeed(double, line, null)!.amount, 40);
      expect(cookLineNeed(half, line, null)!.amount, 10);
    });

    test('a line that names an amount ignores the rough weight', () {
      final need = cookLineNeed(
        run,
        textLine('l', '200 g Mehl', roughWeight: butter),
        parsed,
      );

      expect(need, same(parsed));
    });

    test('the cook amount replaces the rough weight', () {
      final need = cookLineNeed(
        run,
        textLine('l', 'Butter zum Braten', amount: 35, roughWeight: butter),
        null,
      );

      expect(need?.amount, 35);
      expect(
        cookNeedIsRough(
          textLine('l', 'Butter zum Braten', amount: 35, roughWeight: butter),
          null,
        ),
        isFalse,
      );
    });

    test('a need is rough only without text amount and cook amount', () {
      expect(
        cookNeedIsRough(
          textLine('l', 'Butter zum Braten', roughWeight: butter),
          null,
        ),
        isTrue,
      );
      expect(
        cookNeedIsRough(textLine('l', 'Butter zum Braten'), null),
        isFalse,
      );
      expect(
        cookNeedIsRough(
          textLine('l', '200 g Mehl', roughWeight: butter),
          parsed,
        ),
        isFalse,
      );
    });

    test('the override replaces the amount and keeps unit and name', () {
      final need = cookLineNeed(
        run,
        textLine('l', '200 g Mehl', amount: 350),
        parsed,
      )!;

      expect(need.amount, 350);
      expect(need.unit, TemplateIngredientUnit.gram);
      expect(need.name, 'Mehl');
    });

    test('the override keeps the unit of pieces and the direct match', () {
      final pieces = _need(
        2,
        TemplateIngredientUnit.piece,
        name: 'Eier',
        direct: false,
      );

      final need = cookLineNeed(
        run,
        textLine('l', '2 Eier', amount: 3),
        pieces,
      )!;

      expect(need.amount, 3);
      expect(need.unit, TemplateIngredientUnit.piece);
      expect(need.allowsDirectPieceInventoryMatch, isFalse);
    });

    test('an amount for a line without one counts in grams', () {
      final need = cookLineNeed(
        run,
        textLine('l', 'Nudeln', amount: 250),
        null,
      )!;

      expect(need.amount, 250);
      expect(need.unit, TemplateIngredientUnit.gram);
      expect(need.name, 'Nudeln');
      expect(need.allowsDirectPieceInventoryMatch, isTrue);
    });

    test('the override scales with the portions, without drift', () {
      final line = textLine('l', '200 g Mehl', amount: 100, amountPortions: 3);

      int amountFor(int portions) =>
          cookLineNeed(buildCookRun(portions: portions), line, parsed)!.amount;

      expect(amountFor(3), 100);
      expect(amountFor(6), 200);
      expect(amountFor(1), 33);
      expect(amountFor(3), 100);
    });

    test('a scaled amount is rounded', () {
      final line = textLine('l', 'Mehl', amount: 10, amountPortions: 4);

      expect(cookLineNeed(buildCookRun(portions: 6), line, null)!.amount, 15);
      expect(cookLineNeed(buildCookRun(portions: 3), line, null)!.amount, 8);
    });

    test('an amount above 0 never rounds below 1', () {
      final line = textLine('l', 'Salz', amount: 1, amountPortions: 8);

      expect(cookLineNeed(buildCookRun(portions: 1), line, null)!.amount, 1);
    });

    test('an amount of 0 stays 0', () {
      final line = textLine('l', 'Salz', amount: 0, amountPortions: 2);

      expect(cookLineNeed(buildCookRun(portions: 8), line, null)!.amount, 0);
    });
  });

  group('cookRecipeLineText', () {
    test('keeps the text of a line without cook amount', () {
      expect(
        cookRecipeLineText(buildCookRun(), textLine('l', '200 g Mehl'), {}),
        '200 g Mehl',
      );
    });

    test('a cook amount equal to the text keeps the text', () {
      final line = textLine('l', '200 g Mehl', amount: 200, amountPortions: 4);

      expect(cookRecipeLineText(buildCookRun(), line, {}), '200 g Mehl');
    });

    test('a cook amount replaces the amount of the text', () {
      final line = textLine('l', '200 g Reis', amount: 300, amountPortions: 4);

      expect(cookRecipeLineText(buildCookRun(), line, {}), '300 g Reis');
    });

    test('a cook amount scales to the run portions', () {
      final line = textLine('l', 'Reis', amount: 100, amountPortions: 2);

      expect(
        cookRecipeLineText(buildCookRun(portions: 6), line, {}),
        '300 g Reis',
      );
    });

    test('pieces keep their count label', () {
      final line = textLine(
        'l',
        '2 Dosen Tomaten',
        amount: 3,
        amountPortions: 4,
      );

      expect(cookRecipeLineText(buildCookRun(), line, {}), '3 Dosen Tomaten');
    });

    test('pieces without a label read as a count', () {
      final line = textLine('l', '1 Eier', amount: 2, amountPortions: 4);

      expect(cookRecipeLineText(buildCookRun(), line, {}), '2 Eier');
    });

    test('a line without amount uses what it took', () {
      final line = textLine('l', 'Reis', settlement: assigned({'rice': 200}));

      expect(
        cookRecipeLineText(
          buildCookRun(),
          line,
          byId([stockItem('rice', 800)]),
        ),
        '200 g Reis',
      );
    });

    test('piece takes read in the item scale', () {
      final line = textLine('l', 'Eier', settlement: assigned({'egg': 2000}));
      final egg = stockItem(
        'egg',
        6000,
        unit: InventoryAmountUnit.piece,
        scale: 1000,
      );

      expect(cookRecipeLineText(buildCookRun(), line, byId([egg])), '2 Eier');
    });

    test('an amountless line set to 0 reads as its name', () {
      final line = textLine('l', 'Salz', amount: 0, amountPortions: 2);

      expect(cookRecipeLineText(buildCookRun(), line, {}), 'Salz');
    });

    test('a text amount set to 0 falls back to the text, never 0 g', () {
      final line = textLine('l', '200 g Salz', amount: 0, amountPortions: 4);

      expect(cookRecipeLineText(buildCookRun(), line, {}), '200 g Salz');
    });

    test('a line set to 0 that took something reads what it took', () {
      final line = textLine(
        'l',
        'Salz',
        amount: 0,
        amountPortions: 4,
        settlement: assigned({'salt': 5}),
      );

      expect(
        cookRecipeLineText(
          buildCookRun(),
          line,
          byId([stockItem('salt', 100)]),
        ),
        '5 g Salz',
      );
    });

    test('a line that took nothing keeps its text', () {
      expect(
        cookRecipeLineText(buildCookRun(), textLine('l', 'Salz'), {}),
        'Salz',
      );
    });
  });

  group('cookTakeFor', () {
    final gramItem = stockItem('g', 1000);
    final millilitreItem = stockItem(
      'ml',
      1000,
      unit: InventoryAmountUnit.milliliter,
    );
    // Pieces kept as a thousandth: a pack of 6 holds 6000.
    final pieceItem = stockItem(
      'pc',
      6000,
      unit: InventoryAmountUnit.piece,
      scale: 1000,
    );
    final wholePack = packItem('pack', 3);

    test('grams from a gram item', () {
      final take = cookTakeFor(
        _need(200, TemplateIngredientUnit.gram),
        gramItem,
        null,
      );

      expect(take?.amount, 200);
      expect(take?.unit, InventoryAmountUnit.gram);
    });

    test('ml from an ml item, and from a gram item 1:1 in its unit', () {
      final need = _need(300, TemplateIngredientUnit.milliliter);

      expect(cookTakeFor(need, millilitreItem, null)?.amount, 300);
      final fromGrams = cookTakeFor(need, gramItem, null);
      expect(fromGrams?.amount, 300);
      expect(fromGrams?.unit, InventoryAmountUnit.gram);
    });

    test('grams from an ml item count 1:1 in ml', () {
      final take = cookTakeFor(
        _need(200, TemplateIngredientUnit.gram),
        millilitreItem,
        null,
      );

      expect(take?.amount, 200);
      expect(take?.unit, InventoryAmountUnit.milliliter);
    });

    test('pieces from a piece item come in its scale of a thousand', () {
      final take = cookTakeFor(
        _need(2, TemplateIngredientUnit.piece),
        pieceItem,
        null,
      );

      expect(take?.amount, 2000);
      expect(take?.unit, InventoryAmountUnit.piece);
    });

    test('a pack of amountScale 1000 gives a whole pack as 1000', () {
      final pack = stockItem(
        'pack1000',
        1000,
        unit: InventoryAmountUnit.piece,
        scale: 1000,
      );

      expect(
        cookTakeFor(_need(1, TemplateIngredientUnit.piece), pack, null)?.amount,
        1000,
      );
    });

    test('pieces from items counted whole stay whole', () {
      final take = cookTakeFor(
        _need(2, TemplateIngredientUnit.piece),
        wholePack,
        null,
      );

      expect(take?.amount, 2);
      expect(take?.unit, InventoryAmountUnit.piece);
    });

    test('grams from items counted whole are not told', () {
      expect(
        cookTakeFor(_need(200, TemplateIngredientUnit.gram), wholePack, null),
        isNull,
      );
    });

    test('pieces from a gram item use the line piece weight', () {
      final take = cookTakeFor(
        _need(3, TemplateIngredientUnit.piece),
        gramItem,
        const CookLineConversion(
          amountPerPiece: 60,
          unit: TemplateIngredientUnit.gram,
        ),
      );

      expect(take?.amount, 180);
      expect(take?.unit, InventoryAmountUnit.gram);
    });

    test('pieces from an ml item use the piece weight 1:1 in ml', () {
      final need = _need(2, TemplateIngredientUnit.piece);

      expect(
        cookTakeFor(
          need,
          millilitreItem,
          const CookLineConversion(
            amountPerPiece: 50,
            unit: TemplateIngredientUnit.milliliter,
          ),
        )?.amount,
        100,
      );
      final fromGramWeight = cookTakeFor(
        need,
        millilitreItem,
        const CookLineConversion(
          amountPerPiece: 50,
          unit: TemplateIngredientUnit.gram,
        ),
      );
      expect(fromGramWeight?.amount, 100);
      expect(fromGramWeight?.unit, InventoryAmountUnit.milliliter);
      expect(cookTakeFor(need, millilitreItem, null), isNull);
    });

    test('pieces from a gram item without a piece weight are not told', () {
      expect(
        cookTakeFor(_need(3, TemplateIngredientUnit.piece), gramItem, null),
        isNull,
      );
    });

    test('a line without amount needs 0, in no unit', () {
      final take = cookTakeFor(null, gramItem, null);

      expect(take?.amount, 0);
      expect(take?.unit, isNull);
    });
  });

  group('cookWeighedTake', () {
    final gram = stockItem('g', 500);
    final millilitre = stockItem(
      'ml',
      500,
      unit: InventoryAmountUnit.milliliter,
    );
    final piece = stockItem(
      'piece',
      6000,
      unit: InventoryAmountUnit.piece,
      scale: 1000,
    );

    test('a line without weight has none', () {
      expect(cookWeighedTake(textLine('l', 'Öl'), [gram]), isNull);
    });

    test('grams follow the weight', () {
      expect(cookWeighedTake(textLine('l', 'Öl', weighed: 30), [gram]), 30);
    });

    test('ml follow the weight 1:1', () {
      expect(
        cookWeighedTake(textLine('l', 'Milch', weighed: 45), [millilitre]),
        45,
      );
    });

    test('items in grams and ml together follow it', () {
      expect(
        cookWeighedTake(textLine('l', 'Öl', weighed: 30), [gram, millilitre]),
        30,
      );
    });

    test('one item in pieces keeps the weight a record', () {
      final line = textLine('l', 'Zwiebeln', weighed: 180);

      expect(cookWeighedTake(line, [piece]), isNull);
      expect(cookWeighedTake(line, [gram, piece]), isNull);
    });

    test('an item counted in whole packs keeps the weight a record', () {
      expect(
        cookWeighedTake(textLine('l', 'Öl', weighed: 30), [packItem('p', 2)]),
        isNull,
      );
    });

    test('a weight below 1 follows nothing, so never a take of 0', () {
      expect(cookWeighedTake(textLine('l', 'Öl', weighed: 0), [gram]), isNull);
    });

    test('without items there is nothing to follow', () {
      expect(cookWeighedTake(textLine('l', 'Öl', weighed: 30), []), isNull);
    });
  });

  group('cookRecipeLineText with a weight', () {
    test('says what was weighed when the takes follow it', () {
      final line = textLine(
        'l',
        '2 EL Öl',
        settlement: assigned({'oil': 30}),
        weighed: 30,
      );

      expect(
        cookRecipeLineText(buildCookRun(), line, byId([stockItem('oil', 500)])),
        '30 g Öl',
      );
    });

    test('an ml item says the weight in ml', () {
      final line = textLine(
        'l',
        '100 ml Milch',
        settlement: assigned({'milk': 50}),
        weighed: 50,
      );
      final milk = stockItem('milk', 500, unit: InventoryAmountUnit.milliliter);

      expect(
        cookRecipeLineText(buildCookRun(), line, byId([milk])),
        '50 ml Milch',
      );
    });

    test('the weight beats the cook amount', () {
      final line = textLine(
        'l',
        '200 g Reis',
        amount: 300,
        settlement: assigned({'rice': 250}),
        weighed: 250,
      );

      expect(
        cookRecipeLineText(
          buildCookRun(),
          line,
          byId([stockItem('rice', 800)]),
        ),
        '250 g Reis',
      );
    });

    test('a piece item keeps the recipe amount, the weight is a record', () {
      final line = textLine(
        'l',
        '2 Zwiebeln',
        settlement: assigned({'onion': 2000}),
        weighed: 180,
      );
      final onion = stockItem(
        'onion',
        6000,
        unit: InventoryAmountUnit.piece,
        scale: 1000,
      );

      expect(
        cookRecipeLineText(buildCookRun(), line, byId([onion])),
        '2 Zwiebeln',
      );
    });

    test('a line that is not assigned keeps its text', () {
      final line = textLine('l', '200 g Reis', weighed: 250);

      expect(cookRecipeLineText(buildCookRun(), line, {}), '200 g Reis');
    });
  });

  group('cookLineAmountOf', () {
    final gramItem = stockItem('g', 1000);
    final millilitreItem = stockItem(
      'ml',
      1000,
      unit: InventoryAmountUnit.milliliter,
    );
    final pieceItem = stockItem(
      'pc',
      6000,
      unit: InventoryAmountUnit.piece,
      scale: 1000,
    );
    final wholePack = packItem('pack', 3);
    const sixty = CookLineConversion(
      amountPerPiece: 60,
      unit: TemplateIngredientUnit.gram,
    );

    test('the same unit gives the available amount as it is', () {
      expect(
        cookLineAmountOf(
          _need(200, TemplateIngredientUnit.gram),
          gramItem,
          null,
          500,
        ),
        500,
      );
      expect(
        cookLineAmountOf(
          _need(200, TemplateIngredientUnit.milliliter),
          millilitreItem,
          null,
          350,
        ),
        350,
      );
    });

    test('pieces of an item kept in thousandths count whole, rounded down', () {
      final need = _need(2, TemplateIngredientUnit.piece);

      expect(cookLineAmountOf(need, pieceItem, null, 6000), 6);
      expect(cookLineAmountOf(need, pieceItem, null, 4500), 4);
      expect(cookLineAmountOf(need, pieceItem, null, 999), 0);
    });

    test('pieces of items counted whole stay whole', () {
      expect(
        cookLineAmountOf(
          _need(1, TemplateIngredientUnit.piece),
          wholePack,
          null,
          3,
        ),
        3,
      );
    });

    test('pieces from a gram item use the line piece weight', () {
      final need = _need(3, TemplateIngredientUnit.piece);

      expect(cookLineAmountOf(need, gramItem, sixty, 500), 8);
    });

    test('an item that cannot supply the line gives null', () {
      expect(
        cookLineAmountOf(
          _need(3, TemplateIngredientUnit.piece),
          gramItem,
          null,
          500,
        ),
        isNull,
      );
      expect(
        cookLineAmountOf(
          _need(200, TemplateIngredientUnit.gram),
          wholePack,
          null,
          3,
        ),
        isNull,
      );
    });

    test('grams and ml count 1:1, so an ml item supplies grams', () {
      expect(
        cookLineAmountOf(
          _need(200, TemplateIngredientUnit.gram),
          millilitreItem,
          null,
          500,
        ),
        500,
      );
      expect(
        cookLineAmountOf(
          _need(200, TemplateIngredientUnit.milliliter),
          gramItem,
          null,
          500,
        ),
        500,
      );
    });

    test('nothing available is 0', () {
      expect(
        cookLineAmountOf(
          _need(200, TemplateIngredientUnit.gram),
          gramItem,
          null,
          0,
        ),
        0,
      );
    });

    test('a line without amount counts in grams', () {
      expect(cookLineAmountOf(null, gramItem, null, 420), 420);
      expect(cookLineAmountOf(null, wholePack, null, 3), isNull);
    });

    test('is the reverse of cookTakeFor', () {
      final need = _need(3, TemplateIngredientUnit.piece);
      final take = cookTakeFor(need, gramItem, sixty)!.amount;

      expect(cookLineAmountOf(need, gramItem, sixty, take), 3);
    });
  });

  group('cookSameMeasure', () {
    test('the same unit adds up', () {
      for (final unit in InventoryAmountUnit.values) {
        expect(cookSameMeasure(unit, unit), isTrue);
      }
      expect(cookSameMeasure(null, null), isTrue);
    });

    test('grams and ml add up 1:1, in both directions', () {
      expect(
        cookSameMeasure(
          InventoryAmountUnit.gram,
          InventoryAmountUnit.milliliter,
        ),
        isTrue,
      );
      expect(
        cookSameMeasure(
          InventoryAmountUnit.milliliter,
          InventoryAmountUnit.gram,
        ),
        isTrue,
      );
    });

    test('pieces never add up with grams or ml', () {
      for (final other in [
        InventoryAmountUnit.gram,
        InventoryAmountUnit.milliliter,
      ]) {
        expect(cookSameMeasure(InventoryAmountUnit.piece, other), isFalse);
        expect(cookSameMeasure(other, InventoryAmountUnit.piece), isFalse);
      }
    });

    test('an item that cannot supply (null) differs from a unit', () {
      expect(cookSameMeasure(null, InventoryAmountUnit.gram), isFalse);
      expect(cookSameMeasure(InventoryAmountUnit.piece, null), isFalse);
    });
  });

  group('cookLineTakesNothing', () {
    final run = buildCookRun();

    bool takesNothing(String text, {LineSettlement? settlement, int? amount}) =>
        cookLineTakesNothing(
          run,
          textLine(
            'l',
            text,
            settlement: settlement ?? assigned({'g': 0}),
            amount: amount,
          ),
        );

    test('a piece line on a gram item without piece weight takes nothing', () {
      expect(takesNothing('1 Möhre'), isTrue);
    });

    test('a line that takes something does not', () {
      expect(takesNothing('1 Möhre', settlement: assigned({'g': 60})), isFalse);
    });

    test('a line that takes from one of two items does not', () {
      expect(
        takesNothing('200 g Reis', settlement: assigned({'a': 0, 'b': 5})),
        isFalse,
      );
    });

    test('a line without amount, such as Salz, does not', () {
      expect(takesNothing('Salz'), isFalse);
    });

    test('a rough need never makes a line take nothing', () {
      expect(
        cookLineTakesNothing(
          run,
          textLine(
            'l',
            'Butter zum Braten',
            settlement: assigned({'g': 0}),
            roughWeight: const CookRoughWeight(
              amount: 20,
              unit: TemplateIngredientUnit.gram,
            ),
          ),
        ),
        isFalse,
      );
    });

    test('the cook own amount of 0 does not', () {
      expect(takesNothing('1 Möhre', amount: 0), isFalse);
    });

    test('the cook amount above 0 on a line without amount does', () {
      expect(takesNothing('Salz', amount: 5), isTrue);
    });

    test('a line that is not assigned does not', () {
      expect(takesNothing('1 Möhre', settlement: const LineOpen()), isFalse);
      expect(takesNothing('1 Möhre', settlement: const LineIgnored()), isFalse);
    });
  });

  group('cookLineCanFollowWeight', () {
    final items = byId([
      stockItem('g', 500),
      stockItem('ml', 500, unit: InventoryAmountUnit.milliliter),
      stockItem('egg', 3000, unit: InventoryAmountUnit.piece, scale: 1000),
      packItem('pack', 2),
    ]);

    bool can(String text, LineSettlement settlement) => cookLineCanFollowWeight(
      textLine('l', text, settlement: settlement),
      items,
    );

    test('items kept in g or ml can', () {
      expect(can('1 Möhre', assigned({'g': 0})), isTrue);
      expect(can('Milch', assigned({'ml': 0})), isTrue);
      expect(can('Öl', assigned({'g': 0, 'ml': 0})), isTrue);
    });

    test('"1 EL Senf" on a whole pack cannot', () {
      expect(can('1 EL Senf', assigned({'pack': 0})), isFalse);
    });

    test('"200 g Reis" on an item counted in pieces cannot', () {
      expect(can('200 g Reis', assigned({'egg': 0})), isFalse);
    });

    test('one item that cannot spoils the line', () {
      expect(can('Öl', assigned({'g': 0, 'pack': 1})), isFalse);
    });

    test('an item with a take of 0 takes nothing, so it does not spoil', () {
      expect(can('Öl', assigned({'g': 0, 'pack': 0})), isTrue);
    });

    test('an item that is gone cannot', () {
      expect(can('Öl', assigned({'gone': 0})), isFalse);
    });

    test('a line that is not assigned cannot', () {
      expect(can('Öl', const LineOpen()), isFalse);
      expect(can('Öl', const LineIgnored()), isFalse);
    });
  });

  group('cookNeedInBothMeasures', () {
    test('a need in g also asks in ml, its own unit first', () {
      final both = cookNeedInBothMeasures(
        _need(100, TemplateIngredientUnit.gram),
      );

      expect(both.map((need) => need?.unit), [
        TemplateIngredientUnit.gram,
        TemplateIngredientUnit.milliliter,
      ]);
      expect(both.map((need) => need?.amount), [100, 100]);
    });

    test('a need in ml also asks in g', () {
      final both = cookNeedInBothMeasures(
        _need(250, TemplateIngredientUnit.milliliter),
      );

      expect(both.map((need) => need?.unit), [
        TemplateIngredientUnit.milliliter,
        TemplateIngredientUnit.gram,
      ]);
    });

    test('pieces and no need stay as they are', () {
      expect(cookNeedInBothMeasures(null), [null]);
      expect(
        cookNeedInBothMeasures(_need(2, TemplateIngredientUnit.piece)),
        hasLength(1),
      );
    });
  });
}
