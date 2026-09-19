import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';

/// Whether the consumed amount of [entry] can change after logging.
///
/// Bundles count portions of a prepared meal, and entries that can go back
/// to the inventory already took a fixed amount from it. Changing either
/// would leave the stock out of sync.
bool canEditCalorieEntryAmount(CalorieEntry entry) {
  return !entry.isBundle && !entry.canRestoreToInventory;
}

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

/// Whether [entry] can be logged again from its details.
bool canRepeatCalorieEntry(CalorieEntry entry) => !entry.isBundle;

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
  );
}
