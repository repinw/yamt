import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_plan_need.dart';

/// What to buy for [plans]: one need for each plan in [missingShareByPlanId],
/// with the part of its amount that no stock covers, in plan order.
List<ShoppingPlanNeed> inventoryShoppingPlanNeeds(
  List<CalorieEntry> plans,
  Map<String, double> missingShareByPlanId,
) {
  return [
    for (final plan in plans)
      if (missingShareByPlanId[plan.id] case final share?)
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
