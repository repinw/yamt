import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/application/cook_take_ask.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_view_builder.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';

void main() {
  /// What `cookTakeAsk` says for the line [text] on [item], read the way the
  /// page reads it; [there] overrides what the item has for the line.
  ({int needed, int all})? ask(
    String text,
    InventoryItem item, {
    int? weighed,
    int? there,
    CookLineConversion? conversion,
  }) {
    final view = buildKochmodusView(
      run: buildCookRun(
        lines: [textLine('a', text, weighed: weighed, conversion: conversion)],
      ),
      saved: true,
      ended: false,
      busy: false,
      reopened: false,
      finished: null,
      tab: null,
      items: [item],
      otherReservations: const {},
      utensils: const [],
      parser: const TemplateIngredientParser(),
    );
    final line = view.lines.single;
    return cookTakeAsk(
      line: line.line,
      need: line.need,
      rough: line.roughNeed,
      item: item,
      there: there ?? view.stockLeftOf(line, item),
    );
  }

  group('cookTakeAsk on a line in grams', () {
    test('400 g of 500 g asks, needing 400 and offering all 500', () {
      expect(ask('400 g Hähnchenbrust', stockItem('f', 500)), (
        needed: 400,
        all: 500,
      ));
    });

    test('200 g of 1000 g does not ask', () {
      expect(ask('200 g Mehl', stockItem('f', 1000)), isNull);
    });

    test('250 g of 500 g asks', () {
      expect(ask('250 g Mehl', stockItem('f', 500)), (needed: 250, all: 500));
    });

    test('500 g of 500 g does not ask: the food is just enough', () {
      expect(ask('500 g Mehl', stockItem('f', 500)), isNull);
    });

    test('300 g of 200 g does not ask: it lacks, the picker says so', () {
      expect(ask('300 g Mehl', stockItem('f', 200)), isNull);
    });

    test('a weighed line does not ask: its take follows the weight', () {
      expect(
        ask('400 g Hähnchenbrust', stockItem('f', 500), weighed: 380),
        isNull,
      );
    });

    test('a rough need does not ask', () {
      expect(ask('etwas Mehl', stockItem('f', 500)), isNull);
      expect(ask('Mehl', stockItem('f', 500)), isNull);
    });

    test('spoons do not ask', () {
      expect(
        ask(
          '2 EL Öl',
          stockItem('f', 30, unit: InventoryAmountUnit.milliliter),
        ),
        isNull,
      );
      expect(ask('2 EL Mehl', stockItem('f', 40)), isNull);
    });

    test('a unit that does not fit does not ask', () {
      final milliliters = stockItem(
        'f',
        500,
        unit: InventoryAmountUnit.milliliter,
      );
      final pieces = stockItem(
        'f',
        3000,
        unit: InventoryAmountUnit.piece,
        scale: 1000,
        servingQuantity: 100,
        servingQuantityUnit: 'g',
      );

      expect(ask('400 g Mehl', milliliters), isNull);
      expect(ask('400 g Mehl', pieces), isNull);
      expect(ask('400 g Mehl', packItem('f', 2)), isNull);
    });
  });

  group('cookTakeAsk on a line in ml', () {
    test('400 ml of 500 ml asks', () {
      expect(
        ask(
          '400 ml Milch',
          stockItem('f', 500, unit: InventoryAmountUnit.milliliter),
        ),
        (needed: 400, all: 500),
      );
    });

    test('400 ml on a food kept in g does not ask', () {
      expect(ask('400 ml Milch', stockItem('f', 500)), isNull);
    });
  });

  group('cookTakeAsk on a line in pieces', () {
    test('3 of 10 eggs do not ask', () {
      expect(ask('3 Eier', packItem('f', 10)), isNull);
    });

    test('3 of 5 eggs ask', () {
      expect(ask('3 Eier', packItem('f', 5)), (needed: 3, all: 5));
    });

    test('3 of 3 eggs do not ask', () {
      expect(ask('3 Eier', packItem('f', 3)), isNull);
    });

    test('a rest that is a part of a piece does not ask', () {
      final eggs = stockItem(
        'f',
        3500,
        unit: InventoryAmountUnit.piece,
        scale: 1000,
      );

      expect(ask('2 Eier', eggs), isNull);
    });

    test('whole pieces of an item kept in parts of pieces ask in pieces', () {
      final eggs = stockItem(
        'f',
        3000,
        unit: InventoryAmountUnit.piece,
        scale: 1000,
      );

      expect(ask('2 Eier', eggs), (needed: 2000, all: 3));
    });
  });
}
