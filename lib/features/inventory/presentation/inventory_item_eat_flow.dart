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
import 'package:yamt/features/inventory/application/'
    'inventory_calorie_bridge_flow.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_application.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_quick_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Where a staged eat takes its stock from.
enum InventoryEatStockSource {
  /// The loaded inventory list, so the row updates at once.
  inventoryList,

  /// The item the caller shows, without loading the inventory list.
  snapshot,
}

/// Eats an inventory item: stages the stock and logs the calorie entry.
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
  /// Stages the stock from [item] itself. Returns the saved entry, or null
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
    return await runInventoryQuickEatFlow(context, (scope) async {
      final pendingConsumptionId = await scope.actions
          .stageInventoryItemConsumption(
            item: item,
            amount: request.inventoryAmount,
          );
      if (pendingConsumptionId == null) {
        scope.messenger.showAppSnackBar(
          scope.l10n.inventoryItemActionFailed,
          tone: AppSnackBarTone.error,
        );
        return null;
      }
      if (!context.mounted) {
        await scope.actions.discardInventoryItemConsumption(
          pendingConsumptionId,
        );
        return null;
      }
      return await complete(
        context: context,
        container: scope.container,
        itemBeforeMutation: item,
        request: request,
        pendingConsumptionId: pendingConsumptionId,
        stockSource: InventoryEatStockSource.snapshot,
      );
    });
  }

  /// Stages consumption and completes the eat flow.
  static Future<bool> stageAndComplete({
    required BuildContext context,
    required ProviderContainer container,
    required InventoryItem item,
    required InventoryItemEatRequest request,
  }) async {
    final inventoryController = container.read(
      inventoryItemsControllerProvider.notifier,
    );
    final pendingConsumption = await inventoryController
        .stagePendingConsumption(item.id, request.inventoryAmount);
    if (pendingConsumption == null) {
      return false;
    }

    if (!context.mounted) {
      await inventoryController.discardPendingConsumption(
        pendingConsumption.id,
      );
      return false;
    }

    final completion = complete(
      context: context,
      container: container,
      itemBeforeMutation: item,
      request: request,
      pendingConsumptionId: pendingConsumption.id,
      pendingConsumption: pendingConsumption,
    );

    if (shouldAwaitCompletion(item, request)) {
      await completion;
    } else {
      unawaited(completion);
    }
    return true;
  }

  /// Logs the calorie entry for a staged [request].
  ///
  /// Saves directly when the item has enough nutrition data, and opens the
  /// calorie editor otherwise. Discards the staged stock from [stockSource]
  /// on failure. Returns the saved entry, or null.
  static Future<CalorieEntry?> complete({
    required BuildContext context,
    required ProviderContainer container,
    required InventoryItem itemBeforeMutation,
    required InventoryItemEatRequest request,
    required String pendingConsumptionId,
    InventoryEatStockSource stockSource = InventoryEatStockSource.inventoryList,
    PendingInventoryConsumption? pendingConsumption,
    void Function(String calorieEntryId)? onDirectCalorieEntrySaved,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    Future<CalorieEntry?> fail({String? message, bool showMessage = true}) {
      return _discardAndFail(
        context: showMessage && context.mounted ? context : null,
        container: container,
        stockSource: stockSource,
        pendingConsumptionId: pendingConsumptionId,
        message: message,
      );
    }

    try {
      final profile = InventoryCalorieBridgeFlow.buildProfileFromInventoryItem(
        itemBeforeMutation,
      );
      if (profile == null) {
        return await fail(message: l10n.inventoryItemActionFailed);
      }

      final inventoryContext = InventoryCalorieBridgeFlow.buildInventoryContext(
        item: itemBeforeMutation,
        pendingConsumptionId: pendingConsumptionId,
        request: request,
      );
      final scannedSourceRef = InventoryCalorieBridgeFlow.buildScannedSourceRef(
        item: itemBeforeMutation,
        profile: profile,
      );

      if (canDirectlySaveInventoryItemEatRequest(itemBeforeMutation, request)) {
        final savedEntry = await InventoryCalorieBridgeFlow.saveDirectEntry(
          container: container,
          profile: profile,
          inventoryContext: inventoryContext,
          scannedSourceRef: scannedSourceRef,
          loggedAt: request.loggedAt,
          mealType: request.mealType,
          pendingConsumption: pendingConsumption,
          onDirectCalorieEntrySaved: onDirectCalorieEntrySaved,
        );
        if (savedEntry != null) {
          if (context.mounted) {
            _showEatenSnackBar(
              context: context,
              container: container,
              entry: savedEntry,
            );
          }
          return savedEntry;
        }

        return await fail(message: l10n.caloriesSaveFailed);
      }

      if (!context.mounted) {
        return await fail(showMessage: false);
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
    } on Object catch (error, stackTrace) {
      developer.log(
        'Eat flow failed unexpectedly.',
        name: 'InventoryItemEatFlow',
        error: error,
        stackTrace: stackTrace,
      );
      return await fail(message: l10n.inventoryItemActionFailed);
    }
  }

  static Future<CalorieEntry?> _discardAndFail({
    required BuildContext? context,
    required ProviderContainer container,
    required InventoryEatStockSource stockSource,
    required String pendingConsumptionId,
    String? message,
  }) async {
    await switch (stockSource) {
      InventoryEatStockSource.inventoryList =>
        container
            .read(inventoryItemsControllerProvider.notifier)
            .discardPendingConsumption(pendingConsumptionId),
      InventoryEatStockSource.snapshot =>
        container
            .read(inventoryQuickEatActionsProvider)
            .discardInventoryItemConsumption(pendingConsumptionId),
    };
    if (context != null && context.mounted && message != null) {
      ScaffoldMessenger.of(context)
          .showAppSnackBar(message, tone: AppSnackBarTone.error);
    }
    return null;
  }

  static void _showEatenSnackBar({
    required BuildContext context,
    required ProviderContainer container,
    required CalorieEntry entry,
  }) {
    ScaffoldMessenger.of(context).showAppSnackBar(
      AppLocalizations.of(context)!.inventoryManualAddEatSucceeded,
      onUndo: () => InventoryCalorieBridgeFlow.undoEat(
        container: container,
        entry: entry,
      ),
    );
  }
}
