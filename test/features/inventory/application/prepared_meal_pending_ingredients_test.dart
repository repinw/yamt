import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_from_template.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_pending_ingredients.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

InventoryItem _milk({required String id, required InventoryAmountUnit unit}) {
  return InventoryItem.create(
    id: id,
    name: 'Milch',
    entryDate: DateTime.utc(2026, 9),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: 1000,
    amountUnit: unit,
  );
}

InventoryItem _rice(String id, {required int grams}) {
  return InventoryItem.create(
    id: id,
    name: 'Reis',
    entryDate: DateTime.utc(2026, 9),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: grams,
    amountUnit: InventoryAmountUnit.gram,
  );
}

/// The rows that the foods filling [row] from [items] are linked to.
List<String?> _filledRows(String row, List<InventoryItem> items) {
  final result = buildPreparedMealPendingIngredientFillResult(
    currentItems: items,
    ingredient: row,
    inventoryItemIds: [for (final item in items) item.id],
    ingredientParser: const TemplateIngredientParser(),
  )!;
  return [
    for (final component in result.components)
      component.pendingRecipeIngredient,
  ];
}

InventoryItem? _match(String ingredient, List<InventoryItem> items) {
  return findPendingIngredientStockMatch(
    ingredient: ingredient,
    inventoryItems: items,
    ingredientParser: const TemplateIngredientParser(),
    localeCode: 'de',
  );
}

void main() {
  test('skips a match whose unit cannot supply the row', () {
    final items = [
      _milk(id: 'gram', unit: InventoryAmountUnit.gram),
      _milk(id: 'ml', unit: InventoryAmountUnit.milliliter),
    ];

    expect(_match('200 ml Milch', items)?.id, 'ml');
    expect(_match('200 ml Milch', [items.first]), isNull);
  });

  test('offers the item of its name for a row that names no amount, and '
      'none for an amount it cannot read', () {
    final items = [_milk(id: 'ml', unit: InventoryAmountUnit.milliliter)];

    expect(_match('Milch', items)?.id, 'ml');
    expect(_match('etwas Milch', items), isNull);
  });

  test('a row that names no amount is done by an item and takes nothing '
      '(#834)', () {
    final items = [_rice('salt', grams: 500)];
    PreparedMealPendingIngredientFillResult? fill(String row) =>
        buildPreparedMealPendingIngredientFillResult(
          currentItems: items,
          ingredient: row,
          inventoryItemIds: const ['salt'],
          ingredientParser: const TemplateIngredientParser(),
        );

    final result = fill('Salz')!;

    expect(result.components, isEmpty);
    expect(result.nextItems, items);
    expect(result.remainingIngredient, isNull);
    expect(fill('etwas Salz'), isNull);
  });

  test('a food that fills a whole row is linked to the row', () {
    expect(_filledRows('200 g Reis', [_rice('rice', grams: 600)]), [
      '200 g Reis',
    ]);
  });

  test('foods that share a row are linked to their own share of it', () {
    // Unassigning them opens rows that add up to the row again.
    expect(
      _filledRows('500 g Reis', [
        _rice('open', grams: 300),
        _rice('full', grams: 1000),
      ]),
      ['300 g Reis', '200 g Reis'],
    );
  });

  test('a food assigned while cooking is linked to its recipe row', () {
    final now = DateTime.utc(2026, 10);
    final result = buildPreparedMealCreationFromTemplateResult(
      currentItems: [_rice('rice', grams: 1000)],
      preparedMealId: 'pan',
      now: now,
      template: PreparedMeal(
        id: 'recipe',
        name: 'Reispfanne',
        totalPortions: 2,
        remainingPortions: 2,
        totalKcal: 0,
        totalProtein: 0,
        totalCarbs: 0,
        totalFat: 0,
        createdAt: now,
        updatedAt: now,
        components: const <PreparedMealComponent>[],
        recipeIngredients: const ['400 g Reis'],
      ),
      totalPortions: 1,
      recipeIngredientAssignments: const {
        '400 g Reis': ['rice'],
      },
      recipeIngredientAmountConversions: const {},
      ingredientParser: const TemplateIngredientParser(),
    );

    final component = result.preparedMeal.components.single;
    expect(component.usedAmount, 200);
    expect(component.pendingRecipeIngredient, '200 g Reis');
  });
}
