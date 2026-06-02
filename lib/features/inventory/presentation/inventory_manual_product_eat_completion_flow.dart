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
    'inventory_manual_add_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_save_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_quick_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_sheet_result.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _inventoryManualProductEatFlowLogName =
    'InventoryManualProductEatCompletionFlow';

/// Saves a manual product result and continues into the eat flow.
@Dependencies([InventoryItemsController, inventoryBackedCalorieEntrySaveFlow])
Future<InventoryManualProductSaveOutcome> saveManualProductResultForEatFlow({
  required BuildContext context,
  required ProviderContainer container,
  required AppLocalizations l10n,
  required InventoryReceiptManualProductResult result,
  MealType? preselectedMealType,
  DateTime? preselectedLoggedAt,
  bool continueBatchOnConfirm = false,
}) async {
  try {
    return await _saveManualProductResultForEatFlow(
      context: context,
      container: container,
      l10n: l10n,
      result: result,
      preselectedMealType: preselectedMealType,
      preselectedLoggedAt: preselectedLoggedAt,
      continueBatchOnConfirm: continueBatchOnConfirm,
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
  required bool continueBatchOnConfirm,
}) async {
  final inventorySubscription = container.listen(
    inventoryItemsControllerProvider,
    (_, _) {},
    fireImmediately: true,
  );
  try {
    final saveOutcome = await saveManualProductResultToInventory(
      context: context,
      container: container,
      l10n: l10n,
      result: result,
    );
    final savedItem = saveOutcome.item;
    if (saveOutcome.status != InventoryManualProductSaveStatus.saved ||
        savedItem == null) {
      return saveOutcome;
    }
    if (!context.mounted) {
      return saveOutcome;
    }
    return await _completeSavedManualProductEat(
      context: context,
      container: container,
      l10n: l10n,
      result: result,
      item: savedItem,
      preselectedMealType: preselectedMealType,
      preselectedLoggedAt: preselectedLoggedAt,
      continueBatchOnConfirm: continueBatchOnConfirm,
    );
  } finally {
    inventorySubscription.close();
  }
}

@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
Future<InventoryManualProductSaveOutcome> _completeSavedManualProductEat({
  required BuildContext context,
  required ProviderContainer container,
  required AppLocalizations l10n,
  required InventoryReceiptManualProductResult result,
  required InventoryItem item,
  required MealType? preselectedMealType,
  required DateTime? preselectedLoggedAt,
  required bool continueBatchOnConfirm,
}) async {
  String? savedCalorieEntryId;
  final eatResult = await _resolveEatResult(
    context: context,
    l10n: l10n,
    result: result,
    item: item,
    preselectedMealType: preselectedMealType,
    preselectedLoggedAt: preselectedLoggedAt,
    continueBatchOnConfirm: continueBatchOnConfirm,
  );
  if (!context.mounted || eatResult == null) {
    await _deleteSavedItem(container, item);
    return const InventoryManualProductSaveOutcome.canceled();
  }

  final completedEatFlow = await _completeEatFlow(
    context: context,
    item: item,
    request: eatResult.request,
    onDirectCalorieEntrySaved: (entryId) => savedCalorieEntryId = entryId,
  );
  if (!completedEatFlow) {
    await _deleteSavedItem(container, item);
    return const InventoryManualProductSaveOutcome.canceled();
  }
  return InventoryManualProductSaveOutcome.saved(
    item,
    calorieEntryId: savedCalorieEntryId,
    addMoreRequested: eatResult.addMoreRequested,
  );
}

Future<InventoryItemEatSheetResult?> _resolveEatResult({
  required BuildContext context,
  required AppLocalizations l10n,
  required InventoryReceiptManualProductResult result,
  required InventoryItem item,
  required MealType? preselectedMealType,
  required DateTime? preselectedLoggedAt,
  required bool continueBatchOnConfirm,
}) {
  final selectedRequest = inventoryManualAddEatRequestFromSelection(
    result.eatSelection,
  );
  final confirmIntent = _confirmIntent(continueBatchOnConfirm);
  if (selectedRequest != null) {
    return Future.value(selectedRequest.asSheetResult(confirmIntent));
  }
  return _showEatSheet(
    context: context,
    l10n: l10n,
    item: item,
    preselectedMealType: preselectedMealType,
    preselectedLoggedAt: preselectedLoggedAt,
    continueBatchOnConfirm: continueBatchOnConfirm,
  );
}

Future<InventoryItemEatSheetResult?> _showEatSheet({
  required BuildContext context,
  required AppLocalizations l10n,
  required InventoryItem item,
  required MealType? preselectedMealType,
  required DateTime? preselectedLoggedAt,
  required bool continueBatchOnConfirm,
}) async {
  final maxAmount = resolveInventoryManualAddConsumableAmount(item);
  if (maxAmount == null) {
    showInventoryManualAddSnackBar(
      context: context,
      message: l10n.inventoryItemActionFailed,
    );
    return null;
  }

  return InventoryQuickEatFlow.showItemSheetResult(
    context: context,
    item: item,
    maxAmount: maxAmount,
    invalidAmountMessage: l10n.inventoryReceiptReviewInvalidNumber,
    confirmIntent: _confirmIntent(continueBatchOnConfirm),
    initialInventoryAmount: resolveInventoryManualAddInitialConsumedAmount(
      item: item,
      rawWeight: item.weight,
    ),
    initialLoggedAt: preselectedLoggedAt,
    initialMealType: preselectedMealType,
    addMoreActionText: continueBatchOnConfirm
        ? null
        : l10n.inventoryItemEatSheetAddMoreAction,
  );
}

InventoryItemEatSheetIntent _confirmIntent(bool continueBatchOnConfirm) {
  return continueBatchOnConfirm
      ? InventoryItemEatSheetIntent.addMore
      : InventoryItemEatSheetIntent.logOnly;
}

extension on InventoryItemEatRequest {
  InventoryItemEatSheetResult asSheetResult(
    InventoryItemEatSheetIntent intent,
  ) {
    return InventoryItemEatSheetResult(
      request: this,
      intent: intent,
    );
  }
}

@Dependencies([InventoryItemsController, inventoryBackedCalorieEntrySaveFlow])
Future<bool> _completeEatFlow({
  required BuildContext context,
  required InventoryItem item,
  required InventoryItemEatRequest request,
  required void Function(String calorieEntryId) onDirectCalorieEntrySaved,
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
    onDirectCalorieEntrySaved: onDirectCalorieEntrySaved,
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
