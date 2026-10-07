import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';

/// Whether the consumed amount of [entry] can change after logging.
///
/// Bundles count portions of a prepared meal, so their amount follows the
/// portions instead of a weight. A quick entry has no real amount. Entries
/// logged from the inventory can change: the stock follows the new amount.
bool canEditCalorieEntryAmount(CalorieEntry entry) =>
    !entry.isBundle && !entry.isQuickEntry;

/// [entry] with a new consumed [amount] and totals scaled to it.
CalorieEntry rescaleCalorieEntry(
  CalorieEntry entry, {
  required double amount,
  required DateTime now,
}) {
  return entry
      .copyWith(consumedAmount: amount)
      .recalculateTotals(updatedAt: now);
}

/// Whether [entry] can be logged again from its details. A prepared meal
/// entry counts portions of a meal that may be gone; a combined entry can
/// repeat like a single food.
bool canRepeatCalorieEntry(CalorieEntry entry) =>
    entry.isCombined || !entry.isBundle;

/// A new entry with [id] for the same food and amount as [entry], logged at
/// [now] in the meal that fits that time.
///
/// The copy does not take anything from the inventory, so it drops the
/// inventory link of the original.
CalorieEntry repeatCalorieEntry(
  CalorieEntry entry, {
  required String id,
  required DateTime now,
}) {
  return entry.copyWith(
    id: id,
    mealType: MealType.defaultForDateTime(now),
    loggedAt: now,
    createdAt: now,
    updatedAt: now,
    sourceInventoryItemId: null,
    sourceInventoryAmountToRestore: null,
    bundleComponents: [
      for (final component in entry.bundleComponents)
        component.withoutStockSource(),
    ],
  );
}

/// A plan with [id] for the same food and amount as [entry] on [day], in the
/// entry's meal and at its time of day, made at [now].
///
/// A Vorrat food keeps its Vorrat item and stock amount, so eating the plan
/// takes stock like a plan from the eat page, also for packs counted in
/// cans or pieces that the eaten amount cannot tell. The entry took less
/// stock than it ate only when the pack ran empty, and the stock amount
/// applies to that pack alone. A combined entry keeps no stock source,
/// since the stock of its foods was never taken.
CalorieEntry planCalorieEntryAgain(
  CalorieEntry entry, {
  required String id,
  required DateTime day,
  required DateTime now,
}) {
  final plan = repeatCalorieEntry(entry, id: id, now: now).copyWith(
    mealType: entry.mealType,
    loggedAt: loggedAtOnDay(day, now: entry.loggedAt),
  );
  if (entry.isCombined) {
    return plan;
  }
  return plan.copyWith(
    sourceInventoryItemId: entry.sourceInventoryItemId,
    sourceInventoryAmountToRestore: entry.sourceInventoryAmountToRestore,
  );
}
