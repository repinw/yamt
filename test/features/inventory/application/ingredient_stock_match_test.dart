import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/ingredient_stock_match.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

InventoryItem _item(String id, String name, InventoryAmountUnit unit) =>
    InventoryItem.create(
      id: id,
      name: name,
      entryDate: DateTime.utc(2026, 10),
      storeName: 'Store',
      quantity: 1,
      initialAmount: 500,
      currentAmount: 500,
      amountUnit: unit,
    );

void main() {
  final items = [
    _item('milk', 'Milch', InventoryAmountUnit.milliliter),
    _item('carrots-old', 'Karotten Bio', InventoryAmountUnit.gram),
    _item('carrots', 'Karotten', InventoryAmountUnit.gram),
    _item('rice', 'Reis', InventoryAmountUnit.gram),
  ];
  const text = '300 g Karotten';
  final requirement = const TemplateIngredientParser().parseRequirement(
    ingredient: text,
    selectedPortions: 1,
    basePortions: 1,
  );

  test('the first name match is the best match, and the others follow by '
      'name in a fitting unit', () {
    final (:matches, :others) = ingredientStockCandidates(
      text: text,
      requirement: requirement,
      items: items,
      localeCode: 'de',
    );

    expect(
      matches.first,
      bestIngredientStockMatch(
        text: text,
        requirement: requirement,
        items: items,
        localeCode: 'de',
      ),
    );
    expect(matches.map((item) => item.id), ['carrots', 'carrots-old']);
    expect(others.map((item) => item.id), ['rice']);
  });

  test('an ingredient that names no amount fits any item of its name', () {
    expect(
      bestIngredientStockMatch(
        text: 'Milch',
        requirement: null,
        items: items,
        localeCode: 'de',
      )?.id,
      'milk',
    );
  });

  test('a food name alone names no amount', () {
    for (final text in [
      'Salz',
      'Pfeffer',
      'Paprikapulver',
      'Knoblauch',
      'Eier',
      'Butter',
      'Anis',
      'Salz und Pfeffer',
      'Pfeffer aus der Mühle',
      'Salt and pepper to taste',
    ]) {
      expect(ingredientNamesNoAmount(text), isTrue, reason: text);
    }
  });

  test('an ingredient that names no amount offers only its name matches', () {
    final (:matches, :others) = ingredientStockCandidates(
      text: 'Karotten',
      requirement: null,
      items: items,
      localeCode: 'de',
    );

    expect(matches.map((item) => item.id), ['carrots', 'carrots-old']);
    expect(others, isEmpty);
  });

  test('an amount the parser cannot read has no candidates', () {
    for (final text in [
      '1 cup Milch',
      '½ Milch',
      'eine Milch',
      'Einige Karotten',
      'mehrere Karotten',
      'etwas Milch',
      'some carrots',
      'Eineinhalb Liter Milch',
      'halbes Pfund Karotten',
      'Dose Milch',
      'Bund Karotten',
      'seven carrots',
      '⅜ l Milch',
      'Saft einer Milch',
      'Juice of one carrot',
    ]) {
      final (:matches, :others) = ingredientStockCandidates(
        text: text,
        requirement: null,
        items: items,
        localeCode: 'de',
      );

      expect(matches, isEmpty, reason: text);
      expect(others, isEmpty, reason: text);
    }
  });
}
