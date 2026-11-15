import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/cookbook_new/domain/cookbook_overview.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cookbook_controller.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';

import '../../../../helpers/fake_cook_run_repository.dart';
import '../../../../helpers/fake_prepared_meal_repository.dart';
import '../../../../helpers/fake_prepared_meal_template_repository.dart';
import '../../../../helpers/fake_signed_in_user.dart';
import '../../../../support/prepared_meal_test_data.dart';
import '../../../recipes/cook_run_fixtures.dart';

InventoryItem _item(String name) {
  return InventoryItem.create(
    id: name,
    name: name,
    entryDate: DateTime.utc(2026, 9, 29),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 500,
    currentAmount: 500,
    amountUnit: InventoryAmountUnit.gram,
  );
}

ProviderContainer _container({
  required List<PreparedMeal> templates,
  required List<PreparedMeal> meals,
  required List<InventoryItem> items,
  List<CookRun> runs = const [],
}) {
  final container = ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWith(
        (ref) => Stream.value(FakeSignedInUser('uid-1')),
      ),
      cookRunRepositoryProvider.overrideWithValue(
        FakeCookRunRepository(runs: runs),
      ),
      cookbookTemplatesProvider.overrideWith((ref) => Stream.value(templates)),
      inventoryQuickEatMealsProvider.overrideWith((ref) => Stream.value(meals)),
      inventoryQuickEatItemsProvider.overrideWith((ref) => Stream.value(items)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// A container whose Kochbuch reads [templates] and the Vorrat meals in
/// [meals] through their repositories.
ProviderContainer _repositoryContainer({
  required PreparedMealTemplateRepository templates,
  required FakePreparedMealRepository meals,
}) {
  final container = ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWith(
        (ref) => Stream.value(FakeSignedInUser('uid-1')),
      ),
      cookRunRepositoryProvider.overrideWithValue(FakeCookRunRepository()),
      preparedMealTemplateRepositoryProvider.overrideWithValue(templates),
      preparedMealRepositoryProvider.overrideWithValue(meals),
      inventoryQuickEatItemsProvider.overrideWith(
        (ref) => Stream.value(const <InventoryItem>[]),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<CookbookOverview> _overview(
  ProviderContainer container, {
  bool Function(CookbookOverview overview)? until,
}) async {
  final provider = cookbookControllerProvider('en');
  final subscription = container.listen(provider, (_, _) {});
  addTearDown(subscription.close);
  bool settled() {
    final state = container.read(provider);
    if (state.hasError) {
      return true;
    }
    final overview = state.value;
    return overview != null && (until?.call(overview) ?? true);
  }

  while (!settled()) {
    await Future<void>.delayed(Duration.zero);
  }
  return container.read(provider).requireValue;
}

/// A recipe with everything a template can store.
PreparedMeal _fullRecipe() =>
    preparedMealTestData(id: 'pasta', imageAssetId: 'pasta-photo').copyWith(
      name: 'One-pan pasta',
      imageUrl: 'https://example.com/pasta.jpg',
      recipeUrl: 'https://example.com/pasta',
      recipeIngredients: const ['200 g Pasta', '150 g Tomato sauce', 'Salt'],
      recipeInstructions: const ['Boil.', 'Stir.'],
      ignoredRecipeIngredients: const ['Salt'],
      recipeIngredientAssignments: const {
        '200 g Pasta': ['pasta-item'],
      },
      recipeIngredientAmountConversions: const {
        '150 g Tomato sauce': RecipeIngredientAmountConversion(
          amountPerPiece: 400,
          unit: InventoryAmountUnit.gram,
        ),
      },
    );

void main() {
  test('never matches recipe ingredients against the Vorrat', () async {
    final recipe = preparedMealTestData(id: 'pasta').copyWith(
      recipeIngredients: const ['200 g Pasta', 'Salt'],
      recipeIngredientAssignments: const {
        '200 g Pasta': ['Pasta'],
      },
    );
    final container = _container(
      templates: [recipe],
      meals: const [],
      items: [_item('Pasta'), _item('Salt')],
    );

    final overview = await _overview(container);

    expect(overview.recipes.single.inStock, isEmpty);
  });

  test('shows the lines that the cook run of a recipe assigned', () async {
    final recipe = preparedMealTestData(id: 't1')
        .copyWith(recipeIngredients: const ['500 g Beans', '1 Onion']);
    final container = _container(
      templates: [recipe],
      meals: const [],
      items: [_item('Beans')],
      runs: [
        buildCookRun(
          lines: [
            cookLine(
              'line-0',
              settlement: LineAssigned(const [
                ItemTake(itemId: 'Beans', amount: 500),
              ]),
            ),
            cookLine('line-1'),
          ],
        ),
      ],
    );

    final overview = await _overview(container);

    expect(overview.recipes.single.inStock, [true, false]);
  });

  test('lists the household runs', () async {
    final container = _container(
      templates: const [],
      meals: const [],
      items: const [],
      runs: [buildCookRun()],
    );

    final overview = await _overview(container);

    expect(overview.runs.single.run.id, 'recipe-t1');
    // The signed-in member started the fixture's run.
    expect(overview.runs.single.startedByMe, isTrue);
  });

  test('shows meals with open rows in the pot', () async {
    final meal = preparedMealTestData(id: 'free')
        .copyWith(pendingRecipeIngredients: const ['500 g Chicken']);
    final container = _container(
      templates: const [],
      meals: [meal],
      items: const [],
    );

    final overview = await _overview(container);

    expect(overview.openMeals.single.id, 'free');
    expect(overview.recipes, isEmpty);
  });

  test('remove deletes the stored recipe and restore brings it back with '
      'the same id and content', () async {
    final templates = FirestorePreparedMealTemplateRepository(
      household: (
        householdId: 'household-1',
        store: FirestorePreparedMealTemplateStore(
          firestore: FakeFirebaseFirestore(),
          cipher: PayloadCipher(await PayloadCipher.newDataKey()),
        ),
      ),
      sessionShutdownSignal: SessionShutdownSignal(),
    );
    final recipe = _fullRecipe();
    expect(await templates.save(recipe), isTrue);
    // A meal cooked from the recipe shares its photo.
    final cooked = preparedMealTestData(
      id: 'cooked',
      name: 'One-pan pasta',
      imageAssetId: 'pasta-photo',
    ).copyWith(inPot: true);
    final meals = FakePreparedMealRepository(meals: [cooked]);
    final container = _repositoryContainer(templates: templates, meals: meals);
    expect((await _overview(container)).recipes.single.meal, recipe);
    final controller = container.read(
      cookbookControllerProvider('en').notifier,
    );

    expect(await controller.remove(recipe), isTrue);
    final removed = await _overview(
      container,
      until: (overview) => overview.recipes.isEmpty,
    );

    expect(await templates.readAll(), isEmpty);
    // The Vorrat meal cooked from the recipe stays as it was.
    expect(removed.openMeals, [cooked]);
    expect(meals.meals, [cooked]);
    expect(meals.writeCount, 0);

    expect(await controller.restore(recipe), isTrue);
    final restored = await _overview(
      container,
      until: (overview) => overview.recipes.isNotEmpty,
    );

    expect(await templates.readAll(), [recipe]);
    expect(restored.recipes.single.meal, recipe);
  });

  test('a failed remove or restore returns false', () async {
    final templates = FakePreparedMealTemplateRepository(
      templates: [_fullRecipe()],
    )..failWrites = true;
    final container = _repositoryContainer(
      templates: templates,
      meals: FakePreparedMealRepository(),
    );
    await _overview(container);
    final controller = container.read(
      cookbookControllerProvider('en').notifier,
    );

    expect(await controller.remove(_fullRecipe()), isFalse);
    expect(await controller.restore(_fullRecipe()), isFalse);
    expect(templates.templates, [_fullRecipe()]);
  });
}
