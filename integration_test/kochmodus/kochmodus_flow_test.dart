import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/home_bottom_nav_bar.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/data/closed_day_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/cookbook_new/presentation/cookbook_page.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_page.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_cook_actions.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_recipe_card.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_running_section.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/models/recipe_food_pick.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_assign_page.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_page.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_assign_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_card_answers.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_change_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_cook_list.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_discard_menu.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_done_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_entered_card.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_ingredient_row.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_item_picker_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_meal_box.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_portion_lines.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_portion_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_pots_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_ready_card.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_take_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_type_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_voice_bar.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_weigh_sheet.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_planned_entry_repository.dart';
import '../../test/features/kochmodus/kochmodus_fixtures.dart';
import '../../test/features/kochmodus/presentation/kochmodus_cooking_harness.dart';
import '../../test/features/kochmodus/presentation/kochmodus_page_harness.dart';
import '../../test/features/recipes/cook_run_fixtures.dart';
import '../../test/features/shoppinglist/support/fake_shopping_list_repository.dart';
import '../../test/helpers/fake_signed_in_user.dart';
import '../../test/helpers/memory_app_preferences.dart';

GoRoute _placeholder(String path) => GoRoute(
  path: path,
  builder: (context, state) => Scaffold(key: ValueKey<String>(path)),
);

const _pickKey = Key('kochmodus-flow-pick-found-food');

/// The product search "Hab ich" opens when no food of the Vorrat is the one
/// the line names: one button that hands back [found] as a new food with
/// [amount] of it.
GoRoute _foodPickRoute(InventoryItem found, int amount) => GoRoute(
  path: AppRoutes.homeFoodPick,
  builder: (context, state) => Scaffold(
    body: TextButton(
      key: _pickKey,
      onPressed: () => context.pop<RecipeFoodPick>(
        RecipeFoodNew((
          result: InventoryReceiptManualProductResult(
            item: found,
            action: InventoryReceiptManualProductAction.addToInventory,
            requiresGlobalPersistence: false,
            skipMissingBarcodePrompt: true,
          ),
          request: InventoryItemEatRequest(
            inventoryAmount: amount,
            loggedAt: DateTime(2026, 11, 8),
            mealType: MealType.lunch,
          ),
        )),
      ),
      child: const Text('pick'),
    ),
  ),
);

/// The real Kochbuch tab with the real recipe page and cooking routes on top
/// of it, over the real cook run repositories of [harness].
Future<void> _openCookbook(
  WidgetTester tester,
  KochmodusCookingHarness harness,
  FakeShoppingListRepository shopping, {
  List<RouteBase> routes = const [],
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(800, 3000);
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: AppRoutes.homeInventoryTemplates,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomePage(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [_placeholder(AppRoutes.homeInventory)]),
          StatefulShellBranch(routes: [_placeholder(AppRoutes.homeDiary)]),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeInventoryTemplates,
                builder: (context, state) => const CookbookPage(),
              ),
            ],
          ),
          StatefulShellBranch(routes: [_placeholder(AppRoutes.homeProgress)]),
        ],
      ),
      GoRoute(
        path: AppRoutes.homeRecipe,
        builder: (context, state) =>
            RecipePage(recipeId: state.pathParameters['recipeId']!),
      ),
      GoRoute(
        path: AppRoutes.homeCook,
        builder: (context, state) => KochmodusAssignPage(
          recipeId: state.pathParameters['recipeId']!,
          portions: int.tryParse(
            state.uri.queryParameters[AppRoutes.homeCookPortionsParam] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.homeCookRun,
        builder: (context, state) =>
            KochmodusPage.run(runId: state.pathParameters['runId']!),
      ),
      GoRoute(
        path: AppRoutes.homeFreeCooking,
        builder: (context, state) => const KochmodusPage.free(),
      ),
      ...routes,
    ],
  );
  addTearDown(router.dispose);
  harness.router = router;
  final container = ProviderContainer(
    overrides: [
      ...harness.overrides,
      authStateChangesProvider.overrideWith(
        (ref) => Stream.value(FakeSignedInUser(kochmodusTestUserId)),
      ),
      shoppingListRepositoryProvider.overrideWithValue(shopping),
      plannedEntryRepositoryProvider.overrideWithValue(
        FakePlannedEntryRepository(),
      ),
      closedDayRepositoryProvider.overrideWithValue(
        ClosedDayRepository(MemoryAppPreferences(), kochmodusTestUserId),
      ),
      inventoryQuickEatMealsProvider.overrideWith((ref) => Stream.value([])),
    ],
  );
  addTearDown(container.dispose);
  harness.container = container;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await harness.idle(tester);
}

Future<void> _tap(
  WidgetTester tester,
  KochmodusCookingHarness harness,
  Key key,
) async {
  final target = find.byKey(key);
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await harness.idle(tester);
}

// The system back: closes the page on top.
Future<void> _back(WidgetTester tester, KochmodusCookingHarness harness) async {
  harness.router.pop();
  await harness.idle(tester);
}

// Puts the line [lineId] on the card, if it is not there, says "Hab ich" and
// taps the Vorrat food [itemId] in the picker; when the food holds a bit more
// than the line needs, the cook answers "Wie viel nimmst du?" with [answer].
Future<void> _have(
  WidgetTester tester,
  KochmodusCookingHarness harness,
  String lineId,
  String itemId, {
  KochmodusTakeAnswer answer = KochmodusTakeAnswer.recipe,
}) async {
  await _tap(tester, harness, KochmodusIngredientRow.rowKey(lineId));
  await _pickFood(tester, harness, itemId, answer: answer);
}

// "Hab ich" on the card, a tap on the food [itemId] in the picker, and the
// answer to the question how much of it the line takes, if it is asked.
Future<void> _pickFood(
  WidgetTester tester,
  KochmodusCookingHarness harness,
  String itemId, {
  KochmodusTakeAnswer answer = KochmodusTakeAnswer.recipe,
}) async {
  await _tap(tester, harness, KochmodusCardAnswers.haveKey);
  await _tap(tester, harness, KochmodusItemPickerSheet.rowKey(itemId));
  if (find.byType(KochmodusTakeSheet).evaluate().isNotEmpty) {
    await _tap(tester, harness, KochmodusTakeSheet.answerKey(answer));
  }
}

// The pot on the scale: 1200 g, from the pot's field or, with
// [fromMainButton], from the main button that says "Topf wiegen".
Future<void> _weighPot(
  WidgetTester tester,
  KochmodusCookingHarness harness,
  String potId, {
  bool fromMainButton = false,
}) async {
  await _tap(
    tester,
    harness,
    fromMainButton
        ? KochmodusPortionStep.toStockKey
        : KochmodusMealBox.weighKey(potId),
  );
  for (final digit in [1, 2, 0, 0]) {
    await tester.tap(find.byKey(KochmodusWeighSheet.digitKey(digit)));
    await tester.pump();
  }
  await _tap(tester, harness, KochmodusWeighSheet.confirmKey);
}

InventoryItem _named(String id, String name, int amount) =>
    stockItem(id, amount).copyWith(name: name);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cooks a recipe from the Kochbuch through the shopping pause '
      'to Fertig', (tester) async {
    final harness = await KochmodusCookingHarness.open();
    harness.utensils.utensils = [utensil('pot-1', 'Topf')];
    addRecipe(
      harness,
      kochmodusRecipe(ingredients: ['500 g Hackfleisch', '200 g Karotten']),
    );
    await harness.stock(tester, [_named('mince', 'Hackfleisch', 800)]);
    final shopping = FakeShoppingListRepository();
    await _openCookbook(tester, harness, shopping);

    // The recipe from its card, one portion more; "Vorbereiten" opens
    // "Zuweisen", which stores nothing yet.
    await _tap(tester, harness, CookbookRecipeCard.cardKey('t1'));
    expect(find.byType(RecipePage), findsOneWidget);
    await _tap(tester, harness, RecipePage.morePortionsKey);
    await _tap(tester, harness, RecipePage.cookKey);
    expect(find.byType(KochmodusAssignPage), findsOneWidget);
    expect(find.byType(KochmodusPage), findsNothing);
    expect(
      await tester.runAsync(() => harness.cook.storedRun('recipe-t1')),
      isNull,
    );

    // Zuweisen: the mince from the Vorrat, picked in the picker, and the line
    // that says so; the carrots go on the shopping list.
    await _pickFood(tester, harness, 'mince');
    expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
    expect(
      (await harness.storedRun(tester, 'recipe-t1')).lines[0].settlement,
      isA<LineAssigned>(),
    );
    await _tap(tester, harness, KochmodusCardAnswers.shopKey);
    expect(
      (await harness.storedRun(tester, 'recipe-t1')).lines[1].settlement,
      isA<LineShopping>(),
    );

    // Pausieren bis zum Einkauf goes back to the recipe.
    final l10n = harness.l10n(tester);
    expect(find.text(l10n.kochmodusAssignPause), findsOneWidget);
    // Something to buy: no food label of a portion yet.
    expect(find.byKey(KochmodusAssignStep.labelKey), findsNothing);
    await _tap(tester, harness, KochmodusReadyCard.mainKey);
    expect(find.byType(KochmodusAssignPage), findsNothing);
    expect(find.byType(RecipePage), findsOneWidget);
    final paused = await harness.storedRun(tester, 'recipe-t1');
    expect(paused.step, CookRunStep.paused);
    expect(paused.portions, 5);
    expect(
      (await shopping.readAll()).map((item) => item.name).join(),
      contains('Karotten'),
    );

    // Läuft in the Kochbuch: "Weiter" opens "Zuweisen"; the carrots are
    // back, open.
    await _back(tester, harness);
    await _tap(
      tester,
      harness,
      CookbookRunningSection.continueKey('recipe-t1'),
    );
    expect(find.byType(KochmodusAssignPage), findsOneWidget);
    expect(find.byKey(KochmodusAssignStep.cardKey), findsOneWidget);
    expect(find.byKey(KochmodusCardAnswers.haveKey), findsOneWidget);
    await _back(tester, harness);

    // The recipe's own "Weiter" opens "Zuweisen" too.
    await _tap(tester, harness, CookbookRecipeCard.cardKey('t1'));
    final l10nRecipe = harness.l10n(tester);
    expect(
      find.descendant(
        of: find.byKey(RecipePage.cookKey),
        matching: find.text(l10nRecipe.cookbookContinueAction),
      ),
      findsOneWidget,
    );
    await _tap(tester, harness, RecipePage.cookKey);
    expect(find.byType(KochmodusAssignPage), findsOneWidget);
    // The carrots are bought and show up in the Vorrat.
    await harness.stock(tester, [_named('carrots', 'Karotten', 300)]);
    await tester.runAsync(
      () => harness.cook.inventory.replaceItems(harness.cook.inventory.items),
    );
    await harness.idle(tester);
    await _have(tester, harness, 'line-1', 'carrots');

    // "Kochen" replaces "Zuweisen" with the cooking page on Töpfe.
    await _tap(tester, harness, KochmodusReadyCard.mainKey);
    expect(find.byType(KochmodusAssignPage), findsNothing);
    expect(find.byType(KochmodusPage), findsOneWidget);
    await _tap(tester, harness, KochmodusPotsStep.potKey('pot-1'));
    await _tap(tester, harness, KochmodusPotsStep.nextKey);
    expect(find.byKey(KochmodusCookList.portionKey), findsOneWidget);

    // Portionieren: the pot with the food weighs 1200 g.
    await _tap(tester, harness, KochmodusCookList.portionKey);
    final toStock = find.byKey(KochmodusPortionStep.toStockKey);
    // The main button weighs the pot first, then it puts the meal in.
    expect(
      find.descendant(
        of: toStock,
        matching: find.text(l10n.kochmodusWeighPotsAction(1)),
      ),
      findsOneWidget,
    );
    final cookId = (await harness.storedRun(tester, 'recipe-t1')).cookingId;
    await _weighPot(tester, harness, 'pot-1', fromMainButton: true);
    expect(
      find.descendant(of: toStock, matching: find.text(l10n.cookToStock)),
      findsOneWidget,
    );
    await _tap(tester, harness, KochmodusPortionStep.toStockKey);
    expect(find.byType(KochmodusDoneView), findsOneWidget);

    // The saved meal and the gone run.
    final meal = (await tester.runAsync(
      () => harness.cook.storedMeal('$cookId-pot-1'),
    ))!;
    expect(meal.name, 'Eintopf');
    expect(meal.totalPortions, 5);
    expect(meal.components.map((c) => c.inventoryItemId), ['mince', 'carrots']);
    expect(
      await tester.runAsync(() => harness.cook.storedRun('recipe-t1')),
      isNull,
    );
    await _tap(tester, harness, KochmodusDoneView.cookbookKey);
    expect(find.byType(KochmodusPage), findsNothing);

    // The recipe stays in the Kochbuch and can be cooked again.
    await _tap(tester, harness, CookbookRecipeCard.cardKey('t1'));
    expect(
      tester.widget<FilledButton>(find.byKey(RecipePage.cookKey)).onPressed,
      isNotNull,
    );
    expect(find.byKey(RecipePage.editKey), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('cooks a recipe straight from its page to Fertig and back', (
    tester,
  ) async {
    final harness = await KochmodusCookingHarness.open();
    harness.utensils.utensils = [utensil('pot-1', 'Topf')];
    addRecipe(
      harness,
      kochmodusRecipe(ingredients: ['500 g Hackfleisch', '200 g Karotten']),
    );
    await harness.stock(tester, [_named('mince', 'Hackfleisch', 800)]);
    await _openCookbook(
      tester,
      harness,
      FakeShoppingListRepository(),
      routes: [
        _foodPickRoute(
          stockItem('found-carrots', 300).copyWith(weight: '300 g'),
          300,
        ),
      ],
    );

    // The recipe page: "Vorbereiten" opens "Zuweisen".
    await _tap(tester, harness, CookbookRecipeCard.cardKey('t1'));
    final l10n = harness.l10n(tester);
    expect(
      find.descendant(
        of: find.byKey(RecipePage.cookKey),
        matching: find.text(l10n.recipePrepareAction),
      ),
      findsOneWidget,
    );
    await _tap(tester, harness, RecipePage.cookKey);
    expect(find.byType(KochmodusAssignPage), findsOneWidget);
    expect(find.byKey(KochmodusDiscardMenu.menuKey), findsNothing);

    // Zuweisen: the mince from the Vorrat, all of it: the question how much
    // the line takes is answered with "Alles". "Kochen" waits for the last
    // line.
    await _have(
      tester,
      harness,
      'line-0',
      'mince',
      answer: KochmodusTakeAnswer.all,
    );
    final mince = (await harness.storedRun(tester, 'recipe-t1')).lines[0];
    expect((mince.settlement as LineAssigned).takes.single.amount, 800);
    expect(find.byKey(KochmodusDiscardMenu.menuKey), findsOneWidget);
    expect(find.byKey(KochmodusReadyCard.guideKey), findsNothing);
    expect(find.byKey(KochmodusReadyCard.mainKey), findsNothing);

    // The Vorrat holds only the mince, which is no suggestion for the
    // carrots: "Etwas anderes suchen" goes to the search, which finds them,
    // and the line takes what it needs of the 300 g.
    await _tap(tester, harness, KochmodusCardAnswers.haveKey);
    expect(find.byKey(KochmodusItemPickerSheet.suggestedKey), findsNothing);
    await _tap(tester, harness, KochmodusItemPickerSheet.searchOtherKey);
    await _tap(tester, harness, _pickKey);
    // The 300 g pack holds a bit more than the 200 g of the line: the cook is
    // asked how much he takes, as after a pick from the Vorrat.
    expect(find.byType(KochmodusTakeSheet), findsOneWidget);
    await _tap(
      tester,
      harness,
      KochmodusTakeSheet.answerKey(KochmodusTakeAnswer.recipe),
    );
    expect(find.byType(KochmodusTakeSheet), findsNothing);
    expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
    final carrots = (await harness.storedRun(tester, 'recipe-t1')).lines[1];
    expect(carrots.settlement, isA<LineAssigned>());
    expect(carrots.addedItemIds, hasLength(1));
    expect((carrots.settlement as LineAssigned).takes.single.amount, 200);

    // Everything is settled: the food label of one portion stands under
    // "Alles bereit". Kochen: the cooking page opens on Töpfe.
    expect(find.byKey(KochmodusAssignStep.labelKey), findsOneWidget);
    await _tap(tester, harness, KochmodusReadyCard.mainKey);
    expect(find.byType(KochmodusAssignPage), findsNothing);
    expect(find.byType(KochmodusPage), findsOneWidget);
    expect(
      (await harness.storedRun(tester, 'recipe-t1')).step,
      CookRunStep.pots,
    );
    expect(find.byKey(KochmodusPotsStep.nextKey), findsOneWidget);

    // Töpfe: one pot, then Kochen.
    await _tap(tester, harness, KochmodusPotsStep.potKey('pot-1'));
    await _tap(tester, harness, KochmodusPotsStep.nextKey);
    expect(find.byKey(KochmodusCookList.portionKey), findsOneWidget);

    // Portion: weigh the pot, put the meal into the Vorrat. The fake Vorrat
    // holds the found carrots in memory only, so Firestore, where the meal
    // reads the stock, gets them now.
    await _tap(tester, harness, KochmodusCookList.portionKey);
    await _weighPot(tester, harness, 'pot-1');
    await tester.runAsync(harness.cook.syncStoredItems);
    await _tap(tester, harness, KochmodusPortionStep.toStockKey);
    expect(find.byType(KochmodusDoneView), findsOneWidget);
    expect(await tester.runAsync(harness.cook.mealCount), 1);
    expect(
      await tester.runAsync(() => harness.cook.storedRun('recipe-t1')),
      isNull,
    );
    // The carrots found while assigning stay in the Vorrat with the rest.
    final left = await tester.runAsync(
      () => harness.cook.storedItem(carrots.addedItemIds.single),
    );
    expect(left!.currentAmount, 100);

    // "Zum Kochbuch", then the recipe page: its button works again.
    await _tap(tester, harness, KochmodusDoneView.cookbookKey);
    expect(find.byType(KochmodusPage), findsNothing);
    await _tap(tester, harness, CookbookRecipeCard.cardKey('t1'));
    expect(find.byType(RecipePage), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(RecipePage.cookKey)).onPressed,
      isNotNull,
    );
    final l10nAgain = harness.l10n(tester);
    expect(
      find.descendant(
        of: find.byKey(RecipePage.cookKey),
        matching: find.text(l10nAgain.recipePrepareAction),
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('cooks freely up to the Vorrat and keeps the recipe', (
    tester,
  ) async {
    final harness = await KochmodusCookingHarness.open();
    harness.utensils.utensils = [utensil('pot-1', 'Topf')];
    await harness.stock(tester, [_named('flour', 'Mehl', 1000)]);
    await _openCookbook(tester, harness, FakeShoppingListRepository());

    await _tap(tester, harness, HomeBottomNavBar.actionKey);
    await _tap(tester, harness, CookbookCookActionKeys.freeCooking);
    expect(find.byType(KochmodusPage), findsOneWidget);
    await _tap(tester, harness, KochmodusPotsStep.potKey('pot-1'));
    await _tap(tester, harness, KochmodusPotsStep.nextKey);

    // Kochen: an ingredient typed in.
    await _tap(tester, harness, KochmodusVoiceBar.typeKey);
    await tester.enterText(
      find.byKey(KochmodusTypeSheet.fieldKey),
      '200 g Mehl',
    );
    await _tap(tester, harness, KochmodusTypeSheet.addKey);
    expect(find.text('200 g Mehl'), findsOneWidget);

    // Portionieren: weigh, take the new line from the Vorrat, keep it.
    await _tap(tester, harness, KochmodusCookList.portionKey);
    await _weighPot(tester, harness, 'pot-1');
    await _tap(tester, harness, KochmodusPortionLines.takeNewKey);
    await _tap(
      tester,
      harness,
      KochmodusChangeSheet.answerKey(KochmodusChange.have),
    );
    // The cook picks the Vorrat food; none is taken by itself.
    await _tap(tester, harness, KochmodusItemPickerSheet.rowKey('flour'));
    await _tap(tester, harness, KochmodusPortionStep.cookbookKey);
    final run = (await tester.runAsync(
      () => harness.cook.runs.watchAll().first,
    ))!.single;
    expect(run.toCookbook, isTrue);
    await _tap(tester, harness, KochmodusPortionStep.toStockKey);

    expect(find.byType(KochmodusDoneView), findsOneWidget);
    expect(await tester.runAsync(harness.cook.mealCount), 1);
    final meal = (await tester.runAsync(
      () => harness.cook.storedMeal('${run.cookingId}-pot-1'),
    ))!;
    expect(meal.components.map((c) => c.inventoryItemId), ['flour']);
    expect(
      harness.cook.templates.templates.single.id,
      'cookbook-${run.cookingId}',
    );
    expect(await tester.runAsync(() => harness.cook.storedRun(run.id)), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('"Jetzt essen" opens the meal and the recipe can be cooked '
      'again', (tester) async {
    final harness = await KochmodusCookingHarness.open();
    addRecipe(harness, kochmodusRecipe(ingredients: ['200 g Mehl']));
    await harness.stock(tester, [stockItem('flour', 1000)]);
    await harness.store(
      tester,
      buildCookRun(
        step: CookRunStep.portion,
        pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
        steps: const [],
        lines: [
          textLine(
            'line-0',
            '200 g Mehl',
            settlement: assigned({'flour': 200}),
          ),
        ],
      ),
    );
    await _openCookbook(tester, harness, FakeShoppingListRepository());
    unawaited(harness.router.push(AppRoutes.homeCookRunPath('recipe-t1')));
    await harness.idle(tester);
    expect(find.byType(KochmodusPage), findsOneWidget);

    await _weighPot(tester, harness, cookPotA.id);
    await _tap(tester, harness, KochmodusPortionStep.toStockKey);
    expect(find.byType(KochmodusDoneView), findsOneWidget);
    final l10n = harness.l10n(tester);
    expect(find.text(l10n.kochmodusDoneEat), findsOneWidget);

    // "Jetzt essen" leaves for the meal in the Vorrat.
    await _tap(tester, harness, KochmodusDoneView.eatKey);
    expect(find.byType(KochmodusPage), findsNothing);
    expect(
      find.byKey(const ValueKey<String>(AppRoutes.homeInventory)),
      findsOne,
    );
    final location = harness.router.routeInformationProvider.value.uri;
    expect(location.path, AppRoutes.homeInventory);
    expect(
      location.queryParameters[AppRoutes.homeInventoryMealParam],
      endsWith('-${cookPotA.id}'),
    );

    // The recipe stays in the Kochbuch and its button works again.
    harness.router.go(AppRoutes.homeInventoryTemplates);
    await harness.idle(tester);
    await _tap(tester, harness, CookbookRecipeCard.cardKey('t1'));
    expect(
      tester.widget<FilledButton>(find.byKey(RecipePage.cookKey)).onPressed,
      isNotNull,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
