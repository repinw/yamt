import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_pack.dart';

/// What open plans take from the Vorrat.
typedef InventoryPlanDemand = ({
  /// Stock each pack keeps for plans, by item id, in the pack's stored unit
  /// ("verplant").
  Map<String, int> plannedByItemId,

  /// Plans the Vorrat cannot cover in full ("fehlt").
  Set<String> shortPlanIds,
});

/// Walks [plans] by their day and takes each one's stock from [items], in the
/// pack order of accepting. An earlier plan gets the stock first; a plan
/// that one pack cannot cover takes the rest from the next pack of its food.
///
/// Only plans of Vorrat foods count; a plan of a found food names no stock.
// ponytail: cooked meal portions are left out; add them with the
// "verplant" mark on meal rows.
InventoryPlanDemand inventoryPlanDemand(
  List<CalorieEntry> plans,
  List<InventoryItem> items,
) {
  final left = {
    for (final item in items) item.id: consumableInventoryAmount(item) ?? 0,
  };
  final planned = <String, int>{};
  final short = <String>{};
  for (final plan in plans.sortedBy((plan) => plan.loggedAt)) {
    if (plan.sourceInventoryItemId == null) {
      continue;
    }
    // The share of the plan that no pack has covered yet.
    var rest = 1.0;
    for (final item in inventoryPacksForPlan(plan, items)) {
      final need = inventoryAmountForPlan(plan, item);
      final available = left[item.id]!;
      if (need == null || available <= 0) {
        continue;
      }
      // The tolerance keeps a float rest such as 1/3 from rounding up.
      final wanted = (need * rest - 1e-6).ceil();
      final taken = math.min(wanted, available);
      left[item.id] = available - taken;
      planned.update(item.id, (sum) => sum + taken, ifAbsent: () => taken);
      rest = taken == wanted ? 0 : rest - taken / need;
      if (rest == 0) {
        break;
      }
    }
    if (rest > 0) {
      short.add(plan.id);
    }
  }
  return (plannedByItemId: planned, shortPlanIds: short);
}
