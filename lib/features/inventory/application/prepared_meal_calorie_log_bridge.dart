import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart'
    show InventoryAmountUnit, InventoryAmountUnitCode;
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

typedef PreparedMealStatePublisher = void Function(List<PreparedMeal> meals);
typedef PreparedMealSaveCallback =
    Future<bool> Function(
      List<PreparedMeal> previousMeals,
      List<PreparedMeal> nextMeals,
    );

final preparedMealCalorieLogBridgeProvider =
    Provider<PreparedMealCalorieLogBridge>((ref) {
      final commitStore = ref.watch(
        preparedMealCalorieEntryCommitStoreProvider,
      );
      return PreparedMealCalorieLogBridge(
        saveEntry: (entry) {
          return ref
              .read(calorieEntriesControllerProvider.notifier)
              .saveEntry(entry);
        },
        saveEntryAtomically: commitStore == null
            ? null
            : (entry) {
                return ref
                    .read(calorieEntriesControllerProvider.notifier)
                    .saveEntry(
                      entry,
                      persistEntry: (persistedEntry) {
                        return commitStore.commitEntryAndPreparedMeal(
                          entry: persistedEntry,
                        );
                      },
                    );
              },
        now: DateTime.now,
        nextEntryId: Uuid().v4,
      );
    });

class PreparedMealCalorieLogBridge {
  PreparedMealCalorieLogBridge({
    required Future<bool> Function(CalorieEntry entry) saveEntry,
    Future<bool> Function(CalorieEntry entry)? saveEntryAtomically,
    required DateTime Function() now,
    required String Function() nextEntryId,
  }) : _saveEntry = saveEntry,
       _saveEntryAtomically = saveEntryAtomically,
       _now = now,
       _nextEntryId = nextEntryId;

  final Future<bool> Function(CalorieEntry entry) _saveEntry;
  final Future<bool> Function(CalorieEntry entry)? _saveEntryAtomically;
  final DateTime Function() _now;
  final String Function() _nextEntryId;

  Future<bool> logConsumedPreparedMeal({
    required PreparedMeal meal,
    required int consumedPortions,
    required MealType mealType,
    DateTime? loggedDay,
  }) {
    final entry = buildConsumedPreparedMealCalorieEntry(
      meal: meal,
      consumedPortions: consumedPortions,
      mealType: mealType,
      now: _now,
      nextEntryId: _nextEntryId,
      loggedDay: loggedDay,
    );
    if (entry == null) {
      return Future<bool>.value(false);
    }

    return _saveEntry(entry);
  }

  Future<bool> consumePreparedMeal({
    required List<PreparedMeal> currentMeals,
    required List<PreparedMeal> nextMeals,
    required PreparedMeal meal,
    required int consumedPortions,
    required MealType mealType,
    required PreparedMealStatePublisher publishMeals,
    required PreparedMealSaveCallback saveMeals,
    DateTime? loggedDay,
  }) async {
    final entry = buildConsumedPreparedMealCalorieEntry(
      meal: meal,
      consumedPortions: consumedPortions,
      mealType: mealType,
      now: _now,
      nextEntryId: _nextEntryId,
      loggedDay: loggedDay,
    );
    if (entry == null) {
      return false;
    }

    final atomicSave = _saveEntryAtomically;
    if (atomicSave != null) {
      publishMeals(nextMeals);
      final saved = await atomicSave(entry);
      if (saved) {
        return true;
      }
      publishMeals(currentMeals);
      return false;
    }

    final mealsSaved = await saveMeals(currentMeals, nextMeals);
    if (!mealsSaved) {
      return false;
    }

    final calorieSaved = await _saveEntry(entry);
    if (calorieSaved) {
      return true;
    }

    await saveMeals(nextMeals, currentMeals);
    return false;
  }
}

CalorieEntry? buildConsumedPreparedMealCalorieEntry({
  required PreparedMeal meal,
  required int consumedPortions,
  required MealType mealType,
  required DateTime Function() now,
  required String Function() nextEntryId,
  DateTime? loggedDay,
}) {
  if (meal.totalPortions < 1 || consumedPortions < 1) {
    return null;
  }

  final currentTime = now();
  final loggedAt = _resolveLoggedAt(now: currentTime, loggedDay: loggedDay);
  final portionRatio = consumedPortions / meal.totalPortions;
  return CalorieEntry.bundle(
    id: nextEntryId(),
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
