import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_pack.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';

/// A recipe ingredient without a Vorrat item: its name and, when the recipe
/// gives it in grams or milliliters, the amount a plan needs.
typedef PlanUnstockedIngredient = ({
  String name,
  double? amount,
  bool inMilliliters,
});

/// What open plans take from the Vorrat.
typedef InventoryPlanDemand = ({
  /// Stock each pack keeps for plans, by item id, in the pack's stored unit
  /// ("verplant").
  Map<String, int> plannedByItemId,

  /// Stock each pack lacks for the plans that take from it, by item id, in
  /// the pack's stored unit ("fehlen").
  Map<String, int> missingByItemId,

  /// Portions each cooked meal keeps for plans, by meal id ("verplant").
  Map<String, double> plannedPortionsByMealId,

  /// Plans the Vorrat cannot cover in full ("fehlt"): the share of each
  /// that no stock covers, from above 0 to 1, by plan id.
  Map<String, double> missingShareByPlanId,

  /// Stock each recipe plan lacks per ingredient, by plan id, then by item
  /// id, in the item's stored unit.
  Map<String, Map<String, int>> missingIngredientsByPlanId,

  /// The ingredients of each recipe plan that no Vorrat item stands for, by
  /// plan id; they are missing in full.
  Map<String, List<PlanUnstockedIngredient>> unstockedIngredientsByPlanId,
});

/// Walks [plans] by their day and takes each one's stock from [items] the
/// way accepting does: from the first pack of its food that still has stock
/// left once the earlier plans took theirs. A plan that this pack cannot
/// cover falls short, since accepting takes from one pack only.
///
/// A plan of a cooked meal takes its portions from [meals] the same way.
/// A plan of a Kochbuch recipe takes the amounts in
/// [ingredientNeedsByPlanId] (item id to amount) from those items; an
/// ingredient without an item, from [unstockedIngredientsByPlanId], names
/// no stock and leaves the plan missing in full.
///
/// A plan of a found food names no stock.
InventoryPlanDemand inventoryPlanDemand(
  List<CalorieEntry> plans,
  List<InventoryItem> items,
  List<PreparedMeal> meals, {
  Map<String, Map<String, int>> ingredientNeedsByPlanId = const {},
  Map<String, List<PlanUnstockedIngredient>> unstockedIngredientsByPlanId =
      const {},
}) {
  final left = {
    for (final item in items) item.id: consumableInventoryAmount(item) ?? 0,
  };
  final portionsLeft = {
    for (final meal in meals) meal.id: meal.remainingPortions.toDouble(),
  };
  final planned = <String, int>{};
  final missingStock = <String, int>{};
  final plannedPortions = <String, double>{};
  final missing = <String, double>{};
  final missingIngredients = <String, Map<String, int>>{};
  for (final plan in plans.sortedBy((plan) => plan.loggedAt)) {
    if (ingredientNeedsByPlanId[plan.id] case final needs?) {
      // Items count in different units, so the share is the largest one.
      var share = 0.0;
      final short = <String, int>{};
      for (final MapEntry(key: itemId, value: amount) in needs.entries) {
        final taken = math.min(amount, left[itemId] ?? 0);
        if (taken > 0) {
          left[itemId] = left[itemId]! - taken;
          planned.update(itemId, (sum) => sum + taken, ifAbsent: () => taken);
        }
        if (amount > taken) {
          share = math.max(share, (amount - taken) / amount);
          short[itemId] = amount - taken;
          missingStock.update(
            itemId,
            (sum) => sum + amount - taken,
            ifAbsent: () => amount - taken,
          );
        }
      }
      if (unstockedIngredientsByPlanId[plan.id]?.isNotEmpty ?? false) {
        share = 1;
      }
      if (share > 0) {
        missing[plan.id] = share;
      }
      if (short.isNotEmpty) {
        missingIngredients[plan.id] = short;
      }
      continue;
    }
    if (plan.bundleSourcePreparedMealId case final mealId?) {
      final meal = meals.firstWhereOrNull((meal) => meal.id == mealId);
      final wanted = meal == null
          ? 0.0
          : preparedMealPlanShare(plan, meal).toDouble();
      final taken = math.min(wanted, portionsLeft[mealId] ?? 0);
      if (taken > 0) {
        portionsLeft[mealId] = portionsLeft[mealId]! - taken;
        plannedPortions.update(
          mealId,
          (sum) => sum + taken,
          ifAbsent: () => taken,
        );
      }
      // Portions scaled by a new portioning are fractions; a rounding
      // rest is no shortfall.
      final short = wanted - taken;
      if (wanted <= 0) {
        missing[plan.id] = 1;
      } else if (short > 1e-9) {
        missing[plan.id] = short / wanted;
      }
      continue;
    }
    if (plan.sourceInventoryItemId == null) {
      continue;
    }
    final packs = inventoryPacksForPlan(plan, items);
    final pack = packs.firstWhereOrNull((pack) => left[pack.item.id]! > 0);
    if (pack == null) {
      missing[plan.id] = 1;
      // Its food is used up by earlier plans: the last pack it would take
      // from names the whole amount as missing.
      if (packs.lastOrNull case final last?) {
        missingStock.update(
          last.item.id,
          (sum) => sum + last.amount,
          ifAbsent: () => last.amount,
        );
      }
      continue;
    }
    final available = left[pack.item.id]!;
    final taken = math.min(pack.amount, available);
    left[pack.item.id] = available - taken;
    planned.update(pack.item.id, (sum) => sum + taken, ifAbsent: () => taken);
    if (taken < pack.amount) {
      final short = pack.amount - taken;
      missing[plan.id] = short / pack.amount;
      missingStock.update(
        pack.item.id,
        (sum) => sum + short,
        ifAbsent: () => short,
      );
    }
  }
  return (
    plannedByItemId: planned,
    missingByItemId: missingStock,
    plannedPortionsByMealId: plannedPortions,
    missingShareByPlanId: missing,
    missingIngredientsByPlanId: missingIngredients,
    unstockedIngredientsByPlanId: {
      for (final plan in plans)
        if (unstockedIngredientsByPlanId[plan.id] case final unstocked?
            when unstocked.isNotEmpty)
          plan.id: unstocked,
    },
  );
}
