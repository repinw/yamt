import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/provider/calorie_overview_revision_provider.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';

part 'inventory_calorie_entry_delete_flow.g.dart';

const _inventoryDeleteFlowLogName = 'InventoryCalorieEntryDeleteFlow';

/// Inventory-enabled calorie entry delete flow.
@Riverpod(
  dependencies: [
    inventoryItemRepository,
    InventoryItemsController,
    PreparedMealsController,
  ],
)
CalorieEntryDeleteFlow inventoryCalorieEntryDeleteFlow(Ref ref) {
  final calorieLogRepository = ref.read(calorieLogRepositoryProvider);
  final calorieSettingsRepository = ref.read(calorieSettingsRepositoryProvider);
  final inventoryItemRepository = ref.read(inventoryItemRepositoryProvider);
  final inventoryController = ref.read(
    inventoryItemsControllerProvider.notifier,
  );
  final overviewRevision = ref.read(calorieOverviewRevisionProvider.notifier);
  final preparedMealRepository = ref.read(preparedMealRepositoryProvider);
  final preparedMealsController = ref.read(
    preparedMealsControllerProvider.notifier,
  );

  return CalorieEntryDeleteFlow(
    deleteEntryById: (entryId) async {
      final deleted = await calorieLogRepository.deleteEntry(entryId);
      if (deleted) {
        overviewRevision.markChanged();
      }
      return deleted;
    },
    restoreConsumedItem: inventoryController.restoreConsumedItem,
    rollbackRestoredItem: inventoryController.eatItem,
    sourceInventoryItemExists: (itemId) {
      return _sourceInventoryItemExists(
        itemId: itemId,
        repository: inventoryItemRepository,
      );
    },
    restorePreparedMealPortions:
        preparedMealsController.restorePreparedMealPortions,
    rollbackRestoredPreparedMeal:
        ({required mealId, required discardedPortions}) {
          return preparedMealsController.throwAwayPreparedMeal(
            mealId: mealId,
            discardedPortions: discardedPortions,
            reason: InventoryDiscardReason.other,
          );
        },
    invalidateSnapshotsFromDay: (day) {
      return invalidateCalorieWeeklyCheckInSnapshotsFromDay(
        day: day,
        settingsRepository: calorieSettingsRepository,
      );
    },
    sourcePreparedMealExists: (mealId) {
      return _sourcePreparedMealExists(
        mealId: mealId,
        repository: preparedMealRepository,
      );
    },
  );
}

Future<bool> _sourceInventoryItemExists({
  required String itemId,
  required InventoryItemRepository repository,
}) async {
  final normalizedItemId = itemId.trim();
  if (normalizedItemId.isEmpty) {
    return false;
  }
  try {
    final loadedItems = await repository.readAll();
    return loadedItems.any((item) => item.id == normalizedItemId);
  } on Object catch (error, stackTrace) {
    log(
      'Failed to check inventory restore source. Trying restore anyway '
      '(itemId=$normalizedItemId).',
      name: _inventoryDeleteFlowLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  }
}

Future<bool> _sourcePreparedMealExists({
  required String mealId,
  required PreparedMealRepository repository,
}) async {
  final normalizedMealId = mealId.trim();
  if (normalizedMealId.isEmpty) {
    return false;
  }
  try {
    final loadedMeals = await repository.readAll();
    return loadedMeals.any((meal) => meal.id == normalizedMealId);
  } on Object catch (error, stackTrace) {
    log(
      'Failed to check prepared meal restore source. Trying restore anyway '
      '(mealId=$normalizedMealId).',
      name: _inventoryDeleteFlowLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  }
}
