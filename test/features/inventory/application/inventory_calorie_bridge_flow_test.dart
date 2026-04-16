import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_calorie_bridge_flow.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';

import '../../calories/support/fake_calories_repositories.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _FakeInventoryItemRepository implements InventoryItemRepository {
  _FakeInventoryItemRepository({required List<InventoryItem> initialItems})
    : _items = List<InventoryItem>.from(initialItems);

  final StreamController<List<InventoryItem>> _controller =
      StreamController<List<InventoryItem>>.broadcast();
  List<InventoryItem> _items;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return List<InventoryItem>.from(_items);
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    _items = List<InventoryItem>.from(items);
    _controller.add(List<InventoryItem>.from(_items));
    return true;
  }

  @override
  Stream<List<InventoryItem>> watchAll() {
    return Stream<List<InventoryItem>>.multi((controller) {
      controller.add(List<InventoryItem>.from(_items));
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = () {
        unawaited(subscription.cancel());
      };
    });
  }

  Future<void> dispose() {
    return _controller.close();
  }
}

class _RecordingCommitStore implements InventoryCalorieEntryCommitStore {
  PendingInventoryConsumption? pendingConsumption;
  CalorieEntry? entry;

  @override
  Future<InventoryCalorieEntryCommitResult?> commitEntryAndInventory({
    required CalorieEntry entry,
    required PendingInventoryConsumption pendingConsumption,
  }) async {
    this.entry = entry;
    this.pendingConsumption = pendingConsumption;
    return const InventoryCalorieEntryCommitResult(
      itemId: 'inventory-1',
      quantity: 1,
      currentAmount: 500,
    );
  }
}

class _SaveDirectEntryButton extends ConsumerWidget {
  const _SaveDirectEntryButton({
    required this.profile,
    required this.inventoryContext,
    required this.loggedAt,
    required this.mealType,
    required this.onCompleted,
  });

  final CalorieProductProfile profile;
  final CalorieInventoryCreateContext inventoryContext;
  final DateTime loggedAt;
  final MealType mealType;
  final ValueChanged<bool> onCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final saved = await InventoryCalorieBridgeFlow.saveDirectEntry(
          ref: ref,
          profile: profile,
          inventoryContext: inventoryContext,
          scannedSourceRef: null,
          loggedAt: loggedAt,
          mealType: mealType,
        );
        onCompleted(saved);
      },
      child: const Text('save'),
    );
  }
}

InventoryItem _amountItemWithNutrition({
  String id = 'inventory-1',
  String? barcode = '4061458029995',
}) {
  return InventoryItem.create(
    id: id,
    globalFoodItemId: 'off-4061458029995',
    name: 'Waffelhörnchen Haselnuss-Vanille',
    brand: 'Mucci',
    barcode: barcode,
    imageUrl: 'https://example.com/waffel.png',
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 215,
      per100Protein: 4.2,
      per100Carbs: 24.8,
      per100Fat: 9.6,
    ),
    entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
    storeName: 'Aldi',
    quantity: 2,
    initialQuantity: 2,
    initialAmount: 1000,
    currentAmount: 750,
    amountUnit: InventoryAmountUnit.gram,
  );
}

InventoryItem _portionItemWithNutrition() {
  return InventoryItem.create(
    id: 'item-portion',
    name: 'Milk',
    brand: 'Brand',
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 42,
      per100Protein: 3.4,
      per100Carbs: 4.9,
      per100Fat: 1.5,
    ),
    entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
  );
}

InventoryItem _itemWithoutNutrition() {
  return InventoryItem.create(
    id: 'item-no-nutrition',
    name: 'Milk',
    brand: 'Brand',
    entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: 750,
    amountUnit: InventoryAmountUnit.gram,
  );
}

ProviderSubscription<AsyncValue<List<InventoryItem>>> _keepInventoryAlive(
  ProviderContainer container,
) {
  return container.listen(inventoryItemsControllerProvider, (_, _) {});
}

ProviderSubscription<AsyncValue<List<CalorieEntry>>> _keepCaloriesAlive(
  ProviderContainer container,
) {
  return container.listen(calorieEntriesControllerProvider, (_, _) {});
}

void main() {
  test('buildProfileFromInventoryItem maps nutrition and barcode fallback', () {
    final item = _amountItemWithNutrition(barcode: null);

    final profile = InventoryCalorieBridgeFlow.buildProfileFromInventoryItem(
      item,
    );

    expect(profile, isNotNull);
    expect(profile?.barcode, 'inventory-inventory-1');
    expect(profile?.name, 'Waffelhörnchen Haselnuss-Vanille');
    expect(profile?.brand, 'Mucci');
    expect(profile?.per100Kcal, 215);
    expect(profile?.source, CalorieProductSource.userOverride);
    expect(profile?.offProductId, 'off-4061458029995');
  });

  test('buildProfileFromInventoryItem returns null without nutrition', () {
    final profile = InventoryCalorieBridgeFlow.buildProfileFromInventoryItem(
      _itemWithoutNutrition(),
    );

    expect(profile, isNull);
  });

  test('buildScannedSourceRef uses barcode information when available', () {
    final item = _amountItemWithNutrition();
    final profile = InventoryCalorieBridgeFlow.buildProfileFromInventoryItem(
      item,
    )!;

    final sourceRef = InventoryCalorieBridgeFlow.buildScannedSourceRef(
      item: item,
      profile: profile,
    );

    expect(sourceRef, isNotNull);
    expect(sourceRef?.barcode, '4061458029995');
    expect(sourceRef?.source, CalorieProductSource.userOverride);
    expect(sourceRef?.offProductId, 'off-4061458029995');
  });

  test('buildScannedSourceRef returns null when the item has no barcode', () {
    final item = _amountItemWithNutrition(barcode: null);
    final profile = InventoryCalorieBridgeFlow.buildProfileFromInventoryItem(
      item,
    )!;

    final sourceRef = InventoryCalorieBridgeFlow.buildScannedSourceRef(
      item: item,
      profile: profile,
    );

    expect(sourceRef, isNull);
  });

  test('buildInventoryContext uses fixed amount unit from the item', () {
    final item = _amountItemWithNutrition();
    final request = InventoryItemEatRequest(
      inventoryAmount: 250,
      loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
      mealType: MealType.lunch,
    );

    final context = InventoryCalorieBridgeFlow.buildInventoryContext(
      item: item,
      pendingConsumptionId: 'pending-1',
      request: request,
    );

    expect(context.inventoryItemId, 'inventory-1');
    expect(context.pendingConsumptionId, 'pending-1');
    expect(context.inventoryAmountToRestore, 250);
    expect(context.consumedAmount, 250);
    expect(context.consumedUnit, ConsumedUnit.grams);
  });

  test('buildInventoryContext prefers manual portion for fixed-unit items', () {
    final item = _amountItemWithNutrition();
    final request = InventoryItemEatRequest(
      inventoryAmount: 250,
      loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
      mealType: MealType.lunch,
      calorieAmount: 180,
      calorieUnit: ConsumedUnit.grams,
    );

    final context = InventoryCalorieBridgeFlow.buildInventoryContext(
      item: item,
      pendingConsumptionId: 'pending-1',
      request: request,
    );

    expect(context.inventoryItemId, 'inventory-1');
    expect(context.inventoryAmountToRestore, 250);
    expect(context.consumedAmount, 180);
    expect(context.consumedUnit, ConsumedUnit.grams);
  });

  test(
    'buildInventoryContext uses manual portion for non fixed-unit items',
    () {
      final item = _portionItemWithNutrition();
      final request = InventoryItemEatRequest(
        inventoryAmount: 1,
        loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
        mealType: MealType.lunch,
        calorieAmount: 2.5,
        calorieUnit: ConsumedUnit.grams,
      );

      final context = InventoryCalorieBridgeFlow.buildInventoryContext(
        item: item,
        pendingConsumptionId: 'pending-1',
        request: request,
      );

      expect(context.inventoryItemId, 'item-portion');
      expect(context.consumedAmount, 2.5);
      expect(context.consumedUnit, ConsumedUnit.grams);
    },
  );

  test('buildInventoryContext throws without manual portion when required', () {
    final item = _portionItemWithNutrition();
    final request = InventoryItemEatRequest(
      inventoryAmount: 1,
      loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
      mealType: MealType.lunch,
    );

    expect(
      () => InventoryCalorieBridgeFlow.buildInventoryContext(
        item: item,
        pendingConsumptionId: 'pending-1',
        request: request,
      ),
      throwsStateError,
    );
  });

  testWidgets('saveDirectEntry persists through commit flow and clears pending '
      'consumption', (tester) async {
    final item = _amountItemWithNutrition();
    final repository = _FakeInventoryItemRepository(
      initialItems: <InventoryItem>[item],
    );
    final calorieLogRepository = FakeCalorieLogRepository();
    final commitStore = _RecordingCommitStore();
    final auth = _MockFirebaseAuth();
    final user = _MockUser();
    var saved = false;
    addTearDown(repository.dispose);
    addTearDown(calorieLogRepository.dispose);

    when(() => user.uid).thenReturn('user-1');
    when(() => auth.currentUser).thenReturn(user);

    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
        inventoryCalorieEntryCommitStoreProvider.overrideWithValue(commitStore),
        calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
        firebaseAuthProvider.overrideWithValue(auth),
      ],
    );
    addTearDown(container.dispose);
    final inventorySubscription = _keepInventoryAlive(container);
    final caloriesSubscription = _keepCaloriesAlive(container);
    addTearDown(inventorySubscription.close);
    addTearDown(caloriesSubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final pendingConsumption = await container
        .read(inventoryItemsControllerProvider.notifier)
        .stagePendingConsumption(item.id, 250);

    final request = InventoryItemEatRequest(
      inventoryAmount: 250,
      loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
      mealType: MealType.lunch,
    );
    final profile = InventoryCalorieBridgeFlow.buildProfileFromInventoryItem(
      item,
    )!;
    final inventoryContext = InventoryCalorieBridgeFlow.buildInventoryContext(
      item: item,
      pendingConsumptionId: pendingConsumption!.id,
      request: request,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: _SaveDirectEntryButton(
              profile: profile,
              inventoryContext: inventoryContext,
              loggedAt: request.loggedAt,
              mealType: request.mealType,
              onCompleted: (value) {
                saved = value;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();

    expect(saved, isTrue);
    expect(commitStore.pendingConsumption?.id, pendingConsumption.id);
    expect(commitStore.pendingConsumption?.amount, 250);
    expect(commitStore.entry?.name, item.name);
    expect(commitStore.entry?.userId, 'user-1');
    expect(commitStore.entry?.mealType, MealType.lunch);
    expect(commitStore.entry?.consumedAmount, 250);
    expect(commitStore.entry?.consumedUnit, ConsumedUnit.grams);
    expect(
      container
          .read(inventoryItemsControllerProvider.notifier)
          .hasPendingConsumption(pendingConsumption.id),
      isFalse,
    );
    expect(
      container.read(inventoryItemsControllerProvider).value?.single.quantity,
      1,
    );
    expect(commitStore.entry?.sourceInventoryItemId, item.id);
  });
}
