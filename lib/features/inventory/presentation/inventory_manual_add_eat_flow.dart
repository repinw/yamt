import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/domain/eat_selection.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_manual_add_amount_service.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_item_eat_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Complete inventory manual-add eat flow.
@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
Future<bool> completeInventoryManualAddEatFlow({
  required BuildContext context,
  required InventoryItem item,
  required InventoryItemEatRequest request,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final maxAmount = resolveInventoryManualAddConsumableAmount(item);
  if (maxAmount == null ||
      request.inventoryAmount < 1 ||
      request.inventoryAmount > maxAmount) {
    showInventoryManualAddSnackBar(
      context: context,
      message: l10n.inventoryItemActionFailed,
    );
    return false;
  }

  final container = ProviderScope.containerOf(context, listen: false);
  final inventorySubscription = container.listen(
    inventoryItemsControllerProvider,
    (previous, next) {},
    fireImmediately: true,
  );
  try {
    final inventoryReady = container.read(
      inventoryItemsControllerProvider.future,
    );
    final inventoryController = container.read(
      inventoryItemsControllerProvider.notifier,
    );
    await inventoryReady;
    if (!context.mounted) {
      return false;
    }

    final pendingConsumption = await inventoryController
        .stagePendingConsumption(
          item.id,
          request.inventoryAmount,
        );
    if (pendingConsumption == null) {
      if (context.mounted) {
        showInventoryManualAddSnackBar(
          context: context,
          message: l10n.inventoryItemActionFailed,
        );
      }
      return false;
    }
    if (!context.mounted) {
      await inventoryController.discardPendingConsumption(
        pendingConsumption.id,
      );
      return false;
    }

    return InventoryItemEatFlow.complete(
      context: context,
      container: container,
      itemBeforeMutation: item,
      request: request,
      pendingConsumptionId: pendingConsumption.id,
    );
  } on Object catch (error, stackTrace) {
    log(
      'Manual-add eat flow failed while preparing inventory controller.',
      name: 'InventoryManualAddEatFlow',
      error: error,
      stackTrace: stackTrace,
    );
    if (context.mounted) {
      showInventoryManualAddSnackBar(
        context: context,
        message: l10n.inventoryItemActionFailed,
      );
    }
    return false;
  } finally {
    inventorySubscription.close();
  }
}

/// Builds eat request from generic AI/manual selection.
InventoryItemEatRequest? inventoryManualAddEatRequestFromSelection(
  EatSelection? selection,
) {
  if (selection == null) {
    return null;
  }
  return InventoryItemEatRequest(
    inventoryAmount: selection.inventoryAmount,
    loggedAt: selection.loggedAt,
    mealType: selection.mealType,
  );
}

/// Shows manual add snackbar.
void showInventoryManualAddSnackBar({
  required BuildContext context,
  required String message,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
