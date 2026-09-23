import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_snapshot_invalidator.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/provider/calorie_overview_revision_provider.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_controller_access.dart';

part 'inventory_calorie_entry_delete_flow.g.dart';

const _inventoryDeleteFlowLogName = 'InventoryCalorieEntryDeleteFlow';

/// Inventory-enabled calorie entry delete flow.
@riverpod
CalorieEntryDeleteFlow inventoryCalorieEntryDeleteFlow(Ref ref) {
  ref.keepAlive();
  final calorieLogRepository = ref.read(calorieLogRepositoryProvider);
  final calorieSettingsRepository = ref.read(calorieSettingsRepositoryProvider);
  final inventoryItemRepository = ref.read(inventoryItemRepositoryProvider);
  final overviewRevision = ref.read(calorieOverviewRevisionProvider.notifier);
  final preparedMealRepository = ref.read(preparedMealRepositoryProvider);

  return CalorieEntryDeleteFlow(
    deleteEntryById: (entryId) async {
      final deleted = await calorieLogRepository.deleteEntry(entryId);
      if (deleted) {
        overviewRevision.markChanged();
      }
      return deleted;
    },
    restoreConsumedItem: (itemId, amount) {
      return withInventoryController(
        ref: ref,
        operationName: 'restore consumed inventory item',
        fallbackValue: false,
        operation: (controller) {
          return controller.restoreConsumedItem(itemId, amount);
        },
      );
    },
    rollbackRestoredItem: (itemId, amount, {consumedAt}) {
      return withInventoryController(
        ref: ref,
        operationName: 'rollback restored inventory item',
        fallbackValue: false,
        operation: (controller) {
          return controller.eatItem(itemId, amount, consumedAt: consumedAt);
        },
      );
    },
    sourceInventoryItemExists: (itemId) {
      return _sourceInventoryItemExists(
        itemId: itemId,
        repository: inventoryItemRepository,
      );
    },
    restorePreparedMealPortions: ({required mealId, required portions}) {
      return _withPreparedMealsController(
        ref: ref,
        operationName: 'restore prepared meal portions',
        fallbackValue: false,
        operation: (controller) {
          return controller.restorePreparedMealPortions(
            mealId: mealId,
            portions: portions,
          );
        },
      );
    },
    rollbackRestoredPreparedMeal:
        ({required mealId, required discardedPortions}) {
          return _withPreparedMealsController(
            ref: ref,
            operationName: 'rollback restored prepared meal',
            fallbackValue: false,
            operation: (controller) {
              return controller.takePreparedMealPortions(
                mealId: mealId,
                portions: discardedPortions,
              );
            },
          );
        },
    invalidateSnapshotsFromDay: (day) {
      return invalidateCalorieWeeklyCheckInSnapshotsFromDay(
        day: day,
        settingsRepository: calorieSettingsRepository,
        now: ref.read(clockProvider)(),
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

Future<T> _withPreparedMealsController<T>({
  required Ref ref,
  required String operationName,
  required T fallbackValue,
  required Future<T> Function(PreparedMealsController controller) operation,
}) async {
  final subscription = ref.listen(
    preparedMealsControllerProvider,
    (_, _) {},
    fireImmediately: true,
  );
  try {
    if (!ref.mounted) {
      return fallbackValue;
    }
    await waitForLoadedProvider(ref, preparedMealsControllerProvider);
    if (!ref.mounted) {
      return fallbackValue;
    }
    return await operation(ref.read(preparedMealsControllerProvider.notifier));
  } on Object catch (error, stackTrace) {
    log(
      'Failed to $operationName.',
      name: _inventoryDeleteFlowLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return fallbackValue;
  } finally {
    subscription.close();
  }
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
    final item = await findInventoryItem(
      repository: repository,
      itemId: normalizedItemId,
    );
    return item != null;
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
