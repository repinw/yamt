import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/calorie_entry_saver.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';
import 'package:yamt/features/inventory/application/inventory_eat_service.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_entry_delete_service.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_plan_accept_service.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_application.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_eat_outcome.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

import '../../calories/support/fake_planned_entry_repository.dart';

class _MockEatService extends Mock implements InventoryEatService;

class _MockPendings extends Mock implements InventoryPendingConsumptionStore;

class _MockQuickEat extends Mock implements InventoryQuickEatActions;

class _MockDeleteService extends Mock implements InventoryEntryDeleteService;

final _planDay = DateTime(2026, 10, 6, 8);

const _nutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 400,
  per100Protein: 10,
  per100Carbs: 60,
  per100Fat: 12,
);

InventoryItem _oats({
  required String id,
  int currentAmount = 500,
  DateTime? entryDate,
}) => InventoryItem.create(
  id: id,
  name: 'Oats',
  brand: 'Kölln',
  nutrition: _nutrition,
  entryDate: entryDate ?? DateTime(2026, 9),
  storeName: 'Rewe',
  quantity: 1,
  initialAmount: 500,
  currentAmount: currentAmount,
  amountUnit: InventoryAmountUnit.gram,
);

CalorieEntry _itemPlan({String itemId = 'oats-1', int? amount = 60}) =>
    CalorieEntry.create(
      id: 'plan-1',
      userId: 'user-1',
      name: 'Oats',
      brand: 'Kölln',
      mealType: MealType.breakfast,
      consumedAmount: 60,
      consumedUnit: ConsumedUnit.grams,
      per100Kcal: 400,
      per100Protein: 10,
      per100Carbs: 60,
      per100Fat: 12,
      sourceInventoryItemId: itemId,
      sourceInventoryAmountToRestore: amount,
      loggedAt: _planDay,
      createdAt: _planDay,
      updatedAt: _planDay,
    );

PreparedMeal _meal({num remaining = 2}) => PreparedMeal(
  id: 'meal-1',
  name: 'Chili',
  totalPortions: 4,
  remainingPortions: remaining,
  totalKcal: 2000,
  totalProtein: 100,
  totalCarbs: 200,
  totalFat: 80,
  createdAt: DateTime(2026, 10, 5),
  updatedAt: DateTime(2026, 10, 5),
  components: const <PreparedMealComponent>[],
);

CalorieEntry _mealPlan() => CalorieEntry.bundle(
  id: 'plan-2',
  userId: '',
  name: 'Chili',
  mealType: MealType.dinner,
  totalKcal: 500,
  totalProtein: 25,
  totalCarbs: 50,
  totalFat: 20,
  bundleSourcePreparedMealId: 'meal-1',
  bundleConsumedPortions: 1,
  bundleTotalPortions: 4,
  bundleComponents: const [],
  loggedAt: _planDay,
  createdAt: _planDay,
  updatedAt: _planDay,
);

void main() {
  late FakePlannedEntryRepository plans;
  late _MockEatService eatService;
  late _MockPendings pendings;
  late _MockQuickEat quickEat;
  late _MockDeleteService deleter;
  late List<CalorieEntry> saved;
  late InventoryPlanAcceptService service;

  setUpAll(() {
    registerFallbackValue(_oats(id: 'fallback'));
    registerFallbackValue(_itemPlan());
    registerFallbackValue(
      InventoryItemEatRequest(
        inventoryAmount: 1,
        loggedAt: _planDay,
        mealType: MealType.snack,
      ),
    );
    registerFallbackValue(
      const PendingInventoryConsumption(id: 'p', itemId: 'i', amount: 1),
    );
    registerFallbackValue(_meal());
    registerFallbackValue(MealType.snack);
  });

  setUp(() {
    eatService = _MockEatService();
    pendings = _MockPendings();
    quickEat = _MockQuickEat();
    deleter = _MockDeleteService();
    saved = [];
    when(() => pendings.discard(any())).thenAnswer((_) async => true);
    when(() => pendings.stage(any(), any())).thenAnswer(
      (invocation) => PendingInventoryConsumption(
        id: 'pending-1',
        itemId: (invocation.positionalArguments[0] as InventoryItem).id,
        amount: invocation.positionalArguments[1] as int,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        plannedEntryRepositoryProvider.overrideWithValue(
          plans = FakePlannedEntryRepository(plans: [_itemPlan(), _mealPlan()]),
        ),
        inventoryEatServiceProvider.overrideWithValue(eatService),
        inventoryPendingConsumptionStoreProvider.overrideWithValue(pendings),
        inventoryQuickEatActionsProvider.overrideWithValue(quickEat),
        inventoryEntryDeleteServiceProvider.overrideWithValue(deleter),
        calorieEntrySaverProvider.overrideWithValue((
          entry, {
          scannedSourceRef,
          persistEntry,
        }) async {
          saved.add(entry);
          return true;
        }),
      ],
    );
    addTearDown(container.dispose);
    service = container.read(inventoryPlanAcceptServiceProvider);
  });

  void logsWithStock() {
    when(
      () => eatService.log(
        item: any(named: 'item'),
        request: any(named: 'request'),
        pending: any(named: 'pending'),
      ),
    ).thenAnswer(
      (invocation) async =>
          InventoryEatLogged(_itemPlan().copyWith(id: 'entry-1')),
    );
  }

  test('eats an item plan from the opened pack and drops the plan', () async {
    logsWithStock();
    final opened = _oats(id: 'oats-2', currentAmount: 300);

    final result = await service.accept(
      _itemPlan(),
      items: [
        _oats(id: 'oats-1', entryDate: DateTime(2026, 8)),
        opened,
      ],
      meals: const [],
    );

    expect(result.entry.id, 'entry-1');
    expect(result.missedStock, isFalse);
    expect(plans.plans.map((plan) => plan.id), ['plan-2']);
    verify(() => pendings.stage(opened, 60)).called(1);
    final request =
        verify(
              () => eatService.log(
                item: opened,
                request: captureAny(named: 'request'),
                pending: any(named: 'pending'),
              ),
            ).captured.single
            as InventoryItemEatRequest;
    expect(request.loggedAt, _planDay);
    expect(request.mealType, MealType.breakfast);
    expect(request.isPlan, isFalse);
  });

  test('logs without stock when the Vorrat has the food no more', () async {
    final result = await service.accept(
      _itemPlan(),
      items: [_oats(id: 'other', currentAmount: 0)],
      meals: const [],
    );

    expect(result.missedStock, isTrue);
    expect(saved.single.sourceInventoryItemId, isNull);
    expect(saved.single.sourceInventoryAmountToRestore, isNull);
    expect(plans.plans.map((plan) => plan.id), ['plan-2']);
    verifyNever(() => pendings.stage(any(), any()));
  });

  test('an older plan without its amount takes the eaten grams', () async {
    logsWithStock();

    await service.accept(
      _itemPlan(amount: null),
      items: [_oats(id: 'oats-1')],
      meals: const [],
    );

    verify(() => pendings.stage(any(), 60)).called(1);
  });

  test('eats a meal plan from the meal portions', () async {
    final meal = _meal();
    when(
      () => quickEat.consumePreparedMeal(
        meal: any(named: 'meal'),
        consumedPortions: any(named: 'consumedPortions'),
        mealType: any(named: 'mealType'),
        loggedDay: any(named: 'loggedDay'),
      ),
    ).thenAnswer((_) async => (entry: _mealPlan(), isPlan: false));

    final result = await service.accept(
      _mealPlan(),
      items: const [],
      meals: [meal],
    );

    expect(result.missedStock, isFalse);
    verify(
      () => quickEat.consumePreparedMeal(
        meal: meal,
        consumedPortions: 1,
        mealType: MealType.dinner,
        loggedDay: _planDay,
      ),
    ).called(1);
  });

  test('an eaten up meal logs the plan without portions', () async {
    final result = await service.accept(
      _mealPlan(),
      items: const [],
      meals: [_meal(remaining: 0)],
    );

    expect(result.missedStock, isTrue);
    expect(saved.single.bundleSourcePreparedMealId, isNull);
  });

  test('a meal with open rows logs the plan without portions', () async {
    final result = await service.accept(
      _mealPlan(),
      items: const [],
      meals: [
        _meal().copyWith(pendingRecipeIngredients: ['Salz']),
      ],
    );

    expect(result.missedStock, isTrue);
    expect(saved.single.bundleSourcePreparedMealId, isNull);
  });

  test('a failed eat keeps the plan and releases the stock', () async {
    when(
      () => eatService.log(
        item: any(named: 'item'),
        request: any(named: 'request'),
        pending: any(named: 'pending'),
      ),
    ).thenAnswer(
      (_) async => const InventoryEatFailed(InventoryEatFailure.notSaved),
    );

    await expectLater(
      service.accept(
        _itemPlan(),
        items: [_oats(id: 'oats-1')],
        meals: const [],
      ),
      throwsA(isA<InventoryPlanAcceptException>()),
    );

    expect(plans.plans.map((plan) => plan.id), contains('plan-1'));
    verify(() => pendings.discard('pending-1')).called(1);
  });

  test(
    'undo deletes the entry with its stock and brings the plan back',
    () async {
      final entry = _itemPlan().copyWith(id: 'entry-1');
      when(() => deleter.delete(entry, restoreToInventory: true)).thenAnswer(
        (_) async =>
            const CalorieEntryDeleteResult.success(restoredToInventory: true),
      );
      await plans.deletePlannedEntry('plan-1');

      await service.undo(entry, _itemPlan());
      expect(plans.plans.map((plan) => plan.id), contains('plan-1'));
    },
  );

  test('undo of a plan logged without stock gives nothing back', () async {
    final entry = _itemPlan().copyWith(
      id: 'entry-1',
      sourceInventoryItemId: null,
      sourceInventoryAmountToRestore: null,
    );
    when(() => deleter.delete(entry, restoreToInventory: false)).thenAnswer(
      (_) async =>
          const CalorieEntryDeleteResult.success(restoredToInventory: false),
    );

    await service.undo(entry, _itemPlan());

    verify(() => deleter.delete(entry, restoreToInventory: false)).called(1);
  });

  test('another pack of the food takes the eaten grams', () async {
    logsWithStock();

    await service.accept(
      _itemPlan(amount: 80),
      items: [_oats(id: 'oats-9')],
      meals: const [],
    );

    verify(() => pendings.stage(any(), 60)).called(1);
  });

  test('a meal planned in the pot eats the same share once cooked', () async {
    when(
      () => quickEat.consumePreparedMeal(
        meal: any(named: 'meal'),
        consumedPortions: any(named: 'consumedPortions'),
        mealType: any(named: 'mealType'),
        loggedDay: any(named: 'loggedDay'),
      ),
    ).thenAnswer((_) async => (entry: _mealPlan(), isPlan: false));
    // Half of the pot, which was one portion when it was planned.
    final plan = _mealPlan().copyWith(
      bundleConsumedPortions: 0.5,
      bundleTotalPortions: 1,
    );
    final cooked = _meal(remaining: 4);

    await service.accept(plan, items: const [], meals: [cooked]);

    verify(
      () => quickEat.consumePreparedMeal(
        meal: cooked,
        consumedPortions: 2,
        mealType: MealType.dinner,
        loggedDay: _planDay,
      ),
    ).called(1);
  });

  test('a meal still in the pot cannot be eaten yet', () async {
    await expectLater(
      service.accept(
        _mealPlan(),
        items: const [],
        meals: [_meal().copyWith(inPot: true)],
      ),
      throwsA(
        isA<InventoryPlanAcceptException>().having(
          (error) => error.isMealInPot,
          'isMealInPot',
          isTrue,
        ),
      ),
    );
    expect(plans.plans.map((plan) => plan.id), contains('plan-2'));
  });

  test('a piece pack gives the pieces the eaten grams weigh', () async {
    logsWithStock();
    final eggs = InventoryItem.create(
      id: 'eggs',
      name: 'Eggs',
      nutrition: _nutrition,
      entryDate: DateTime(2026, 9),
      storeName: 'Rewe',
      quantity: 6,
      amountUnit: InventoryAmountUnit.piece,
      servingQuantity: 60,
      servingQuantityUnit: 'g',
    );
    final plan = _itemPlan(
      itemId: 'eggs',
      amount: null,
    ).copyWith(name: 'Eggs', consumedAmount: 120);

    final result = await service.accept(plan, items: [eggs], meals: const []);

    expect(result.missedStock, isFalse);
    verify(() => pendings.stage(eggs, 2)).called(1);
  });

  test('a pack with less stock than planned eats it and says so', () async {
    logsWithStock();
    // The stage takes at most what the pack has left.
    when(() => pendings.stage(any(), any())).thenReturn(
      const PendingInventoryConsumption(
        id: 'pending-1',
        itemId: 'oats-1',
        amount: 20,
      ),
    );

    final result = await service.accept(
      _itemPlan(),
      items: [_oats(id: 'oats-1', currentAmount: 20)],
      meals: const [],
    );

    expect(result.missedStock, isTrue);
  });
}
