import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
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

import '../../../../helpers/fake_prepared_meal_repository.dart';
import '../../../../helpers/fake_prepared_meal_template_repository.dart';
import '../../../../support/prepared_meal_test_data.dart';

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
}) {
  final container = ProviderContainer(
    overrides: [
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
  test('marks recipe ingredients that the Vorrat holds', () async {
    final recipe = preparedMealTestData(
      id: 'pasta',
    ).copyWith(recipeIngredients: const ['200 g Pasta', '150 g Tomato sauce']);
    final container = _container(
      templates: [recipe],
      meals: const [],
      items: [_item('Pasta')],
    );

    final overview = await _overview(container);

    expect(overview.recipes.single.inStock, [true, false]);
  });

  test('a food kept in another unit does not count as in stock', () async {
    final recipe = preparedMealTestData(id: 'pancakes')
        .copyWith(recipeIngredients: const ['300 ml Milk', '200 g Flour']);
    final container = _container(
      templates: [recipe],
      meals: const [],
      // The milk is kept in grams, so it cannot give 300 ml.
      items: [_item('Milk'), _item('Flour')],
    );

    final overview = await _overview(container);

    expect(overview.recipes.single.inStock, [false, true]);
  });

  test('a saved item counts as in stock without a name match', () async {
    final recipe = preparedMealTestData(id: 'chili').copyWith(
      recipeIngredients: const ['500 g Minced beef'],
      recipeIngredientAssignments: const {
        '500 g Minced beef': ['Organic chuck'],
      },
    );
    final container = _container(
      templates: [recipe],
      meals: const [],
      items: [_item('Organic chuck')],
    );

    final overview = await _overview(container);

    expect(overview.recipes.single.inStock, [true]);
  });

  test('a saved unit conversion counts only for its own recipe', () async {
    final converted = preparedMealTestData(id: 'soup').copyWith(
      name: 'Soup',
      recipeIngredients: const ['2 Onions'],
      recipeIngredientAmountConversions: const {
        '2 Onions': RecipeIngredientAmountConversion(
          amountPerPiece: 80,
          unit: InventoryAmountUnit.gram,
        ),
      },
    );
    final plain = preparedMealTestData(id: 'stew')
        .copyWith(name: 'Stew', recipeIngredients: const ['2 Onions']);
    final container = _container(
      templates: [converted, plain],
      meals: const [],
      // The onions are kept in grams.
      items: [_item('Onions')],
    );

    final overview = await _overview(container);

    expect(
      {for (final recipe in overview.recipes) recipe.meal.name: recipe.inStock},
      {
        'Soup': [true],
        'Stew': [false],
      },
    );
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
