import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_pack.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';

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
});

/// Walks [plans] by their day and takes each one's stock from [items] the
/// way accepting does: from the first pack of its food that still has stock
/// left once the earlier plans took theirs. A plan that this pack cannot
/// cover falls short, since accepting takes from one pack only.
///
/// A plan of a cooked meal takes its portions from [meals] the same way.
/// A plan of a found food names no stock.
InventoryPlanDemand inventoryPlanDemand(
  List<CalorieEntry> plans,
  List<InventoryItem> items,
  List<PreparedMeal> meals,
) {
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
  for (final plan in plans.sortedBy((plan) => plan.loggedAt)) {
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
  );
}
