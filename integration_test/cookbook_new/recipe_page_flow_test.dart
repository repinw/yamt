import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/device/screen_wake_lock.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/cookbook_new/presentation/cooked_meal_page.dart';
import 'package:yamt/features/cookbook_new/presentation/cooking_guide_page.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_page.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_ingredient_tile.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_stock_picker_sheet.dart';
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cooks a recipe for more portions with a picked Vorrat item', (
    tester,
  ) async {
    final meals = _FakeMealRepository();
    final inventory = _FakeInventoryRepository([
      _item('mince', 'Hackfleisch'),
      _item('carrots', 'Karotten'),
    ]);
    await tester.pumpWidget(_app(meals: meals, inventory: inventory));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_startKey));
    await tester.pumpAndSettle();

    expect(find.byType(RecipePage), findsOneWidget);

    // Two portions in the recipe, three in the pot.
    await tester.tap(find.byKey(RecipePage.morePortionsKey));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(RecipePage.portionsKey)).data, '3');

    // The carrots stay in the Vorrat this time.
    final carrots = find.byKey(RecipeIngredientTile.tileKey(1));
    await tester.scrollUntilVisible(carrots, 100);
    await tester.ensureVisible(carrots);
    await tester.pumpAndSettle();
    await tester.tap(carrots);
    await tester.pumpAndSettle();
    expect(
      find.byKey(RecipeStockPickerSheet.optionKey('carrots')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(RecipeStockPickerSheet.noneKey));
    await tester.pumpAndSettle();

    // Straight to "Gekocht", without the Kochhelfer.
    await tester.tap(find.byKey(RecipePage.withGuideKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RecipePage.cookKey));
    await tester.pumpAndSettle();

    expect(find.byType(CookedMealPage), findsOneWidget);
    final meal = meals.saved.single;
    expect(meal.name, 'Bauerntopf');
    expect(meal.isInPot, isTrue);
    expect(meal.totalPortions, 3);
    expect(meal.components.single.inventoryItemId, 'mince');
    expect(meal.components.single.usedAmount, 750);
    expect(meal.pendingRecipeIngredients.single, contains('Karotten'));
    expect(
      inventory.items.firstWhere((item) => item.id == 'carrots').currentAmount,
      2000,
    );
  });

  testWidgets('cooks with the Kochhelfer, one sentence at a time', (
    tester,
  ) async {
    final meals = _FakeMealRepository();
    final screenOn = <bool>[];
    await tester.pumpWidget(
      _app(
        meals: meals,
        inventory: _FakeInventoryRepository([
          _item('mince', 'Hackfleisch'),
          _item('carrots', 'Karotten'),
        ]),
        screenOn: screenOn,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_startKey));
    await tester.pumpAndSettle();

    // Back from the first screen cooks nothing.
    await tester.tap(find.byKey(RecipePage.cookKey));
    await tester.pumpAndSettle();
    expect(find.byType(CookingGuidePage), findsOneWidget);
    expect(screenOn, [true]);
    await tester.tap(find.byKey(CookingGuidePage.backKey));
    await tester.pumpAndSettle();
    expect(find.byType(RecipePage), findsOneWidget);
    expect(meals.saved, isEmpty);

    await tester.tap(find.byKey(RecipePage.cookKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookingGuidePage.startKey));
    await tester.pumpAndSettle();
    // Back from the first sentence shows everything again.
    await tester.tap(find.byKey(CookingGuidePage.backKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookingGuidePage.startKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookingGuidePage.nextKey));
    await tester.pumpAndSettle();
    // The system back goes one sentence back, not out of the Kochhelfer.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(CookingGuidePage.nextKey), findsOneWidget);
    await tester.tap(find.byKey(CookingGuidePage.nextKey));
    await tester.pumpAndSettle();

    // The last sentence only finishes.
    expect(find.byKey(CookingGuidePage.nextKey), findsNothing);
    await tester.tap(find.byKey(CookingGuidePage.doneKey));
    await tester.pumpAndSettle();

    expect(find.byType(CookedMealPage), findsOneWidget);
    expect(meals.saved.single.name, 'Bauerntopf');
    // Closing "Gekocht" goes back to where the recipe was opened.
    expect(find.byType(RecipePage, skipOffstage: false), findsNothing);
    expect(find.byType(CookingGuidePage, skipOffstage: false), findsNothing);
  });

  testWidgets('a recipe that is gone says so', (tester) async {
    await tester.pumpWidget(
      _app(
        meals: _FakeMealRepository(),
        inventory: _FakeInventoryRepository(const []),
        recipes: const [],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_startKey));
    await tester.pumpAndSettle();

    expect(find.byKey(RecipePage.cookKey), findsNothing);
    expect(find.byKey(RecipePage.notFoundKey), findsOneWidget);
  });
}

InventoryItem _item(String id, String name) => InventoryItem.create(
  id: id,
  name: name,
  entryDate: DateTime.utc(2026, 10, 9),
  storeName: 'Store',
  quantity: 1,
  initialAmount: 2000,
  currentAmount: 2000,
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
  List<PreparedMeal>? recipes,
  List<bool>? screenOn,
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
        path: AppRoutes.homeRecipeGuide,
        builder: (context, state) =>
            CookingGuidePage(recipeId: state.pathParameters['recipeId']!),
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
      preparedMealRepositoryProvider.overrideWithValue(meals),
      preparedMealTemplateRepositoryProvider.overrideWithValue(
        _FakeTemplateRepository(recipes ?? [_recipe]),
      ),
      inventoryItemRepositoryProvider.overrideWithValue(inventory),
      inventoryActivityEventRepositoryProvider.overrideWithValue(
        _FakeActivityRepository(),
      ),
      inventoryActivityActorProvider.overrideWithValue(null),
      shoppingListRepositoryProvider.overrideWithValue(
        _FakeShoppingListRepository(),
      ),
      screenWakeLockProvider.overrideWithValue(
        ScreenWakeLock(toggle: ({required on}) async => screenOn?.add(on)),
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

class _FakeTemplateRepository implements PreparedMealTemplateRepository {
  new(this.saved);

  final List<PreparedMeal> saved;

  @override
  Stream<List<PreparedMeal>> watchAll() async* {
    yield List.of(saved);
  }

  @override
  Future<List<PreparedMeal>> readAll() async => List.of(saved);

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
  Stream<List<ShoppingListItem>> watchAll() async* {
    yield const <ShoppingListItem>[];
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
