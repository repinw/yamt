import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_view_builder.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

import '../../../../support/prepared_meal_test_data.dart';

const _lines = ['200 g Pasta', '100 g Tomaten'];
const _pasta = RecipeLineNutrition(kcal: 700, protein: 24, carbs: 140, fat: 4);
const _tomato = RecipeLineNutrition(kcal: 20, protein: 1, carbs: 4, fat: 0.5);

RecipeEstimate _estimate({
  List<RecipeLineNutrition>? lines,
  int portions = 2,
  List<String> forLines = _lines,
}) => RecipeEstimate(
  kcal: 360,
  protein: 12.5,
  carbs: 72,
  fat: 2.25,
  portions: portions,
  linesKey: recipeLinesKey(forLines),
  createdAt: DateTime.utc(2026, 11, 13),
  lines: lines,
);

PreparedMeal _recipe({RecipeEstimate? estimate, List<String> lines = _lines}) =>
    preparedMealTestData(
      id: 'r1',
      name: 'Tomatenpasta',
      totalPortions: 2,
    ).copyWith(
      components: const [],
      recipeIngredients: lines,
      recipeEstimate: estimate,
    );

RecipeView _view(PreparedMeal recipe, {int? portions}) => buildRecipeView(
  recipeId: 'r1',
  templates: AsyncData([recipe]),
  items: const AsyncData([]),
  parser: const TemplateIngredientParser(),
  localeCode: 'de',
  portions: portions,
).requireValue!;

void main() {
  group('RecipeView.lineNutrition', () {
    test('gives each ingredient with its own nutrition for its portions', () {
      final view = _view(
        _recipe(estimate: _estimate(lines: const [_pasta, _tomato])),
      );

      final rows = view.lineNutrition!;

      expect(rows, hasLength(2));
      expect(rows.first.food, view.lines.first.row.foodName);
      expect(rows.first.nutrition, _pasta);
      expect(rows.last.food, view.lines.last.row.foodName);
      expect(rows.last.nutrition, _tomato);
    });

    test('scales to the chosen portions', () {
      final view = _view(
        _recipe(estimate: _estimate(lines: const [_pasta, _tomato])),
        portions: 6,
      );

      final rows = view.lineNutrition!;

      expect(rows.first.nutrition.kcal, 2100);
      expect(rows.first.nutrition.protein, 72);
      expect(rows.last.nutrition.fat, 1.5);
    });

    test('scales down to fewer portions', () {
      final view = _view(
        _recipe(estimate: _estimate(lines: const [_pasta, _tomato])),
        portions: 1,
      );

      expect(view.lineNutrition!.first.nutrition.kcal, 350);
    });

    test('is null for an estimate without per-line values', () {
      expect(_view(_recipe(estimate: _estimate())).lineNutrition, isNull);
    });

    test('is null without an estimate', () {
      expect(_view(_recipe()).lineNutrition, isNull);
    });

    test('is null when the estimate has another number of lines', () {
      final view = _view(_recipe(estimate: _estimate(lines: const [_pasta])));

      expect(view.estimate, isNotNull);
      expect(view.lineNutrition, isNull);
    });

    test('is null once the ingredients changed since the estimate', () {
      final view = _view(
        _recipe(
          lines: const ['200 g Pasta', '150 g Tomaten'],
          estimate: _estimate(lines: const [_pasta, _tomato]),
        ),
      );

      expect(view.estimate, isNull);
      expect(view.lineNutrition, isNull);
    });

    test('is null once the recipe portions changed since the estimate', () {
      final view = _view(
        _recipe(
          estimate: _estimate(lines: const [_pasta, _tomato], portions: 4),
        ),
      );

      expect(view.lineNutrition, isNull);
    });
  });

  group('the names of the rows', () {
    const names = {
      '500 g Penne Rigate': 'Penne Rigate',
      '2 Zehen Knoblauch': 'Knoblauch',
      '2 EL Olivenöl': 'Olivenöl',
      '1 Prise Salz': 'Salz',
      '1 Prise Schwarzer Pfeffer': 'Schwarzer Pfeffer',
      '1 TL Oregano getrocknet': 'Oregano getrocknet',
      '½ Zitrone': 'Zitrone',
      'eine halbe Zitrone': 'Zitrone',
      'zwei Zwiebeln': 'Zwiebeln',
      '1 Dose (400 g) Tomaten': 'Tomaten',
      'Öl, 30 g': 'Öl',
    };

    for (final MapEntry(key: line, value: food) in names.entries) {
      test('"$line" is "$food"', () {
        final view = _view(
          _recipe(
            lines: [line],
            estimate: _estimate(lines: const [_pasta], forLines: [line]),
          ),
        );

        expect(view.lineNutrition!.single.food, food);
      });
    }
  });

  group('RecipeView.anyLineInStock', () {
    final flour = InventoryItem.create(
      id: 'flour',
      name: 'Pasta',
      entryDate: DateTime.utc(2026, 11),
      storeName: 'Store',
      quantity: 1,
      initialAmount: 500,
      currentAmount: 500,
      amountUnit: InventoryAmountUnit.gram,
    );

    RecipeView viewWith(List<InventoryItem> items) => buildRecipeView(
      recipeId: 'r1',
      templates: AsyncData([_recipe()]),
      items: AsyncData(items),
      parser: const TemplateIngredientParser(),
      localeCode: 'de',
      portions: null,
    ).requireValue!;

    test('is false while the Vorrat supplies none of the lines', () {
      expect(viewWith(const []).anyLineInStock, isFalse);
    });

    test('is true once one line has a Vorrat item', () {
      final view = viewWith([flour]);

      expect(view.lines.first.items, isNotEmpty);
      expect(view.lines.last.items, isEmpty);
      expect(view.anyLineInStock, isTrue);
    });
  });

  group('RecipeView.portionFacts', () {
    test('gives energy and the macros of one portion in whole values', () {
      final view = _view(_recipe(estimate: _estimate()));

      final facts = view.portionFacts!;

      expect(facts.kcal, 360);
      expect(facts.protein, 13);
      expect(facts.carbs, 72);
      expect(facts.fat, 2);
      expect(facts.sugar, isNull);
    });

    test('is the same at other portions', () {
      final view = _view(_recipe(estimate: _estimate()), portions: 6);

      expect(view.portions, 6);
      expect(view.portionFacts!.kcal, 360);
      expect(view.portionFacts!.protein, 13);
    });

    test('is null without an estimate', () {
      expect(_view(_recipe()).portionFacts, isNull);
    });

    test('is null when the estimate no longer fits the lines', () {
      final view = _view(
        _recipe(estimate: _estimate(forLines: const ['100 g Reis'])),
      );

      expect(view.portionFacts, isNull);
    });
  });
}
