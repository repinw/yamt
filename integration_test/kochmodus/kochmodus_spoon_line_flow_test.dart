import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/food_pick_route_args.dart';
import 'package:yamt/features/inventory/presentation/models/recipe_food_pick.dart';
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

import '../../test/features/kochmodus/kochmodus_fixtures.dart';
import '../../test/features/kochmodus/presentation/kochmodus_cooking_harness.dart';
import '../../test/features/kochmodus/presentation/kochmodus_held_support.dart';
import '../../test/features/kochmodus/presentation/kochmodus_page_harness.dart';
import '../../test/features/recipes/cook_run_fixtures.dart';

const _pickKey = Key('spoon-flow-pick');

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

CookRun _run(List<CookRunLine> lines) => buildCookRun(
  pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
  steps: const [],
  lines: lines,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<FoodPickRouteArgs?> Function() openAssign(
    WidgetTester tester,
    KochmodusCookingHarness harness, {
    required RecipeFoodPick Function(FoodPickRouteArgs args) answer,
  }) {
    FoodPickRouteArgs? foodSearch;
    return () async {
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
              final args = state.extra! as FoodPickRouteArgs;
              foodSearch = args;
              return Scaffold(
                body: TextButton(
                  key: _pickKey,
                  onPressed: () => context.pop<RecipeFoodPick>(answer(args)),
                  child: const Text('pick'),
                ),
              );
            },
          ),
        ],
      );
      return foodSearch;
    };
  }

  testWidgets('"5 EL Olivenöl" asks the food pick by weight, and "Egal, '
      'irgendeins" gives a food the line takes 50 ml of', (tester) async {
    final harness = await KochmodusCookingHarness.open();
    await harness.store(
      tester,
      _run([
        textLine(
          'a',
          '5 EL Olivenöl',
          conversion: const CookLineConversion(
            amountPerPiece: 10,
            unit: TemplateIngredientUnit.milliliter,
          ),
        ),
        textLine('b', 'Milch'),
      ]),
    );
    await openAssign(
      tester,
      harness,
      answer: (args) {
        final guessed = recipeGuessItem(
          baseItem: stockItem('guess', 1),
          estimate: _estimate,
          description: 'Olivenöl',
          unit: InventoryAmountUnit.milliliter,
          need: args.ingredientNeed!,
        );
        return newPackFood(guessed.item, amount: guessed.amount);
      },
    )();

    await tester.tap(find.byKey(KochmodusCardAnswers.haveKey));
    await harness.idle(tester);
    expect(find.byKey(_pickKey), findsOneWidget);
    await tester.tap(find.byKey(_pickKey));
    await harness.idle(tester);

    expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
    final stored = await harness.storedRun(tester, 'recipe-t1');
    final takes =
        (stored.lines.singleWhere((line) => line.id == 'a').settlement
                as LineAssigned)
            .takes;
    expect(takes.single.amount, 50);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('"2 EL Honig" takes a standard spoon from the jar the cook '
      'taps', (tester) async {
    final harness = await KochmodusCookingHarness.open();
    await harness.stock(tester, [
      stockItem('jar', 250).copyWith(name: 'Honig'),
    ]);
    await harness.store(
      tester,
      _run([textLine('a', '2 EL Honig'), textLine('b', 'Milch')]),
    );
    await openAssign(
      tester,
      harness,
      answer: (_) => throw StateError('none'),
    )();

    await tester.tap(find.byKey(KochmodusCardAnswers.haveKey));
    await harness.idle(tester);
    // The app takes nothing by itself: the cook taps the jar.
    expect(find.byKey(KochmodusEnteredCard.cardKey), findsNothing);
    await tester.tap(find.byKey(KochmodusItemPickerSheet.rowKey('jar')));
    await harness.idle(tester);

    expect(find.byKey(_pickKey), findsNothing);
    expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
    final stored = await harness.storedRun(tester, 'recipe-t1');
    final takes =
        (stored.lines.singleWhere((line) => line.id == 'a').settlement
                as LineAssigned)
            .takes;
    expect(takes.single.itemId, 'jar');
    expect(takes.single.amount, 30);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('"1 TL Zimt" takes the 4 g that are left and asks for nothing '
      'more', (tester) async {
    final harness = await KochmodusCookingHarness.open();
    await harness.stock(tester, [stockItem('z', 4).copyWith(name: 'Zimt')]);
    await harness.store(
      tester,
      _run([textLine('a', '1 TL Zimt'), textLine('b', 'Milch')]),
    );
    await openAssign(
      tester,
      harness,
      answer: (_) => throw StateError('none'),
    )();

    await tester.tap(find.byKey(KochmodusCardAnswers.haveKey));
    await harness.idle(tester);
    await tester.tap(find.byKey(KochmodusItemPickerSheet.rowKey('z')));
    await harness.idle(tester);

    expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
    expect(find.byKey(KochmodusCardAnswers.buyRestKey), findsNothing);
    final stored = await harness.storedRun(tester, 'recipe-t1');
    final takes =
        (stored.lines.singleWhere((line) => line.id == 'a').settlement
                as LineAssigned)
            .takes;
    expect(takes.single.itemId, 'z');
    expect(takes.single.amount, 4);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('"1 Zwiebel" on a food kept in g is weighed while cooking', (
    tester,
  ) async {
    final harness = await KochmodusCookingHarness.open();
    await harness.stock(tester, [
      stockItem('onion', 800).copyWith(name: 'Zwiebel'),
    ]);
    await harness.store(
      tester,
      _run([textLine('a', '1 Zwiebel'), textLine('b', 'Milch')]),
    );
    await openAssign(
      tester,
      harness,
      answer: (_) => throw StateError('none'),
    )();

    await tester.tap(find.byKey(KochmodusCardAnswers.haveKey));
    await harness.idle(tester);
    await tester.tap(find.byKey(KochmodusItemPickerSheet.rowKey('onion')));
    await harness.idle(tester);
    // The weight comes while cooking: the tapped food covers the line and the
    // picker closes at once.

    // No guess is passed off as a weight: the cook weighs it while cooking.
    final l10n = harness.l10n(tester);
    expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
    expect(
      find.text(l10n.kochmodusEnteredFromStockWeigh('800\u00A0g')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
