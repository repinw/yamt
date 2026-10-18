import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_demand.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_pack.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_plan_need.dart';

/// What to buy for [plans]: one need for each plan the [demand] finds short,
/// with the part of its amount that no stock covers, in plan order. A recipe
/// plan needs each missing ingredient instead. A short plan of a cooked meal
/// needs cooking, not shopping, so it is left out.
// shortcut: an ingredient counted in whole packs, or in pieces without a
// serving size, has no grams and is left out; show packs when users miss it.
List<ShoppingPlanNeed> inventoryShoppingPlanNeeds(
  List<CalorieEntry> plans,
  InventoryPlanDemand demand,
  List<InventoryItem> items,
) {
  final itemsById = {for (final item in items) item.id: item};
  return [
    for (final plan in plans)
      if (demand.missingIngredientsByPlanId[plan.id] case final ingredients?)
        ..._ingredientNeeds(plan, ingredients, itemsById)
      else if (plan.bundleSourcePreparedMealId == null)
        if (demand.missingShareByPlanId[plan.id] case final share?)
          ShoppingPlanNeed(
            name: plan.name,
            brand: plan.brand,
            day: plan.loggedAt,
            mealType: plan.mealType,
            amount: plan.consumedAmount * share,
            inMilliliters: plan.consumedUnit == ConsumedUnit.milliliters,
            isPartial: share < 1,
          ),
  ];
}

/// The missing ingredients of the recipe [plan], [missingByItemId] in each
/// item's stored unit.
Iterable<ShoppingPlanNeed> _ingredientNeeds(
  CalorieEntry plan,
  Map<String, int> missingByItemId,
  Map<String, InventoryItem> itemsById,
) sync* {
  for (final MapEntry(key: itemId, value: missing) in missingByItemId.entries) {
    final item = itemsById[itemId];
    final stock = item == null
        ? null
        : inventoryStockInConsumedUnit(item, missing);
    if (stock != null) {
      yield ShoppingPlanNeed(
        name: item!.name,
        brand: item.brand,
        day: plan.loggedAt,
        mealType: plan.mealType,
        amount: stock.amount,
        inMilliliters: stock.unit == ConsumedUnit.milliliters,
        isPartial: true,
      );
    }
  }
}
