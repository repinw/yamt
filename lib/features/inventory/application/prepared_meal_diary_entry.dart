import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart'
    show InventoryAmountUnit, InventoryAmountUnitCode;
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// [plan] of a cooked meal with [portions] of [meal] as it is now instead,
/// kept on its id, user, day and meal. Null when the meal has no portions to
/// share.
CalorieEntry? preparedMealPlanWithPortions(
  CalorieEntry plan,
  PreparedMeal meal,
  int portions, {
  required DateTime Function() now,
}) {
  return buildConsumedPreparedMealCalorieEntry(
    meal: meal,
    consumedPortions: portions,
    mealType: plan.mealType,
    now: now,
    nextEntryId: () => plan.id,
  )?.copyWith(
    userId: plan.userId,
    loggedAt: plan.loggedAt,
    createdAt: plan.createdAt,
  );
}

/// The diary entry for eating [consumedPortions] of [meal], scaled from the
/// whole meal, or null when the meal has no portions to share.
CalorieEntry? buildConsumedPreparedMealCalorieEntry({
  required PreparedMeal meal,
  required num consumedPortions,
  required MealType mealType,
  required DateTime Function() now,
  required String Function() nextEntryId,
  DateTime? loggedDay,
}) {
  if (meal.totalPortions < 1 || consumedPortions <= 0) {
    return null;
  }

  final currentTime = now();
  final loggedAt = _resolveLoggedAt(now: currentTime, loggedDay: loggedDay);
  final portionRatio = consumedPortions / meal.totalPortions;
  return CalorieEntry.bundle(
    id: nextEntryId(),
    userId: '',
    name: meal.name,
    imageUrl:
        meal.imageUrl ??
        meal.components
            .map((component) => component.imageUrl)
            .nonNulls
            .firstOrNull,
    imageAssetId: meal.imageAssetId,
    mealType: mealType,
    totalKcal: meal.totalKcal * portionRatio,
    totalProtein: meal.totalProtein * portionRatio,
    totalCarbs: meal.totalCarbs * portionRatio,
    totalFat: meal.totalFat * portionRatio,
    bundleSourcePreparedMealId: meal.id,
    bundleConsumedPortions: consumedPortions,
    bundleTotalPortions: meal.totalPortions,
    bundleComponents: _buildBundleComponents(
      meal: meal,
      portionRatio: portionRatio,
    ),
    loggedAt: loggedAt,
    createdAt: currentTime,
    updatedAt: currentTime,
  );
}

DateTime _resolveLoggedAt({
  required DateTime now,
  required DateTime? loggedDay,
}) {
  if (loggedDay == null) {
    return now;
  }

  final normalizedDay = normalizeDiaryDay(loggedDay);
  return DateTime(
    normalizedDay.year,
    normalizedDay.month,
    normalizedDay.day,
    now.hour,
    now.minute,
    now.second,
    now.millisecond,
    now.microsecond,
  );
}

List<CalorieEntryBundleComponent> _buildBundleComponents({
  required PreparedMeal meal,
  required double portionRatio,
}) {
  return meal.components
      .map(
        (component) => CalorieEntryBundleComponent(
          name: component.name,
          brand: component.brand,
          imageUrl: component.imageUrl,
          amountLabel: _formatMealComponentAmountLabel(
            amount: preparedMealComponentDisplayAmount(
              component,
              component.usedAmount * portionRatio,
            ).toStringAsFixed(1),
            unit: component.usedUnit,
          ),
          totalKcal: component.totalKcal * portionRatio,
          totalProtein: component.totalProtein * portionRatio,
          totalCarbs: component.totalCarbs * portionRatio,
          totalFat: component.totalFat * portionRatio,
        ),
      )
      .toList(growable: false);
}

String _formatMealComponentAmountLabel({
  required String amount,
  required InventoryAmountUnit unit,
}) {
  final normalizedAmount = amount.endsWith('.0')
      ? amount.substring(0, amount.length - 2)
      : amount;
  return '$normalizedAmount ${unit.code}';
}
