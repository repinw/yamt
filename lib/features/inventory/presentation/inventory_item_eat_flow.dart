import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_calorie_bridge_flow.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines inventory item eat flow.
class InventoryItemEatFlow {
  const InventoryItemEatFlow._();

  /// Should await completion.
  static bool shouldAwaitCompletion(
    InventoryItem item,
    InventoryItemEatRequest request,
  ) {
    return canDirectlySaveInventoryItemEatRequest(item, request);
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
      inventoryController: inventoryController,
    );

    if (shouldAwaitCompletion(item, request)) {
      await completion;
    } else {
      unawaited(completion);
    }
    return true;
  }

  /// Complete.
  static Future<bool> complete({
    required BuildContext context,
    required ProviderContainer container,
    required InventoryItem itemBeforeMutation,
    required InventoryItemEatRequest request,
    required String pendingConsumptionId,
    PendingInventoryConsumption? pendingConsumption,
    InventoryItemsController? inventoryController,
    void Function(String calorieEntryId)? onDirectCalorieEntrySaved,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final successMessage = l10n.inventoryManualAddEatSucceeded;
      final profile = InventoryCalorieBridgeFlow.buildProfileFromInventoryItem(
        itemBeforeMutation,
      );
      if (profile == null) {
        return _discardAndFail(
          context: context,
          container: container,
          pendingConsumptionId: pendingConsumptionId,
          message: l10n.inventoryItemActionFailed,
        );
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
        final saved = await InventoryCalorieBridgeFlow.saveDirectEntry(
          container: container,
          profile: profile,
          inventoryContext: inventoryContext,
          scannedSourceRef: scannedSourceRef,
          loggedAt: request.loggedAt,
          mealType: request.mealType,
          pendingConsumption: pendingConsumption,
          onDirectCalorieEntrySaved: onDirectCalorieEntrySaved,
        );
        if (saved) {
          if (context.mounted) {
            _showSnackBar(context: context, message: successMessage);
          }
          return true;
        }

        return _discardAndFail(
          context: context.mounted ? context : null,
          container: container,
          pendingConsumptionId: pendingConsumptionId,
          message: l10n.caloriesSaveFailed,
        );
      }

      if (!context.mounted) {
        return _discardAndFail(
          context: null,
          container: container,
          pendingConsumptionId: pendingConsumptionId,
        );
      }

      final saved = await context.push<bool>(
        AppRoutes.homeCaloriesEntryCreate,
        extra: CalorieEntryCreateArgs(
          prefilledProfile: profile,
          scannedSourceRef: scannedSourceRef,
          inventoryContext: inventoryContext,
          preselectedMealType: request.mealType,
          preselectedLoggedAt: request.loggedAt,
        ),
      );
      if (saved == true && context.mounted) {
        _showSnackBar(context: context, message: successMessage);
      }
      return saved == true;
    } on Object catch (error, stackTrace) {
      developer.log(
        'Eat flow failed unexpectedly.',
        name: 'InventoryItemEatFlow',
        error: error,
        stackTrace: stackTrace,
      );
      return _discardAndFail(
        context: context.mounted ? context : null,
        container: container,
        pendingConsumptionId: pendingConsumptionId,
        message: l10n.inventoryItemActionFailed,
      );
    }
  }

  static Future<bool> _discardAndFail({
    required BuildContext? context,
    required ProviderContainer container,
    required String pendingConsumptionId,
    String? message,
  }) async {
    await _discardPendingConsumption(
      container: container,
      pendingConsumptionId: pendingConsumptionId,
    );
    if (context != null && context.mounted && message != null) {
      _showSnackBar(context: context, message: message);
    }
    return false;
  }

  static Future<void> _discardPendingConsumption({
    required ProviderContainer container,
    required String pendingConsumptionId,
  }) {
    return container
        .read(inventoryItemsControllerProvider.notifier)
        .discardPendingConsumption(pendingConsumptionId);
  }

  static void _showSnackBar({
    required BuildContext context,
    required String message,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
