import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/data/closed_day_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/cookbook_new/presentation/cookbook_page.dart';
import 'package:yamt/features/cookbook_new/presentation/'
    'cookbook_remove_flow.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_plan_flow.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_entry_ink_well.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_open_meal_card.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_recipe_card.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_template_strip.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_template_tile.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_combine_pick_page.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_template_name_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_planned_entry_repository.dart';
import '../../test/helpers/fake_prepared_meal_template_repository.dart';
import '../../test/helpers/inventory_item_whole_list_writes.dart';
import '../../test/helpers/memory_app_preferences.dart';
import '../../test/support/prepared_meal_test_data.dart';

GoRoute _placeholder(String path, String label) {
  return GoRoute(
    path: path,
    builder: (context, state) => Scaffold(
      key: ValueKey<String>(path),
      body: Center(child: Text(label)),
    ),
  );
}

Widget _app({
  required FakePreparedMealTemplateRepository templates,
  required List<PreparedMeal> meals,
  FakePlannedEntryRepository? plans,
  _Inventory? inventory,
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.homeInventoryTemplates,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomePage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [_placeholder(AppRoutes.homeInventory, 'Vorrat page')],
          ),
          StatefulShellBranch(
            routes: [_placeholder(AppRoutes.homeDiary, 'Diary page')],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeInventoryTemplates,
                builder: (context, state) => const CookbookPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [_placeholder(AppRoutes.homeProgress, 'Progress page')],
          ),
        ],
      ),
      _placeholder(AppRoutes.homeRecipe, 'Recipe page'),
      _placeholder(AppRoutes.homeCookedMeal, 'Cooked page'),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 2, 20)),
      preparedMealTemplateRepositoryProvider.overrideWithValue(templates),
      plannedEntryRepositoryProvider.overrideWithValue(
        plans ?? FakePlannedEntryRepository(),
      ),
      closedDayRepositoryProvider.overrideWithValue(
        ClosedDayRepository(MemoryAppPreferences(), 'user-1'),
      ),
      inventoryItemRepositoryProvider.overrideWithValue(
        inventory ?? _Inventory(const []),
      ),
      inventoryQuickEatMealsProvider.overrideWith((ref) => Stream.value(meals)),
      inventoryQuickEatItemsProvider.overrideWith(
        (ref) => Stream.value([
          InventoryItem.create(
            id: 'pasta',
            name: 'Pasta',
            entryDate: DateTime.utc(2026, 9, 29),
            storeName: 'Store',
            quantity: 1,
            initialAmount: 500,
            currentAmount: 500,
            amountUnit: InventoryAmountUnit.gram,
          ),
        ]),
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

/// The stored Vorrat; counts its writes.
class _Inventory with InventoryItemWholeListWrites {
  new(this.items);

  final List<InventoryItem> items;
  int writes = 0;

  @override
  Stream<List<InventoryItem>> watchAll() => Stream.value(items);

  @override
  Future<List<InventoryItem>> readAll() async => items;

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async {
    writes += 1;
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) => replaceItems(items);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final recipe = preparedMealTestData(
    id: 'pasta',
    name: 'One-pan pasta',
  ).copyWith(recipeIngredients: const ['200 g Pasta', '150 g Tomato sauce']);
  final template = preparedMealTestData(id: 'bowl');
  final openMeal = preparedMealTestData(
    id: 'free',
    name: 'Chicken with rice',
  ).copyWith(pendingRecipeIngredients: const ['40 g Butter', '200 g Rice']);

  testWidgets('shows pot, templates, recipes and opens a recipe', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        templates: FakePreparedMealTemplateRepository(
          templates: [recipe, template],
        ),
        meals: [openMeal],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 RECIPE'), findsOneWidget);
    expect(find.text('OPEN'), findsOneWidget);
    expect(find.text('Chicken with rice'), findsOneWidget);
    expect(find.text('In stock · 2 rows open'), findsOneWidget);
    expect(find.text('Rice bowl'), findsOneWidget);
    expect(find.text('One-pan pasta'), findsOneWidget);
    // The pasta recipe lacks tomato sauce; the rice bowl lacks rice.
    expect(find.text('1 missing'), findsNWidgets(2));

    // Center the card, so the dock does not cover it.
    await Scrollable.ensureVisible(
      tester.element(find.text('One-pan pasta')),
      alignment: 0.3,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('One-pan pasta'));
    await tester.pumpAndSettle();

    expect(find.text('Recipe page'), findsOneWidget);

    // A Vorlage opens the recipe page too.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final vorlage = find.byKey(CookbookTemplateTile.tileKey('bowl'));
    await Scrollable.ensureVisible(tester.element(vorlage), alignment: 0.3);
    await tester.pumpAndSettle();
    await tester.tap(vorlage);
    await tester.pumpAndSettle();
    expect(find.text('Recipe page'), findsOneWidget);
  });

  testWidgets('removes a recipe and a Vorlage by long press and brings the '
      'recipe back', (tester) async {
    final templates = FakePreparedMealTemplateRepository(
      templates: [recipe, template],
    );
    await tester.pumpWidget(_app(templates: templates, meals: [openMeal]));
    await tester.pumpAndSettle();
    final recipeCard = find.byKey(CookbookRecipeCard.cardKey('pasta'));
    final templateTile = find.byKey(CookbookTemplateTile.tileKey('bowl'));
    final snackBar = find.byKey(CookbookRemoveFlow.snackBarKey);

    // Center the card, so the dock does not cover it.
    await Scrollable.ensureVisible(tester.element(recipeCard), alignment: 0.3);
    await tester.pumpAndSettle();
    await tester.longPress(recipeCard);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookbookEntryInkWell.removeKey));
    await tester.pumpAndSettle();

    expect(recipeCard, findsNothing);
    expect(templates.templates, [template]);
    expect(snackBar, findsOneWidget);
    // The meal under "Offen" stays.
    expect(find.byType(CookbookOpenMealCard), findsOneWidget);

    await tester.tap(
      find.descendant(of: snackBar, matching: find.byType(TextButton)),
    );
    await tester.pumpAndSettle();

    expect(recipeCard, findsOneWidget);
    expect(templates.templates, unorderedEquals([recipe, template]));

    await Scrollable.ensureVisible(
      tester.element(templateTile),
      alignment: 0.3,
    );
    await tester.pumpAndSettle();
    await tester.longPress(templateTile);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookbookEntryInkWell.removeKey));
    await tester.pumpAndSettle();

    expect(templateTile, findsNothing);
    expect(templates.templates, [recipe]);
    expect(snackBar, findsOneWidget);
  });

  testWidgets('plans a Vorlage and a recipe by long press', (tester) async {
    final plans = FakePlannedEntryRepository();
    await tester.pumpWidget(
      _app(
        templates: FakePreparedMealTemplateRepository(
          templates: [recipe, template],
        ),
        meals: const [],
        plans: plans,
      ),
    );
    await tester.pumpAndSettle();

    Future<void> plan(Finder card) async {
      // Center the card, so the dock does not cover it.
      await Scrollable.ensureVisible(tester.element(card), alignment: 0.3);
      await tester.pumpAndSettle();
      await tester.longPress(card);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CookbookEntryInkWell.planKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byKey(RecipePlanFlow.snackBarKey), findsOneWidget);
    }

    await plan(find.byKey(CookbookTemplateTile.tileKey('bowl')));
    await plan(find.byKey(CookbookRecipeCard.cardKey('pasta')));

    final [vorlage, pasta] = plans.plans;
    // The Vorlage keeps its own values; the pasta lacks tomato sauce, so it
    // is a reminder without kcal.
    expect(vorlage.bundleSourceTemplateId, 'bowl');
    expect(vorlage.nutritionPending, isFalse);
    expect(vorlage.totalKcal, greaterThan(0));
    expect(pasta.bundleSourceTemplateId, 'pasta');
    expect(pasta.nutritionPending, isTrue);
    expect(pasta.totalKcal, 0);
  });

  testWidgets('saves foods picked from the Vorrat as a new template and '
      'leaves the Vorrat as it is', (tester) async {
    final templates = FakePreparedMealTemplateRepository();
    final inventory = _Inventory([
      labeledFoodTestData(
        id: 'rice',
        name: 'Rice',
        grams: 500,
        label: riceLabelTestData,
      ),
      labeledFoodTestData(
        id: 'sauce',
        name: 'Sauce',
        grams: 300,
        label: sauceLabelTestData,
      ),
      labeledFoodTestData(
        id: 'apple',
        name: 'Apple',
        grams: 200,
        label: const GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
          per100Kcal: 52,
        ),
      ),
    ]);
    await tester.pumpWidget(
      _app(templates: templates, meals: [openMeal], inventory: inventory),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CookbookTemplateStrip.createKey));
    await tester.pumpAndSettle();
    // A food without a full label cannot be added up into a template.
    expect(find.byKey(const ValueKey('combine_pick_row_apple')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('combine_pick_row_rice')));
    await tester.tap(find.byKey(const ValueKey('combine_pick_row_sauce')));
    await tester.pump();
    await tester.tap(find.byKey(InventoryCombinePickPage.confirmKey));
    await tester.pumpAndSettle();

    final field = find.byKey(PreparedMealTemplateNameSheet.fieldKey);
    expect(tester.widget<TextField>(field).controller?.text, 'Rice, Sauce');
    await tester.enterText(field, 'Rice bowl');
    await tester.tap(find.byKey(PreparedMealTemplateNameSheet.saveKey));
    await tester.pumpAndSettle();

    final saved = templates.templates.single;
    expect(saved.name, 'Rice bowl');
    expect(
      saved.components.map((food) => (food.inventoryItemId, food.usedAmount)),
      [('rice', 500), ('sauce', 300)],
    );
    expect(inventory.writes, 0);
    expect(find.byType(CookbookPage), findsOneWidget);
    expect(find.text('Template saved.'), findsOneWidget);
  });

  testWidgets('without a fitting food the Vorrat says so', (tester) async {
    await tester.pumpWidget(
      _app(templates: FakePreparedMealTemplateRepository(), meals: [openMeal]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CookbookTemplateStrip.createKey));
    await tester.pumpAndSettle();

    final hint = tester.widget<Text>(
      find.byKey(InventoryCombinePickPage.emptyKey),
    );
    expect(
      hint.data,
      'No food in your stock has an amount left and full nutrition values.',
    );
  });

  testWidgets('closing the Vorrat saves no template', (tester) async {
    final templates = FakePreparedMealTemplateRepository();
    await tester.pumpWidget(
      _app(
        templates: templates,
        meals: [openMeal],
        inventory: _Inventory([
          labeledFoodTestData(
            id: 'rice',
            name: 'Rice',
            grams: 500,
            label: riceLabelTestData,
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CookbookTemplateStrip.createKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    expect(templates.templates, isEmpty);
    expect(find.byType(CookbookPage), findsOneWidget);
  });

  testWidgets('continues a meal in the pot on the cooked page', (tester) async {
    final potMeal = preparedMealTestData(
      id: 'pot',
      name: 'Lentil soup',
    ).copyWith(inPot: true);
    await tester.pumpWidget(
      _app(templates: FakePreparedMealTemplateRepository(), meals: [potMeal]),
    );
    await tester.pumpAndSettle();

    // Without open rows the meal is in the pot until it is marked cooked.
    expect(find.byType(CookbookOpenMealCard), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(CookbookOpenMealCard),
        matching: find.byType(FilledButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>(AppRoutes.homeCookedMeal)),
      findsOneWidget,
    );
  });
}
