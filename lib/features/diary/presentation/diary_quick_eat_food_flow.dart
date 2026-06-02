import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/'
    'diary_quick_eat_inventory_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/'
    'diary_day_dashboard_controller.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/inventory_quick_eat_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _diaryQuickEatFlowLogName = 'DiaryQuickEatFlow';

/// Eats an inventory item from the diary quick-eat flow.
@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
Future<void> eatDiaryQuickEatInventoryItem({
  required BuildContext context,
  required InventoryItem item,
  required MealType mealType,
  required DateTime loggedAt,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final maxAmount = maxDiaryQuickEatInventoryAmount(item);
  if (maxAmount == null) {
    return;
  }
  final request = await InventoryQuickEatFlow.showItemSheet(
    context: context,
    item: item,
    maxAmount: maxAmount,
    invalidAmountMessage: l10n.inventoryReceiptReviewInvalidNumber,
    initialLoggedAt: loggedAt,
    initialMealType: mealType,
  );
  if (!context.mounted || request == null) {
    return;
  }
  await _completeInventoryItemEatFlow(
    context: context,
    item: item,
    request: request,
  );
}

/// Eats a prepared meal from the diary quick-eat flow.
@Dependencies([PreparedMealsController])
Future<void> eatDiaryQuickEatPreparedMeal({
  required BuildContext context,
  required PreparedMeal meal,
  required MealType mealType,
  required DateTime loggedAt,
}) async {
  final result = await InventoryQuickEatFlow.showPreparedMealSheet(
    context: context,
    meal: meal,
    initialLoggedAt: loggedAt,
    initialMealType: mealType,
  );
  if (!context.mounted || result == null) {
    return;
  }
  final container = ProviderScope.containerOf(context, listen: false);
  final mealsSubscription = container.listen(
    preparedMealsControllerProvider,
    (_, _) {},
    fireImmediately: true,
  );
  try {
    await container.read(preparedMealsControllerProvider.future);
    if (!context.mounted) {
      return;
    }
    final saved = await container
        .read(preparedMealsControllerProvider.notifier)
        .consumePreparedMeal(
          mealId: meal.id,
          consumedPortions: result.portions,
          mealType: result.mealType,
          loggedDay: result.loggedDay,
        );
    if (saved) {
      refreshDiaryAfterQuickEat(container, result.loggedDay);
      return;
    }
    if (context.mounted) {
      _showSnackBar(
        context,
        AppLocalizations.of(context)!.preparedMealActionFailed,
      );
    }
  } on Object catch (error, stackTrace) {
    log(
      'Diary prepared meal eat flow failed.',
      name: _diaryQuickEatFlowLogName,
      error: error,
      stackTrace: stackTrace,
    );
    if (context.mounted) {
      _showSnackBar(
        context,
        AppLocalizations.of(context)!.preparedMealActionFailed,
      );
    }
  } finally {
    mealsSubscription.close();
  }
}

/// Refreshes diary dashboard data after a quick-eat mutation.
void refreshDiaryAfterQuickEat(
  ProviderContainer container,
  DateTime loggedAt,
) {
  final day = normalizeDiaryDay(loggedAt);
  container
      .read(diaryDayDashboardControllerProvider(day).notifier)
      .refreshAfterMutation();
}

@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
Future<void> _completeInventoryItemEatFlow({
  required BuildContext context,
  required InventoryItem item,
  required InventoryItemEatRequest request,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final inventorySubscription = container.listen(
    inventoryItemsControllerProvider,
    (_, _) {},
    fireImmediately: true,
  );
  try {
    final inventoryController = container.read(
      inventoryItemsControllerProvider.notifier,
    );
    await container.read(inventoryItemsControllerProvider.future);
    if (!context.mounted) {
      return;
    }
    await _stageAndCompleteInventoryItemEat(
      context: context,
      container: container,
      inventoryController: inventoryController,
      item: item,
      request: request,
      messenger: messenger,
      failedMessage: l10n.inventoryItemActionFailed,
    );
  } on Object catch (error, stackTrace) {
    log(
      'Diary inventory item eat flow failed.',
      name: _diaryQuickEatFlowLogName,
      error: error,
      stackTrace: stackTrace,
    );
    if (context.mounted) {
      _showSnackBarWithMessenger(messenger, l10n.inventoryItemActionFailed);
    }
  } finally {
    inventorySubscription.close();
  }
}

@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
Future<void> _stageAndCompleteInventoryItemEat({
  required BuildContext context,
  required ProviderContainer container,
  required InventoryItemsController inventoryController,
  required InventoryItem item,
  required InventoryItemEatRequest request,
  required ScaffoldMessengerState messenger,
  required String failedMessage,
}) async {
  final pendingConsumption = await inventoryController.stagePendingConsumption(
    item.id,
    request.inventoryAmount,
  );
  if (pendingConsumption == null) {
    _showSnackBarWithMessenger(messenger, failedMessage);
    return;
  }
  if (!context.mounted) {
    await inventoryController.discardPendingConsumption(pendingConsumption.id);
    return;
  }
  final saved = await InventoryItemEatFlow.complete(
    context: context,
    container: container,
    itemBeforeMutation: item,
    request: request,
    pendingConsumptionId: pendingConsumption.id,
    pendingConsumption: pendingConsumption,
    inventoryController: inventoryController,
  );
  if (saved) {
    refreshDiaryAfterQuickEat(container, request.loggedAt);
  }
}

void _showSnackBar(BuildContext context, String message) {
  _showSnackBarWithMessenger(ScaffoldMessenger.of(context), message);
}

void _showSnackBarWithMessenger(
  ScaffoldMessengerState messenger,
  String message,
) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
