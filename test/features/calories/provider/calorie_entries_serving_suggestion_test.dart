import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_entry_post_persist_hook.dart';
import 'package:yamt/features/inventory/application/'
    'global_food_serving_suggestion_repository.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_calorie_entry_post_persist_hook.dart';
import 'package:yamt/features/inventory/domain/global_food_serving_suggestion.dart';

import '../support/fake_calories_repositories.dart';

class _FakeGlobalFoodServingSuggestionRepository
    implements GlobalFoodServingSuggestionRepository {
  final List<
    ({
      String foodFingerprint,
      String? globalFoodItemId,
      double amount,
      ConsumedUnit unit,
      DateTime selectedAt,
      String? label,
    })
  >
  calls =
      <
        ({
          String foodFingerprint,
          String? globalFoodItemId,
          double amount,
          ConsumedUnit unit,
          DateTime selectedAt,
          String? label,
        })
      >[];

  @override
  Future<GlobalFoodServingSuggestionSet> readSuggestions({
    required String foodFingerprint,
    String? globalFoodItemId,
    int limit = 5,
  }) async {
    return const GlobalFoodServingSuggestionSet.empty();
  }

  @override
  Future<void> recordSelection({
    required String foodFingerprint,
    required double amount,
    required ConsumedUnit unit,
    required DateTime selectedAt,
    String? globalFoodItemId,
    String? label,
  }) async {
    calls.add((
      foodFingerprint: foodFingerprint,
      globalFoodItemId: globalFoodItemId,
      amount: amount,
      unit: unit,
      selectedAt: selectedAt,
      label: label,
    ));
  }
}

CalorieEntry _entry({double consumedAmount = 35}) {
  final now = DateTime.parse('2026-04-12T10:00:00.000Z');
  return CalorieEntry.create(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Cheese',
    mealType: MealType.lunch,
    consumedAmount: consumedAmount,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 320,
    per100Protein: 24,
    per100Carbs: 0,
    per100Fat: 26,
    loggedAt: now,
    createdAt: now,
    updatedAt: now,
  );
}

const _inventoryContext = CalorieInventoryCreateContext(
  inventoryItemId: 'inventory-1',
  foodFingerprint: 'cheese__brand',
  globalFoodItemId: 'off-cheese',
  pendingConsumptionId: 'pending-1',
  inventoryAmountToRestore: 1,
  itemName: 'Cheese',
  itemBrand: 'Brand',
  consumedAmount: 35,
  consumedUnit: ConsumedUnit.grams,
);

void main() {
  test(
    'saveEntry records serving suggestion after a successful save',
    () async {
      final logRepository = FakeCalorieLogRepository();
      final servingRepository = _FakeGlobalFoodServingSuggestionRepository();
      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
          calorieEntryPostPersistHookProvider.overrideWith(
            (ref) =>
                ({
                  required entry,
                  inventoryContext,
                  scannedSourceRef,
                }) async {
                  if (inventoryContext == null) {
                    return;
                  }
                  await servingRepository.recordSelection(
                    foodFingerprint: inventoryContext.foodFingerprint,
                    globalFoodItemId: inventoryContext.globalFoodItemId,
                    amount: entry.consumedAmount,
                    unit: entry.consumedUnit,
                    selectedAt: entry.updatedAt,
                  );
                },
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(logRepository.dispose);

      await container.read(calorieEntriesControllerProvider.future);
      final saved = await container
          .read(calorieEntriesControllerProvider.notifier)
          .saveEntry(_entry(), inventoryContext: _inventoryContext);

      expect(saved, isTrue);
      expect(servingRepository.calls, hasLength(1));
      expect(servingRepository.calls.single.foodFingerprint, 'cheese__brand');
      expect(servingRepository.calls.single.globalFoodItemId, 'off-cheese');
      expect(servingRepository.calls.single.amount, 35);
      expect(servingRepository.calls.single.unit, ConsumedUnit.grams);
      expect(servingRepository.calls.single.label, isNull);
    },
  );

  test('inventory post-persist hook learns base portion with label', () async {
    final servingRepository = _FakeGlobalFoodServingSuggestionRepository();
    final container = ProviderContainer(
      overrides: [
        globalFoodServingSuggestionRepositoryProvider.overrideWithValue(
          servingRepository,
        ),
      ],
    );
    addTearDown(container.dispose);

    final hook = container.read(inventoryCalorieEntryPostPersistHookProvider);
    await hook(
      entry: _entry(consumedAmount: 75),
      inventoryContext: const CalorieInventoryCreateContext(
        inventoryItemId: 'inventory-1',
        foodFingerprint: 'cheese__brand',
        globalFoodItemId: 'off-cheese',
        pendingConsumptionId: 'pending-1',
        inventoryAmountToRestore: 75,
        itemName: 'Cheese',
        itemBrand: 'Brand',
        consumedAmount: 75,
        consumedUnit: ConsumedUnit.grams,
        portionBaseAmount: 25,
        portionBaseUnit: ConsumedUnit.grams,
        portionCount: 3,
        portionLabel: 'Scheibe',
      ),
    );

    expect(servingRepository.calls, hasLength(1));
    expect(servingRepository.calls.single.amount, 25);
    expect(servingRepository.calls.single.unit, ConsumedUnit.grams);
    expect(servingRepository.calls.single.label, 'Scheibe');
  });

  test('saveEntry skips serving suggestion learning when save fails', () async {
    final logRepository = FakeCalorieLogRepository()..saveShouldFail = true;
    final servingRepository = _FakeGlobalFoodServingSuggestionRepository();
    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieEntryPostPersistHookProvider.overrideWith(
          (ref) =>
              ({
                required entry,
                inventoryContext,
                scannedSourceRef,
              }) async {
                if (inventoryContext == null) {
                  return;
                }
                await servingRepository.recordSelection(
                  foodFingerprint: inventoryContext.foodFingerprint,
                  globalFoodItemId: inventoryContext.globalFoodItemId,
                  amount: entry.consumedAmount,
                  unit: entry.consumedUnit,
                  selectedAt: entry.updatedAt,
                );
              },
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(logRepository.dispose);

    await container.read(calorieEntriesControllerProvider.future);
    final saved = await container
        .read(calorieEntriesControllerProvider.notifier)
        .saveEntry(_entry(), inventoryContext: _inventoryContext);

    expect(saved, isFalse);
    expect(servingRepository.calls, isEmpty);
  });
}
