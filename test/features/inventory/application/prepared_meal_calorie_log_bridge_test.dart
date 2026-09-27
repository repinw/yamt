import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
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

      final saved = await _consume(
        container.read(preparedMealCalorieLogBridgeProvider),
        meal: meal,
        consumedPortions: 1,
        mealType: MealType.lunch,
      );

      expect(saved, isNotNull);
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

  test('buildConsumedPreparedMealCalorieEntry scales fractional portions', () {
    final rice = _item(id: 'rice', name: 'Rice');
    final meal = PreparedMeal(
      id: 'meal-1',
      name: 'Rice',
      totalPortions: 4,
      remainingPortions: 4,
      totalKcal: 400,
      totalProtein: 20,
      totalCarbs: 40,
      totalFat: 10,
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
          totalKcal: 400,
          totalProtein: 20,
          totalCarbs: 40,
          totalFat: 10,
          sourceItemSnapshot: rice,
        ),
      ],
    );

    final entry = buildConsumedPreparedMealCalorieEntry(
      meal: meal,
      consumedPortions: 0.5,
      mealType: MealType.lunch,
      now: () => DateTime(2026, 3, 27, 13),
      nextEntryId: () => 'entry-1',
    );

    expect(entry, isNotNull);
    expect(entry!.bundleConsumedPortions, 0.5);
    expect(entry.totalKcal, 50);
    expect(entry.bundleComponents.single.amountLabel, '25 g');
    // Without an own meal image the diary shows the first food's image.
    expect(entry.imageUrl, rice.imageUrl);
  });

  test(
    'buildConsumedPreparedMealCalorieEntry shows a piece amount label in '
    'pieces, not thousandths',
    () {
      final eggs = InventoryItem.create(
        id: 'eggs',
        name: 'Eggs',
        entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
        storeName: 'Store',
        quantity: 8,
        initialAmount: 8000,
        currentAmount: 8000,
        amountScale: inventoryPieceAmountScale,
        amountUnit: InventoryAmountUnit.piece,
      );
      final meal = PreparedMeal(
        id: 'meal-eggs',
        name: 'Omelette',
        totalPortions: 1,
        remainingPortions: 1,
        totalKcal: 620,
        totalProtein: 52,
        totalCarbs: 4,
        totalFat: 44,
        createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
        updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
        components: [
          PreparedMealComponent(
            inventoryItemId: eggs.id,
            name: eggs.name,
            brand: eggs.brand,
            imageUrl: eggs.imageUrl,
            usedAmount: 8000,
            usedUnit: InventoryAmountUnit.piece,
            totalKcal: 620,
            totalProtein: 52,
            totalCarbs: 4,
            totalFat: 44,
            sourceItemSnapshot: eggs,
          ),
        ],
      );

      final entry = buildConsumedPreparedMealCalorieEntry(
        meal: meal,
        consumedPortions: 0.5,
        mealType: MealType.lunch,
        now: () => DateTime(2026, 3, 27, 13),
        nextEntryId: () => 'entry-eggs',
      );

      expect(entry, isNotNull);
      expect(entry!.bundleComponents.single.amountLabel, '4 pc');
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

    final saved = await _consume(
      bridge,
      meal: meal,
      consumedPortions: 1,
      mealType: MealType.dinner,
    );

    expect(saved, isNotNull);
    final entry = calorieLogRepository.entries.single;
    expect(entry.imageAssetId, meal.imageAssetId);
  });

  test(
    'bridge still saves after unused calorie providers were disposed',
    () async {
      final calorieLogRepository = FakeCalorieLogRepository();
      addTearDown(calorieLogRepository.dispose);
      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
        ],
      );
      addTearDown(container.dispose);
      final meal = PreparedMeal(
        id: 'meal-3',
        name: 'Milk + Oats',
        totalPortions: 1,
        remainingPortions: 1,
        totalKcal: 314,
        totalProtein: 13,
        totalCarbs: 43,
        totalFat: 10,
        createdAt: DateTime.parse('2026-09-26T12:00:00Z'),
        updatedAt: DateTime.parse('2026-09-26T12:00:00Z'),
        components: const <PreparedMealComponent>[],
      );

      // Nothing listens, so auto-dispose providers read while building the
      // bridge are gone before the save.
      final bridge = container.read(preparedMealCalorieLogBridgeProvider);
      await pumpEventQueue();

      final saved = await _consume(
        bridge,
        meal: meal,
        consumedPortions: 1,
        mealType: MealType.breakfast,
      );

      expect(saved, isNotNull);
      expect(calorieLogRepository.entries.single.name, 'Milk + Oats');
    },
  );

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

    final saved = await _consume(
      bridge,
      meal: meal,
      consumedPortions: 1,
      mealType: MealType.dinner,
      loggedDay: DateTime(2026, 3, 30),
    );

    expect(saved, isNotNull);
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

    expect(saved, isNull);
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

    expect(saved, isNull);
    expect(saveCalls, hasLength(2));
    expect(saveCalls.first.previousMeals.single.remainingPortions, 2);
    expect(saveCalls.first.nextMeals.single.remainingPortions, 1);
    expect(saveCalls.last.previousMeals.single.remainingPortions, 1);
    expect(saveCalls.last.nextMeals.single.remainingPortions, 2);
  });
}

Future<CalorieEntry?> _consume(
  PreparedMealCalorieLogBridge bridge, {
  required PreparedMeal meal,
  required num consumedPortions,
  required MealType mealType,
  DateTime? loggedDay,
}) {
  return bridge.consumePreparedMeal(
    currentMeals: [meal],
    nextMeals: [meal],
    meal: meal,
    consumedPortions: consumedPortions,
    mealType: mealType,
    loggedDay: loggedDay,
    publishMeals: (_) {},
    saveMeals: (_, _) async => true,
  );
}
