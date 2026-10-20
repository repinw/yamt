import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_demand.dart';
import 'package:yamt/features/inventory/domain/plan_reservation.dart';
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
    expect(demand.missingByItemId, {'oats': 100});
  });

  test('a plan after the stock ran out counts as missing in full', () {
    final demand = inventoryPlanDemand(
      [
        _plan('first', day: 8, grams: 300),
        _plan('second', day: 9, grams: 300),
        _plan('third', day: 10, grams: 300),
      ],
      [_pack('oats')],
      const [],
    );

    expect(demand.plannedByItemId, {'oats': 500});
    expect(demand.missingByItemId, {'oats': 400});
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
    expect(demand.missingByItemId, {'opened': 100});
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

  test('a recipe plan takes its ingredients from their packs', () {
    final first = _plan('recipe-1', day: 10, grams: 300, itemId: null);
    final second = _plan('recipe-2', day: 11, grams: 300, itemId: null);

    final demand = inventoryPlanDemand(
      [second, first],
      [_pack('oats', currentAmount: 300), _pack('milk', currentAmount: 0)],
      const [],
      ingredientNeedsByPlanId: {
        'recipe-1': {'oats': 200},
        'recipe-2': {'oats': 200, 'milk': 100},
      },
    );

    expect(demand.plannedByItemId, {'oats': 300});
    expect(demand.missingByItemId, {'oats': 100, 'milk': 100});
    expect(demand.missingShareByPlanId, {'recipe-2': 1.0});
    expect(demand.missingIngredientsByPlanId, {
      'recipe-2': {'oats': 100, 'milk': 100},
    });
  });

  test('a recipe ingredient without a Vorrat item leaves the plan short', () {
    final plan = _plan('recipe', day: 10, grams: 300, itemId: null);
    const eggs = (name: 'Eier', amount: null, inMilliliters: false);

    final demand = inventoryPlanDemand(
      [plan],
      [_pack('oats')],
      const [],
      ingredientNeedsByPlanId: {
        'recipe': {'oats': 100},
      },
      unstockedIngredientsByPlanId: {
        'recipe': [eggs],
      },
    );

    expect(demand.plannedByItemId, {'oats': 100});
    expect(demand.missingShareByPlanId, {'recipe': 1.0});
    expect(demand.missingIngredientsByPlanId, isEmpty);
    expect(demand.unstockedIngredientsByPlanId, {
      'recipe': [eggs],
    });
  });

  group('household', () {
    MemberPlanReservation other(
      String uid,
      String stockId,
      double amount, {
      required int day,
    }) => (
      uid: uid,
      reservation: (
        stockId: stockId,
        amount: amount,
        at: DateTime(2026, 10, day, 12),
      ),
    );

    test('lists what the own plans want from each pack and meal', () {
      final demand = inventoryPlanDemand(
        [
          _plan('oats', day: 8, grams: 300, itemId: 'pack'),
          _mealPlan('chili', day: 9, portions: 2),
        ],
        [_pack('pack')],
        [_meal()],
      );

      expect(demand.ownReservations, [
        (stockId: 'pack', amount: 300.0, at: DateTime(2026, 10, 8, 8)),
        (stockId: 'chili', amount: 2.0, at: DateTime(2026, 10, 9, 18)),
      ]);
      expect(demand.othersByStockId, isEmpty);
    });

    test('an earlier plan of another member takes the stock first', () {
      final demand = inventoryPlanDemand(
        [_plan('mine', day: 9, grams: 300, itemId: 'pack')],
        [_pack('pack')],
        [_meal()],
        othersReservations: [
          other('anna', 'pack', 400, day: 8),
          other('ben', 'chili', 1, day: 10),
        ],
      );

      expect(demand.plannedByItemId, {'pack': 500});
      expect(demand.missingShareByPlanId['mine'], closeTo(2 / 3, 1e-9));
      expect(demand.plannedPortionsByMealId, {'chili': 1.0});
      expect(demand.othersByStockId, {
        'pack': [(uid: 'anna', day: DateTime(2026, 10, 8))],
        'chili': [(uid: 'ben', day: DateTime(2026, 10, 10))],
      });
      // The own plan still wants its full amount.
      expect(demand.ownReservations.single.amount, 300);
    });

    test('at the same time the smaller uid comes first on every device', () {
      final mine = _plan(
        'mine',
        day: 8,
        grams: 300,
        itemId: 'pack',
      ).copyWith(loggedAt: DateTime(2026, 10, 8, 12));
      final pack = _pack('pack', currentAmount: 300);

      final asAnna = inventoryPlanDemand(
        [mine],
        [pack],
        const [],
        othersReservations: [other('ben', 'pack', 300, day: 8)],
        ownUid: 'anna',
      );
      final asBen = inventoryPlanDemand(
        [mine],
        [pack],
        const [],
        othersReservations: [other('anna', 'pack', 300, day: 8)],
        ownUid: 'ben',
      );

      expect(asAnna.missingShareByPlanId, isEmpty);
      expect(asBen.missingShareByPlanId, {'mine': 1.0});
    });

    test('a later plan of another member gets what is left', () {
      final demand = inventoryPlanDemand(
        [_plan('mine', day: 8, grams: 300, itemId: 'pack')],
        [_pack('pack')],
        const [],
        othersReservations: [
          other('anna', 'pack', 400, day: 9),
          other('anna', 'pack', 100, day: 10),
          other('anna', 'gone', 100, day: 9),
        ],
      );

      expect(demand.plannedByItemId, {'pack': 500});
      expect(demand.missingShareByPlanId, isEmpty);
      // Nothing left for the plan on the 10th; a used-up pack names nobody.
      expect(demand.othersByStockId, {
        'pack': [(uid: 'anna', day: DateTime(2026, 10, 9))],
      });
    });
  });
}
