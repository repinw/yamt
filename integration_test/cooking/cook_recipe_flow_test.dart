import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/data/closed_day_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_page.dart';
import 'package:yamt/features/cooking/presentation/cook_page.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_found_step.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_open_step.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_portion_step.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_pot_step.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_step_frame.dart';
import 'package:yamt/features/cooking/presentation/widgets/cook_top_bar.dart';
import 'package:yamt/features/inventory/data/cooked_meal_repository.dart';
import 'package:yamt/features/inventory/data/inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/kitchen_utensils/data/kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/data/kitchen_utensil_repository_contract.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_planned_entry_repository.dart';
import '../../test/features/shoppinglist/support/fake_shopping_list_repository.dart';
import '../../test/helpers/fake_inventory_item_repository.dart';
import '../../test/helpers/fake_prepared_meal_repository.dart';
import '../../test/helpers/fake_prepared_meal_template_repository.dart';
import '../../test/helpers/memory_app_preferences.dart';

const _startKey = ValueKey<String>('open-recipe');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cooks a recipe from the Vorrat up to the portion step', (
    tester,
  ) async {
    final cooked = _RecordingCookedMeals();
    await tester.pumpWidget(_app(cooked: cooked));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_startKey));
    await tester.pumpAndSettle();

    expect(find.byType(RecipePage), findsOneWidget);
    await _openCooking(tester);
    expect(find.byType(CookPage), findsOneWidget);

    // Recipe step: go on to the Vorrat.
    await tester.tap(find.byKey(CookStepFrame.buttonKey));
    await tester.pumpAndSettle();

    // Found step: the two lines with a suggestion, "Salz" is not among them.
    expect(find.byKey(CookFoundStep.acceptKey('line-0')), findsOneWidget);
    expect(find.byKey(CookFoundStep.acceptKey('line-1')), findsOneWidget);
    expect(find.byKey(CookFoundStep.acceptKey('line-2')), findsNothing);
    await tester.tap(find.byKey(CookFoundStep.acceptKey('line-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookFoundStep.acceptKey('line-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookStepFrame.buttonKey));
    await tester.pumpAndSettle();

    // Open step: leave "Salz" out; the recipe already leaves "Pfeffer" out.
    expect(find.byKey(CookOpenStep.omitKey('line-2')), findsOneWidget);
    expect(find.byKey(CookOpenStep.omitKey('line-3')), findsNothing);
    await tester.tap(find.byKey(CookOpenStep.omitKey('line-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookStepFrame.buttonKey));
    await tester.pumpAndSettle();

    // Pot step: no pot, the meal is counted.
    await tester.tap(find.byKey(CookPotStep.noPotKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookStepFrame.buttonKey));
    await tester.pumpAndSettle();

    // Portion step: the name starts as the recipe's.
    expect(find.byKey(CookPortionStep.nameKey), findsOneWidget);
    expect(find.byKey(CookPortionStep.weightKey), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(CookPortionStep.nameKey))
          .controller!
          .text,
      'Bauerntopf',
    );

    // Back goes through the steps instead of leaving the page.
    await tester.tap(find.byKey(CookTopBar.backKey));
    await tester.pumpAndSettle();
    expect(find.byKey(CookPotStep.noPotKey), findsOneWidget);
    expect(find.byType(CookPage), findsOneWidget);
    expect(cooked.written, isEmpty);
  });

  testWidgets('puts the cooked meal into the Vorrat and leaves the page', (
    tester,
  ) async {
    final cooked = _RecordingCookedMeals();
    await tester.pumpWidget(_app(cooked: cooked));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_startKey));
    await tester.pumpAndSettle();
    await _openCooking(tester);

    await tester.tap(find.byKey(CookStepFrame.buttonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookFoundStep.acceptKey('line-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookFoundStep.acceptKey('line-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookStepFrame.buttonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookOpenStep.omitKey('line-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookStepFrame.buttonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookPotStep.noPotKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookStepFrame.buttonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookStepFrame.buttonKey));
    await tester.pumpAndSettle();

    final meal = cooked.written.single;
    expect(meal.name, 'Bauerntopf');
    expect(meal.totalPortions, 2);
    expect(meal.components.map((c) => c.inventoryItemId), ['mince', 'carrots']);
    expect(find.byType(CookPage), findsNothing);
    expect(find.byType(RecipePage), findsOneWidget);
  });
}

// The hidden entry on the ingredients title opens the new flow.
Future<void> _openCooking(WidgetTester tester) async {
  final title = find.byKey(RecipePage.newCookingKey);
  await tester.scrollUntilVisible(title, 100);
  await tester.ensureVisible(title);
  await tester.pumpAndSettle();
  await tester.longPress(title);
  await tester.pumpAndSettle();
}

const _nutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 100,
  per100Protein: 10,
  per100Carbs: 20,
  per100Fat: 5,
);

InventoryItem _item(String id, String name) => InventoryItem.create(
  id: id,
  name: name,
  entryDate: DateTime.utc(2026, 10, 9),
  storeName: 'Store',
  quantity: 1,
  initialAmount: 2000,
  currentAmount: 2000,
  amountUnit: InventoryAmountUnit.gram,
  nutrition: _nutrition,
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
  components: const [],
  recipeIngredients: const [
    '500 g Hackfleisch',
    '200 g Karotten',
    'Salz',
    'Pfeffer',
  ],
  ignoredRecipeIngredients: const ['Pfeffer'],
  recipeInstructions: const ['Anbraten.', 'Köcheln lassen.'],
);

Widget _app({required _RecordingCookedMeals cooked}) {
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
        path: AppRoutes.homeCook,
        builder: (context, state) =>
            CookPage(recipeId: state.pathParameters['recipeId']!),
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      preparedMealRepositoryProvider.overrideWithValue(
        FakePreparedMealRepository(),
      ),
      preparedMealTemplateRepositoryProvider.overrideWithValue(
        FakePreparedMealTemplateRepository(templates: [_recipe]),
      ),
      inventoryItemRepositoryProvider.overrideWithValue(
        FakeInventoryItemRepository([
          _item('mince', 'Hackfleisch'),
          _item('carrots', 'Karotten'),
        ]),
      ),
      inventoryActivityActorProvider.overrideWithValue(null),
      inventoryActivityEventRepositoryProvider.overrideWithValue(
        _FakeActivityRepository(),
      ),
      shoppingListRepositoryProvider.overrideWithValue(
        FakeShoppingListRepository(),
      ),
      plannedEntryRepositoryProvider.overrideWithValue(
        FakePlannedEntryRepository(),
      ),
      closedDayRepositoryProvider.overrideWithValue(
        ClosedDayRepository(MemoryAppPreferences(), 'user-1'),
      ),
      cookedMealRepositoryProvider.overrideWithValue(cooked),
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

class _RecordingCookedMeals implements CookedMealRepository {
  final written = <PreparedMeal>[];

  @override
  Future<void> addCookedMeal({
    required PreparedMeal meal,
    required List<CookedStockChange> changes,
    required DateTime happenedAt,
  }) async {
    await Future<void>.delayed(Duration.zero);
    written.add(meal);
  }
}

class _FakeUtensilRepository implements KitchenUtensilRepository {
  @override
  Stream<List<KitchenUtensil>> watchAll() async* {
    yield const <KitchenUtensil>[];
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeActivityRepository implements InventoryActivityEventRepository {
  @override
  Stream<List<InventoryActivityEvent>> watchRecent({int limit = 100}) {
    return const Stream.empty();
  }

  @override
  Future<bool> appendAll(List<InventoryActivityEvent> events) async => true;
}
