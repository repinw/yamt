import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_manual_add_amount_service.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_dialogs.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_save_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_quick_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _inventoryManualProductEatFlowLogName =
    'InventoryManualProductEatCompletionFlow';

/// Saves a manual product result and continues into the eat flow.
@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
Future<InventoryManualProductSaveOutcome> saveManualProductResultForEatFlow({
  required BuildContext context,
  required ProviderContainer container,
  required AppLocalizations l10n,
  required InventoryReceiptManualProductResult result,
  MealType? preselectedMealType,
  DateTime? preselectedLoggedAt,
}) async {
  try {
    return await _saveManualProductResultForEatFlow(
      context: context,
      container: container,
      l10n: l10n,
      result: result,
      preselectedMealType: preselectedMealType,
      preselectedLoggedAt: preselectedLoggedAt,
    );
  } on Object catch (error, stackTrace) {
    log(
      'Failed to complete manual product eat flow.',
      name: _inventoryManualProductEatFlowLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return const InventoryManualProductSaveOutcome.failed();
  }
}

@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
Future<InventoryManualProductSaveOutcome> _saveManualProductResultForEatFlow({
  required BuildContext context,
  required ProviderContainer container,
  required AppLocalizations l10n,
  required InventoryReceiptManualProductResult result,
  required MealType? preselectedMealType,
  required DateTime? preselectedLoggedAt,
}) async {
  final itemToSave = await _resolveEatItem(context, result.item);
  if (!context.mounted || itemToSave == null) {
    return const InventoryManualProductSaveOutcome.canceled();
  }

  final saveOutcome = await saveManualProductResultToInventory(
    context: context,
    container: container,
    l10n: l10n,
    result: _resultWithItem(result, itemToSave),
  );
  final savedItem = saveOutcome.item;
  if (!context.mounted ||
      saveOutcome.status != InventoryManualProductSaveStatus.saved ||
      savedItem == null) {
    return saveOutcome;
  }

  final request =
      inventoryManualAddEatRequestFromSelection(
        result.eatSelection,
      ) ??
      await _showEatSheet(
        context: context,
        l10n: l10n,
        item: savedItem,
        preselectedMealType: preselectedMealType,
        preselectedLoggedAt: preselectedLoggedAt,
      );
  if (!context.mounted || request == null) {
    await _deleteSavedItem(container, savedItem);
    return const InventoryManualProductSaveOutcome.canceled();
  }

  final completedEatFlow = await _completeEatFlow(
    context: context,
    item: savedItem,
    request: request,
  );
  if (!completedEatFlow) {
    await _deleteSavedItem(container, savedItem);
    return const InventoryManualProductSaveOutcome.canceled();
  }
  return saveOutcome;
}

Future<InventoryItem?> _resolveEatItem(
  BuildContext context,
  InventoryItem item,
) async {
  if (!requiresInventoryManualAddConsumedAmountPrompt(item)) {
    return item;
  }

  final eatAmount = await showInventoryManualAddEatAmountDialog(
    context: context,
    initialUnit: defaultInventoryManualAddConsumedAmountUnit(item),
  );
  if (!context.mounted || eatAmount == null) {
    return null;
  }

  return resolveInventoryManualAddItemAmount(
    item: item,
    amount: eatAmount.amount,
    unit: eatAmount.unit,
  );
}

Future<InventoryItemEatRequest?> _showEatSheet({
  required BuildContext context,
  required AppLocalizations l10n,
  required InventoryItem item,
  required MealType? preselectedMealType,
  required DateTime? preselectedLoggedAt,
}) async {
  final maxAmount = resolveInventoryManualAddConsumableAmount(item);
  if (maxAmount == null) {
    showInventoryManualAddSnackBar(
      context: context,
      message: l10n.inventoryItemActionFailed,
    );
    return null;
  }

  return InventoryQuickEatFlow.showItemSheet(
    context: context,
    item: item,
    maxAmount: maxAmount,
    invalidAmountMessage: l10n.inventoryReceiptReviewInvalidNumber,
    initialInventoryAmount: resolveInventoryManualAddInitialConsumedAmount(
      item: item,
      rawWeight: item.weight,
    ),
    initialLoggedAt: preselectedLoggedAt,
    initialMealType: preselectedMealType,
  );
}

@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
Future<bool> _completeEatFlow({
  required BuildContext context,
  required InventoryItem item,
  required InventoryItemEatRequest request,
}) async {
  final resizedItem = resizeInventoryManualAddItemToConsumedAmount(
    item: item,
    inventoryAmount: request.inventoryAmount,
  );
  final itemForConsumption = await _updateSavedItemIfNeeded(
    context: context,
    originalItem: item,
    resizedItem: resizedItem,
  );
  if (!context.mounted || itemForConsumption == null) {
    return false;
  }

  return completeInventoryManualAddEatFlow(
    context: context,
    item: itemForConsumption,
    request: request,
  );
}

@Dependencies([InventoryItemsController])
Future<InventoryItem?> _updateSavedItemIfNeeded({
  required BuildContext context,
  required InventoryItem originalItem,
  required InventoryItem resizedItem,
}) async {
  if (resizedItem == originalItem) {
    return originalItem;
  }

  final controller = ProviderScope.containerOf(context, listen: false).read(
    inventoryItemsControllerProvider.notifier,
  );
  final saved = await controller.updateItem(resizedItem);
  if (!context.mounted) {
    return null;
  }
  if (saved) {
    return resizedItem;
  }
  showInventoryManualAddSnackBar(
    context: context,
    message: AppLocalizations.of(context)!.inventoryItemActionFailed,
  );
  return null;
}

@Dependencies([InventoryItemsController])
Future<void> _deleteSavedItem(
  ProviderContainer container,
  InventoryItem savedItem,
) {
  return container
      .read(inventoryItemsControllerProvider.notifier)
      .deleteItem(savedItem.id);
}

InventoryReceiptManualProductResult _resultWithItem(
  InventoryReceiptManualProductResult result,
  InventoryItem item,
) {
  return InventoryReceiptManualProductResult(
    item: item,
    action: InventoryReceiptManualProductAction.eatNow,
    selectedProduct: result.selectedProduct,
    selectedGlobalFoodItemId: result.selectedGlobalFoodItemId,
    requiresGlobalPersistence: result.requiresGlobalPersistence,
    globalPackageWeight: result.globalPackageWeight,
    skipMissingBarcodePrompt: result.skipMissingBarcodePrompt,
    eatSelection: result.eatSelection,
  );
}
