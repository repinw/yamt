import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_manual_add_amount_service.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_eat_selection_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_save_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _inventoryManualProductEatFlowLogName =
    'InventoryManualProductEatCompletionFlow';

/// Saves a manual product result and continues into the eat flow.
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

Future<InventoryManualProductSaveOutcome> _saveManualProductResultForEatFlow({
  required BuildContext context,
  required ProviderContainer container,
  required AppLocalizations l10n,
  required InventoryReceiptManualProductResult result,
  required MealType? preselectedMealType,
  required DateTime? preselectedLoggedAt,
  required bool continueBatchOnConfirm,
}) async {
  final eatResult = await InventoryManualProductEatSelectionFlow.resolve(
    context: context,
    l10n: l10n,
    item: result.item,
    selectedRequest: inventoryManualAddEatRequestFromSelection(
      result.eatSelection,
    ),
    preselectedMealType: preselectedMealType,
    preselectedLoggedAt: preselectedLoggedAt,
    continueBatchOnConfirm: continueBatchOnConfirm,
  );
  if (!context.mounted || eatResult == null) {
    log(
      'Manual product eat selection closed without a result '
      '(mounted=${context.mounted}).',
      name: _inventoryManualProductEatFlowLogName,
    );
    return const InventoryManualProductSaveOutcome.canceled();
  }

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
      adjustItem: (item) => resizeInventoryManualAddItemToConsumedAmount(
        item: item,
        inventoryAmount: eatResult.request.inventoryAmount,
      ),
    );
    final savedItem = saveOutcome.item;
    if (saveOutcome.status != InventoryManualProductSaveStatus.saved ||
        savedItem == null) {
      log(
        'Manual product was not saved to inventory '
        '(status=${saveOutcome.status.name}).',
        name: _inventoryManualProductEatFlowLogName,
      );
      return saveOutcome;
    }
    if (!context.mounted) {
      return saveOutcome;
    }

    String? savedCalorieEntryId;
    final completedEatFlow = await completeInventoryManualAddEatFlow(
      context: context,
      item: savedItem,
      request: eatResult.request,
      onDirectCalorieEntrySaved: (entryId) => savedCalorieEntryId = entryId,
    );
    if (!completedEatFlow) {
      log(
        'Eat flow for manual product ${savedItem.id} did not complete; '
        'deleting the saved inventory item.',
        name: _inventoryManualProductEatFlowLogName,
      );
      await _deleteSavedItem(container, savedItem);
      return const InventoryManualProductSaveOutcome.canceled();
    }
    return InventoryManualProductSaveOutcome.saved(
      savedItem,
      calorieEntryId: savedCalorieEntryId,
      addMoreRequested: eatResult.addMoreRequested,
    );
  } finally {
    inventorySubscription.close();
  }
}

Future<void> _deleteSavedItem(
  ProviderContainer container,
  InventoryItem savedItem,
) {
  return container
      .read(inventoryItemsControllerProvider.notifier)
      .deleteItem(savedItem.id);
}
