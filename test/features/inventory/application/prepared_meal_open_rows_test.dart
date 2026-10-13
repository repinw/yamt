import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_service.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

import '../../../helpers/fake_prepared_meal_repository.dart';
import '../../../helpers/inventory_item_whole_list_writes.dart';

final _cookedAt = DateTime.utc(2026, 10, 10, 18);
final _now = DateTime.utc(2026, 10, 10, 19);

void main() {
  group('taking a food out of a meal', () {
    test('assigning a row and taking the food out again gives back the '
        'meal, its totals and the stock exactly as they were', () async {
      final world = _World(meal: _cookedMeal(open: const ['200 g Hähnchen']));
      final before = world.meal;

      expect(await world.service.fill('200 g Hähnchen', 'chicken'), isTrue);
      final filled = world.meal;
      expect(filled.pendingRecipeIngredients, isEmpty);
      expect(filled.components, hasLength(2));
      expect(filled.totalKcal, isNot(before.totalKcal));
      expect(world.stock('chicken'), 300);

      expect(
        await world.service.unassignPreparedMealComponent(
          mealId: 'pan',
          component: filled.components.last,
        ),
        isTrue,
      );

      // The totals are summed from the foods again, so they match the
      // stored ones bit for bit; subtracting would leave rounding errors.
      expect(world.meal, before.copyWith(updatedAt: _now));
      expect(world.stock('chicken'), 500);
    });

    test('a food that covered part of a row opens only its share', () async {
      final world = _World(
        meal: _cookedMeal(open: const ['500 g Hähnchen']),
        chickenGrams: 300,
      );

      await world.service.fill('500 g Hähnchen', 'chicken');
      expect(world.meal.pendingRecipeIngredients, ['200 g Hähnchen']);

      await world.service.unassignPreparedMealComponent(
        mealId: 'pan',
        component: world.meal.components.last,
      );

      expect(world.meal.pendingRecipeIngredients, [
        '200 g Hähnchen',
        '300 g Hähnchen',
      ]);
      expect(world.stock('chicken'), 300);
    });

    test('a food that fills no row opens its own amount and name', () async {
      final world = _World(meal: _cookedMeal());

      await world.service.unassignPreparedMealComponent(
        mealId: 'pan',
        component: world.meal.components.single,
      );

      expect(world.meal.components, isEmpty);
      expect(world.meal.pendingRecipeIngredients, ['150 g Reis']);
      expect(world.meal.totalKcal, 0);
      expect(world.stock('rice'), 1000);
    });

    test('once a portion is gone, the foods stay', () async {
      final world = _World(
        meal: _cookedMeal().copyWith(totalPortions: 2, remainingPortions: 1),
      );
      final before = world.meal;

      expect(
        await world.service.unassignPreparedMealComponent(
          mealId: 'pan',
          component: before.components.single,
        ),
        isFalse,
      );
      expect(world.meal, before);
      expect(world.stock('rice'), 850);
    });

    test('the stock goes back when the meal cannot be saved', () async {
      final world = _World(meal: _cookedMeal(), mealWrites: const [false]);

      expect(
        await world.service.unassignPreparedMealComponent(
          mealId: 'pan',
          component: world.meal.components.single,
        ),
        isFalse,
      );
      expect(world.stock('rice'), 850);
    });
  });

  group('ignored rows', () {
    test('an ignored row stays and opens again', () async {
      final world = _World(meal: _cookedMeal(open: const ['Salz']));
      final before = world.meal;
      expect(before.allows(PreparedMealAction.eat), isFalse);

      expect(
        await world.service.ignorePreparedMealPendingIngredient(
          mealId: 'pan',
          ingredient: 'Salz',
        ),
        isTrue,
      );
      expect(world.meal.ignoredPendingRecipeIngredients, ['Salz']);
      expect(world.meal.allows(PreparedMealAction.eat), isTrue);

      expect(
        await world.service.unignorePreparedMealPendingIngredient(
          mealId: 'pan',
          ingredient: 'Salz',
        ),
        isTrue,
      );
      expect(world.meal, before.copyWith(updatedAt: _now));
    });

    test('an ignored row can still be filled', () async {
      final world = _World(meal: _cookedMeal(open: const ['200 g Hähnchen']));
      await world.service.ignorePreparedMealPendingIngredient(
        mealId: 'pan',
        ingredient: '200 g Hähnchen',
      );

      expect(await world.service.fill('200 g Hähnchen', 'chicken'), isTrue);

      expect(world.meal.ignoredPendingRecipeIngredients, isEmpty);
      expect(
        world.meal.components.last.pendingRecipeIngredient,
        '200 g Hähnchen',
      );
      expect(world.stock('chicken'), 300);
    });
  });

  group('editing the foods', () {
    test('a food removed in the editor comes back as an open row, and the '
        'undo puts the meal back as it was', () async {
      final world = _World(meal: _cookedMeal(open: const ['Salz']));
      final before = world.meal;

      expect(
        await world.service.updatePreparedMealDetails(
          mealId: 'pan',
          name: before.name,
          totalPortions: before.totalPortions,
          items: const [],
        ),
        isTrue,
      );
      expect(world.meal.components, isEmpty);
      expect(world.meal.pendingRecipeIngredients, ['Salz', '150 g Reis']);
      expect(world.stock('rice'), 1000);

      expect(await world.service.restorePreparedMeal(before), isTrue);
      expect(world.meal, before.copyWith(updatedAt: _now));
      expect(world.stock('rice'), 850);
    });

    test('rows deleted in the editor leave the meal', () async {
      final world = _World(
        meal: _cookedMeal(open: const ['Salz'])
            .copyWith(ignoredPendingRecipeIngredients: const ['Pfeffer']),
      );
      final before = world.meal;

      await world.service.updatePreparedMealDetails(
        mealId: 'pan',
        name: before.name,
        totalPortions: before.totalPortions,
        items: [_input(before.components.single)],
        deletedRows: const ['Salz', 'Pfeffer'],
      );

      expect(world.meal.pendingRecipeIngredients, isEmpty);
      expect(world.meal.ignoredPendingRecipeIngredients, isEmpty);
      expect(world.meal.components, before.components);
      expect(world.stock('rice'), 850);
    });

    test('a food the editor adds for an open row opens that row again when '
        'it is taken out', () async {
      final world = _World(
        meal: _cookedMeal(open: const ['200 g Hähnchen']),
        chickenName: 'Hähnchen Brustfilet',
      );
      final before = world.meal;

      await world.service.updatePreparedMealDetails(
        mealId: 'pan',
        name: before.name,
        totalPortions: before.totalPortions,
        items: [
          _input(before.components.single),
          const PreparedMealItemInput(itemId: 'chicken', usedAmount: 200),
        ],
      );
      expect(world.meal.pendingRecipeIngredients, isEmpty);

      await world.service.unassignPreparedMealComponent(
        mealId: 'pan',
        component: world.meal.components.last,
      );
      expect(world.meal.pendingRecipeIngredients, ['200 g Hähnchen']);
    });

    test('the undo keeps the foods once a portion is gone, and leaves the '
        'pot as it is now', () async {
      final world = _World(
        meal: _cookedMeal().copyWith(totalPortions: 2, remainingPortions: 2),
      );
      final before = world.meal;
      await world.service.updatePreparedMealDetails(
        mealId: 'pan',
        name: before.name,
        totalPortions: 2,
        items: const [],
      );

      world.meal = world.meal.copyWith(remainingPortions: 1);
      expect(await world.service.restorePreparedMeal(before), isFalse);

      world.meal = world.meal.copyWith(
        remainingPortions: 2,
        inPot: true,
        potTareWeight: 800,
      );
      expect(await world.service.restorePreparedMeal(before), isTrue);
      expect(world.meal.components, before.components);
      expect(world.meal.inPot, isTrue);
      expect(world.meal.potTareWeight, 800);
    });
  });
}

PreparedMealItemInput _input(PreparedMealComponent component) =>
    PreparedMealItemInput(
      itemId: component.inventoryItemId,
      usedAmount: component.usedAmount,
    );

/// A cooked meal of 150 g rice that the cook assigned while cooking, with
/// the open rows [open].
PreparedMeal _cookedMeal({List<String> open = const []}) {
  final rice = _item('rice', 'Reis', grams: 1000, kcal: 130.3);
  final component = PreparedMealComponent(
    inventoryItemId: rice.id,
    name: rice.name,
    brand: null,
    imageUrl: null,
    usedAmount: 150,
    usedUnit: InventoryAmountUnit.gram,
    totalKcal: 130.3 * 1.5,
    totalProtein: 2.7 * 1.5,
    totalCarbs: 28.1 * 1.5,
    totalFat: 0.3 * 1.5,
    sourceItemSnapshot: rice,
  );
  final totals = [component].nutritionTotals;
  return PreparedMeal(
    id: 'pan',
    name: 'Reispfanne',
    totalPortions: 1,
    remainingPortions: 1,
    totalKcal: totals.totalKcal,
    totalProtein: totals.totalProtein,
    totalCarbs: totals.totalCarbs,
    totalFat: totals.totalFat,
    createdAt: _cookedAt,
    updatedAt: _cookedAt,
    components: [component],
    pendingRecipeIngredients: open,
  );
}

InventoryItem _item(
  String id,
  String name, {
  required int grams,
  required double kcal,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: _cookedAt,
    storeName: 'Store',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: grams,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: kcal,
      per100Protein: 2.7,
      per100Carbs: 28.1,
      per100Fat: 0.3,
    ),
  );
}

/// One meal and a Vorrat with rice and chicken, changed through the meal
/// service.
class _World {
  new({
    required PreparedMeal meal,
    int chickenGrams = 500,
    String chickenName = 'Hähnchen',
    List<bool> mealWrites = const [true],
  }) : _meals = FakePreparedMealRepository(
         meals: [meal],
         writeResults: mealWrites,
       ),
       _items = _Items([
         // The rice of the meal is already taken from the Vorrat.
         _item('rice', 'Reis', grams: 850, kcal: 130.3),
         _item('chicken', chickenName, grams: chickenGrams, kcal: 165.7),
       ]);

  final FakePreparedMealRepository _meals;
  final _Items _items;

  PreparedMeal get meal => _meals.meals.single;

  set meal(PreparedMeal meal) => _meals.meals = [meal];

  int stock(String itemId) =>
      _items.items.firstWhere((item) => item.id == itemId).currentAmount;

  late final service = PreparedMealMutationService(
    queue: SerializedMutationQueue(),
    meals: _meals,
    inventory: _items,
    discardEvents: _NoDiscardEvents(),
    activity: _NoActivity(),
    actor: null,
    ingredientParser: const TemplateIngredientParser(),
    clock: () => _now,
  );
}

extension on PreparedMealMutationService {
  Future<bool> fill(String row, String itemId) =>
      fillPreparedMealPendingIngredient(
        mealId: 'pan',
        ingredient: row,
        inventoryItemIds: [itemId],
      );
}

class _Items with InventoryItemWholeListWrites {
  new(this.items);

  List<InventoryItem> items;

  @override
  Stream<List<InventoryItem>> watchAll() => Stream.value(items);

  @override
  Future<List<InventoryItem>> readAll() async => List.of(items);

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async {
    this.items = List.of(items);
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    this.items = [...this.items, ...items];
    return true;
  }
}

class _NoActivity implements InventoryActivityEventRepository {
  @override
  Stream<List<InventoryActivityEvent>> watchRecent({int limit = 0}) =>
      const Stream.empty();

  @override
  Future<bool> appendAll(List<InventoryActivityEvent> events) async => true;
}

class _NoDiscardEvents implements InventoryDiscardEventRepository {
  @override
  Future<List<InventoryDiscardEvent>> readAll() async => const [];

  @override
  Future<bool> saveEvent(InventoryDiscardEvent event) async => true;

  @override
  Future<bool> deleteEvent(String eventId) async => true;
}
