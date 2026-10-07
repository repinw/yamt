import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_shopping.dart';

CalorieEntry _plan(String id, {ConsumedUnit unit = ConsumedUnit.grams}) {
  final day = DateTime(2026, 10, 8, 8);
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: id,
    brand: 'Brand',
    mealType: MealType.breakfast,
    consumedAmount: 400,
    consumedUnit: unit,
    per100Kcal: 100,
    per100Protein: 1,
    per100Carbs: 1,
    per100Fat: 1,
    sourceInventoryItemId: 'item',
    loggedAt: day,
    createdAt: day,
    updatedAt: day,
  );
}

void main() {
  test('a short plan needs the part that no stock covers', () {
    final needs = inventoryShoppingPlanNeeds(
      [
        _plan('covered'),
        _plan('half'),
        _plan('milk', unit: ConsumedUnit.milliliters),
      ],
      {'half': 0.5, 'milk': 1},
    );

    expect(needs.map((need) => need.name), ['half', 'milk']);
    expect(needs.first.amount, 200);
    expect(needs.first.isPartial, isTrue);
    expect(needs.first.inMilliliters, isFalse);
    expect(needs.first.brand, 'Brand');
    expect(needs.last.amount, 400);
    expect(needs.last.isPartial, isFalse);
    expect(needs.last.inMilliliters, isTrue);
  });
}
