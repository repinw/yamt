import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/nutrition_facts.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/eat_meal_nutrition.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/application/cook_finish_check.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_portion_builder.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_view_builder.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../../recipes/cook_run_fixtures.dart';
import '../../kochmodus_fixtures.dart';

final _pots = CookPotsChosen(pots: const [cookPotA, cookPotB], inCans: false);

KochmodusView _view(CookRun run, {List<InventoryItem> items = const []}) =>
    buildKochmodusView(
      run: run,
      saved: true,
      ended: false,
      busy: false,
      reopened: false,
      finished: null,
      tab: null,
      items: items,
      otherReservations: const {},
      utensils: const [],
      parser: const TemplateIngredientParser(),
    );

CookRun _portionRun(
  List<CookRunLine> lines, {
  CookPotChoice? pots,
  List<CookMealDraft> meals = const [],
}) => buildCookRun(
  step: CookRunStep.portion,
  pots: pots ?? _pots,
  steps: const [],
  lines: lines,
  meals: meals,
);

CookRun _settled(List<CookRunLine> lines, {int portions = 4}) =>
    buildCookRun(pots: _pots, lines: lines, portions: portions);

void main() {
  group('kochmodusPortionLabel', () {
    test('energy and macros equal the portion of the take', () {
      final run = _settled([
        textLine('a', '800 g Reis', settlement: assigned({'i1': 800})),
      ]);
      final view = _view(run, items: [stockItem('i1', 1000)]);

      final label = kochmodusPortionLabel(run, view.lines)!;

      // 800 g at 100 kcal, 1 g of each macro per 100 g, over 4 portions.
      expect(label.total.kcal, 200);
      expect(label.total.protein, 2);
      expect(label.total.carbs, 2);
      expect(label.total.fat, 2);
      expect(label.incomplete, isEmpty);
      expect(view.portionLabel?.total.kcal, label.total.kcal);
      expect(view.portionLabel?.total.fat, label.total.fat);
      expect(view.perPortion, kochmodusPortionMacros(label));
      expect(view.perPortion, (kcal: 200, protein: 2, carbs: 2, fat: 2));
    });

    test('follows the portions of the run', () {
      final run = _settled([
        textLine('a', '800 g Reis', settlement: assigned({'i1': 800})),
      ], portions: 2);
      final view = _view(run, items: [stockItem('i1', 1000)]);

      expect(kochmodusPortionLabel(run, view.lines)?.total.kcal, 400);
    });

    test('a nutrient one food does not list is incomplete: a minimum', () {
      final sweet = stockItem('sweet', 1000, nutrition: _withSugar);
      final plain = stockItem('plain', 1000);
      final run = _settled([
        textLine('a', '400 g Reis', settlement: assigned({'sweet': 400})),
        textLine('b', '400 g Mehl', settlement: assigned({'plain': 400})),
      ]);
      final view = _view(run, items: [sweet, plain]);

      final label = kochmodusPortionLabel(run, view.lines)!;

      expect(label.incomplete, contains(Nutrient.sugar));
      expect(label.total.sugar, closeTo(5, 0.001));
      // Energy and macros stay complete.
      expect(label.incomplete, isNot(contains(Nutrient.kcal)));
      expect(label.total.kcal, 200);
    });

    test('is null when something is on the shopping list', () {
      final run = _settled([
        textLine('a', '800 g Reis', settlement: assigned({'i1': 800})),
        textLine('b', 'Milch', settlement: const LineShopping()),
      ]);
      final view = _view(run, items: [stockItem('i1', 1000)]);

      expect(view.portionLabel, isNull);
      expect(view.perPortion, isNull);
    });

    test('is null while a line is open', () {
      final run = _settled([
        textLine('a', '800 g Reis', settlement: assigned({'i1': 800})),
        textLine('b', 'Milch'),
      ]);
      final view = _view(run, items: [stockItem('i1', 1000)]);

      expect(view.portionLabel, isNull);
    });

    test('is null when a take has no complete nutrition', () {
      final run = _settled([
        textLine('a', '800 g Reis', settlement: assigned({'i1': 800})),
      ]);
      final view = _view(run, items: [stockItem('i1', 1000, nutrition: null)]);

      expect(kochmodusPortionLabel(run, view.lines), isNull);
      expect(view.portionLabel, isNull);
    });

    test('is null when nothing is taken', () {
      final run = _settled([
        textLine('a', 'Salz', settlement: const LineIgnored()),
      ]);
      final view = _view(run);

      expect(kochmodusPortionLabel(run, view.lines), isNull);
      expect(view.portionLabel, isNull);
    });
  });

  group('kochmodusPortionMacros', () {
    EatMealNutrition meal(NutritionFacts eaten) => EatMealNutrition.combine([
      (eaten: eaten, amount: 0, unit: ConsumedUnit.grams),
    ]);

    test('rounds energy and the three macros', () {
      final portion = meal(
        const NutritionFacts(kcal: 199.6, protein: 2.4, carbs: 2.5, fat: 1.49),
      );

      expect(kochmodusPortionMacros(portion), (
        kcal: 200,
        protein: 2,
        carbs: 3,
        fat: 1,
      ));
    });

    test('throws a StateError without energy or one macro', () {
      expect(
        () => kochmodusPortionMacros(
          meal(const NutritionFacts(protein: 2, carbs: 2, fat: 2)),
        ),
        throwsStateError,
      );
      expect(
        () => kochmodusPortionMacros(
          meal(const NutritionFacts(kcal: 100, protein: 2, carbs: 2)),
        ),
        throwsStateError,
      );
    });
  });

  group('potToWeigh', () {
    CookRunLine lineIn(String id, CookPot pot) =>
        textLine(id, 'Reis', settlement: assigned({'i1': 100}), potId: pot.id);

    final items = [stockItem('i1', 500)];

    test('is the meal of the one pot that waits for its weight', () {
      final view = _view(
        _portionRun([lineIn('a', cookPotA)], pots: _onePot),
        items: items,
      );

      expect(view.portion.blocks.first, isA<CookPotUnweighed>());
      expect(view.portion.potToWeigh?.potId, cookPotA.id);
      expect(view.portion.unweighedPots, 1);
    });

    test('with two pots and the first weighed it is the second', () {
      final view = _view(
        _portionRun(
          [lineIn('a', cookPotA), lineIn('b', cookPotB)],
          meals: const [
            CookMealDraft(
              potId: 'pot-a',
              name: 'Eintopf',
              count: 4,
              inPieces: false,
              grossWeight: 2400,
            ),
          ],
        ),
        items: items,
      );

      expect(view.portion.unweighedPots, 1);
      expect(view.portion.potToWeigh?.potId, cookPotB.id);
    });

    test('with two pots waiting it is the first of them', () {
      final view = _view(
        _portionRun([lineIn('a', cookPotA), lineIn('b', cookPotB)]),
        items: items,
      );

      expect(view.portion.unweighedPots, 2);
      expect(view.portion.potToWeigh?.potId, cookPotA.id);
    });

    test('is null when every pot is weighed', () {
      final view = _view(
        _portionRun(
          [lineIn('a', cookPotA), lineIn('b', cookPotB)],
          meals: const [
            CookMealDraft(
              potId: 'pot-a',
              name: 'Eintopf',
              count: 4,
              inPieces: false,
              grossWeight: 2400,
            ),
            CookMealDraft(
              potId: 'pot-b',
              name: 'Suppe',
              count: 2,
              inPieces: false,
              grossWeight: 1800,
            ),
          ],
        ),
        items: items,
      );

      expect(view.portion.unweighedPots, 0);
      expect(view.portion.potToWeigh, isNull);
    });

    test('is null when another reason comes first', () {
      final view = _view(
        _portionRun([
          textLine(
            'a',
            '300 g Reis',
            settlement: assigned({'i1': 300}),
            potId: cookPotA.id,
          ),
        ]),
        items: [stockItem('i1', 100)],
      );

      expect(view.portion.blocks.first, isA<CookStockShort>());
      expect(view.portion.potToWeigh, isNull);
    });

    test('a pot at or below its empty weight still waits', () {
      final view = _view(
        _portionRun(
          [lineIn('a', cookPotA)],
          pots: _onePot,
          meals: [
            CookMealDraft(
              potId: cookPotA.id,
              name: 'Eintopf',
              count: 4,
              inPieces: false,
              grossWeight: cookPotA.emptyWeight,
            ),
          ],
        ),
        items: items,
      );

      expect(view.portion.potToWeigh?.potId, cookPotA.id);
    });
  });
}

final _onePot = CookPotsChosen(pots: const [cookPotA], inCans: false);

const _withSugar = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 100,
  per100Protein: 1,
  per100Carbs: 1,
  per100Fat: 1,
  per100Sugar: 5,
);
