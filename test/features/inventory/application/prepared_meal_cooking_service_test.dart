import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_cooking_service.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

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

    await service.finishCooking(
      mealId: mealId,
      totalPortions: 4,
      potTareWeight: 1240,
      finalNetWeight: 1180,
    );

    final meal = meals.saved.single;
    expect(meal.isInPot, isFalse);
    expect(meal.inPot, isNull);
    expect(meal.totalPortions, 4);
    expect(meal.remainingPortions, 4);
    expect(meal.potTareWeight, 1240);
    expect(meal.finalNetWeight, 1180);
    expect(PreparedMeal.fromJson(meal.toJson()), meal);
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
      potTareWeight: 1240,
      finalNetWeight: 1180,
    );

    await expectLater(
      service.finishCooking(
        mealId: mealId,
        totalPortions: 2,
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
  new({this.saves = true, this.throwsOnSave = false});

  final bool saves;
  final bool throwsOnSave;
  List<PreparedMeal> saved = const [];

  @override
  Stream<List<PreparedMeal>> watchAll() => Stream.value(saved);

  @override
  Future<List<PreparedMeal>> readAll() async => saved;

  @override
  Future<bool> saveAll(List<PreparedMeal> meals) async {
    if (throwsOnSave) {
      throw StateError('offline');
    }
    if (saves) {
      saved = meals;
    }
    return saves;
  }
}

class _FakeInventoryRepository implements InventoryItemRepository {
  new(this.items);

  List<InventoryItem> items;

  @override
  Stream<List<InventoryItem>> watchAll() => Stream.value(items);

  @override
  Future<List<InventoryItem>> readAll() async => items;

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
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
