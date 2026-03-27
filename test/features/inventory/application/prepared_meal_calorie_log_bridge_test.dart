import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/features/calories/data/calorie_entry_image_ref.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_calorie_log_bridge.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_refs.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

import '../../calories/support/fake_calories_repositories.dart';
import '../../../support/fake_local_image_store.dart';

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
      final localImageStore = FakeLocalImageStore();
      addTearDown(calorieLogRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          localImageStoreProvider.overrideWithValue(localImageStore),
          calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
        ],
      );
      addTearDown(container.dispose);

      final rice = _item(id: 'rice', name: 'Rice');
      final beans = _item(id: 'beans', name: 'Beans');
      final meal = PreparedMeal(
        id: 'meal-1',
        name: 'Chili',
        imageBase64: base64Encode(<int>[1, 2, 3]),
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
      await localImageStore.saveBytes(
        imageRef: preparedMealImageRef('meal-1'),
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
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
      expect(entry.imageBase64, meal.imageBase64);
      expect(
        await localImageStore.readBytes(calorieEntryImageRef(entry.id)),
        isNotNull,
      );
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

  test(
    'bridge still copies diary images after provider invalidation',
    () async {
      final calorieLogRepository = FakeCalorieLogRepository();
      final localImageStore = FakeLocalImageStore();
      addTearDown(calorieLogRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          localImageStoreProvider.overrideWithValue(localImageStore),
          calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
        ],
      );
      addTearDown(container.dispose);

      final meal = PreparedMeal(
        id: 'meal-2',
        name: 'Soup',
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
      await localImageStore.saveBytes(
        imageRef: preparedMealImageRef(meal.id),
        bytes: Uint8List.fromList(<int>[9, 8, 7]),
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
      expect(
        await localImageStore.readBytes(calorieEntryImageRef(entry.id)),
        Uint8List.fromList(<int>[9, 8, 7]),
      );
    },
  );
}
