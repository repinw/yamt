import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/inventory/application/inventory_eat_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Eats an inventory item: reserves the stock and logs the calorie entry.
class InventoryItemEatFlow {
  const new _();

  /// Should await completion.
  static bool shouldAwaitCompletion(
    InventoryItem item,
    InventoryItemEatRequest request,
  ) {
    return canDirectlySaveInventoryItemEatRequest(item, request);
  }

  /// Opens the eat sheet for [item] and logs the entered amount.
  ///
  /// Reserves the stock from [item] itself. Returns the saved entry, or null
  /// when the user cancels or saving fails.
  static Future<CalorieEntry?> eat({
    required BuildContext context,
    required InventoryItem item,
    DateTime? initialLoggedAt,
    MealType? initialMealType,
  }) async {
    final request = await showInventoryItemEatSheet(
      context: context,
      item: item,
      initialLoggedAt: initialLoggedAt,
      initialMealType: initialMealType,
    );
    if (request == null || !context.mounted) {
      return null;
    }
    final container = ProviderScope.containerOf(context, listen: false);
    final pending = container
        .read(inventoryItemEatControllerProvider.notifier)
        .stage(item, request.inventoryAmount);
    if (pending == null) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        AppLocalizations.of(context)!.inventoryItemActionFailed,
        tone: AppSnackBarTone.error,
      );
      return null;
    }
    return await complete(
      context: context,
      container: container,
      item: item,
      request: request,
      pending: pending,
    );
  }

  /// Reserves the stock from the inventory list and completes the eat flow.
  static Future<bool> stageAndComplete({
    required BuildContext context,
    required ProviderContainer container,
    required InventoryItem item,
    required InventoryItemEatRequest request,
  }) async {
    // Read before the await: the page's container may be gone after it.
    final eating = container.read(inventoryItemEatControllerProvider.notifier);
    final pending = await container
        .read(inventoryItemsControllerProvider.notifier)
        .stagePendingConsumption(item.id, request.inventoryAmount);
    if (pending == null) {
      return false;
    }

    if (!context.mounted) {
      await eating.discard(pending.id);
      return false;
    }

    final completion = complete(
      context: context,
      container: container,
      item: item,
      request: request,
      pending: pending,
    );

    if (shouldAwaitCompletion(item, request)) {
      await completion;
    } else {
      unawaited(completion);
    }
    return true;
  }

  /// Logs the calorie entry for [request] with its reserved [pending] stock.
  ///
  /// Saves directly when the item has enough nutrition data, and opens the
  /// calorie editor otherwise. Returns the saved entry, or null.
  static Future<CalorieEntry?> complete({
    required BuildContext context,
    required ProviderContainer container,
    required InventoryItem item,
    required InventoryItemEatRequest request,
    required PendingInventoryConsumption pending,
    void Function(String calorieEntryId)? onDirectCalorieEntrySaved,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final eating = container.read(inventoryItemEatControllerProvider.notifier);
    try {
      final outcome = await eating.log(
        item: item,
        request: request,
        pending: pending,
      );
      switch (outcome) {
        case InventoryEatLogged(:final entry):
          onDirectCalorieEntrySaved?.call(entry.id);
          if (context.mounted) {
            _showEatenSnackBar(
              context: context,
              container: container,
              entry: entry,
            );
          }
          return entry;
        case InventoryEatFailed(:final failure):
          if (context.mounted) {
            _showError(context, switch (failure) {
              InventoryEatFailure.noNutrition => l10n.inventoryItemActionFailed,
              InventoryEatFailure.notSaved => l10n.caloriesSaveFailed,
            });
          }
          return null;
        case InventoryEatNeedsEditor(
          :final profile,
          :final scannedSourceRef,
          :final inventoryContext,
        ):
          if (!context.mounted) {
            await eating.discard(pending.id);
            return null;
          }
          final savedEntry = await context.push<CalorieEntry>(
            AppRoutes.homeCaloriesEntryCreate,
            extra: CalorieEntryCreateArgs(
              prefilledProfile: profile,
              scannedSourceRef: scannedSourceRef,
              inventoryContext: inventoryContext,
              preselectedMealType: request.mealType,
              preselectedLoggedAt: request.loggedAt,
            ),
          );
          if (savedEntry != null && context.mounted) {
            _showEatenSnackBar(
              context: context,
              container: container,
              entry: savedEntry,
            );
          }
          return savedEntry;
      }
    } on Object catch (error, stackTrace) {
      developer.log(
        'Eat flow failed unexpectedly.',
        name: 'InventoryItemEatFlow',
        error: error,
        stackTrace: stackTrace,
      );
      // The service releases the stock itself; this covers a service that
      // could not even start.
      await eating.discard(pending.id);
      if (context.mounted) {
        _showError(context, l10n.inventoryItemActionFailed);
      }
      return null;
    }
  }

  /// Undoes an eat: deletes [entry] and returns its amount to the inventory.
  static Future<bool> undoEat({
    required ProviderContainer container,
    required CalorieEntry entry,
  }) => container.read(inventoryItemEatControllerProvider.notifier).undo(entry);

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showAppSnackBar(message, tone: AppSnackBarTone.error);
  }

  static void _showEatenSnackBar({
    required BuildContext context,
    required ProviderContainer container,
    required CalorieEntry entry,
  }) {
    ScaffoldMessenger.of(context).showAppSnackBar(
      AppLocalizations.of(context)!.inventoryManualAddEatSucceeded,
      onUndo: () => undoEat(container: container, entry: entry),
    );
  }
}
