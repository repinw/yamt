import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_demand.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';

const _nutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 400,
  per100Protein: 10,
  per100Carbs: 60,
  per100Fat: 12,
);

CalorieEntry _plan(
  String id, {
  required int day,
  required double grams,
  String? itemId = 'gone',
}) {
  final loggedAt = DateTime(2026, 10, day, 8);
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Oats',
    brand: 'Kölln',
    mealType: MealType.breakfast,
    consumedAmount: grams,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 400,
    per100Protein: 10,
    per100Carbs: 60,
    per100Fat: 12,
    sourceInventoryItemId: itemId,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

InventoryItem _pack(
  String id, {
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

PreparedMeal _meal({num remaining = 3}) => PreparedMeal(
  id: 'chili',
  name: 'Chili',
  totalPortions: 4,
  remainingPortions: remaining,
  totalKcal: 2000,
  totalProtein: 100,
  totalCarbs: 200,
  totalFat: 80,
  createdAt: DateTime(2026, 10),
  updatedAt: DateTime(2026, 10),
  components: const <PreparedMealComponent>[],
);

CalorieEntry _mealPlan(
  String id, {
  required int day,
  required int portions,
  int totalPortions = 4,
}) {
  final loggedAt = DateTime(2026, 10, day, 18);
  return CalorieEntry.bundle(
    id: id,
    userId: 'user-1',
    name: 'Chili',
    mealType: MealType.dinner,
    totalKcal: 500.0 * portions,
    totalProtein: 25,
    totalCarbs: 50,
    totalFat: 20,
    bundleSourcePreparedMealId: 'chili',
    bundleConsumedPortions: portions,
    bundleTotalPortions: totalPortions,
    bundleComponents: const [],
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

void main() {
  test('the earlier plan gets the stock, the later one falls short', () {
    final demand = inventoryPlanDemand(
      [
        _plan('later', day: 9, grams: 300),
        _plan('earlier', day: 8, grams: 300),
      ],
      [_pack('oats')],
      const [],
    );

    expect(demand.plannedByItemId, {'oats': 500});
    expect(demand.missingShareByPlanId.keys, ['later']);
  });

  test('a plan takes from one pack, as accepting does', () {
    final demand = inventoryPlanDemand(
      [_plan('first', day: 8, grams: 300), _plan('second', day: 9, grams: 100)],
      [
        _pack('full', entryDate: DateTime(2026, 8)),
        _pack('opened', currentAmount: 200),
      ],
      const [],
    );

    // The opened pack covers only part of the first plan; the second plan
    // takes the next pack once the opened one is empty.
    expect(demand.plannedByItemId, {'opened': 200, 'full': 100});
    expect(demand.missingShareByPlanId, {'first': 1 / 3});
  });

  test('a plan without stock falls short; a found food counts nowhere', () {
    final demand = inventoryPlanDemand(
      [
        _plan('vorrat', day: 8, grams: 100),
        _plan('found', day: 8, grams: 100, itemId: null),
      ],
      const [],
      const [],
    );

    expect(demand.plannedByItemId, isEmpty);
    expect(demand.missingShareByPlanId, {'vorrat': 1});
  });

  test('plans take portions of a cooked meal; the later one falls short', () {
    final demand = inventoryPlanDemand(
      [
        _mealPlan('later', day: 9, portions: 2),
        _mealPlan('earlier', day: 8, portions: 2),
      ],
      const [],
      [_meal()],
    );

    expect(demand.plannedPortionsByMealId, {'chili': 3});
    expect(demand.missingShareByPlanId, {'later': 0.5});
    expect(demand.plannedByItemId, isEmpty);
  });

  test('a meal plan made in the pot takes its share of the portions now', () {
    // Planned as the whole pot, which was one portion then.
    final demand = inventoryPlanDemand(
      [_mealPlan('pot', day: 8, portions: 1, totalPortions: 1)],
      const [],
      [_meal(remaining: 4)],
    );

    expect(demand.plannedPortionsByMealId, {'chili': 4});
    expect(demand.missingShareByPlanId, isEmpty);
  });

  test('plans of a meal portioned anew add up without a rounding rest', () {
    // Planned when the meal had 3 portions; it now has 5, all left.
    final demand = inventoryPlanDemand(
      [
        for (var day = 8; day < 11; day++)
          _mealPlan('day$day', day: day, portions: 1, totalPortions: 3),
      ],
      const [],
      [
        PreparedMeal(
          id: 'chili',
          name: 'Chili',
          totalPortions: 5,
          remainingPortions: 5,
          totalKcal: 2000,
          totalProtein: 100,
          totalCarbs: 200,
          totalFat: 80,
          createdAt: DateTime(2026, 10),
          updatedAt: DateTime(2026, 10),
          components: const <PreparedMealComponent>[],
        ),
      ],
    );

    expect(demand.missingShareByPlanId, isEmpty);
  });

  test('a plan of a meal that is gone falls short', () {
    final demand = inventoryPlanDemand(
      [_mealPlan('gone', day: 8, portions: 1)],
      const [],
      const [],
    );

    expect(demand.plannedPortionsByMealId, isEmpty);
    expect(demand.missingShareByPlanId, {'gone': 1});
  });
}
