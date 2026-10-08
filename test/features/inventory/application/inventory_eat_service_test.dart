import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_create_context.dart';
import 'package:yamt/features/inventory/application/inventory_eat_service.dart';
import 'package:yamt/features/inventory/application/inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/data/'
    'global_food_serving_suggestion_repository.dart';
import 'package:yamt/features/inventory/data/inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/global_food_serving_suggestion.dart';
import 'package:yamt/features/inventory/domain/inventory_eat_outcome.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';

import '../../calories/support/fake_calories_repositories.dart';
import '../../calories/support/fake_planned_entry_repository.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

class _MockUser extends Mock implements User;

class _RecordingCommitStore implements InventoryCalorieEntryCommitStore {
  new({this.fails = false, this.gate});

  final bool fails;

  /// Holds the write open until it completes.
  final Future<void>? gate;
  CalorieEntry? entry;
  List<PendingInventoryConsumption>? pendings;

  @override
  Future<List<InventoryCalorieEntryCommitResult>?>
  commitEntryAndInventoryItems({
    required CalorieEntry entry,
    required List<PendingInventoryConsumption> pendingConsumptions,
  }) async {
    this.entry = entry;
    pendings = pendingConsumptions;
    await gate;
    if (fails) {
      return null;
    }
    return [
      for (final pending in pendingConsumptions)
        InventoryCalorieEntryCommitResult(
          itemId: pending.itemId,
          quantity: 1,
          currentAmount: 500,
        ),
    ];
  }

  @override
  Future<List<InventoryCalorieEntryCommitResult>?> saveEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  }) async => null;

  @override
  Future<List<InventoryCalorieEntryCommitResult>?> deleteEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  }) => throw UnimplementedError();
}

typedef _Serving = ({double amount, ConsumedUnit unit, String? label});

/// Records the servings the eat service learns.
class _RecordingServings implements GlobalFoodServingSuggestionRepository {
  new({this.gate});

  /// Holds a recording open until it completes.
  final Future<void>? gate;
  final calls = <_Serving>[];

  @override
  Future<GlobalFoodServingSuggestionSet> readSuggestions({
    required String foodFingerprint,
    String? globalFoodItemId,
    int limit = 5,
  }) async => const GlobalFoodServingSuggestionSet.empty();

  @override
  Future<void> recordSelection({
    required String foodFingerprint,
    required double amount,
    required ConsumedUnit unit,
    required DateTime selectedAt,
    String? globalFoodItemId,
    String? label,
  }) async {
    await gate;
    calls.add((amount: amount, unit: unit, label: label));
  }
}

final DateTime _now = DateTime.parse('2026-10-05T12:00:00Z');

const _nutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 215,
  per100Protein: 4,
  per100Carbs: 25,
  per100Fat: 10,
);

InventoryItem _gramItem({GlobalFoodNutrition? nutrition = _nutrition}) {
  return InventoryItem.create(
    id: 'waffles',
    name: 'Waffles',
    barcode: '4061458029995',
    nutrition: nutrition,
    entryDate: _now,
    storeName: 'Aldi',
    quantity: 2,
    initialQuantity: 2,
    initialAmount: 1000,
    currentAmount: 750,
    amountUnit: InventoryAmountUnit.gram,
  );
}

InventoryItem _pieceItem() {
  return InventoryItem.create(
    id: 'eggs',
    name: 'Eggs',
    nutrition: _nutrition,
    entryDate: _now,
    storeName: 'Aldi',
    quantity: 6,
  );
}

CalorieEntry _entry() {
  return CalorieEntry.create(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Waffles',
    mealType: MealType.lunch,
    consumedAmount: 250,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 215,
    per100Protein: 4,
    per100Carbs: 25,
    per100Fat: 10,
    loggedAt: _now,
    createdAt: _now,
    updatedAt: _now,
  );
}

InventoryItemEatRequest _request(int amount) {
  return InventoryItemEatRequest(
    inventoryAmount: amount,
    loggedAt: _now,
    mealType: MealType.lunch,
  );
}

/// What the calorie editor needs to finish an eat of 250 g of waffles,
/// picked as [portionCount] slices of 50 g when given.
CalorieInventoryCreateContext _editorContext(
  PendingInventoryConsumption pending, {
  double? portionCount,
}) {
  return CalorieInventoryCreateContext(
    inventoryItemId: 'waffles',
    foodFingerprint: 'waffles__aldi',
    globalFoodItemId: 'off-waffles',
    inventoryAmountToRestore: pending.amount,
    itemName: 'Waffles',
    itemBrand: null,
    consumedAmount: 250,
    consumedUnit: ConsumedUnit.grams,
    portionBaseAmount: portionCount == null ? null : 50,
    portionBaseUnit: portionCount == null ? null : ConsumedUnit.grams,
    portionCount: portionCount,
    portionLabel: portionCount == null ? null : 'Scheibe',
  );
}

typedef _Harness = ({
  ProviderContainer container,
  InventoryEatService service,
  InventoryPendingConsumptionStore pendings,
  _RecordingServings servings,
});

_Harness _harness(
  _RecordingCommitStore commitStore, {
  _RecordingServings? servings,
  List<Override> overrides = const <Override>[],
}) {
  final learned = servings ?? _RecordingServings();
  final auth = _MockFirebaseAuth();
  final user = _MockUser();
  when(() => user.uid).thenReturn('user-1');
  when(() => auth.currentUser).thenReturn(user);
  final calorieLog = FakeCalorieLogRepository();
  addTearDown(calorieLog.dispose);
  final container = ProviderContainer(
    overrides: [
      inventoryCalorieEntryCommitStoreProvider.overrideWithValue(commitStore),
      calorieLogRepositoryProvider.overrideWithValue(calorieLog),
      firebaseAuthProvider.overrideWithValue(auth),
      clockProvider.overrideWithValue(() => _now),
      globalFoodServingSuggestionRepositoryProvider.overrideWithValue(learned),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  final subscription = container.listen(inventoryEatServiceProvider, (_, _) {});
  addTearDown(subscription.close);
  return (
    container: container,
    service: subscription.read(),
    pendings: container.read(inventoryPendingConsumptionStoreProvider),
    servings: learned,
  );
}

void main() {
  group('log', () {
    test('saves the entry and the stock change in one write', () async {
      final commitStore = _RecordingCommitStore();
      final harness = _harness(commitStore);
      final finalized = <InventoryPendingConsumptionFinalized>[];
      harness.pendings.finalizations.listen(finalized.add);
      final pending = harness.pendings.stage(_gramItem(), 250)!;

      final outcome = await harness.service.log(
        item: _gramItem(),
        request: _request(250),
        pending: pending,
      );

      final entry = (outcome as InventoryEatLogged).entry;
      expect(entry.name, 'Waffles');
      expect(entry.userId, 'user-1');
      expect(entry.mealType, MealType.lunch);
      expect(entry.consumedAmount, 250);
      expect(entry.consumedUnit, ConsumedUnit.grams);
      expect(entry.sourceInventoryItemId, 'waffles');
      expect(entry.sourceInventoryAmountToRestore, 250);
      expect(entry.createdAt, _now);
      expect(commitStore.entry?.id, entry.id);
      expect(commitStore.pendings?.single.id, pending.id);
      expect(harness.pendings.pendingConsumptionById(pending.id), isNull);
      expect(finalized.single.itemId, 'waffles');
      expect(finalized.single.currentAmount, 500);
    });

    test('restores what the stock gave, not what was asked', () async {
      final commitStore = _RecordingCommitStore();
      final harness = _harness(commitStore);
      final pending = harness.pendings.stage(_gramItem(), 900)!;

      final outcome = await harness.service.log(
        item: _gramItem(),
        request: _request(900),
        pending: pending,
      );

      final entry = (outcome as InventoryEatLogged).entry;
      expect(entry.consumedAmount, 900);
      expect(entry.sourceInventoryAmountToRestore, 750);
    });

    test(
      'a failed write releases the stock and reports no new stock',
      () async {
        final harness = _harness(_RecordingCommitStore(fails: true));
        final finalized = <InventoryPendingConsumptionFinalized>[];
        harness.pendings.finalizations.listen(finalized.add);
        final pending = harness.pendings.stage(_gramItem(), 250)!;

        final outcome = await harness.service.log(
          item: _gramItem(),
          request: _request(250),
          pending: pending,
        );

        expect(outcome, isA<InventoryEatFailed>());
        expect(
          (outcome as InventoryEatFailed).failure,
          InventoryEatFailure.notSaved,
        );
        expect(harness.pendings.pendingConsumptionById(pending.id), isNull);
        expect(finalized, isEmpty);
      },
    );

    test('an item without nutrition fails and releases its stock', () async {
      final commitStore = _RecordingCommitStore();
      final harness = _harness(commitStore);
      final item = _gramItem(nutrition: null);
      final pending = harness.pendings.stage(item, 250)!;

      final outcome = await harness.service.log(
        item: item,
        request: _request(250),
        pending: pending,
      );

      expect(
        (outcome as InventoryEatFailed).failure,
        InventoryEatFailure.noNutrition,
      );
      expect(harness.pendings.pendingConsumptionById(pending.id), isNull);
      expect(commitStore.entry, isNull);
    });

    test('a portion in another unit than the stock needs the editor', () async {
      final commitStore = _RecordingCommitStore();
      final harness = _harness(commitStore);
      final pending = harness.pendings.stage(_gramItem(), 250)!;

      final outcome = await harness.service.log(
        item: _gramItem(),
        request: InventoryItemEatRequest(
          inventoryAmount: 250,
          loggedAt: _now,
          mealType: MealType.lunch,
          calorieAmount: 200,
          calorieUnit: ConsumedUnit.milliliters,
        ),
        pending: pending,
      );

      final editor = outcome as InventoryEatNeedsEditor;
      expect(editor.profile.name, 'Waffles');
      expect(editor.scannedSourceRef?.barcode, '4061458029995');
      expect(editor.inventoryContext.consumedUnit, ConsumedUnit.milliliters);
      expect(editor.inventoryContext.inventoryAmountToRestore, 250);
      expect(harness.pendings.pendingConsumptionById(pending.id), isNotNull);
      expect(commitStore.entry, isNull);
    });

    test('a later day saves a plan and releases the stock', () async {
      final commitStore = _RecordingCommitStore();
      final plans = FakePlannedEntryRepository();
      final harness = _harness(
        commitStore,
        overrides: [plannedEntryRepositoryProvider.overrideWithValue(plans)],
      );
      final finalized = <InventoryPendingConsumptionFinalized>[];
      harness.pendings.finalizations.listen(finalized.add);
      final pending = harness.pendings.stage(_gramItem(), 250)!;
      final tomorrow = _now.add(const Duration(days: 1));

      final outcome = await harness.service.log(
        item: _gramItem(),
        request: InventoryItemEatRequest(
          inventoryAmount: 250,
          loggedAt: tomorrow,
          mealType: MealType.dinner,
        ),
        pending: pending,
      );

      final plan = (outcome as InventoryEatPlanned).entry;
      expect(plans.plans, [plan]);
      expect(plan.loggedAt, tomorrow);
      expect(plan.consumedAmount, 250);
      expect(plan.sourceInventoryItemId, 'waffles');
      // Kept for the accept, which takes the stock then.
      expect(plan.sourceInventoryAmountToRestore, 250);
      expect(commitStore.entry, isNull);
      expect(harness.pendings.pendingConsumptionById(pending.id), isNull);
      expect(finalized, isEmpty);
      expect(harness.container.read(calorieOverviewRevisionProvider), 1);
    });

    test('an explicit plan on today saves a plan', () async {
      final commitStore = _RecordingCommitStore();
      final plans = FakePlannedEntryRepository();
      final harness = _harness(
        commitStore,
        overrides: [plannedEntryRepositoryProvider.overrideWithValue(plans)],
      );
      final pending = harness.pendings.stage(_gramItem(), 250)!;

      final outcome = await harness.service.log(
        item: _gramItem(),
        request: InventoryItemEatRequest(
          inventoryAmount: 250,
          loggedAt: _now,
          mealType: MealType.dinner,
          isPlan: true,
        ),
        pending: pending,
      );

      expect(outcome, isA<InventoryEatPlanned>());
      expect(plans.plans, hasLength(1));
      expect(commitStore.entry, isNull);
    });

    test('a failed plan releases the stock and throws', () async {
      final plans = FakePlannedEntryRepository()..writeShouldFail = true;
      final harness = _harness(
        _RecordingCommitStore(),
        overrides: [plannedEntryRepositoryProvider.overrideWithValue(plans)],
      );
      final pending = harness.pendings.stage(_gramItem(), 250)!;

      await expectLater(
        harness.service.log(
          item: _gramItem(),
          request: InventoryItemEatRequest(
            inventoryAmount: 250,
            loggedAt: _now.add(const Duration(days: 1)),
            mealType: MealType.dinner,
          ),
          pending: pending,
        ),
        throwsStateError,
      );

      expect(plans.plans, isEmpty);
      expect(harness.pendings.pendingConsumptionById(pending.id), isNull);
      expect(harness.container.read(calorieOverviewRevisionProvider), 0);
    });

    test('a later day that needs the editor cannot be planned', () async {
      final plans = FakePlannedEntryRepository();
      final harness = _harness(
        _RecordingCommitStore(),
        overrides: [plannedEntryRepositoryProvider.overrideWithValue(plans)],
      );
      final pending = harness.pendings.stage(_gramItem(), 250)!;

      final outcome = await harness.service.log(
        item: _gramItem(),
        request: InventoryItemEatRequest(
          inventoryAmount: 250,
          loggedAt: _now.add(const Duration(days: 1)),
          mealType: MealType.lunch,
          calorieAmount: 200,
          calorieUnit: ConsumedUnit.milliliters,
        ),
        pending: pending,
      );

      expect(
        (outcome as InventoryEatFailed).failure,
        InventoryEatFailure.cannotPlan,
      );
      expect(plans.plans, isEmpty);
      expect(harness.pendings.pendingConsumptionById(pending.id), isNull);
    });

    test('an eat that throws releases its stock', () async {
      final harness = _harness(_RecordingCommitStore());
      // A piece item needs a calorie portion; without one the eat throws.
      final pending = harness.pendings.stage(_pieceItem(), 2)!;

      await expectLater(
        harness.service.log(
          item: _pieceItem(),
          request: _request(2),
          pending: pending,
        ),
        throwsStateError,
      );

      expect(harness.pendings.pendingConsumptionById(pending.id), isNull);
    });
  });

  test('a write that lands after its stock was released still reports the '
      'new stock', () async {
    final gate = Completer<void>();
    final harness = _harness(_RecordingCommitStore(gate: gate.future));
    final finalized = <InventoryPendingConsumptionFinalized>[];
    harness.pendings.finalizations.listen(finalized.add);
    final pending = harness.pendings.stage(_gramItem(), 250)!;

    final logged = harness.service.log(
      item: _gramItem(),
      request: _request(250),
      pending: pending,
    );
    await Future<void>.delayed(Duration.zero);
    await harness.pendings.discard(pending.id);
    gate.complete();

    expect(await logged, isA<InventoryEatLogged>());
    expect(finalized.single.id, pending.id);
    expect(finalized.single.currentAmount, 500);
  });

  group('logEdited', () {
    test('saves the edited entry with its Vorrat source and stock', () async {
      final commitStore = _RecordingCommitStore();
      final harness = _harness(commitStore);
      final pending = harness.pendings.stage(_gramItem(), 250)!;

      final outcome = await harness.service.logEdited(
        entry: _entry(),
        pending: pending,
        inventoryContext: _editorContext(pending),
      );

      final entry = (outcome as InventoryEatLogged).entry;
      expect(entry.sourceInventoryItemId, 'waffles');
      expect(entry.sourceInventoryAmountToRestore, 250);
      expect(commitStore.entry?.sourceInventoryItemId, 'waffles');
      expect(commitStore.pendings?.single.id, pending.id);
      expect(harness.pendings.pendingConsumptionById(pending.id), isNull);
    });

    test('a failed save releases the stock', () async {
      final harness = _harness(_RecordingCommitStore(fails: true));
      final pending = harness.pendings.stage(_gramItem(), 250)!;

      final outcome = await harness.service.logEdited(
        entry: _entry(),
        pending: pending,
        inventoryContext: _editorContext(pending),
      );

      expect(outcome, isA<InventoryEatFailed>());
      expect(harness.pendings.pendingConsumptionById(pending.id), isNull);
    });

    test('a released stock saves nothing', () async {
      final commitStore = _RecordingCommitStore();
      final harness = _harness(commitStore);
      final pending = harness.pendings.stage(_gramItem(), 250)!;
      await harness.pendings.discard(pending.id);

      final outcome = await harness.service.logEdited(
        entry: _entry(),
        pending: pending,
        inventoryContext: _editorContext(pending),
      );

      expect(outcome, isA<InventoryEatFailed>());
      expect(commitStore.entry, isNull);
    });
  });

  group('learned serving', () {
    test('an eat records its amount as the next serving', () async {
      final harness = _harness(_RecordingCommitStore());
      final pending = harness.pendings.stage(_gramItem(), 250)!;

      await harness.service.log(
        item: _gramItem(),
        request: _request(250),
        pending: pending,
      );
      await pumpEventQueue();

      expect(harness.servings.calls, [
        (amount: 250.0, unit: ConsumedUnit.grams, label: null),
      ]);
    });

    test('an untouched portion is learned with its label', () async {
      final harness = _harness(_RecordingCommitStore());
      final pending = harness.pendings.stage(_gramItem(), 250)!;

      final outcome = await harness.service.logEdited(
        entry: _entry(),
        pending: pending,
        inventoryContext: _editorContext(pending, portionCount: 5),
      );
      await pumpEventQueue();

      final entry = (outcome as InventoryEatLogged).entry;
      expect(entry.portionAmount, 50);
      expect(entry.portionLabel, 'Scheibe');
      expect(harness.servings.calls, [
        (amount: 50.0, unit: ConsumedUnit.grams, label: 'Scheibe'),
      ]);
    });

    test('an amount edited off the portion is learned without it', () async {
      final harness = _harness(_RecordingCommitStore());
      final pending = harness.pendings.stage(_gramItem(), 250)!;

      final outcome = await harness.service.logEdited(
        entry: _entry().copyWith(consumedAmount: 120),
        pending: pending,
        inventoryContext: _editorContext(pending, portionCount: 5),
      );
      await pumpEventQueue();

      expect((outcome as InventoryEatLogged).entry.portionAmount, isNull);
      expect(harness.servings.calls, [
        (amount: 120.0, unit: ConsumedUnit.grams, label: null),
      ]);
    });

    test('a failed save learns nothing', () async {
      final harness = _harness(_RecordingCommitStore(fails: true));
      final pending = harness.pendings.stage(_gramItem(), 250)!;

      await harness.service.log(
        item: _gramItem(),
        request: _request(250),
        pending: pending,
      );
      await pumpEventQueue();

      expect(harness.servings.calls, isEmpty);
    });

    test('the eat does not wait for the serving to be recorded', () async {
      final recording = Completer<void>();
      final harness = _harness(
        _RecordingCommitStore(),
        servings: _RecordingServings(gate: recording.future),
      );
      final pending = harness.pendings.stage(_gramItem(), 250)!;

      final outcome = await harness.service.log(
        item: _gramItem(),
        request: _request(250),
        pending: pending,
      );

      expect(outcome, isA<InventoryEatLogged>());
      expect(harness.servings.calls, isEmpty);
      recording.complete();
    });
  });
}
