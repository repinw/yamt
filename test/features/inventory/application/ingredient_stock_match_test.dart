import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/ingredient_stock_match.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_manual_add_product_factory.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

InventoryItem _item(
  String id,
  String name,
  InventoryAmountUnit unit, {
  String? brand,
}) => InventoryItem.create(
  id: id,
  name: name,
  brand: brand,
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

  test('the best name match is the best match, and the others follow: the '
      'weaker name matches, then the rest by name in a fitting unit', () {
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
    expect(matches.map((item) => item.id), ['carrots']);
    expect(others.map((item) => item.id), ['carrots-old', 'rice']);
  });

  group('an exact name kept in another unit', () {
    const rice = '100 g Testreis';
    final riceRequirement = const TemplateIngredientParser().parseRequirement(
      ingredient: rice,
      selectedPortions: 1,
      basePortions: 1,
    );
    // "Reis" in the brand gives a weak name match through the base word.
    final longGrain = _item(
      'long-grain',
      'Langkornreis',
      InventoryAmountUnit.gram,
      brand: 'Reis-Fit',
    );

    test('lets no weaker match stand in for it (#785)', () {
      final items = [
        _item('apple', 'Apfel', InventoryAmountUnit.gram),
        _item('test-rice', 'Testreis', InventoryAmountUnit.piece),
        longGrain,
        _item('rice', 'Reis', InventoryAmountUnit.gram),
      ];

      expect(
        bestIngredientStockMatch(
          text: rice,
          requirement: riceRequirement,
          items: items,
          localeCode: 'de',
        ),
        isNull,
      );
      final (:matches, :others) = ingredientStockCandidates(
        text: rice,
        requirement: riceRequirement,
        items: items,
        localeCode: 'de',
      );
      expect(matches, isEmpty);
      // The weaker name matches come first, best first, then the rest.
      expect(others.map((item) => item.id), ['rice', 'long-grain', 'apple']);
    });

    test('the same food from a brand does not stand in either', () {
      const carrots = '300 g Karotten';
      expect(
        bestIngredientStockMatch(
          text: carrots,
          requirement: const TemplateIngredientParser().parseRequirement(
            ingredient: carrots,
            selectedPortions: 1,
            basePortions: 1,
          ),
          items: [
            _item('carrots', 'Karotten', InventoryAmountUnit.piece),
            _item(
              'bio-carrots',
              'Karotten',
              InventoryAmountUnit.gram,
              brand: 'Bio',
            ),
          ],
          localeCode: 'de',
        ),
        isNull,
      );
    });

    test('supplies the line when it fits', () {
      expect(
        bestIngredientStockMatch(
          text: rice,
          requirement: riceRequirement,
          items: [
            longGrain,
            _item('test-rice', 'Testreis', InventoryAmountUnit.gram),
          ],
          localeCode: 'de',
        )?.id,
        'test-rice',
      );
    });
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

    expect(matches.map((item) => item.id), ['carrots']);
    expect(others.map((item) => item.id), ['carrots-old']);
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

  test('a food that speech writes apart still finds its own item (#785)', () {
    // Rebuilt as on the phone: a self-made food with its package weight, and
    // a rice whose brand holds the word "Reis".
    final now = DateTime.utc(2026, 10, 23);
    InventoryItem ownFood(
      String id,
      String name,
      String weight,
      String? brand,
    ) => buildInventoryManualAddSavedItem(
      id: id,
      globalProduct: GlobalFoodItem.create(
        id: 'food-$id',
        name: name,
        now: now,
        brand: brand,
        packageWeight: weight,
      ),
      now: now,
      storeName: 'Store',
      inventoryWeight: weight,
      inCatalog: false,
    );
    final items = [
      ownFood('long-grain', 'Langkornreis', '1000 g', 'Reis-Fit'),
      ownFood('test-rice', 'Testreis', '785 g', null),
    ];

    for (final text in [
      '100 g Test Reis',
      '100 g Test-Reis',
      '100 g Testreis',
    ]) {
      expect(
        bestIngredientStockMatch(
          text: text,
          requirement: const TemplateIngredientParser().parseRequirement(
            ingredient: text,
            selectedPortions: 1,
            basePortions: 1,
          ),
          items: items,
          localeCode: 'de',
        )?.id,
        'test-rice',
        reason: text,
      );
    }
  });

  group('a weak compound match is only offered (#842)', () {
    const rice = '100 g Reis';
    final riceRequirement = const TemplateIngredientParser().parseRequirement(
      ingredient: rice,
      selectedPortions: 1,
      basePortions: 1,
    );
    final cakes = _item('cakes', 'Reiswaffeln', InventoryAmountUnit.gram);

    test('alone, it supplies nothing but can be picked', () {
      final (:matches, :others) = ingredientStockCandidates(
        text: rice,
        requirement: riceRequirement,
        items: [cakes],
        localeCode: 'de',
      );

      expect(matches, isEmpty);
      expect(others.map((item) => item.id), ['cakes']);
      expect(
        bestIngredientStockMatch(
          text: rice,
          requirement: riceRequirement,
          items: [cakes],
          localeCode: 'de',
        ),
        isNull,
      );
    });

    test('the food as the last part supplies the line before it', () {
      final (:matches, :others) = ingredientStockCandidates(
        text: rice,
        requirement: riceRequirement,
        items: [
          cakes,
          _item('basmati', 'Basmatireis', InventoryAmountUnit.gram),
        ],
        localeCode: 'de',
      );

      expect(matches.map((item) => item.id), ['basmati']);
      expect(others.map((item) => item.id), contains('cakes'));
    });
  });
}
