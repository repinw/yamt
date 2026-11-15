import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/data/closed_day_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/cookbook_new/data/recipe_estimate_repository.dart';
import 'package:yamt/features/cookbook_new/presentation/cookbook_page.dart';
import 'package:yamt/features/cookbook_new/presentation/'
    'cookbook_remove_flow.dart';
import 'package:yamt/features/cookbook_new/presentation/cooked_meal_page.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_editor_page.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_page.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_plan_flow.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_entry_ink_well.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_recipe_card.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_template_tile.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'ingredient_stock_text.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_estimate_line.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_hero.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_ingredient_tile.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_line_nutrition_section.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_line_status_card.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_nutrition_section.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository_contract.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_plan_needs_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_planned_entry_repository.dart';
import '../../test/features/kochmodus/kochmodus_fixtures.dart';
import '../../test/features/recipes/cook_run_fixtures.dart';
import '../../test/features/shoppinglist/support/fake_shopping_list_repository.dart';
import '../../test/helpers/fake_cook_run_repository.dart';
import '../../test/helpers/fake_prepared_meal_template_repository.dart';
import '../../test/helpers/fake_recipe_estimate_client.dart';
import '../../test/helpers/fake_signed_in_user.dart';
import '../../test/helpers/inventory_item_whole_list_writes.dart';
import '../../test/helpers/memory_app_preferences.dart';

const _cookPageKey = ValueKey<String>('cook-page');
const _runPageKey = ValueKey<String>('run-page');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('"Vorbereiten" opens "Zuweisen" with the chosen portions', (
    tester,
  ) async {
    final meals = _FakeMealRepository();
    await tester.pumpWidget(
      _app(
        meals: meals,
        inventory: _FakeInventoryRepository([
          _item('mince', 'Hackfleisch'),
          _item('carrots', 'Karotten'),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    await _openRecipe(tester);

    expect(find.byType(RecipePage), findsOneWidget);

    // Two portions in the recipe, three to cook.
    await tester.tap(find.byKey(RecipePage.morePortionsKey));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(RecipePage.portionsKey)).data, '3');

    await tester.tap(find.byKey(RecipePage.cookKey));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(_cookPageKey)).data,
      AppRoutes.homeCookPath('stew', portions: 3),
    );
    expect(find.byKey(_runPageKey), findsNothing);
    // Nothing goes into the pot from the recipe page.
    expect(meals.saved, isEmpty);
  });

  testWidgets('"Weiter" opens "Zuweisen" while a line of the run is open', (
    tester,
  ) async {
    final meals = _FakeMealRepository();
    await tester.pumpWidget(
      _app(
        meals: meals,
        inventory: _FakeInventoryRepository([_item('mince', 'Hackfleisch')]),
        runs: [buildCookRun(id: 'recipe-stew', recipeId: 'stew')],
      ),
    );
    await tester.pumpAndSettle();
    await _openRecipe(tester);

    await tester.tap(find.byKey(RecipePage.cookKey));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(_cookPageKey)).data,
      startsWith(AppRoutes.homeCookPath('stew')),
    );
    expect(find.byKey(_runPageKey), findsNothing);
    expect(meals.saved, isEmpty);
  });

  testWidgets('"Kochen" opens the cook run once nothing is left to assign', (
    tester,
  ) async {
    final meals = _FakeMealRepository();
    await tester.pumpWidget(
      _app(
        meals: meals,
        inventory: _FakeInventoryRepository([_item('mince', 'Hackfleisch')]),
        runs: [
          buildCookRun(
            id: 'recipe-stew',
            recipeId: 'stew',
            lines: [
              textLine('line-0', 'Salz', settlement: const LineIgnored()),
            ],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await _openRecipe(tester);

    await tester.tap(find.byKey(RecipePage.cookKey));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(_runPageKey)).data,
      AppRoutes.homeCookRunPath('recipe-stew'),
    );
    expect(find.byKey(_cookPageKey), findsNothing);
    expect(meals.saved, isEmpty);
  });

  testWidgets('shows where each ingredient stands in the cook run', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        meals: _FakeMealRepository(),
        inventory: _FakeInventoryRepository([_item('mince', 'Hackfleisch')]),
        runs: [
          buildCookRun(
            id: 'recipe-stew',
            recipeId: 'stew',
            portions: 3,
            lines: [
              textLine(
                'line-0',
                '500 g Hackfleisch',
                settlement: LineAssigned(const [
                  ItemTake(itemId: 'mince', amount: 750),
                ]),
              ),
              textLine(
                'line-1',
                '200 g Karotten',
                settlement: const LineIgnored(),
              ),
              textLine('line-2', 'Salz'),
            ],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await _openRecipe(tester);

    // One open line of three.
    expect(find.byKey(RecipeLineStatusCard.cardKey), findsOneWidget);
    expect(find.text('1 still open'), findsOneWidget);
    expect(
      find.textContaining('1 ready · 1 left out · 1 open'),
      findsOneWidget,
    );
    expect(find.byKey(RecipePage.openHintKey), findsOneWidget);

    // The portions are the run's and cannot be changed.
    expect(tester.widget<Text>(find.byKey(RecipePage.portionsKey)).data, '3');
    await tester.tap(find.byKey(RecipePage.morePortionsKey));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(RecipePage.portionsKey)).data, '3');

    // Ready: what the Vorrat food holds; left out; open.
    await tester.scrollUntilVisible(
      find.byKey(RecipeIngredientTile.tileKey(2)),
      100,
    );
    Finder inTile(int index, String text) => find.descendant(
      of: find.byKey(RecipeIngredientTile.tileKey(index)),
      matching: find.text(text),
    );
    expect(
      find.descendant(
        of: find.byKey(RecipeIngredientTile.tileKey(0)),
        matching: find.byType(IngredientStockText),
      ),
      findsOneWidget,
    );
    expect(inTile(1, 'left out'), findsOneWidget);
    expect(inTile(2, 'open'), findsOneWidget);

    // A run goes on instead of starting over.
    expect(
      find.descendant(
        of: find.byKey(RecipePage.cookKey),
        matching: find.text('Continue'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a cook run sizes the recipe page for its portions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        meals: _FakeMealRepository(),
        inventory: _FakeInventoryRepository([_item('mince', 'Hackfleisch')]),
        runs: [buildCookRun(id: 'recipe-stew', recipeId: 'stew', portions: 6)],
      ),
    );
    await tester.pumpAndSettle();
    await _openRecipe(tester);

    // Two portions in the recipe, six in the run: 500 g become 1500 g.
    expect(tester.widget<Text>(find.byKey(RecipePage.portionsKey)).data, '6');
    await tester.scrollUntilVisible(
      find.byKey(RecipeIngredientTile.tileKey(0)),
      100,
    );
    expect(
      find.descendant(
        of: find.byKey(RecipeIngredientTile.tileKey(0)),
        matching: find.textContaining('1500 g'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('reads the lines like the Kochmodus: a half, a number in words '
      'and a scale reading', (tester) async {
    final recipe = _recipe.copyWith(
      recipeIngredients: const [
        '½ Zitrone',
        'eine halbe Zitrone',
        'zwei Zwiebeln',
        '1,250 kg Mehl',
      ],
      ignoredRecipeIngredients: const <String>[],
    );
    await tester.pumpWidget(
      _app(
        meals: _FakeMealRepository(),
        inventory: _FakeInventoryRepository(const []),
        templates: FakePreparedMealTemplateRepository(templates: [recipe]),
      ),
    );
    await tester.pumpAndSettle();
    await _openRecipe(tester);

    Finder inTile(int index, String text) => find.descendant(
      of: find.byKey(RecipeIngredientTile.tileKey(index)),
      matching: find.text(text, findRichText: true),
    );
    expect(inTile(0, '1/2 Zitrone'), findsOneWidget);
    expect(inTile(1, '1/2 Zitrone'), findsOneWidget);
    expect(inTile(2, '2 Zwiebeln'), findsOneWidget);
    expect(inTile(3, '1250 g Mehl'), findsOneWidget);
  });

  testWidgets('cooks a Vorlage from its foods', (tester) async {
    final meals = _FakeMealRepository();
    final mince = _item('mince', 'Hackfleisch');
    final vorlage = _recipe.copyWith(
      totalPortions: 1,
      recipeIngredients: const <String>[],
      ignoredRecipeIngredients: const <String>[],
      recipeInstructions: const <String>[],
      components: [
        PreparedMealComponent(
          inventoryItemId: mince.id,
          name: mince.name,
          brand: null,
          imageUrl: null,
          usedAmount: 300,
          usedUnit: InventoryAmountUnit.gram,
          totalKcal: 0,
          totalProtein: 0,
          totalCarbs: 0,
          totalFat: 0,
          sourceItemSnapshot: mince,
        ),
      ],
    );
    await tester.pumpWidget(
      _app(
        meals: meals,
        inventory: _FakeInventoryRepository([mince]),
        templates: FakePreparedMealTemplateRepository(templates: [vorlage]),
      ),
    );
    await tester.pumpAndSettle();
    await _openRecipe(tester, vorlage: true);

    expect(find.byKey(RecipeIngredientTile.tileKey(0)), findsOneWidget);
    // A Vorlage is combined from Vorrat foods, so the editor has no entry.
    expect(find.byKey(RecipePage.editKey), findsNothing);
    await tester.tap(find.byKey(RecipePage.cookKey));
    await tester.pumpAndSettle();

    expect(find.byType(CookedMealPage), findsOneWidget);
    final meal = meals.saved.single;
    expect(meal.isInPot, isTrue);
    expect(meal.components.single.inventoryItemId, 'mince');
    expect(meal.components.single.usedAmount, 300);
  });

  testWidgets('"Bearbeiten" opens the recipe editor with the saved lines', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        meals: _FakeMealRepository(),
        inventory: _FakeInventoryRepository([_item('mince', 'Hackfleisch')]),
      ),
    );
    await tester.pumpAndSettle();
    await _openRecipe(tester);

    await tester.scrollUntilVisible(find.byKey(RecipePage.editKey), 100);
    await tester.tap(find.byKey(RecipePage.editKey));
    await tester.pumpAndSettle();

    expect(find.byType(RecipeEditorPage), findsOneWidget);
  });

  testWidgets('removes the recipe from its page and brings it back', (
    tester,
  ) async {
    final meals = _FakeMealRepository();
    final templates = FakePreparedMealTemplateRepository(templates: [_recipe]);
    await tester.pumpWidget(
      _app(
        meals: meals,
        inventory: _FakeInventoryRepository([_item('mince', 'Hackfleisch')]),
        templates: templates,
      ),
    );
    await tester.pumpAndSettle();
    await _openRecipe(tester);

    await tester.tap(find.byKey(RecipeHero.removeKey));
    await tester.pumpAndSettle();

    // The page closes; the snack bar shows where the recipe was opened.
    expect(find.byType(RecipePage), findsNothing);
    expect(find.byType(CookbookPage), findsOneWidget);
    expect(templates.templates, isEmpty);
    final snackBar = find.byKey(CookbookRemoveFlow.snackBarKey);
    expect(snackBar, findsOneWidget);

    await tester.tap(
      find.descendant(of: snackBar, matching: find.byType(TextButton)),
    );
    await tester.pumpAndSettle();

    expect(templates.templates, [_recipe]);
    expect(meals.saved, isEmpty);
    await _openRecipe(tester);
    expect(find.byKey(RecipePage.cookKey), findsOneWidget);
  });

  testWidgets('plans a portion of the recipe from the Kochbuch and takes it '
      'back', (tester) async {
    final plans = FakePlannedEntryRepository();
    final meals = _FakeMealRepository();
    await tester.pumpWidget(
      _app(
        meals: meals,
        inventory: _FakeInventoryRepository([
          _item('mince', 'Hackfleisch'),
          _item('carrots', 'Karotten'),
        ]),
        plans: plans,
      ),
    );
    await tester.pumpAndSettle();

    await _planFromCookbook(tester);

    // Planned for today with the Vorrat values; nothing is cooked.
    final plan = plans.plans.single;
    expect(plan.bundleSourceTemplateId, 'stew');
    expect(plan.nutritionPending, isFalse);
    expect(plan.nutritionEstimated, isFalse);
    expect(plan.bundleConsumedPortions, 1);
    expect(meals.saved, isEmpty);

    await tester.tap(
      find.descendant(
        of: find.byKey(RecipePlanFlow.snackBarKey),
        matching: find.byType(TextButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(plans.plans, isEmpty);
  });

  testWidgets('plans a recipe with its estimate while an ingredient has no '
      'Vorrat item', (tester) async {
    final plans = FakePlannedEntryRepository();
    final lines = _recipe.recipeIngredients;
    final estimated = _recipe.copyWith(
      recipeEstimate: RecipeEstimate(
        kcal: 450,
        protein: 30,
        carbs: 40,
        fat: 12,
        portions: _recipe.totalPortions,
        linesKey: recipeLinesKey(lines),
        createdAt: DateTime.utc(2026, 10, 9),
      ),
    );
    await tester.pumpWidget(
      _app(
        meals: _FakeMealRepository(),
        // No carrots in the Vorrat at all.
        inventory: _FakeInventoryRepository([_item('mince', 'Hackfleisch')]),
        templates: FakePreparedMealTemplateRepository(templates: [estimated]),
        plans: plans,
      ),
    );
    await tester.pumpAndSettle();

    await _planFromCookbook(tester);

    final plan = plans.plans.single;
    expect(plan.bundleSourceTemplateId, 'stew');
    expect(plan.nutritionEstimated, isTrue);
    expect(plan.nutritionPending, isFalse);
    expect(plan.totalKcal, 450);
    // The mince has an item, but the estimate is the plan's only values.
    expect(plan.isCombined, isFalse);
    expect(plan.bundleComponents, isEmpty);
  });

  testWidgets('offers the ingredients the Vorrat lacks for the list', (
    tester,
  ) async {
    final shopping = FakeShoppingListRepository();
    await tester.pumpWidget(
      _app(
        meals: _FakeMealRepository(),
        inventory: _FakeInventoryRepository([
          _item('mince', 'Hackfleisch'),
          // One portion of two needs 100 g of the carrots.
          _item('carrots', 'Karotten', currentAmount: 40),
        ]),
        shopping: shopping,
      ),
    );
    await tester.pumpAndSettle();

    await _planFromCookbook(tester);

    // Only the carrots are short.
    expect(find.byKey(ShoppingPlanNeedsDialog.needKey(0)), findsOneWidget);
    expect(find.byKey(ShoppingPlanNeedsDialog.needKey(1)), findsNothing);
    await tester.tap(find.byKey(ShoppingPlanNeedsDialog.addKey));
    await tester.pumpAndSettle();

    expect(shopping.savedItems.single.name, 'Karotten');
  });

  testWidgets('offers an ingredient that no Vorrat item stands for', (
    tester,
  ) async {
    final shopping = FakeShoppingListRepository();
    await tester.pumpWidget(
      _app(
        meals: _FakeMealRepository(),
        // No carrots in the Vorrat at all.
        inventory: _FakeInventoryRepository([_item('mince', 'Hackfleisch')]),
        shopping: shopping,
      ),
    );
    await tester.pumpAndSettle();

    await _planFromCookbook(tester);

    expect(find.byKey(ShoppingPlanNeedsDialog.needKey(0)), findsOneWidget);
    expect(find.byKey(ShoppingPlanNeedsDialog.needKey(1)), findsNothing);
    await tester.tap(find.byKey(ShoppingPlanNeedsDialog.addKey));
    await tester.pumpAndSettle();

    expect(shopping.savedItems.single.name, 'Karotten');
  });

  testWidgets('does not offer what the closed shopping list holds', (
    tester,
  ) async {
    final shopping = FakeShoppingListRepository(
      initialItems: const [
        ShoppingListItem(
          id: 'carrots',
          name: 'Karotten',
          normalizedName: 'karotten',
          normalizedBrand: '',
          quantity: 1,
          estimatedUnitPrice: 0,
        ),
      ],
    );
    await tester.pumpWidget(
      _app(
        meals: _FakeMealRepository(),
        inventory: _FakeInventoryRepository([
          _item('mince', 'Hackfleisch'),
          _item('carrots', 'Karotten', currentAmount: 40),
        ]),
        shopping: shopping,
      ),
    );
    await tester.pumpAndSettle();

    await _planFromCookbook(tester);

    // The carrots are on the list already, so nothing is asked.
    expect(find.byType(ShoppingPlanNeedsDialog), findsNothing);
    expect(shopping.savedItems, isEmpty);
  });

  testWidgets('"Bearbeiten" is gone while the recipe has a cook run', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        meals: _FakeMealRepository(),
        inventory: _FakeInventoryRepository([_item('mince', 'Hackfleisch')]),
        runs: [buildCookRun(id: 'recipe-stew', recipeId: 'stew')],
      ),
    );
    await tester.pumpAndSettle();
    await _openRecipe(tester);

    expect(find.byType(RecipePage), findsOneWidget);
    // The ingredients are on screen, but not their "Bearbeiten".
    await tester.scrollUntilVisible(
      find.byKey(RecipeIngredientTile.tileKey(0)),
      100,
    );
    expect(find.byKey(RecipePage.editKey), findsNothing);
  });

  testWidgets('a recipe without a fitting estimate costs one AI call across '
      'the Kochbuch and its page, not another when the Kochbuch changes', (
    tester,
  ) async {
    final client = FakeRecipeEstimateClient()..hold();
    final templates = FakePreparedMealTemplateRepository(templates: [_recipe]);
    await tester.pumpWidget(
      _app(
        meals: _FakeMealRepository(),
        inventory: _FakeInventoryRepository([_item('mince', 'Hackfleisch')]),
        templates: templates,
        estimates: client,
      ),
    );
    await _pumpWhileEstimating(tester);

    // The Kochbuch estimates the recipe and shows that its value is coming.
    expect(client.calls, 1);
    expect(
      find.byKey(CookbookRecipeCard.estimatingKey('stew')),
      findsOneWidget,
    );

    // The page finds the recipe still without an estimate and joins the call.
    await _openRecipe(tester, estimating: true);
    expect(find.byType(RecipePage), findsOneWidget);
    expect(client.calls, 1);

    client.release();
    await _pumpWhileEstimating(tester);
    await tester.pumpAndSettle();
    expect(client.calls, 1);
    expect(templates.templates.single.recipeEstimate?.kcal, 420);

    // A later change of the recipe, such as the estimate's own save,
    // leaves it at that.
    await templates.save(
      templates.templates.single.copyWith(name: 'Bauerntopf II'),
    );
    await tester.pumpAndSettle();
    expect(client.calls, 1);
  });

  testWidgets('the page alone estimates a recipe when the Kochbuch was never '
      'open', (tester) async {
    final client = FakeRecipeEstimateClient()..hold();
    final templates = FakePreparedMealTemplateRepository(templates: [_recipe]);
    await tester.pumpWidget(
      _app(
        meals: _FakeMealRepository(),
        inventory: _FakeInventoryRepository([_item('mince', 'Hackfleisch')]),
        templates: templates,
        openRecipeId: 'stew',
        estimates: client,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RecipePage), findsOneWidget);
    expect(client.calls, 1);
    // The header keeps the place of the values while the AI works.
    expect(find.byKey(RecipeEstimateLine.waitKey), findsOneWidget);
    expect(find.byKey(RecipeEstimateLine.lineKey), findsNothing);

    client.release();
    await _pumpWhileEstimating(tester);
    await tester.pumpAndSettle();
    expect(client.calls, 1);
    expect(templates.templates.single.recipeEstimate?.kcal, 420);
    // The values replace the place, and the food label comes with them.
    expect(find.byKey(RecipeEstimateLine.waitKey), findsNothing);
    expect(find.byKey(RecipeEstimateLine.lineKey), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(RecipeNutritionSection.labelKey),
      200,
    );
    expect(find.byKey(RecipeNutritionSection.labelKey), findsOneWidget);
  });

  testWidgets('opening a recipe whose estimate fits, or a Vorlage, starts no '
      'estimate', (tester) async {
    final fitting = _recipe.copyWith(
      recipeEstimate: RecipeEstimate(
        kcal: 450,
        protein: 30,
        carbs: 40,
        fat: 12,
        portions: _recipe.totalPortions,
        linesKey: recipeLinesKey(_recipe.recipeIngredients),
        createdAt: DateTime.utc(2026, 10, 9),
      ),
    );
    final client = FakeRecipeEstimateClient();
    await tester.pumpWidget(
      _app(
        meals: _FakeMealRepository(),
        inventory: _FakeInventoryRepository([_item('mince', 'Hackfleisch')]),
        templates: FakePreparedMealTemplateRepository(templates: [fitting]),
        estimates: client,
      ),
    );
    await tester.pumpAndSettle();
    await _openRecipe(tester);
    expect(find.byType(RecipePage), findsOneWidget);
    expect(client.calls, 0);

    final mince = _item('mince', 'Hackfleisch');
    final vorlage = _recipe.copyWith(
      totalPortions: 1,
      recipeIngredients: const <String>[],
      ignoredRecipeIngredients: const <String>[],
      recipeInstructions: const <String>[],
      components: [
        PreparedMealComponent(
          inventoryItemId: mince.id,
          name: mince.name,
          brand: null,
          imageUrl: null,
          usedAmount: 300,
          usedUnit: InventoryAmountUnit.gram,
          totalKcal: 0,
          totalProtein: 0,
          totalCarbs: 0,
          totalFat: 0,
          sourceItemSnapshot: mince,
        ),
      ],
    );
    await tester.pumpWidget(
      _app(
        meals: _FakeMealRepository(),
        inventory: _FakeInventoryRepository([mince]),
        templates: FakePreparedMealTemplateRepository(templates: [vorlage]),
        estimates: client,
      ),
    );
    await tester.pumpAndSettle();
    await _openRecipe(tester, vorlage: true);
    expect(find.byType(RecipePage), findsOneWidget);
    expect(client.calls, 0);
  });

  testWidgets('shows the nutrition per ingredient folded when the estimate '
      'has values per line, and none without them', (tester) async {
    RecipeEstimate estimate({List<RecipeLineNutrition>? lines}) =>
        RecipeEstimate(
          kcal: 450,
          protein: 30,
          carbs: 40,
          fat: 12,
          portions: _recipe.totalPortions,
          linesKey: recipeLinesKey(_recipe.recipeIngredients),
          createdAt: DateTime.utc(2026, 10, 9),
          lines: lines,
        );
    final withLines = _recipe.copyWith(
      recipeEstimate: estimate(
        lines: const [
          RecipeLineNutrition(kcal: 800, protein: 60, carbs: 0, fat: 50),
          RecipeLineNutrition(kcal: 80, protein: 2, carbs: 16, fat: 0),
          RecipeLineNutrition(kcal: 0, protein: 0, carbs: 0, fat: 0),
        ],
      ),
    );
    await tester.pumpWidget(
      _app(
        meals: _FakeMealRepository(),
        inventory: _FakeInventoryRepository([_item('mince', 'Hackfleisch')]),
        templates: FakePreparedMealTemplateRepository(templates: [withLines]),
        estimates: FakeRecipeEstimateClient(),
      ),
    );
    await tester.pumpAndSettle();
    await _openRecipe(tester);

    // The food label of one portion stands above the nutrition per
    // ingredient.
    final label = find.byKey(RecipeNutritionSection.labelKey);
    await tester.scrollUntilVisible(label, 200);
    expect(label, findsOneWidget);
    final toggle = find.byKey(RecipeLineNutritionSection.toggleKey);
    await tester.scrollUntilVisible(toggle, 200);
    // Clear of the lower edge, so the tap hits it.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(toggle, findsOneWidget);
    expect(find.byKey(RecipeLineNutritionSection.tableKey), findsNothing);

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    final table = find.byKey(RecipeLineNutritionSection.tableKey);
    await tester.scrollUntilVisible(table, 200);
    expect(table, findsOneWidget);
    // The head names the portions of the recipe, and the stepper moves it.
    expect(
      find.descendant(of: table, matching: find.text('For 2 portions')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(RecipePage.morePortionsKey),
      -200,
    );
    await tester.tap(find.byKey(RecipePage.morePortionsKey));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: table, matching: find.text('For 3 portions')),
      findsOneWidget,
    );

    final plain = _recipe.copyWith(recipeEstimate: estimate());
    await tester.pumpWidget(
      _app(
        meals: _FakeMealRepository(),
        inventory: _FakeInventoryRepository([_item('mince', 'Hackfleisch')]),
        templates: FakePreparedMealTemplateRepository(templates: [plain]),
        estimates: FakeRecipeEstimateClient(),
      ),
    );
    await tester.pumpAndSettle();
    await _openRecipe(tester);

    expect(find.byType(RecipePage), findsOneWidget);
    expect(find.byKey(RecipeLineNutritionSection.toggleKey), findsNothing);
    // The label stands alone then.
    await tester.scrollUntilVisible(label, 200);
    expect(label, findsOneWidget);
  });

  testWidgets('a recipe that is gone says so', (tester) async {
    await tester.pumpWidget(
      _app(
        meals: _FakeMealRepository(),
        inventory: _FakeInventoryRepository(const []),
        templates: FakePreparedMealTemplateRepository(),
        openRecipeId: 'stew',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(RecipePage.cookKey), findsNothing);
    expect(find.byKey(RecipePage.notFoundKey), findsOneWidget);
  });
}

/// Pumps for a second, while the AI has not answered: pumpAndSettle would
/// not end while the spinner of a Kochbuch card turns.
Future<void> _pumpWhileEstimating(WidgetTester tester) async {
  for (var i = 0; i < 20; i += 1) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Opens the recipe `stew` from its card in the Kochbuch, or from its tile
/// when it is a [vorlage]. While [estimating], its card holds a spinner.
Future<void> _openRecipe(
  WidgetTester tester, {
  bool vorlage = false,
  bool estimating = false,
}) async {
  Future<void> settle() async => estimating
      ? await _pumpWhileEstimating(tester)
      : await tester.pumpAndSettle();
  final entry = find.byKey(
    vorlage
        ? CookbookTemplateTile.tileKey('stew')
        : CookbookRecipeCard.cardKey('stew'),
  );
  // Center the entry, so the dock does not cover it.
  await Scrollable.ensureVisible(tester.element(entry), alignment: 0.3);
  await settle();
  await tester.tap(entry);
  await settle();
}

/// Plans one portion of the recipe `stew` for today from its Kochbuch card.
Future<void> _planFromCookbook(WidgetTester tester) async {
  final card = find.byKey(CookbookRecipeCard.cardKey('stew'));
  await Scrollable.ensureVisible(tester.element(card), alignment: 0.3);
  await tester.pumpAndSettle();
  await tester.longPress(card);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(CookbookEntryInkWell.planKey));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

InventoryItem _item(String id, String name, {int currentAmount = 2000}) =>
    InventoryItem.create(
      id: id,
      name: name,
      entryDate: DateTime.utc(2026, 10, 9),
      storeName: 'Store',
      quantity: 1,
      initialAmount: 2000,
      currentAmount: currentAmount,
      amountUnit: InventoryAmountUnit.gram,
    );

final _recipe = PreparedMeal(
  id: 'stew',
  name: 'Bauerntopf',
  totalPortions: 2,
  remainingPortions: 2,
  totalKcal: 0,
  totalProtein: 0,
  totalCarbs: 0,
  totalFat: 0,
  createdAt: DateTime.utc(2026, 10, 9),
  updatedAt: DateTime.utc(2026, 10, 9),
  components: const <PreparedMealComponent>[],
  recipeIngredients: const ['500 g Hackfleisch', '200 g Karotten', 'Salz'],
  ignoredRecipeIngredients: const ['Salz'],
  recipeInstructions: const ['Anbraten.', 'Köcheln lassen.'],
);

Widget _app({
  required _FakeMealRepository meals,
  required _FakeInventoryRepository inventory,
  FakePreparedMealTemplateRepository? templates,
  FakePlannedEntryRepository? plans,
  ShoppingListRepository? shopping,
  String? openRecipeId,
  FakeRecipeEstimateClient? estimates,
  List<CookRun> runs = const [],
}) {
  final router = GoRouter(
    initialLocation: openRecipeId == null
        ? AppRoutes.homeInventoryTemplates
        : AppRoutes.homeRecipePath(openRecipeId),
    routes: [
      GoRoute(
        path: AppRoutes.homeInventoryTemplates,
        builder: (context, state) => const CookbookPage(),
      ),
      GoRoute(
        path: AppRoutes.homeRecipe,
        builder: (context, state) =>
            RecipePage(recipeId: state.pathParameters['recipeId']!),
      ),
      GoRoute(
        path: AppRoutes.homeRecipeEdit,
        builder: (context, state) =>
            RecipeEditorPage(recipeId: state.pathParameters['recipeId']),
      ),
      GoRoute(
        path: AppRoutes.homeCook,
        builder: (context, state) =>
            Text(state.uri.toString(), key: _cookPageKey),
      ),
      GoRoute(
        path: AppRoutes.homeCookRun,
        builder: (context, state) =>
            Text(state.uri.toString(), key: _runPageKey),
      ),
      GoRoute(
        path: AppRoutes.homeCookedMeal,
        builder: (context, state) =>
            CookedMealPage(mealId: state.pathParameters['mealId']!),
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWith(
        (ref) => Stream.value(FakeSignedInUser('uid-1')),
      ),
      cookRunRepositoryProvider.overrideWithValue(
        FakeCookRunRepository(runs: runs),
      ),
      preparedMealRepositoryProvider.overrideWithValue(meals),
      // Without an answer the estimate fails quietly, so the recipe stays as
      // the test wrote it.
      recipeEstimateTemplateClientProvider.overrideWithValue(
        (estimates ?? FakeRecipeEstimateClient(noAnswer: true)).request,
      ),
      preparedMealTemplateRepositoryProvider.overrideWithValue(
        templates ?? FakePreparedMealTemplateRepository(templates: [_recipe]),
      ),
      inventoryItemRepositoryProvider.overrideWithValue(inventory),
      inventoryActivityEventRepositoryProvider.overrideWithValue(
        _FakeActivityRepository(),
      ),
      inventoryActivityActorProvider.overrideWithValue(null),
      shoppingListRepositoryProvider.overrideWithValue(
        shopping ?? _FakeShoppingListRepository(),
      ),
      kitchenUtensilRepositoryProvider.overrideWithValue(
        _FakeUtensilRepository(),
      ),
      plannedEntryRepositoryProvider.overrideWithValue(
        plans ?? FakePlannedEntryRepository(),
      ),
      closedDayRepositoryProvider.overrideWithValue(
        ClosedDayRepository(MemoryAppPreferences(), 'user-1'),
      ),
    ],
  );
  addTearDown(container.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

class _FakeMealRepository implements PreparedMealRepository {
  final _changes = StreamController<List<PreparedMeal>>.broadcast();
  List<PreparedMeal> saved = const [];

  @override
  Stream<List<PreparedMeal>> watchAll() async* {
    yield saved;
    yield* _changes.stream;
  }

  @override
  Future<List<PreparedMeal>> readAll() async => saved;

  @override
  Future<bool> save(PreparedMeal meal) => _saveAll([
    for (final stored in saved)
      if (stored.id != meal.id) stored,
    meal,
  ]);

  @override
  Future<bool> delete(String mealId) => _saveAll([
    for (final stored in saved)
      if (stored.id != mealId) stored,
  ]);

  Future<bool> _saveAll(List<PreparedMeal> meals) async {
    saved = meals;
    _changes.add(meals);
    return true;
  }

  @override
  Future<List<PreparedMeal>> readAllForChange() => readAll();
}

class _FakeUtensilRepository implements KitchenUtensilRepository {
  @override
  Stream<List<KitchenUtensil>> watchAll() async* {
    yield const <KitchenUtensil>[];
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeInventoryRepository with InventoryItemWholeListWrites {
  new(this.items);

  List<InventoryItem> items;

  @override
  Stream<List<InventoryItem>> watchAll() => Stream.value(items);

  @override
  Future<List<InventoryItem>> readAll() async => items;

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async {
    this.items = items;
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    this.items = [...this.items, ...items];
    return true;
  }
}

class _FakeActivityRepository implements InventoryActivityEventRepository {
  @override
  Stream<List<InventoryActivityEvent>> watchRecent({int limit = 100}) {
    return const Stream.empty();
  }

  @override
  Future<bool> appendAll(List<InventoryActivityEvent> events) async => true;
}

class _FakeShoppingListRepository implements ShoppingListRepository {
  @override
  bool holdsUnmigratedItems = false;

  @override
  Stream<List<ShoppingListItem>> watchAll() async* {
    yield const <ShoppingListItem>[];
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
