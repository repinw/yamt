import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/diary/application/diary_plan_ingredients_provider.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

final _now = DateTime(2026, 10, 26, 9);

final InventoryItem _waffles = InventoryItem.create(
  id: 'waffles',
  name: 'Reiswaffeln',
  brand: 'Kölln',
  entryDate: DateTime(2026, 9),
  storeName: 'Rewe',
  quantity: 1,
  initialAmount: 500,
  currentAmount: 500,
  amountUnit: InventoryAmountUnit.gram,
);

CalorieEntryBundleComponent _food(String amount, double kcal) =>
    CalorieEntryBundleComponent(
      name: 'Reiswaffeln',
      brand: 'Kölln',
      amountLabel: amount,
      totalKcal: kcal,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
    );

CalorieEntry _plan(List<CalorieEntryBundleComponent> foods) =>
    CalorieEntry.bundle(
      id: 'plan',
      userId: 'user-1',
      name: 'Reis-Bowl',
      mealType: MealType.dinner,
      totalKcal: 266,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
      bundleSourcePreparedMealId: 'bowl',
      bundleConsumedPortions: 1,
      bundleTotalPortions: 1,
      bundleComponents: foods,
      loggedAt: _now,
      createdAt: _now,
      updatedAt: _now,
    );

void main() {
  test('two lines of one item each take their own food', () {
    final (:lines, :others) = diaryPlanIngredientLines(
      _plan([_food('50 g', 190), _food('20 g', 76)]),
      [
        (ingredient: '50 g Reis', items: [_waffles], candidates: [_waffles]),
        (ingredient: '20 g Reis', items: [_waffles], candidates: [_waffles]),
        (ingredient: '2 Eier', items: const [], candidates: const []),
      ],
    );

    expect(
      [for (final line in lines) (line.amount, line.kcal)],
      [('50 g', 190), ('20 g', 76), (null, null)],
    );
    expect(others, isEmpty);
  });

  test('a food no line takes now stays below the lines', () {
    // Counted with the waffles, which are used up since; the line takes
    // rice now.
    final rice = InventoryItem.create(
      id: 'rice',
      name: 'Reis',
      entryDate: DateTime(2026, 9),
      storeName: 'Rewe',
      quantity: 1,
      initialAmount: 500,
      currentAmount: 500,
      amountUnit: InventoryAmountUnit.gram,
    );

    final (:lines, :others) = diaryPlanIngredientLines(
      _plan([_food('50 g', 190)]),
      [
        (ingredient: '50 g Reis', items: [rice], candidates: [rice]),
      ],
    );

    expect(lines.single.items, 'Reis');
    expect(lines.single.kcal, isNull);
    expect(others, [(name: 'Reiswaffeln', amount: '50 g', kcal: 190.0)]);
  });
}
