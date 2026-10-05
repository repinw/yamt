import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/inventory_combined_eat_service.dart';
import 'package:yamt/features/inventory/application/inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/data/inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';

import '../../calories/support/fake_calories_repositories.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

class _MockUser extends Mock implements User;

class _RecordingCommitStore implements InventoryCalorieEntryCommitStore {
  new({this.fails = false});

  final bool fails;
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
    if (fails) {
      return null;
    }
    return [
      for (final pending in pendingConsumptions)
        InventoryCalorieEntryCommitResult(
          itemId: pending.itemId,
          quantity: 1,
          currentAmount: 100,
        ),
    ];
  }
}

final DateTime _now = DateTime.parse('2026-09-26T12:00:00Z');

InventoryItem _item(String id, String name, double kcal, {double? sugar}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: _now,
    storeName: 'Store',
    quantity: 1,
    initialAmount: 500,
    currentAmount: 500,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: kcal,
      per100Protein: 10,
      per100Carbs: 20,
      per100Fat: 5,
      per100Sugar: sugar,
    ),
  );
}

InventoryCombinedFood _food(
  InventoryPendingConsumptionStore pendings,
  InventoryItem item,
  int amount, {
  int? staged,
}) {
  return (
    item: item,
    request: InventoryItemEatRequest(
      inventoryAmount: amount,
      loggedAt: _now,
      mealType: MealType.lunch,
    ),
    pending: pendings.stage(item, staged ?? amount)!,
  );
}

Future<(InventoryCombinedEatService, InventoryPendingConsumptionStore)>
_service(ProviderContainer container) async {
  final subscription = container.listen(
    inventoryCombinedEatServiceProvider,
    (_, _) {},
  );
  addTearDown(subscription.close);
  return (
    subscription.read(),
    container.read(inventoryPendingConsumptionStoreProvider),
  );
}

ProviderContainer _container(_RecordingCommitStore commitStore) {
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
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('saves the foods as one entry with their stock sources', () async {
    final commitStore = _RecordingCommitStore();
    final (service, pendingStore) = await _service(_container(commitStore));
    final bread = _food(
      pendingStore,
      _item('bread', 'Bread', 250, sugar: 2),
      80,
    );
    // The stock capped the gouda at 50 of the wanted 60.
    final gouda = _food(
      pendingStore,
      _item('gouda', 'Gouda', 361, sugar: 0),
      60,
      staged: 50,
    );

    final entry = await service.save(
      foods: [bread, gouda],
      loggedAt: _now,
      mealType: MealType.lunch,
    );

    expect(entry?.name, 'Bread + Gouda');
    expect(entry?.isCombined, isTrue);
    expect(entry?.totalKcal, closeTo(250 * 0.8 + 361 * 0.6, 0.001));
    expect(entry?.nutrientDetails?.per100Sugar, closeTo(1.6, 0.001));
    expect(entry?.bundleComponents.map((c) => c.amountLabel), ['80 g', '60 g']);
    expect(entry?.bundleComponents.last.sourceInventoryItemId, 'gouda');
    expect(entry?.bundleComponents.last.sourceInventoryAmountToRestore, 50);
    expect(commitStore.pendings?.map((p) => p.itemId), ['bread', 'gouda']);
    expect(pendingStore.pendingConsumptionById(bread.pending.id), isNull);
    expect(pendingStore.pendingConsumptionById(gouda.pending.id), isNull);
  });

  test(
    'returns null and keeps the staged stock when the write fails',
    () async {
      final commitStore = _RecordingCommitStore(fails: true);
      final (service, pendingStore) = await _service(_container(commitStore));
      final bread = _food(pendingStore, _item('bread', 'Bread', 250), 80);
      final gouda = _food(pendingStore, _item('gouda', 'Gouda', 361), 60);

      final entry = await service.save(
        foods: [bread, gouda],
        loggedAt: _now,
        mealType: MealType.lunch,
      );

      expect(entry, isNull);
      expect(pendingStore.pendingConsumptionById(bread.pending.id), isNotNull);
    },
  );

  test('only items with nutrition values can be combined', () {
    final withNutrition = _item('bread', 'Bread', 250);
    final withoutNutrition = InventoryItem.create(
      id: 'salt',
      name: 'Salt',
      entryDate: _now,
      storeName: 'Store',
      quantity: 1,
    );

    expect(InventoryCombinedEatService.canCombine(withNutrition), isTrue);
    expect(InventoryCombinedEatService.canCombine(withoutNutrition), isFalse);
  });
}
