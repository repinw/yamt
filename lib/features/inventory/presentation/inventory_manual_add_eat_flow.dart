import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/domain/eat_selection.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_manual_add_amount_service.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Complete inventory manual-add eat flow.
@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
Future<void> completeInventoryManualAddEatFlow({
  required BuildContext context,
  required WidgetRef ref,
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
    return;
  }

  final inventoryController = ref.read(
    inventoryItemsControllerProvider.notifier,
  );
  final pendingConsumption = await inventoryController.stagePendingConsumption(
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
    return;
  }
  if (!context.mounted) {
    await inventoryController.discardPendingConsumption(
      pendingConsumption.id,
    );
    return;
  }

  await InventoryItemEatFlow.complete(
    context: context,
    ref: ref,
    itemBeforeMutation: item,
    request: request,
    pendingConsumptionId: pendingConsumption.id,
  );
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
