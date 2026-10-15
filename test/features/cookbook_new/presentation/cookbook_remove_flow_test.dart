import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/cookbook_new/presentation/cookbook_page.dart';
import 'package:yamt/features/cookbook_new/presentation/'
    'cookbook_remove_flow.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_page.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_entry_ink_well.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_recipe_card.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_template_tile.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_hero.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/fake_prepared_meal_repository.dart';
import '../../../helpers/fake_prepared_meal_template_repository.dart';
import '../../../support/prepared_meal_test_data.dart';

final PreparedMeal _recipe =
    preparedMealTestData(id: 'pasta', imageAssetId: 'pasta-photo').copyWith(
      name: 'One-pan pasta',
      imageUrl: 'https://example.com/pasta.jpg',
      recipeUrl: 'https://example.com/pasta',
      recipeIngredients: const ['200 g Pasta', '150 g Tomato sauce'],
      recipeIngredientAssignments: const {
        '200 g Pasta': ['pasta-item'],
      },
    );

final PreparedMeal _template = preparedMealTestData(id: 'bowl');

final Finder _recipeCard = find.byKey(CookbookRecipeCard.cardKey('pasta'));

final Finder _snackBar = find.byKey(CookbookRemoveFlow.snackBarKey);

Widget _app({
  required FakePreparedMealTemplateRepository templates,
  FakePreparedMealRepository? meals,
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.homeInventoryTemplates,
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
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      preparedMealTemplateRepositoryProvider.overrideWithValue(templates),
      preparedMealRepositoryProvider.overrideWithValue(
        meals ?? FakePreparedMealRepository(),
      ),
      inventoryItemRepositoryProvider.overrideWithValue(_EmptyVorrat()),
      shoppingListRepositoryProvider.overrideWithValue(_EmptyShoppingList()),
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

Future<void> _longPressRemove(WidgetTester tester, Finder card) async {
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.longPress(card);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(CookbookEntryInkWell.removeKey));
  await tester.pumpAndSettle();
}

Future<void> _undo(WidgetTester tester) async {
  await tester.tap(
    find.descendant(of: _snackBar, matching: find.byType(TextButton)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a long press removes a recipe, and "Rückgängig" brings it '
      'back as it was', (tester) async {
    final cooked = preparedMealTestData(
      id: 'cooked',
      name: 'Pasta from Monday',
      imageAssetId: 'pasta-photo',
    ).copyWith(inPot: true);
    final templates = FakePreparedMealTemplateRepository(templates: [_recipe]);
    final meals = FakePreparedMealRepository(meals: [cooked]);
    await tester.pumpWidget(_app(templates: templates, meals: meals));
    await tester.pumpAndSettle();

    await _longPressRemove(tester, _recipeCard);

    expect(_recipeCard, findsNothing);
    expect(templates.templates, isEmpty);
    expect(
      find.descendant(
        of: _snackBar,
        matching: find.text('One-pan pasta removed'),
      ),
      findsOneWidget,
    );
    // The meal cooked from the recipe stays in the Vorrat.
    expect(find.text('Pasta from Monday'), findsOneWidget);
    expect(meals.meals, [cooked]);
    expect(meals.writeCount, 0);

    await _undo(tester);

    expect(templates.templates, [_recipe]);
    expect(_recipeCard, findsOneWidget);
    expect(_snackBar, findsNothing);
  });

  testWidgets('screen readers remove a Vorlage without the long press', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final templates = FakePreparedMealTemplateRepository(
      templates: [_template],
    );
    await tester.pumpWidget(_app(templates: templates));
    await tester.pumpAndSettle();
    const remove = CustomSemanticsAction(label: 'Remove');
    final tile = find.descendant(
      of: find.byKey(CookbookTemplateTile.tileKey('bowl')),
      matching: find.byType(CookbookEntryInkWell),
    );

    final node = tester.getSemantics(tile);
    expect(
      node,
      isSemantics(
        hasTapAction: true,
        hasLongPressAction: true,
        onLongPressHint: 'Show actions',
        customActions: const [CustomSemanticsAction(label: 'Plan'), remove],
      ),
    );
    node.owner!.performAction(
      node.id,
      SemanticsAction.customAction,
      CustomSemanticsAction.getIdentifier(remove),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CookbookTemplateTile.tileKey('bowl')), findsNothing);
    expect(templates.templates, isEmpty);
    expect(
      find.descendant(of: _snackBar, matching: find.text('Rice bowl removed')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('a long press removes a Vorlage', (tester) async {
    final templates = FakePreparedMealTemplateRepository(
      templates: [_recipe, _template],
    );
    await tester.pumpWidget(_app(templates: templates));
    await tester.pumpAndSettle();

    await _longPressRemove(
      tester,
      find.byKey(CookbookTemplateTile.tileKey('bowl')),
    );

    expect(find.byKey(CookbookTemplateTile.tileKey('bowl')), findsNothing);
    expect(templates.templates, [_recipe]);
    await _undo(tester);
    expect(templates.templates, [_recipe, _template]);
    expect(find.byKey(CookbookTemplateTile.tileKey('bowl')), findsOneWidget);
  });

  testWidgets('a failed remove says so and keeps the recipe', (tester) async {
    final templates = FakePreparedMealTemplateRepository(templates: [_recipe])
      ..failWrites = true;
    await tester.pumpWidget(_app(templates: templates));
    await tester.pumpAndSettle();

    await _longPressRemove(tester, _recipeCard);

    expect(find.text('Could not remove One-pan pasta.'), findsOneWidget);
    expect(_snackBar, findsNothing);
    expect(_recipeCard, findsOneWidget);
    expect(templates.templates, [_recipe]);
  });

  testWidgets('the recipe page removes its recipe, closes, and "Rückgängig" '
      'brings it back on the Kochbuch', (tester) async {
    final templates = FakePreparedMealTemplateRepository(templates: [_recipe]);
    await tester.pumpWidget(_app(templates: templates));
    await tester.pumpAndSettle();
    await tester.ensureVisible(_recipeCard);
    await tester.pumpAndSettle();
    await tester.tap(_recipeCard);
    await tester.pumpAndSettle();
    expect(find.byType(RecipePage), findsOneWidget);

    await tester.tap(find.byKey(RecipeHero.removeKey));
    await tester.pump();
    // A second tap while the page slides out removes nothing more, and the
    // page keeps its recipe until it is gone.
    await tester.tap(find.byKey(RecipeHero.removeKey), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(RecipePage.notFoundKey), findsNothing);
    expect(templates.templates, [_recipe]);
    await tester.pumpAndSettle();

    expect(templates.writeCount, 1);
    expect(find.byType(RecipePage), findsNothing);
    expect(find.byType(CookbookPage), findsOneWidget);
    expect(_recipeCard, findsNothing);
    expect(templates.templates, isEmpty);
    expect(
      find.descendant(
        of: _snackBar,
        matching: find.text('One-pan pasta removed'),
      ),
      findsOneWidget,
    );

    await _undo(tester);

    expect(templates.templates, [_recipe]);
    expect(_recipeCard, findsOneWidget);
  });
}

class _EmptyVorrat implements InventoryItemRepository {
  @override
  Stream<List<InventoryItem>> watchAll() =>
      Stream.value(const <InventoryItem>[]);

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyShoppingList implements ShoppingListRepository {
  @override
  Stream<List<ShoppingListItem>> watchAll() =>
      Stream.value(const <ShoppingListItem>[]);

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
