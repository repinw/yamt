import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_demand.dart';

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

void main() {
  test('the earlier plan gets the stock, the later one falls short', () {
    final demand = inventoryPlanDemand(
      [
        _plan('later', day: 9, grams: 300),
        _plan('earlier', day: 8, grams: 300),
      ],
      [_pack('oats')],
    );

    expect(demand.plannedByItemId, {'oats': 500});
    expect(demand.shortPlanIds, {'later'});
  });

  test('a plan takes from one pack, as accepting does', () {
    final demand = inventoryPlanDemand(
      [_plan('first', day: 8, grams: 300), _plan('second', day: 9, grams: 100)],
      [
        _pack('full', entryDate: DateTime(2026, 8)),
        _pack('opened', currentAmount: 200),
      ],
    );

    // The opened pack covers only part of the first plan; the second plan
    // takes the next pack once the opened one is empty.
    expect(demand.plannedByItemId, {'opened': 200, 'full': 100});
    expect(demand.shortPlanIds, {'first'});
  });

  test('a plan without stock falls short; a found food counts nowhere', () {
    final demand = inventoryPlanDemand([
      _plan('vorrat', day: 8, grams: 100),
      _plan('found', day: 8, grams: 100, itemId: null),
    ], const []);

    expect(demand.plannedByItemId, isEmpty);
    expect(demand.shortPlanIds, {'vorrat'});
  });
}
