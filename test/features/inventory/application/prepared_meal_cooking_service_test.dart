import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_cooking_service.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

import '../../../helpers/inventory_item_whole_list_writes.dart';

final _now = DateTime.utc(2026, 10, 1, 18);

void main() {
  test('takes stock rows from the Vorrat and leaves the others open', () async {
    final meals = _FakeMealRepository();
    final items = _FakeInventoryRepository([_rice()]);
    final activity = _FakeActivityRepository();
    final service = _service(meals, items, activity);

    final result = await service.cook(
      name: 'Reispfanne',
      ingredients: const ['200 g Reis', '500 g Hähnchen'],
      assignments: const {
        '200 g Reis': ['rice'],
      },
    );

    expect(result.isSuccess, isTrue);
    final meal = meals.saved.single;
    expect(meal.name, 'Reispfanne');
    expect(meal.totalPortions, 1);
    expect(meal.createdAt, _now);
    expect(meal.components.single.usedAmount, 200);
    expect(meal.pendingRecipeIngredients.single, contains('Hähnchen'));
    expect(meal.totalKcal, 260);
    expect(meal.isInPot, isTrue);
    expect(items.items.single.currentAmount, 800);
    expect(
      activity.events.single.type,
      InventoryActivityEventType.itemUsedInPreparedMeal,
    );
  });

  test(
    'cookRecipe sizes the recipe for the portions and fills the pot',
    () async {
      final meals = _FakeMealRepository();
      final items = _FakeInventoryRepository([_rice()]);
      final service = _service(meals, items, _FakeActivityRepository());
      final recipe = PreparedMeal(
        id: 'recipe-1',
        name: 'Reistopf',
        totalPortions: 2,
        remainingPortions: 2,
        totalKcal: 0,
        totalProtein: 0,
        totalCarbs: 0,
        totalFat: 0,
        createdAt: _now,
        updatedAt: _now,
        components: const [],
        recipeIngredients: const ['100 g Reis', '1 Zwiebel', 'Salz'],
        ignoredRecipeIngredients: const ['Salz'],
        recipeInstructions: const ['Kochen.'],
      );

      final result = await service.cookRecipe(
        recipe: recipe,
        portions: 4,
        assignments: const {
          '100 g Reis': ['rice'],
        },
      );

      expect(result.isSuccess, isTrue);
      final meal = meals.saved.single;
      expect(meal.id, isNot('recipe-1'));
      expect(meal.name, 'Reistopf');
      expect(meal.isInPot, isTrue);
      expect(meal.totalPortions, 4);
      expect(meal.components.single.usedAmount, 200);
      expect(meal.pendingRecipeIngredients.single, contains('Zwiebel'));
      expect(meal.recipeInstructions, ['Kochen.']);
      expect(items.items.single.currentAmount, 800);
    },
  );

  test('cookRecipe takes pieces by the saved amount conversion', () async {
    final meals = _FakeMealRepository();
    final items = _FakeInventoryRepository([
      InventoryItem.create(
        id: 'eggs',
        name: 'Eier',
        entryDate: DateTime.utc(2026, 9),
        storeName: 'Store',
        quantity: 1,
        initialAmount: 600,
        currentAmount: 600,
        amountUnit: InventoryAmountUnit.gram,
      ),
    ]);
    final service = _service(meals, items, _FakeActivityRepository());
    final recipe = PreparedMeal(
      id: 'recipe-1',
      name: 'Rührei',
      totalPortions: 1,
      remainingPortions: 1,
      totalKcal: 0,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
      createdAt: _now,
      updatedAt: _now,
      components: const [],
      recipeIngredients: const ['2 Eier'],
      recipeIngredientAmountConversions: const {
        '2 Eier': RecipeIngredientAmountConversion(
          amountPerPiece: 60,
          unit: InventoryAmountUnit.gram,
        ),
      },
    );

    final result = await service.cookRecipe(
      recipe: recipe,
      portions: 1,
      assignments: const {
        '2 Eier': ['eggs'],
      },
    );

    expect(result.isSuccess, isTrue);
    final meal = meals.saved.single;
    expect(meal.components.single.usedAmount, 120);
    expect(meal.pendingRecipeIngredients, isEmpty);
    expect(items.items.single.currentAmount, 480);
  });

  test('finishCooking sets portions and weights and leaves the pot', () async {
    final meals = _FakeMealRepository();
    final service = _service(
      meals,
      _FakeInventoryRepository([_rice()]),
      _FakeActivityRepository(),
    );
    await service.cook(
      name: 'Reis',
      ingredients: const ['200 g Reis'],
      assignments: const {
        '200 g Reis': ['rice'],
      },
    );
    final mealId = meals.saved.single.id;

    final returned = await service.finishCooking(
      mealId: mealId,
      totalPortions: 4,
      servedInPieces: false,
      potTareWeight: 1240,
      finalNetWeight: 1180,
    );

    final meal = meals.saved.single;
    expect(returned, meal);
    expect(meal.isInPot, isFalse);
    expect(meal.inPot, isNull);
    expect(meal.totalPortions, 4);
    expect(meal.remainingPortions, 4);
    expect(meal.potTareWeight, 1240);
    expect(meal.finalNetWeight, 1180);
    expect(meal.isServedInPieces, isFalse);
    expect(meal.toJson().containsKey('served_in_pieces'), isFalse);
    expect(PreparedMeal.fromJson(meal.toJson()), meal);
  });

  test('finishCooking counts a meal in pieces without weights', () async {
    final meals = _FakeMealRepository();
    final service = _service(
      meals,
      _FakeInventoryRepository([_rice()]),
      _FakeActivityRepository(),
    );
    await service.cook(
      name: 'Wraps',
      ingredients: const ['200 g Reis'],
      assignments: const {
        '200 g Reis': ['rice'],
      },
    );

    await service.finishCooking(
      mealId: meals.saved.single.id,
      totalPortions: 6,
      servedInPieces: true,
      potTareWeight: null,
      finalNetWeight: null,
    );

    final meal = meals.saved.single;
    expect(meal.totalPortions, 6);
    expect(meal.isServedInPieces, isTrue);
    expect(meal.finalNetWeight, isNull);
    expect(meal.toJson()['served_in_pieces'], isTrue);
    expect(PreparedMeal.fromJson(meal.toJson()), meal);
  });

  test('discard gives the foods back and deletes the open meal', () async {
    final meals = _FakeMealRepository();
    final items = _FakeInventoryRepository([_rice()]);
    final service = _service(meals, items, _FakeActivityRepository());
    await service.cook(
      name: 'Reis',
      ingredients: const ['200 g Reis'],
      assignments: const {
        '200 g Reis': ['rice'],
      },
    );
    expect(items.items.single.currentAmount, 800);

    await service.discard(meals.saved.single.id);

    expect(meals.saved, isEmpty);
    expect(items.items.single.currentAmount, 1000);
  });

  test('discard deletes the foods added only for the meal', () async {
    final found = _rice().copyWith(id: 'found', name: 'Hafer');
    final meals = _FakeMealRepository();
    final items = _FakeInventoryRepository([_rice(), found]);
    final service = _service(meals, items, _FakeActivityRepository());
    await service.cook(
      name: 'Reis',
      ingredients: const ['200 g Reis'],
      assignments: const {
        '200 g Reis': ['rice'],
      },
    );
    final meal = meals.saved.single;
    meals.saved = [
      meal.copyWith(
        components: [
          ...meal.components,
          meal.components.single.copyWith(
            inventoryItemId: 'found',
            sourceItemSnapshot: found,
            addedForMeal: true,
          ),
        ],
      ),
    ];

    await service.discard(meal.id);

    expect(meals.saved, isEmpty);
    expect(items.items.map((item) => item.id), ['rice']);
    expect(items.items.single.currentAmount, 1000);
  });

  test('discard refuses a meal that is already cooked', () async {
    final meals = _FakeMealRepository();
    final service = _service(
      meals,
      _FakeInventoryRepository([_rice()]),
      _FakeActivityRepository(),
    );
    await service.cook(
      name: 'Reis',
      ingredients: const ['200 g Reis'],
      assignments: const {
        '200 g Reis': ['rice'],
      },
    );
    final mealId = meals.saved.single.id;
    await service.finishCooking(
      mealId: mealId,
      totalPortions: 2,
      servedInPieces: false,
      potTareWeight: null,
      finalNetWeight: null,
    );

    await expectLater(service.discard(mealId), throwsStateError);
    expect(meals.saved, hasLength(1));
  });

  test('finishCooking refuses a meal that is already cooked', () async {
    final meals = _FakeMealRepository();
    final service = _service(
      meals,
      _FakeInventoryRepository([_rice()]),
      _FakeActivityRepository(),
    );
    await service.cook(
      name: 'Reis',
      ingredients: const ['200 g Reis'],
      assignments: const {
        '200 g Reis': ['rice'],
      },
    );
    final mealId = meals.saved.single.id;
    await service.finishCooking(
      mealId: mealId,
      totalPortions: 4,
      servedInPieces: false,
      potTareWeight: 1240,
      finalNetWeight: 1180,
    );

    await expectLater(
      service.finishCooking(
        mealId: mealId,
        totalPortions: 2,
        servedInPieces: false,
        potTareWeight: null,
        finalNetWeight: null,
      ),
      throwsStateError,
    );
    expect(meals.saved.single.finalNetWeight, 1180);
  });

  test(
    'restores the Vorrat and rethrows when saving the meal throws',
    () async {
      final meals = _FakeMealRepository(throwsOnSave: true);
      final items = _FakeInventoryRepository([_rice()]);
      final service = _service(meals, items, _FakeActivityRepository());

      await expectLater(
        service.cook(
          name: 'Reis',
          ingredients: const ['200 g Reis'],
          assignments: const {
            '200 g Reis': ['rice'],
          },
        ),
        throwsStateError,
      );

      expect(items.items.single.currentAmount, 1000);
    },
  );

  test('restores the Vorrat when the meal cannot be saved', () async {
    final meals = _FakeMealRepository(saves: false);
    final items = _FakeInventoryRepository([_rice()]);
    final activity = _FakeActivityRepository();
    final service = _service(meals, items, activity);

    final result = await service.cook(
      name: 'Reis',
      ingredients: const ['200 g Reis'],
      assignments: const {
        '200 g Reis': ['rice'],
      },
    );

    expect(result.isSuccess, isFalse);
    expect(items.items.single.currentAmount, 1000);
    expect(activity.events, isEmpty);
  });

  test('saves nothing when the meals cannot be read', () async {
    final meals = _FakeMealRepository(throwsOnRead: true);
    final items = _FakeInventoryRepository([_rice()]);
    final service = _service(meals, items, _FakeActivityRepository());

    await expectLater(
      service.cook(
        name: 'Reis',
        ingredients: const ['200 g Reis'],
        assignments: const {
          '200 g Reis': ['rice'],
        },
      ),
      throwsStateError,
    );

    // Saving only the new meal would delete every other meal.
    expect(meals.saveCount, 0);
    expect(items.items.single.currentAmount, 1000);
  });
}

PreparedMealCookingService _service(
  _FakeMealRepository meals,
  _FakeInventoryRepository items,
  _FakeActivityRepository activity,
) {
  return PreparedMealCookingService(
    mealRepository: meals,
    inventoryRepository: items,
    activityRepository: activity,
    actor: const InventoryActivityActor(userId: 'cook', displayName: 'Cook'),
    ingredientParser: const TemplateIngredientParser(),
    clock: () => _now,
  );
}

InventoryItem _rice() {
  return InventoryItem.create(
    id: 'rice',
    name: 'Reis',
    entryDate: DateTime.utc(2026, 9),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: 1000,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 130,
      per100Protein: 3,
      per100Carbs: 28,
      per100Fat: 0.3,
    ),
  );
}

class _FakeMealRepository implements PreparedMealRepository {
  new({
    this.saves = true,
    this.throwsOnSave = false,
    this.throwsOnRead = false,
  });

  final bool saves;
  final bool throwsOnSave;
  final bool throwsOnRead;
  List<PreparedMeal> saved = const [];
  int saveCount = 0;

  @override
  Stream<List<PreparedMeal>> watchAll() => Stream.value(saved);

  @override
  Future<List<PreparedMeal>> readAll() async {
    if (throwsOnRead) {
      throw StateError('unreadable meal');
    }
    return saved;
  }

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
    saveCount += 1;
    if (throwsOnSave) {
      throw StateError('offline');
    }
    if (saves) {
      saved = meals;
    }
    return saves;
  }

  @override
  Future<List<PreparedMeal>> readAllForChange() => readAll();
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
  final events = <InventoryActivityEvent>[];

  @override
  Stream<List<InventoryActivityEvent>> watchRecent({int limit = 100}) {
    return Stream.value(events);
  }

  @override
  Future<bool> appendAll(List<InventoryActivityEvent> events) async {
    this.events.addAll(events);
    return true;
  }
}
