import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/cookbook_new/presentation/cookbook_page.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_editor_page.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_recipe_grid.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'new_recipe_sheet.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/fake_cook_run_repository.dart';
import '../../../helpers/fake_inventory_item_repository.dart';
import '../../../helpers/fake_prepared_meal_repository.dart';
import '../../../helpers/fake_prepared_meal_template_repository.dart';
import '../../../helpers/fake_signed_in_user.dart';
import '../../../support/prepared_meal_test_data.dart';
import '../../shoppinglist/support/fake_shopping_list_repository.dart';

const _editorKey = ValueKey<String>('editor-page');

Widget _app({List<PreparedMeal> recipes = const []}) {
  final shopping = FakeShoppingListRepository();
  addTearDown(shopping.dispose);
  final router = GoRouter(
    initialLocation: AppRoutes.homeInventoryTemplates,
    routes: [
      GoRoute(
        path: AppRoutes.homeInventoryTemplates,
        builder: (context, state) => const CookbookPage(),
      ),
      GoRoute(
        path: AppRoutes.homeRecipeNew,
        builder: (context, state) =>
            const Scaffold(key: _editorKey, body: RecipeEditorPage()),
      ),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      preparedMealTemplateRepositoryProvider.overrideWithValue(
        FakePreparedMealTemplateRepository(templates: recipes),
      ),
      preparedMealRepositoryProvider.overrideWithValue(
        FakePreparedMealRepository(),
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
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('an empty Kochbuch offers "Add a recipe", which opens the '
      'new-recipe sheet', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final add = find.byKey(CookbookRecipeGrid.addKey);
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: add, matching: find.text('Add a recipe')),
      findsOneWidget,
    );

    await tester.tap(add);
    await tester.pumpAndSettle();

    expect(find.byType(NewRecipeSheet), findsOneWidget);
    await tester.tap(find.byKey(NewRecipeSheet.entryKey(NewRecipeChoice.type)));
    await tester.pumpAndSettle();
    expect(find.byKey(_editorKey), findsOneWidget);
  });

  testWidgets('with a recipe the "Add a recipe" button is gone', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        recipes: [
          preparedMealTestData(
            id: 'pasta',
            name: 'Pasta',
          ).copyWith(recipeIngredients: const ['200 g Pasta']),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CookbookRecipeGrid.addKey), findsNothing);
  });

  testWidgets('the header tool that lists the utensils is called "Pots"', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('POTS'), findsOneWidget);
  });
}
