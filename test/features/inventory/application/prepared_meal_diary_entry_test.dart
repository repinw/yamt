import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_diary_entry.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';

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
  test('a meal entry has precise portion snapshots', () {
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

    final entry = buildConsumedPreparedMealCalorieEntry(
      meal: meal,
      consumedPortions: 1,
      mealType: MealType.lunch,
      now: () => DateTime(2026, 3, 27, 13),
      nextEntryId: () => 'entry-1',
    )!;

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
  });

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

  test('buildConsumedPreparedMealCalorieEntry shows a piece amount label in '
      'pieces, not thousandths', () {
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
  });

  test('a meal entry takes the picked day and the current time', () {
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

    final entry = buildConsumedPreparedMealCalorieEntry(
      meal: meal,
      consumedPortions: 1,
      mealType: MealType.dinner,
      now: () => DateTime(2026, 4, 2, 18, 45, 30),
      nextEntryId: () => 'entry-1',
      loggedDay: DateTime(2026, 3, 30),
    )!;
    expect(normalizeDiaryDay(entry.loggedAt), DateTime(2026, 3, 30));
    expect(entry.loggedAt.hour, 18);
    expect(entry.loggedAt.minute, 45);
    expect(entry.createdAt, DateTime(2026, 4, 2, 18, 45, 30));
  });

  test('a plan with other portions keeps its id, user, day and meal', () {
    final meal = PreparedMeal(
      id: 'chili',
      name: 'Chili',
      totalPortions: 3,
      remainingPortions: 3,
      totalKcal: 600,
      totalProtein: 30,
      totalCarbs: 60,
      totalFat: 15,
      createdAt: DateTime(2026, 10, 5),
      updatedAt: DateTime(2026, 10, 5),
      components: const [],
    );
    final plan = buildConsumedPreparedMealCalorieEntry(
      meal: meal,
      consumedPortions: 1,
      mealType: MealType.dinner,
      now: () => DateTime(2026, 10, 5, 12),
      nextEntryId: () => 'meal-plan',
      loggedDay: DateTime(2026, 10, 6),
    )!.copyWith(userId: 'user-1');

    final resized = preparedMealPlanWithPortions(
      plan,
      meal,
      2,
      now: () => DateTime(2026, 10, 5, 13),
    );

    expect(resized?.id, plan.id);
    expect(resized?.userId, 'user-1');
    expect(resized?.loggedAt, plan.loggedAt);
    expect(resized?.createdAt, plan.createdAt);
    expect(resized?.mealType, MealType.dinner);
    expect(resized?.bundleConsumedPortions, 2);
    expect(resized?.totalKcal, 400);
  });
}
