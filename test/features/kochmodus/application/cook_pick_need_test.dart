import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/application/cook_line_amount.dart';
import 'package:yamt/features/kochmodus/application/cook_line_parse.dart';
import 'package:yamt/features/kochmodus/application/cook_pick_need.dart';
import 'package:yamt/features/kochmodus/application/cook_takes.dart';
import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

import '../kochmodus_fixtures.dart';

const _parser = TemplateIngredientParser();

TemplateIngredientRequirement? _need(String text) =>
    readCookLineText(_parser, text);

const _tenMl = CookLineConversion(
  amountPerPiece: 10,
  unit: TemplateIngredientUnit.milliliter,
);
const _sixtyGrams = CookLineConversion(
  amountPerPiece: 60,
  unit: TemplateIngredientUnit.gram,
);
const _cupGrams = CookLineConversion(
  amountPerPiece: 120,
  unit: TemplateIngredientUnit.gram,
);

void main() {
  group('cookPickNeed', () {
    test("asks for spoons by the recipe's weight of one, in its unit", () {
      final pick = cookPickNeed(_need('5 EL Olivenöl'), _tenMl);

      expect(pick.need?.amount, 50);
      expect(pick.need?.unit, TemplateIngredientUnit.milliliter);
      expect(pick.need?.name, 'Olivenöl');
      expect(pick.pieceWeight, isNull);
    });

    test('asks for a spoon without a weight by a level spoon in grams', () {
      final pick = cookPickNeed(_need('2 EL Honig'), null);

      expect(pick.need?.amount, 30);
      expect(pick.need?.unit, TemplateIngredientUnit.gram);
      expect(pick.pieceWeight, isNull);
    });

    test('rounds a part of a spoon once', () {
      expect(cookPickNeed(_need('2,5 TL Zucker'), null).need?.amount, 13);
      expect(cookPickNeed(_need('1/2 TL Salz'), null).need?.amount, 3);
    });

    for (final spoons in [
      '2 gehäufte EL Mehl',
      '2 Eßlöffel Mehl',
      '2 tbsp flour',
    ]) {
      test('"$spoons" is 15 g a spoon', () {
        final pick = cookPickNeed(_need(spoons), null);

        expect(pick.need?.amount, 30);
        expect(pick.need?.unit, TemplateIngredientUnit.gram);
      });
    }

    test('a scoop without a weight stays in pieces', () {
      final need = _need('2 Tassen Reis');
      final pick = cookPickNeed(need, null);

      expect(pick.need, same(need));
      expect(pick.need?.unit, TemplateIngredientUnit.piece);
      expect(pick.need?.amount, 2);
      expect(pick.pieceWeight, isNull);
    });

    test("a scoop with the recipe's weight asks by weight", () {
      final pick = cookPickNeed(_need('2 Tassen Reis'), _cupGrams);

      expect(pick.need?.amount, 240);
      expect(pick.need?.unit, TemplateIngredientUnit.gram);
      expect(pick.pieceWeight, isNull);
    });

    test('pieces keep their count and give the weight of one', () {
      final pick = cookPickNeed(_need('3 Eier'), _sixtyGrams);

      expect(pick.need?.amount, 3);
      expect(pick.need?.unit, TemplateIngredientUnit.piece);
      expect(pick.pieceWeight, 60);
    });

    test('a line in grams is asked as it is', () {
      final need = _need('375 g Zucchini');
      final pick = cookPickNeed(need, null);

      expect(pick.need, same(need));
      expect(pick.pieceWeight, isNull);
    });

    test('a line without a need asks for nothing', () {
      expect(cookPickNeed(null, _sixtyGrams), (need: null, pieceWeight: null));
    });
  });

  group('cookSpoonWeight', () {
    test('is null for a scoop without a weight', () {
      expect(cookSpoonWeight(_need('2 Tassen Reis'), null), isNull);
    });

    test('is null for a line that is no spoon line', () {
      expect(cookSpoonWeight(_need('375 g Zucchini'), null), isNull);
      expect(cookSpoonWeight(_need('3 Eier'), _sixtyGrams), isNull);
      expect(cookSpoonWeight(null, _sixtyGrams), isNull);
    });

    test("takes the recipe's own weight first", () {
      expect(cookSpoonWeight(_need('5 EL Olivenöl'), _tenMl), _tenMl);
      expect(cookSpoonWeight(_need('2 Tassen Reis'), _cupGrams), _cupGrams);
    });

    test('falls back to 15 g a tablespoon and 5 g a teaspoon', () {
      expect(cookSpoonWeight(_need('1 EL Öl'), null)?.amountPerPiece, 15);
      expect(cookSpoonWeight(_need('1 TL Öl'), null)?.amountPerPiece, 5);
      expect(
        cookSpoonWeight(_need('1 TL Öl'), null)?.unit,
        TemplateIngredientUnit.gram,
      );
    });
  });

  group('cookSpoonGuessed', () {
    test('a spoon without the recipe weight of one is a guess', () {
      expect(cookSpoonGuessed(_need('1 EL Honig'), null), isTrue);
      expect(cookSpoonGuessed(_need('1 TL Zimt'), null), isTrue);
    });

    test("a spoon with the recipe's weight of one is no guess", () {
      expect(cookSpoonGuessed(_need('2 EL Öl'), _tenMl), isFalse);
    });

    test('a line that is no spoon line is no guess', () {
      expect(cookSpoonGuessed(_need('375 g Zucchini'), null), isFalse);
      expect(cookSpoonGuessed(_need('2 Tassen Reis'), null), isFalse);
      expect(cookSpoonGuessed(null, null), isFalse);
    });

    test('a conversion in pieces gives no weight, so it is a guess', () {
      const pieces = CookLineConversion(
        amountPerPiece: 2,
        unit: TemplateIngredientUnit.piece,
      );

      expect(cookSpoonGuessed(_need('1 EL Honig'), pieces), isTrue);
    });
  });

  group('cookLineWeightOf', () {
    final grams = stockItem('g', 1000);
    final millis = stockItem('ml', 1000, unit: InventoryAmountUnit.milliliter);
    final items = byId([grams, millis]);

    CookLineWeight weightOf(
      String text,
      Map<String, int> takes, {
      CookLineConversion? conversion,
      int? weighed,
    }) => cookLineWeightOf(
      textLine(
        'l',
        text,
        settlement: assigned(takes),
        conversion: conversion,
        weighed: weighed,
      ),
      items,
    );

    test('a spoon line is estimated and to weigh', () {
      expect(
        weightOf('1 EL Honig', {'g': 15}),
        const CookWeightEstimated(15, toWeigh: true),
      );
    });

    test('a spoon line with the recipe conversion is to weigh too', () {
      expect(
        weightOf('2 EL Öl', {'ml': 20}, conversion: _tenMl),
        const CookWeightEstimated(20, toWeigh: true),
      );
    });

    test('a line in grams on a food in grams stays exact', () {
      expect(weightOf('200 g Mehl', {'g': 200}), const CookWeightExact(200));
    });

    test('a weighed spoon line is weighed', () {
      expect(
        weightOf('1 EL Honig', {'g': 15}, weighed: 12),
        const CookWeightWeighed(12),
      );
    });
  });

  group('a standard spoon', () {
    final grams = stockItem('g', 1000);
    final millis = stockItem('ml', 1000, unit: InventoryAmountUnit.milliliter);

    test('is taken from an item in grams or milliliters', () {
      expect(cookTakeFor(_need('2 EL Honig'), grams, null)?.amount, 30);
      expect(cookTakeFor(_need('2,5 TL Zucker'), grams, null)?.amount, 13);
      expect(cookTakeFor(_need('2 EL Honig'), millis, null)?.amount, 30);
    });

    test("gives way to the recipe's weight of a spoon", () {
      expect(cookTakeFor(_need('5 EL Öl'), millis, _tenMl)?.amount, 50);
    });

    test('says how many spoons an item holds', () {
      final jar = stockItem('jar', 250);

      expect(cookLineAmountOf(_need('1 EL Honig'), jar, null, 250), 16);
    });
  });

  group('cookLineAmountKind', () {
    CookLineAmountKind kind(String text, {CookLineConversion? conversion}) =>
        cookLineAmountKind(textLine('a', text, conversion: conversion));

    test('EL and TL are spoons', () {
      expect(kind('2 EL Honig'), CookLineAmountKind.spoons);
      expect(kind('1 TL Zimt'), CookLineAmountKind.spoons);
      expect(kind('5 EL Öl', conversion: _tenMl), CookLineAmountKind.spoons);
    });

    test('a cup, a ladle or a handful with a recipe weight is not a spoon', () {
      expect(
        kind('1 Tasse Reis', conversion: _cupGrams),
        CookLineAmountKind.other,
      );
      expect(
        kind('2 Kellen Brühe', conversion: _cupGrams),
        CookLineAmountKind.other,
      );
      expect(
        kind('1 Handvoll Nüsse', conversion: _cupGrams),
        CookLineAmountKind.other,
      );
    });

    test('a pinch with a recipe weight is not a spoon either', () {
      expect(
        kind('1 Prise Salz', conversion: _sixtyGrams),
        CookLineAmountKind.other,
      );
    });

    test('pieces and a line without an amount are other, grams are weight', () {
      expect(kind('3 Zwiebeln'), CookLineAmountKind.other);
      expect(kind('Petersilie'), CookLineAmountKind.other);
      expect(kind('200 g Mehl'), CookLineAmountKind.weight);
    });
  });

  group('cookTakeGuessed', () {
    final grams = stockItem('g', 1000);
    final pieces = stockItem(
      'egg',
      3000,
      unit: InventoryAmountUnit.piece,
      scale: 1000,
    );

    bool guessed(
      String text,
      InventoryItem item, {
      CookLineConversion? conversion,
    }) {
      final line = textLine('a', text, conversion: conversion);
      return cookTakeGuessed(line, _need(text), item);
    }

    test('a guessed spoon and a piece on a food kept in g are guesses', () {
      expect(guessed('1 EL Honig', grams), isTrue);
      expect(guessed('3 Zwiebeln', grams, conversion: _sixtyGrams), isTrue);
      expect(guessed('1 Tasse Reis', grams, conversion: _cupGrams), isTrue);
    });

    test('an exact weight, or a food kept in pieces, is none', () {
      expect(guessed('200 g Mehl', grams), isFalse);
      expect(guessed('3 Eier', pieces), isFalse);
    });

    test('a line that does not count is none', () {
      expect(guessed('Salz nach Geschmack', grams), isFalse);
    });
  });
}
