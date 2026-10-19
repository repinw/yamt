import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/prepared_meal_from_vorlage.dart';
import 'package:yamt/features/inventory/application/prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

const _nutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 100,
  per100Protein: 10,
  per100Carbs: 20,
  per100Fat: 5,
);

InventoryItem _grams(String id, String name, int amount) =>
    InventoryItem.create(
      id: id,
      name: name,
      entryDate: DateTime(2026, 10, 19),
      storeName: 'Store',
      quantity: 1,
      initialAmount: amount,
      currentAmount: amount,
      amountUnit: InventoryAmountUnit.gram,
      nutrition: _nutrition,
    );

InventoryItem _counted(String id, String name, int quantity) =>
    InventoryItem.create(
      id: id,
      name: name,
      entryDate: DateTime(2026, 10, 19),
      storeName: 'Store',
      quantity: quantity,
      initialQuantity: quantity,
      nutrition: _nutrition,
    );

InventoryItem _pieces(String id, String name, double pieces) {
  final stored = (pieces * inventoryPieceAmountScale).round();
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime(2026, 10, 19),
    storeName: 'Store',
    quantity: 1,
    initialAmount: stored,
    currentAmount: stored,
    amountScale: inventoryPieceAmountScale,
    amountUnit: InventoryAmountUnit.piece,
    nutrition: _nutrition,
  );
}

final _vorlage = PreparedMeal(
  id: 'bowl',
  name: 'Bowl',
  totalPortions: 1,
  remainingPortions: 1,
  totalKcal: 0,
  totalProtein: 0,
  totalCarbs: 0,
  totalFat: 0,
  createdAt: DateTime(2026, 10, 19),
  updatedAt: DateTime(2026, 10, 19),
  components: const <PreparedMealComponent>[],
);

void main() {
  test('takes the amounts as given, across packs and in parts of a piece', () {
    final result = buildPreparedMealFromVorlage(
      currentItems: [
        _grams('rice', 'Reis', 200),
        _grams('rice-2', 'Reis', 500),
        _pieces('lemon', 'Zitrone', 1),
      ],
      preparedMealId: 'meal',
      now: DateTime(2026, 10, 19),
      vorlage: _vorlage,
      totalPortions: 2,
      foods: const [
        (
          name: 'Reis',
          unit: InventoryAmountUnit.gram,
          amount: 300,
          itemIds: ['rice', 'rice-2'],
        ),
        (
          name: 'Zitrone',
          unit: InventoryAmountUnit.piece,
          amount: 0.3,
          itemIds: ['lemon'],
        ),
      ],
    );

    final meal = result.preparedMeal;
    expect(meal.totalPortions, 2);
    expect(meal.pendingRecipeIngredients, isEmpty);
    expect(meal.components.map((c) => (c.inventoryItemId, c.usedAmount)), [
      ('rice', 200),
      ('rice-2', 100),
      ('lemon', 300),
    ]);
    // Rows count whole pieces, so the parser can fill them again.
    expect(meal.components.last.openRow, '1 Zitrone');
    expect(meal.recipeIngredients, ['300 g Reis', '1 Zitrone']);
    expect(meal.recipeIngredientAssignments['300 g Reis'], ['rice', 'rice-2']);
    expect(result.nextItems.map((item) => (item.id, item.currentAmount)), [
      ('rice', 0),
      ('rice-2', 400),
      ('lemon', 700),
    ]);
  });

  test('leaves what the items cannot supply as an open row', () {
    final result = buildPreparedMealFromVorlage(
      currentItems: [_grams('rice', 'Reis', 100)],
      preparedMealId: 'meal',
      now: DateTime(2026, 10, 19),
      vorlage: _vorlage,
      totalPortions: 1,
      foods: const [
        (
          name: 'Reis',
          unit: InventoryAmountUnit.gram,
          amount: 250,
          itemIds: ['rice'],
        ),
        (
          name: 'Eier',
          unit: InventoryAmountUnit.piece,
          amount: 2,
          itemIds: ['rice', 'gone'],
        ),
      ],
    );

    expect(result.preparedMeal.components.single.usedAmount, 100);
    // Rice in grams cannot supply eggs, and a gone item supplies nothing.
    expect(result.preparedMeal.pendingRecipeIngredients, [
      '150 g Reis',
      '2 Eier',
    ]);
  });

  test(
    'a pack by weight is one piece, and counted items give whole pieces',
    () {
      final result = buildPreparedMealFromVorlage(
        currentItems: [
          _grams('mozzarella', 'Mozzarella 125 g', 125),
          _counted('lemons', 'Zitrone', 3),
          _grams('rice', 'Reis', 500),
        ],
        preparedMealId: 'meal',
        now: DateTime(2026, 10, 19),
        vorlage: _vorlage,
        totalPortions: 1,
        foods: const [
          (
            name: 'Mozzarella',
            unit: InventoryAmountUnit.piece,
            amount: 1,
            itemIds: ['mozzarella'],
          ),
          (
            name: 'Zitrone',
            unit: InventoryAmountUnit.piece,
            amount: 1 / 3,
            itemIds: ['lemons'],
          ),
          // A third of 100 g counts whole and leaves no row open.
          (
            name: 'Reis',
            unit: InventoryAmountUnit.gram,
            amount: 100 / 3,
            itemIds: ['rice'],
          ),
        ],
      );

      expect(
        result.preparedMeal.components.map(
          (c) => (c.inventoryItemId, c.usedAmount),
        ),
        [('mozzarella', 125), ('lemons', 1), ('rice', 33)],
      );
      expect(result.preparedMeal.pendingRecipeIngredients, isEmpty);
    },
  );

  test('a Vorlage without foods is no meal', () {
    expect(
      () => buildPreparedMealFromVorlage(
        currentItems: const [],
        preparedMealId: 'meal',
        now: DateTime(2026, 10, 19),
        vorlage: _vorlage,
        totalPortions: 1,
        foods: const [],
      ),
      throwsA(isA<PreparedMealBuildException>()),
    );
  });

  test('an open part of a piece is a row the Vorrat can fill', () {
    final result = buildPreparedMealFromVorlage(
      currentItems: const [],
      preparedMealId: 'meal',
      now: DateTime(2026, 10, 19),
      vorlage: _vorlage,
      totalPortions: 1,
      foods: const [
        (
          name: 'Zitrone',
          unit: InventoryAmountUnit.piece,
          amount: 1 / 3,
          itemIds: [],
        ),
      ],
    );

    final row = result.preparedMeal.pendingRecipeIngredients.single;
    expect(row, '1 Zitrone');
    expect(
      const TemplateIngredientParser().parseRequirement(
        ingredient: row,
        selectedPortions: 1,
        basePortions: 1,
      ),
      isNotNull,
    );
  });

  test('whole pieces rounded down still cover the food', () {
    final result = buildPreparedMealFromVorlage(
      currentItems: [_counted('eggs', 'Eier', 10)],
      preparedMealId: 'meal',
      now: DateTime(2026, 10, 19),
      vorlage: _vorlage,
      totalPortions: 1,
      foods: const [
        (
          name: 'Eier',
          unit: InventoryAmountUnit.piece,
          amount: 7 / 3,
          itemIds: ['eggs'],
        ),
      ],
    );

    expect(result.preparedMeal.components.single.usedAmount, 2);
    expect(result.preparedMeal.pendingRecipeIngredients, isEmpty);
  });

  test('a rounding rest takes nothing from the next item', () {
    final result = buildPreparedMealFromVorlage(
      currentItems: [
        _pieces('lemon', 'Zitrone', 1),
        _counted('lemons', 'Zitrone', 3),
      ],
      preparedMealId: 'meal',
      now: DateTime(2026, 10, 19),
      vorlage: _vorlage,
      totalPortions: 1,
      // Two lemons for six portions, cooked for one.
      foods: const [
        (
          name: 'Zitrone',
          unit: InventoryAmountUnit.piece,
          amount: 2 / 6,
          itemIds: ['lemon', 'lemons'],
        ),
      ],
    );

    expect(
      result.preparedMeal.components.map(
        (c) => (c.inventoryItemId, c.usedAmount),
      ),
      [('lemon', 333)],
    );
    expect(result.preparedMeal.pendingRecipeIngredients, isEmpty);
  });
}
