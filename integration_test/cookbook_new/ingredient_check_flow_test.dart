import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/device/screen_wake_lock.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'ingredient_check_draft.dart';
import 'package:yamt/features/cookbook_new/presentation/cooked_meal_page.dart';
import 'package:yamt/features/cookbook_new/presentation/ingredient_check_page.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_page.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'ingredient_check_edit_list.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'ingredient_check_row.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_check_card.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_meal_food_pick.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository_contract.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/inventory_item_whole_list_writes.dart';

const _startKey = ValueKey<String>('open-recipe');
const _pickKey = ValueKey<String>('pick-pepper');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'checks the ingredients, adds a food it has, and lists the rest',
    (tester) async {
      final templates = _FakeTemplateRepository([_recipe]);
      final inventory = _FakeInventoryRepository([
        _item('mince', 'Hackfleisch', 2000),
        _item('carrots', 'Karotten', 400),
      ]);
      final shopping = _FakeShoppingListRepository();
      await tester.pumpWidget(
        _app(templates: templates, inventory: inventory, shopping: shopping),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_startKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(RecipeCheckCard.cardKey));
      await tester.pumpAndSettle();
      expect(find.byType(IngredientCheckPage), findsOneWidget);

      // Nothing changes this time.
      await tester.tap(find.byKey(IngredientCheckPage.nextKey));
      await tester.pumpAndSettle();

      // Hackfleisch and the 400 g of carrots come from the Vorrat.
      expect(
        find.byKey(
          IngredientCheckRow.choiceKey('found-1', IngredientCheckChoice.use),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(IngredientCheckPage.nextKey));
      await tester.pumpAndSettle();

      // The pepper is in the kitchen; the missing carrots go on the list.
      await tester.tap(
        find.byKey(
          IngredientCheckRow.choiceKey('missing-0', IngredientCheckChoice.have),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_pickKey));
      await tester.pumpAndSettle();
      expect(find.byType(IngredientCheckPage), findsOneWidget);
      expect(
        find.byKey(
          IngredientCheckRow.choiceKey('rest-0', IngredientCheckChoice.cart),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(IngredientCheckPage.nextKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(IngredientCheckPage.nextKey));
      await tester.pumpAndSettle();

      expect(find.byType(RecipePage), findsOneWidget);
      expect(find.byType(IngredientCheckPage), findsNothing);
      final pepper = inventory.items.singleWhere(
        (item) => item.name == 'Paprika',
      );
      expect(pepper.currentAmount, 300);
      expect(templates.saved.single.recipeIngredientAssignments, {
        '500 g Hackfleisch': ['mince'],
        '600 g Karotten': ['carrots'],
        '300 g Paprika': [pepper.id],
      });
      expect(shopping.saved.map((item) => item.name), ['200 g Karotten']);
    },
  );

  testWidgets('cooks with more meat, peas, and without the pepper this time', (
    tester,
  ) async {
    final templates = _FakeTemplateRepository([_recipe]);
    final shopping = _FakeShoppingListRepository();
    final meals = _FakeMealRepository();
    await tester.pumpWidget(
      _app(
        templates: templates,
        inventory: _FakeInventoryRepository([
          _item('mince', 'Hackfleisch', 2000),
          _item('carrots', 'Karotten', 1000),
        ]),
        shopping: shopping,
        meals: meals,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_startKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RecipeCheckCard.cardKey));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(IngredientCheckPage.changeKey));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(IngredientCheckEditList.amountKey('500 g Hackfleisch')),
      '900',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(IngredientCheckEditList.removeKey('300 g Paprika')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(IngredientCheckEditList.addKey),
      '200 g Erbsen',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(IngredientCheckEditList.addKey))
          .controller
          ?.text,
      isEmpty,
    );

    // Weiter through the found and the missing ones, then Fertig.
    for (var step = 0; step < 4; step++) {
      await tester.tap(find.byKey(IngredientCheckPage.nextKey));
      await tester.pumpAndSettle();
    }
    expect(find.byType(RecipePage), findsOneWidget);
    expect(templates.saved.single.recipeIngredients, _recipe.recipeIngredients);
    expect(shopping.saved.map((item) => item.name), ['200 g Erbsen']);

    await tester.tap(find.byKey(RecipePage.cookKey));
    await tester.pumpAndSettle();

    expect(find.byType(CookedMealPage), findsOneWidget);
    final meal = meals.saved.single;
    expect(meal.components.map((c) => (c.inventoryItemId, c.usedAmount)), [
      ('mince', 900),
      ('carrots', 600),
    ]);
    expect(meal.pendingRecipeIngredients, ['200 g Erbsen']);
  });
}

InventoryItem _item(String id, String name, int amount) => InventoryItem.create(
  id: id,
  name: name,
  entryDate: DateTime.utc(2026, 10, 9),
  storeName: 'Store',
  quantity: 1,
  initialAmount: amount,
  currentAmount: amount,
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
  recipeIngredients: const [
    '500 g Hackfleisch',
    '600 g Karotten',
    '300 g Paprika',
    'Salz',
  ],
  ignoredRecipeIngredients: const ['Salz'],
);

/// Stands in for the food pick: it returns 300 g of pepper.
class _FakeFoodPickPage extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        key: _pickKey,
        onPressed: () => context.pop<InventoryMealFoodPick>((
          result: InventoryReceiptManualProductResult(
            item: _item(
              'pepper-draft',
              'Paprika',
              500,
            ).copyWith(weight: '500 g'),
            action: InventoryReceiptManualProductAction.addToInventory,
            requiresGlobalPersistence: false,
            skipMissingBarcodePrompt: true,
          ),
          request: InventoryItemEatRequest(
            inventoryAmount: 300,
            loggedAt: DateTime.utc(2026, 10, 9),
            mealType: MealType.lunch,
          ),
        )),
        child: const Text('Pick'),
      ),
    ),
  );
}

Widget _app({
  required _FakeTemplateRepository templates,
  required _FakeInventoryRepository inventory,
  required _FakeShoppingListRepository shopping,
  _FakeMealRepository? meals,
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.homeInventoryTemplates,
    routes: [
      GoRoute(
        path: AppRoutes.homeInventoryTemplates,
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              key: _startKey,
              onPressed: () => context.push(AppRoutes.homeRecipePath('stew')),
              child: const Text('Start'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.homeRecipe,
        builder: (context, state) =>
            RecipePage(recipeId: state.pathParameters['recipeId']!),
      ),
      GoRoute(
        path: AppRoutes.homeRecipeCheck,
        builder: (context, state) =>
            IngredientCheckPage(recipeId: state.pathParameters['recipeId']!),
      ),
      GoRoute(
        path: AppRoutes.homeCookedMeal,
        builder: (context, state) =>
            CookedMealPage(mealId: state.pathParameters['mealId']!),
      ),
      GoRoute(
        path: AppRoutes.homeFoodPick,
        builder: (context, state) => const _FakeFoodPickPage(),
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      firebaseFirestoreProvider.overrideWith((ref) => null),
      preparedMealRepositoryProvider.overrideWithValue(
        meals ?? _FakeMealRepository(),
      ),
      preparedMealTemplateRepositoryProvider.overrideWithValue(templates),
      inventoryItemRepositoryProvider.overrideWithValue(inventory),
      inventoryActivityEventRepositoryProvider.overrideWithValue(
        _FakeActivityRepository(),
      ),
      inventoryActivityActorProvider.overrideWithValue(null),
      shoppingListRepositoryProvider.overrideWithValue(shopping),
      screenWakeLockProvider.overrideWithValue(
        ScreenWakeLock(toggle: ({required on}) async {}),
      ),
      kitchenUtensilRepositoryProvider.overrideWithValue(
        _FakeUtensilRepository(),
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
  Future<List<PreparedMeal>> readAllForChange() => readAll();

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
}

class _FakeTemplateRepository implements PreparedMealTemplateRepository {
  new(this.saved);

  List<PreparedMeal> saved;
  final _changes = StreamController<List<PreparedMeal>>.broadcast();

  @override
  Stream<List<PreparedMeal>> watchAll() async* {
    yield List.of(saved);
    yield* _changes.stream;
  }

  @override
  Future<List<PreparedMeal>> readAll() async => List.of(saved);

  @override
  Future<bool> save(PreparedMeal template) async {
    saved = [
      for (final stored in saved)
        if (stored.id != template.id) stored,
      template,
    ];
    _changes.add(saved);
    return true;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  final _changes = StreamController<List<InventoryItem>>.broadcast();

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield items;
    yield* _changes.stream;
  }

  @override
  Future<List<InventoryItem>> readAll() async => items;

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async {
    this.items = items;
    _changes.add(items);
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) =>
      replaceItems([...this.items, ...items]);
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
  List<ShoppingListItem> saved = const [];

  @override
  Stream<List<ShoppingListItem>> watchAll() async* {
    yield saved;
  }

  @override
  Future<List<ShoppingListItem>> readAll() async => saved;

  @override
  Future<bool> saveAll(List<ShoppingListItem> items) async {
    saved = items;
    return true;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
