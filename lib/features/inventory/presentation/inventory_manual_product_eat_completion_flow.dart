import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_eat_outcome.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_manual_add_amount_service.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_item_eat_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_amount_unit_l10n.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_eat_selection_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_save_flow.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_eat_sheet_result.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_manual_product_save_outcome.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_rest_to_stock_dialog.dart';
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

Future<InventoryManualProductSaveOutcome> _saveManualProductResultForEatFlow({
  required BuildContext context,
  required ProviderContainer container,
  required AppLocalizations l10n,
  required InventoryReceiptManualProductResult result,
  required MealType? preselectedMealType,
  required DateTime? preselectedLoggedAt,
}) async {
  final eatResult = await InventoryManualProductEatSelectionFlow.resolve(
    context: context,
    l10n: l10n,
    item: result.item,
    selectedRequest:
        result.eatRequest ??
        inventoryManualAddEatRequestFromSelection(result.eatSelection),
    preselectedMealType: preselectedMealType,
    preselectedLoggedAt: preselectedLoggedAt,
  );
  if (!context.mounted || eatResult == null) {
    log(
      'Manual product eat selection closed without a result '
      '(mounted=${context.mounted}).',
      name: _inventoryManualProductEatFlowLogName,
    );
    return const InventoryManualProductSaveOutcome.canceled();
  }
  final eating = container.read(inventoryItemEatControllerProvider.notifier);
  if (eating.isPlan(eatResult.request)) {
    return await _plan(context, container, l10n, result, eatResult);
  }

  // A rest of a known package may stay in the Vorrat instead of being
  // dropped with the resize to the eaten amount.
  final keepsRest = await _askKeepRest(context, result.item, eatResult);
  if (!context.mounted) {
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
      adjustItem: (item) => keepsRest
          ? item
          : resizeInventoryManualAddItemToConsumedAmount(
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

    final completedEatFlow = await completeInventoryManualAddEatFlow(
      context: context,
      item: savedItem,
      request: eatResult.request,
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
    return InventoryManualProductSaveOutcome.saved(savedItem);
  } finally {
    inventorySubscription.close();
  }
}

/// Plans [eatResult] for the found product. A plan takes no stock, so the
/// product does not go into the Vorrat; the shared catalog still learns it.
Future<InventoryManualProductSaveOutcome> _plan(
  BuildContext context,
  ProviderContainer container,
  AppLocalizations l10n,
  InventoryReceiptManualProductResult result,
  InventoryItemEatSheetResult eatResult,
) async {
  final built = await saveManualProductResultToInventory(
    context: context,
    container: container,
    l10n: l10n,
    result: result,
    adjustItem: (item) => resizeInventoryManualAddItemToConsumedAmount(
      item: item,
      inventoryAmount: eatResult.request.inventoryAmount,
    ),
    addToInventory: false,
  );
  final item = built.item;
  if (built.status != InventoryManualProductSaveStatus.saved || item == null) {
    return built;
  }
  final InventoryEatOutcome outcome;
  try {
    outcome = await container
        .read(inventoryItemEatControllerProvider.notifier)
        .planNew(item: item, request: eatResult.request);
  } on Object catch (error, stackTrace) {
    log(
      'Failed to save the plan for ${item.name}.',
      name: _inventoryManualProductEatFlowLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return const InventoryManualProductSaveOutcome.planFailed(
      InventoryEatFailure.notSaved,
    );
  }
  return switch (outcome) {
    InventoryEatPlanned(:final entry) =>
      InventoryManualProductSaveOutcome.planned(entry),
    InventoryEatFailed(:final failure) =>
      InventoryManualProductSaveOutcome.planFailed(failure),
    InventoryEatLogged() || InventoryEatNeedsEditor() => throw StateError(
      'A plan never logs or needs the editor.',
    ),
  };
}

/// Asks whether the rest of [item]'s package goes into the Vorrat, when its
/// package size is known and [eatResult] does not eat all of it.
Future<bool> _askKeepRest(
  BuildContext context,
  InventoryItem item,
  InventoryItemEatSheetResult eatResult,
) async {
  final rest = inventoryManualAddRestAmount(
    item: item,
    inventoryAmount: eatResult.request.inventoryAmount,
  );
  final unit = item.amountUnit;
  if (rest == null || unit == null) {
    return false;
  }
  final amount = formatInventoryAmountValue(
    amount: rest,
    unit: unit,
    scale: item.amountScale,
  );
  final l10n = AppLocalizations.of(context)!;
  return await showInventoryRestToStockDialog(
    context,
    rest: l10n.inventoryEatSheetAmountWithUnit(
      amount,
      unit.localizedName(l10n),
    ),
  );
}

Future<void> _deleteSavedItem(
  ProviderContainer container,
  InventoryItem savedItem,
) {
  return container
      .read(inventoryItemsControllerProvider.notifier)
      .deleteItem(savedItem.id);
}
