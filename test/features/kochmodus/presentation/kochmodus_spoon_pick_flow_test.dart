import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/inventory_stock_amount_page.dart';
import 'package:yamt/features/inventory/presentation/models/food_pick_route_args.dart';
import 'package:yamt/features/inventory/presentation/models/recipe_food_pick.dart';
import 'package:yamt/features/inventory/presentation/widgets/stock_amount/stock_amount_parts.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_assign_page.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_page.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_card_answers.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_entered_card.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_item_picker_sheet.dart';
import 'package:yamt/features/product_search_hub/domain/recipe_guess_item.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';
import 'kochmodus_page_harness.dart';

const _pickKey = Key('spoon-pick-food');

const _estimate = FoodEstimate(
  name: 'Olivenöl',
  portionGrams: 10,
  kcalLean: 880,
  kcalRich: 900,
  per100: GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
    per100Kcal: 884,
  ),
  ingredients: [],
);

const _tenMl = CookLineConversion(
  amountPerPiece: 10,
  unit: TemplateIngredientUnit.milliliter,
);

CookRun _run(List<CookRunLine> lines) => buildCookRun(
  pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
  steps: const [],
  lines: lines,
);

void main() {
  late KochmodusCookingHarness harness;
  RecipeFoodPick Function()? answer;
  FoodPickRouteArgs? pickArgs;

  setUp(() async {
    harness = await KochmodusCookingHarness.open();
    answer = null;
    pickArgs = null;
  });

  Future<void> open(
    WidgetTester tester,
    CookRun run, {
    List<InventoryItem> items = const [],
  }) async {
    await harness.stock(tester, items);
    await harness.store(tester, run);
    await openPage(
      tester,
      harness,
      const KochmodusAssignPage(recipeId: 't1'),
      routes: [
        GoRoute(
          path: AppRoutes.homeCookRun,
          builder: (context, state) =>
              KochmodusPage.run(runId: state.pathParameters['runId']!),
        ),
        GoRoute(
          path: AppRoutes.homeFoodPick,
          builder: (context, state) {
            pickArgs = state.extra as FoodPickRouteArgs?;
            return Scaffold(
              body: TextButton(
                key: _pickKey,
                onPressed: () => context.pop<RecipeFoodPick>(answer!()),
                child: const Text('pick'),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await harness.idle(tester);
  }

  FoodPickRouteArgs pick() => pickArgs!;

  RecipeFoodNew newFood(InventoryItem item, {required int amount}) =>
      RecipeFoodNew((
        result: InventoryReceiptManualProductResult(
          item: item,
          action: InventoryReceiptManualProductAction.addToInventory,
          requiresGlobalPersistence: false,
          skipMissingBarcodePrompt: true,
        ),
        request: InventoryItemEatRequest(
          inventoryAmount: amount,
          loggedAt: DateTime(2026, 11, 12),
          mealType: MealType.lunch,
        ),
      ));

  Future<Map<String, int>> takesOf(WidgetTester tester, String lineId) async {
    final run = await harness.storedRun(tester, 'recipe-t1');
    final line = run.lines.singleWhere((line) => line.id == lineId);
    return {
      for (final take in (line.settlement as LineAssigned).takes)
        take.itemId: take.amount,
    };
  }

  group('"Hab ich" on a line in spoons asks the food pick by weight', () {
    testWidgets("with the recipe's weight of a spoon, in its unit", (
      tester,
    ) async {
      await open(
        tester,
        _run([
          textLine('a', '5 EL Olivenöl', conversion: _tenMl),
          textLine('b', 'Milch'),
        ]),
      );

      await tap(tester, KochmodusCardAnswers.haveKey);

      expect(pick().ingredientUnit, InventoryAmountUnit.milliliter);
      expect(pick().ingredientNeed, 50);
      expect(pick().query, 'Olivenöl');
      expect(pick().ingredient, '5 EL Olivenöl');
      expect(pick().pieceWeight, isNull);
    });

    testWidgets('with a standard spoon without a weight from the recipe', (
      tester,
    ) async {
      await open(
        tester,
        _run([textLine('a', '2 EL Honig'), textLine('b', 'Milch')]),
      );

      await tap(tester, KochmodusCardAnswers.haveKey);

      expect(pick().ingredientUnit, InventoryAmountUnit.gram);
      expect(pick().ingredientNeed, 30);
      expect(pick().pieceWeight, isNull);
    });

    testWidgets('and keeps a scoop without a weight in pieces', (tester) async {
      await open(
        tester,
        _run([textLine('a', '2 Tassen Reis'), textLine('b', 'Milch')]),
      );

      await tap(tester, KochmodusCardAnswers.haveKey);

      expect(pick().ingredientUnit, InventoryAmountUnit.piece);
      expect(pick().ingredientNeed, 2);
      expect(pick().pieceWeight, isNull);
    });

    testWidgets('and gives the piece weight of a line in pieces', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          textLine(
            'a',
            '3 Eier',
            conversion: const CookLineConversion(
              amountPerPiece: 60,
              unit: TemplateIngredientUnit.gram,
            ),
          ),
          textLine('b', 'Milch'),
        ]),
      );

      await tap(tester, KochmodusCardAnswers.haveKey);

      expect(pick().ingredientUnit, InventoryAmountUnit.piece);
      expect(pick().ingredientNeed, 3);
      expect(pick().pieceWeight, 60);
    });
  });

  group('the food pick asks for the whole name of the food', () {
    testWidgets('"1/2 TL Schwarzer Pfeffer" searches "Schwarzer Pfeffer"', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          textLine('a', '1/2 TL Schwarzer Pfeffer'),
          textLine('b', 'Milch'),
        ]),
      );

      await tap(tester, KochmodusCardAnswers.haveKey);

      expect(pick().query, 'Schwarzer Pfeffer');
      expect(pick().ingredient, '1/2 TL Schwarzer Pfeffer');
    });

    testWidgets('a bracket addition stays out of the search, in the line', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          textLine('a', '100 g Frischkäse (Doppelrahmstufe)'),
          textLine('b', 'Milch'),
        ]),
      );

      await tap(tester, KochmodusCardAnswers.haveKey);

      expect(pick().query, 'Frischkäse');
      expect(pick().ingredient, '100 g Frischkäse (Doppelrahmstufe)');
    });
  });

  group('a line in spoons takes a standard spoon', () {
    testWidgets('"Hab ich" and a tap on the one jar in grams takes it', (
      tester,
    ) async {
      await open(
        tester,
        _run([textLine('a', '2 EL Honig'), textLine('b', 'Milch')]),
        items: [stockItem('jar', 250).copyWith(name: 'Honig')],
      );

      await tap(tester, KochmodusCardAnswers.haveKey);
      // Not by itself: the picker waits for the cook.
      expect(find.byKey(KochmodusEnteredCard.cardKey), findsNothing);
      await tap(tester, KochmodusItemPickerSheet.rowKey('jar'));

      expect(pickArgs, isNull);
      expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
      expect(await takesOf(tester, 'a'), {'jar': 30});
    });

    testWidgets('an estimated food from the pick gives the line its weight', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          textLine('a', '5 EL Olivenöl', conversion: _tenMl),
          textLine('b', 'Milch'),
        ]),
      );
      await tap(tester, KochmodusCardAnswers.haveKey);
      // What "Egal, irgendeins" makes from the pick's need.
      final guessed = recipeGuessItem(
        baseItem: stockItem('guess', 1),
        estimate: _estimate,
        description: 'Olivenöl',
        unit: InventoryAmountUnit.milliliter,
        need: pick().ingredientNeed!,
      );
      answer = () => newFood(guessed.item, amount: guessed.amount);

      await tap(tester, _pickKey);

      expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
      expect((await takesOf(tester, 'a')).values.single, 50);
    });

    testWidgets('"Ändern" of a new food shows the need by weight', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          textLine('a', '5 EL Olivenöl', conversion: _tenMl),
          textLine('b', 'Milch'),
        ]),
      );
      await tap(tester, KochmodusCardAnswers.haveKey);
      final guessed = recipeGuessItem(
        baseItem: stockItem('guess', 1),
        estimate: _estimate,
        description: 'Olivenöl',
        unit: InventoryAmountUnit.milliliter,
        need: 50,
      );
      answer = () => newFood(guessed.item, amount: guessed.amount);
      await tap(tester, _pickKey);

      await tap(tester, KochmodusEnteredCard.changeKey);

      expect(find.byType(InventoryStockAmountPage), findsOneWidget);
      expect(find.byKey(StockAmountNeedLine.lineKey), findsOneWidget);
    });
  });
}
