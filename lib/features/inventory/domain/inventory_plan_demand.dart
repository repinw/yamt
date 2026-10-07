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

  /// Plans the Vorrat cannot cover in full ("fehlt"): the share of each
  /// that no stock covers, from above 0 to 1, by plan id.
  Map<String, double> missingShareByPlanId,
});

/// Walks [plans] by their day and takes each one's stock from [items] the
/// way accepting does: from the first pack of its food that still has stock
/// left once the earlier plans took theirs. A plan that this pack cannot
/// cover falls short, since accepting takes from one pack only.
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
  final missing = <String, double>{};
  for (final plan in plans.sortedBy((plan) => plan.loggedAt)) {
    if (plan.sourceInventoryItemId == null) {
      continue;
    }
    final pack = inventoryPacksForPlan(
      plan,
      items,
    ).firstWhereOrNull((pack) => left[pack.item.id]! > 0);
    if (pack == null) {
      missing[plan.id] = 1;
      continue;
    }
    final available = left[pack.item.id]!;
    final taken = math.min(pack.amount, available);
    left[pack.item.id] = available - taken;
    planned.update(pack.item.id, (sum) => sum + taken, ifAbsent: () => taken);
    if (taken < pack.amount) {
      missing[plan.id] = (pack.amount - taken) / pack.amount;
    }
  }
  return (plannedByItemId: planned, missingShareByPlanId: missing);
}
