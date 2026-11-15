import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_image_generator.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_repository.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_sheet/ai_chef_setup_view.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_sheet/ai_chef_sheet.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/cookbook_new/presentation/cookbook_page.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_idea_flow.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_recipe_card.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_recipe_grid.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'new_recipe_sheet.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_idea_sheet.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_nutrition_section.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/shoppinglist/support/fake_shopping_list_repository.dart';
import '../../test/helpers/fake_ai_chef.dart';
import '../../test/helpers/fake_cook_run_repository.dart';
import '../../test/helpers/fake_inventory_item_repository.dart';
import '../../test/helpers/fake_prepared_meal_repository.dart';
import '../../test/helpers/fake_prepared_meal_template_repository.dart';
import '../../test/helpers/fake_signed_in_user.dart';

Widget _app({
  required FakeAiChef chef,
  required FakePreparedMealTemplateRepository templates,
}) {
  final shopping = FakeShoppingListRepository();
  addTearDown(shopping.dispose);
  final router = GoRouter(
    initialLocation: AppRoutes.homeInventoryTemplates,
    routes: [
      GoRoute(
        path: AppRoutes.homeInventoryTemplates,
        builder: (context, state) => const CookbookPage(),
      ),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => DateTime(2026, 11, 13, 12)),
      aiChefRepositoryProvider.overrideWithValue(chef.repository),
      aiChefImageGeneratorProvider.overrideWithValue(chef.imageGenerator),
      preparedMealTemplateRepositoryProvider.overrideWithValue(templates),
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

Future<void> _toIdeaWindow(WidgetTester tester) async {
  final add = find.byKey(CookbookRecipeGrid.addKey);
  await Scrollable.ensureVisible(tester.element(add), alignment: 0.3);
  await tester.pumpAndSettle();
  await tester.tap(add);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(NewRecipeSheet.entryKey(NewRecipeChoice.ai)));
  await tester.pumpAndSettle();
  expect(find.byType(AiChefSheet), findsOneWidget);
  await tester.tap(find.byKey(AiChefSetupView.generateKey));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a recipe idea opens as a recipe and is saved to the Kochbuch', (
    tester,
  ) async {
    final chef = FakeAiChef();
    final templates = FakePreparedMealTemplateRepository();
    await tester.pumpWidget(_app(chef: chef, templates: templates));
    await tester.pumpAndSettle();

    await _toIdeaWindow(tester);

    expect(find.byType(RecipeIdeaSheet), findsOneWidget);
    expect(find.text('Tomatenpasta'), findsOneWidget);
    expect(templates.templates, isEmpty);
    // The food label of one estimated portion stands under the ingredients.
    await tester.scrollUntilVisible(
      find.byKey(RecipeNutritionSection.labelKey),
      200,
      scrollable: find
          .descendant(
            of: find.byType(RecipeIdeaSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.byKey(RecipeNutritionSection.labelKey), findsOneWidget);

    await tester.tap(find.byKey(RecipeIdeaSheet.saveKey));
    await tester.pumpAndSettle();

    expect(find.byType(RecipeIdeaSheet), findsNothing);
    expect(find.byKey(RecipeIdeaFlow.savedSnackBarKey), findsOneWidget);
    expect(templates.templates.single.name, 'Tomatenpasta');
    expect(find.byType(CookbookRecipeCard), findsOneWidget);
    expect(find.text('Tomatenpasta'), findsOneWidget);
    expect(chef.uploads, [FakeAiChef.coverPath(templates.templates.single.id)]);
  });

  testWidgets('a recipe that shows in the Kochbuch late still gets its '
      'picture', (tester) async {
    final chef = FakeAiChef();
    final templates = FakePreparedMealTemplateRepository();
    await tester.pumpWidget(_app(chef: chef, templates: templates));
    await tester.pumpAndSettle();
    await _toIdeaWindow(tester);
    final show = templates.showHold = Completer();

    await tester.tap(find.byKey(RecipeIdeaSheet.saveKey));
    await tester.pumpAndSettle();

    expect(find.byKey(RecipeIdeaFlow.savedSnackBarKey), findsOneWidget);
    expect(find.byType(CookbookRecipeCard), findsNothing);
    expect(chef.uploads, isEmpty);

    show.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CookbookRecipeCard), findsOneWidget);
    expect(chef.uploads, [FakeAiChef.coverPath(templates.templates.single.id)]);
  });

  testWidgets('closing the window without saving leaves the Kochbuch empty', (
    tester,
  ) async {
    final chef = FakeAiChef();
    final templates = FakePreparedMealTemplateRepository();
    await tester.pumpWidget(_app(chef: chef, templates: templates));
    await tester.pumpAndSettle();

    await _toIdeaWindow(tester);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byType(RecipeIdeaSheet), findsNothing);
    expect(find.byType(CookbookRecipeCard), findsNothing);
    expect(templates.templates, isEmpty);
    expect(chef.uploads, isEmpty);
  });
}
