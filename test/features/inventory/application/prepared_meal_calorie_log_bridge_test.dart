import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_calorie_log_bridge.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

import '../../calories/support/fake_calories_repositories.dart';

InventoryItem _item({required String id, required String name}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    initialAmount: 300,
    currentAmount: 300,
    amountUnit: InventoryAmountUnit.gram,
    imageUrl: 'https://example.com/$id.png',
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 200,
      per100Protein: 10,
      per100Carbs: 20,
      per100Fat: 5,
    ),
  );
}

void main() {
  test(
    'bridge writes prepared meal bundles with precise portion snapshots',
    () async {
      final calorieLogRepository = FakeCalorieLogRepository();
      addTearDown(calorieLogRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
        ],
      );
      addTearDown(container.dispose);

      final rice = _item(id: 'rice', name: 'Rice');
      final beans = _item(id: 'beans', name: 'Beans');
      final meal = PreparedMeal(
        id: 'meal-1',
        name: 'Chili',
        imageAssetId: 'asset-1',
        totalPortions: 3,
        remainingPortions: 3,
        totalKcal: 510,
        totalProtein: 33,
        totalCarbs: 66,
        totalFat: 12,
        createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
        updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
        components: [
          PreparedMealComponent(
            inventoryItemId: rice.id,
            name: rice.name,
            brand: rice.brand,
            imageUrl: rice.imageUrl,
            usedAmount: 200,
            usedUnit: InventoryAmountUnit.gram,
            totalKcal: 300,
            totalProtein: 18,
            totalCarbs: 40,
            totalFat: 4,
            sourceItemSnapshot: rice,
          ),
          PreparedMealComponent(
            inventoryItemId: beans.id,
            name: beans.name,
            brand: beans.brand,
            imageUrl: beans.imageUrl,
            usedAmount: 100,
            usedUnit: InventoryAmountUnit.gram,
            totalKcal: 210,
            totalProtein: 15,
            totalCarbs: 26,
            totalFat: 8,
            sourceItemSnapshot: beans,
          ),
        ],
      );

      final saved = await container
          .read(preparedMealCalorieLogBridgeProvider)
          .logConsumedPreparedMeal(
            meal: meal,
            consumedPortions: 1,
            mealType: MealType.lunch,
          );

      expect(saved, isTrue);
      expect(calorieLogRepository.entries, hasLength(1));

      final entry = calorieLogRepository.entries.single;
      expect(entry.isBundle, isTrue);
      expect(entry.imageAssetId, meal.imageAssetId);
      expect(entry.bundleConsumedPortions, 1);
      expect(entry.bundleTotalPortions, 3);
      expect(entry.totalKcal, closeTo(170, 0.0001));
      expect(entry.totalProtein, closeTo(11, 0.0001));
      expect(entry.totalCarbs, closeTo(22, 0.0001));
      expect(entry.totalFat, closeTo(4, 0.0001));
      expect(entry.bundleComponents, hasLength(2));
      expect(entry.bundleComponents.first.amountLabel, '66.7 g');
      expect(entry.bundleComponents.first.totalKcal, closeTo(100, 0.0001));
      expect(entry.bundleComponents.last.amountLabel, '33.3 g');
      expect(entry.bundleComponents.last.totalProtein, closeTo(5, 0.0001));
    },
  );

  test('bridge still saves after provider invalidation', () async {
    final calorieLogRepository = FakeCalorieLogRepository();
    addTearDown(calorieLogRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
      ],
    );
    addTearDown(container.dispose);

    final meal = PreparedMeal(
      id: 'meal-2',
      name: 'Soup',
      imageAssetId: 'asset-2',
      totalPortions: 2,
      remainingPortions: 2,
      totalKcal: 300,
      totalProtein: 20,
      totalCarbs: 30,
      totalFat: 10,
      createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
      updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
      components: const <PreparedMealComponent>[],
    );

    final bridge = container.read(preparedMealCalorieLogBridgeProvider);
    container.invalidate(preparedMealCalorieLogBridgeProvider);

    final saved = await bridge.logConsumedPreparedMeal(
      meal: meal,
      consumedPortions: 1,
      mealType: MealType.dinner,
    );

    expect(saved, isTrue);
    final entry = calorieLogRepository.entries.single;
    expect(entry.imageAssetId, meal.imageAssetId);
  });

  test('bridge writes selected diary day while keeping current time', () async {
    final savedEntries = <CalorieEntry>[];
    final bridge = PreparedMealCalorieLogBridge(
      saveEntry: (entry) async {
        savedEntries.add(entry);
        return true;
      },
      now: () => DateTime(2026, 4, 2, 18, 45, 30),
      nextEntryId: () => 'entry-bridge-test',
    );
    final meal = PreparedMeal(
      id: 'meal-3',
      name: 'Soup',
      imageAssetId: 'asset-3',
      totalPortions: 2,
      remainingPortions: 2,
      totalKcal: 300,
      totalProtein: 20,
      totalCarbs: 30,
      totalFat: 10,
      createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
      updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
      components: const <PreparedMealComponent>[],
    );

    final saved = await bridge.logConsumedPreparedMeal(
      meal: meal,
      consumedPortions: 1,
      mealType: MealType.dinner,
      loggedDay: DateTime(2026, 3, 30),
    );

    expect(saved, isTrue);
    final entry = savedEntries.single;
    expect(normalizeDiaryDay(entry.loggedAt), DateTime(2026, 3, 30));
    expect(entry.loggedAt.hour, 18);
    expect(entry.loggedAt.minute, 45);
    expect(entry.createdAt, DateTime(2026, 4, 2, 18, 45, 30));
  });

  test('bridge restores optimistic meals when atomic save fails', () async {
    final publishedMeals = <List<PreparedMeal>>[];
    var fallbackSaveCalled = false;
    var directSaveCalled = false;
    final meal = PreparedMeal(
      id: 'meal-4',
      name: 'Soup',
      imageAssetId: 'asset-4',
      totalPortions: 2,
      remainingPortions: 2,
      totalKcal: 300,
      totalProtein: 20,
      totalCarbs: 30,
      totalFat: 10,
      createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
      updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
      components: const <PreparedMealComponent>[],
    );
    final currentMeals = <PreparedMeal>[meal];
    final nextMeals = <PreparedMeal>[meal.copyWith(remainingPortions: 1)];
    final bridge = PreparedMealCalorieLogBridge(
      saveEntry: (_) async {
        directSaveCalled = true;
        return true;
      },
      saveEntryAtomically: (_) async => false,
      now: () => DateTime(2026, 4, 2, 18, 45, 30),
      nextEntryId: () => 'entry-atomic-failure',
    );

    final saved = await bridge.consumePreparedMeal(
      currentMeals: currentMeals,
      nextMeals: nextMeals,
      meal: meal,
      consumedPortions: 1,
      mealType: MealType.dinner,
      publishMeals: (meals) {
        publishedMeals.add(List<PreparedMeal>.from(meals));
      },
      saveMeals: (previousMeals, nextMeals) async {
        fallbackSaveCalled = true;
        return true;
      },
    );

    expect(saved, isFalse);
    expect(directSaveCalled, isFalse);
    expect(fallbackSaveCalled, isFalse);
    expect(
      publishedMeals.map((meals) => meals.single.remainingPortions).toList(),
      <int>[1, 2],
    );
  });

  test('bridge returns false after fallback calorie save rollback', () async {
    final saveCalls =
        <({List<PreparedMeal> previousMeals, List<PreparedMeal> nextMeals})>[];
    final meal = PreparedMeal(
      id: 'meal-5',
      name: 'Soup',
      imageAssetId: 'asset-5',
      totalPortions: 2,
      remainingPortions: 2,
      totalKcal: 300,
      totalProtein: 20,
      totalCarbs: 30,
      totalFat: 10,
      createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
      updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
      components: const <PreparedMealComponent>[],
    );
    final currentMeals = <PreparedMeal>[meal];
    final nextMeals = <PreparedMeal>[meal.copyWith(remainingPortions: 1)];
    final bridge = PreparedMealCalorieLogBridge(
      saveEntry: (_) async => false,
      now: () => DateTime(2026, 4, 2, 18, 45, 30),
      nextEntryId: () => 'entry-fallback-failure',
    );

    final saved = await bridge.consumePreparedMeal(
      currentMeals: currentMeals,
      nextMeals: nextMeals,
      meal: meal,
      consumedPortions: 1,
      mealType: MealType.dinner,
      publishMeals: (_) {},
      saveMeals: (previousMeals, nextMeals) async {
        saveCalls.add((
          previousMeals: List<PreparedMeal>.from(previousMeals),
          nextMeals: List<PreparedMeal>.from(nextMeals),
        ));
        return true;
      },
    );

    expect(saved, isFalse);
    expect(saveCalls, hasLength(2));
    expect(saveCalls.first.previousMeals.single.remainingPortions, 2);
    expect(saveCalls.first.nextMeals.single.remainingPortions, 1);
    expect(saveCalls.last.previousMeals.single.remainingPortions, 1);
    expect(saveCalls.last.nextMeals.single.remainingPortions, 2);
  });
}
