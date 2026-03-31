import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart'
    show InventoryAmountUnit, InventoryAmountUnitCode;
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

final preparedMealCalorieLogBridgeProvider =
    Provider<PreparedMealCalorieLogBridge>((ref) {
      return PreparedMealCalorieLogBridge(
        saveEntry: (entry) {
          return ref
              .read(calorieEntriesControllerProvider.notifier)
              .saveEntry(entry);
        },
        now: DateTime.now,
      );
    });

/// Bridges prepared-meal consumption into the calorie diary domain.
class PreparedMealCalorieLogBridge {
  PreparedMealCalorieLogBridge({
    required Future<bool> Function(CalorieEntry entry) saveEntry,
    required DateTime Function() now,
  }) : _saveEntry = saveEntry,
       _now = now;

  static const _uuid = Uuid();

  final Future<bool> Function(CalorieEntry entry) _saveEntry;
  final DateTime Function() _now;

  Future<bool> logConsumedPreparedMeal({
    required PreparedMeal meal,
    required int consumedPortions,
    required MealType mealType,
  }) {
    if (meal.totalPortions < 1 || consumedPortions < 1) {
      return Future<bool>.value(false);
    }

    final now = _now();
    final portionRatio = consumedPortions / meal.totalPortions;
    final entry = CalorieEntry.bundle(
      id: _uuid.v4(),
      userId: '',
      name: meal.name,
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
      loggedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    return _saveEntry(entry);
  }
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
            amount: (component.usedAmount * portionRatio).toStringAsFixed(1),
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
