import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_page.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_hero.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_ingredient_tile.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_line_nutrition_section.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/fake_cook_run_repository.dart';
import '../../../helpers/fake_inventory_item_repository.dart';
import '../../../helpers/fake_prepared_meal_template_repository.dart';
import '../../../helpers/fake_signed_in_user.dart';
import '../../../support/prepared_meal_test_data.dart';
import '../../shoppinglist/support/fake_shopping_list_repository.dart';

const _lines = ['200 g Pasta', '100 g Tomaten'];

RecipeEstimate _estimate({List<RecipeLineNutrition>? lines}) => RecipeEstimate(
  kcal: 360,
  protein: 12,
  carbs: 72,
  fat: 2,
  portions: 2,
  linesKey: recipeLinesKey(_lines),
  createdAt: DateTime.utc(2026, 11, 13),
  lines: lines,
);

const _perLine = [
  RecipeLineNutrition(kcal: 700, protein: 24, carbs: 140, fat: 4),
  RecipeLineNutrition(kcal: 20, protein: 1, carbs: 4, fat: 1),
];

PreparedMeal _recipe({
  RecipeEstimate? estimate,
  List<String> steps = const ['Cook the pasta.'],
}) => preparedMealTestData(id: 'pasta').copyWith(
  name: 'Tomato pasta',
  totalPortions: 2,
  recipeIngredients: _lines,
  recipeInstructions: steps,
  recipeEstimate: estimate,
);

Widget _app(PreparedMeal recipe, {double statusBar = 0}) {
  final shopping = FakeShoppingListRepository();
  addTearDown(shopping.dispose);
  final router = GoRouter(
    initialLocation: AppRoutes.homeRecipePath('pasta'),
    routes: [
      GoRoute(
        path: AppRoutes.homeRecipe,
        builder: (context, state) =>
            RecipePage(recipeId: state.pathParameters['recipeId']!),
      ),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      preparedMealTemplateRepositoryProvider.overrideWithValue(
        FakePreparedMealTemplateRepository(templates: [recipe]),
      ),
      authStateChangesProvider.overrideWith(
        (ref) => Stream.value(FakeSignedInUser('uid-1')),
      ),
      cookRunRepositoryProvider.overrideWithValue(FakeCookRunRepository()),
      inventoryItemRepositoryProvider.overrideWithValue(
        FakeInventoryItemRepository(const []),
      ),
      shoppingListRepositoryProvider.overrideWithValue(shopping),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: EdgeInsets.only(top: statusBar),
          viewPadding: EdgeInsets.only(top: statusBar),
        ),
        child: child!,
      ),
      routerConfig: router,
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  PreparedMeal recipe, {
  double statusBar = 0,
}) async {
  tester.view.physicalSize = const Size(400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(recipe, statusBar: statusBar));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the nutrition per ingredient folded when the estimate has '
      'values per line', (tester) async {
    await _pump(tester, _recipe(estimate: _estimate(lines: _perLine)));

    expect(find.byKey(RecipeLineNutritionSection.toggleKey), findsOneWidget);
    expect(find.byKey(RecipeLineNutritionSection.tableKey), findsNothing);

    await tester.ensureVisible(
      find.byKey(RecipeLineNutritionSection.toggleKey),
    );
    await tester.tap(find.byKey(RecipeLineNutritionSection.toggleKey));
    await tester.pumpAndSettle();

    final table = find.byKey(RecipeLineNutritionSection.tableKey);
    expect(table, findsOneWidget);
    expect(find.descendant(of: table, matching: find.text('700')), findsOne);
    expect(find.descendant(of: table, matching: find.text('20')), findsOne);
  });

  testWidgets('scales the table to the chosen portions', (tester) async {
    await _pump(tester, _recipe(estimate: _estimate(lines: _perLine)));
    await tester.tap(find.byKey(RecipePage.morePortionsKey));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(RecipeLineNutritionSection.toggleKey),
    );
    await tester.tap(find.byKey(RecipeLineNutritionSection.toggleKey));
    await tester.pumpAndSettle();

    // From 2 to 3 portions: 700 kcal become 1,050, and the head says so.
    final table = find.byKey(RecipeLineNutritionSection.tableKey);
    expect(
      find.descendant(of: table, matching: find.text('For 3 portions')),
      findsOne,
    );
    expect(find.descendant(of: table, matching: find.text('1,050')), findsOne);
    expect(
      find.descendant(of: table, matching: find.text('700')),
      findsNothing,
    );
  });

  testWidgets('says the portions of the recipe in the head of the table', (
    tester,
  ) async {
    await _pump(tester, _recipe(estimate: _estimate(lines: _perLine)));
    await tester.ensureVisible(
      find.byKey(RecipeLineNutritionSection.toggleKey),
    );
    await tester.tap(find.byKey(RecipeLineNutritionSection.toggleKey));
    await tester.pumpAndSettle();

    final table = find.byKey(RecipeLineNutritionSection.tableKey);
    expect(
      find.descendant(of: table, matching: find.text('For 2 portions')),
      findsOne,
    );
  });

  testWidgets('shows no section for an estimate without values per line', (
    tester,
  ) async {
    await _pump(tester, _recipe(estimate: _estimate()));

    expect(find.byKey(RecipeLineNutritionSection.toggleKey), findsNothing);
  });

  testWidgets('shows no section when the values do not match the ingredients', (
    tester,
  ) async {
    await _pump(tester, _recipe(estimate: _estimate(lines: [_perLine.first])));

    expect(find.byKey(RecipeLineNutritionSection.toggleKey), findsNothing);
  });

  testWidgets('shows the preparation when the recipe has steps', (
    tester,
  ) async {
    await _pump(tester, _recipe(estimate: _estimate()));

    expect(find.text('PREPARATION'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Cook the pasta.'), 200);
    expect(find.text('Cook the pasta.'), findsOneWidget);
  });

  testWidgets('shows no "Preparation" without steps', (tester) async {
    await _pump(tester, _recipe(estimate: _estimate(), steps: const []));

    expect(find.text('PREPARATION'), findsNothing);
    expect(find.text('Preparation'), findsNothing);
  });

  testWidgets('says a spoon amount exactly at scaled portions', (tester) async {
    final recipe = preparedMealTestData(id: 'pasta').copyWith(
      name: 'Tomato pasta',
      totalPortions: 2,
      recipeIngredients: const ['1 TL Salz', '1/2 Zitrone', '2 EL Öl'],
    );
    await _pump(tester, recipe);
    for (var i = 0; i < 3; i += 1) {
      await tester.tap(find.byKey(RecipePage.morePortionsKey));
      await tester.pumpAndSettle();
    }

    String amountOf(int index) => tester
        .widget<Text>(
          find
              .descendant(
                of: find.byKey(RecipeIngredientTile.tileKey(index)),
                matching: find.byType(Text),
              )
              .first,
        )
        .textSpan!
        .toPlainText();

    expect(amountOf(0), startsWith('2,5 TL'));
    expect(amountOf(1), startsWith('1,25'));
    expect(amountOf(2), startsWith('5 EL'));
  });

  testWidgets('starts the picture below the status bar', (tester) async {
    await _pump(tester, _recipe(estimate: _estimate()), statusBar: 40);

    expect(
      tester.getTopLeft(find.byType(RecipeHero)).dy,
      greaterThanOrEqualTo(40),
    );
  });

  testWidgets('starts the picture at the top without a status bar', (
    tester,
  ) async {
    await _pump(tester, _recipe(estimate: _estimate()));

    expect(tester.getTopLeft(find.byType(RecipeHero)).dy, 0);
  });
}
