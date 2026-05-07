import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/domain/eat_selection.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _inventoryManualAddAmountParser = InventoryAmountParser();

/// Resolve inventory manual add eat flow max amount.
int? resolveInventoryManualAddEatFlowMaxAmount(InventoryItem item) {
  if (item.usesAmountProgress) {
    if (item.amountUnit == null || item.currentAmount < 1) {
      return null;
    }
    return item.currentAmount;
  }
  if (item.quantity < 1) {
    return null;
  }
  return item.quantity;
}

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
  final maxAmount = resolveInventoryManualAddEatFlowMaxAmount(item);
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

/// Whether manual add must ask for the consumed amount first.
bool requiresInventoryManualAddEatAmountPrompt(InventoryItem item) {
  return item.weight == null ||
      item.amountUnit == null ||
      item.initialAmount < 1;
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

/// Resizes newly saved inventory stock to match immediate consumed amount.
InventoryItem resizeInventoryManualAddItemToImmediateEatAmount({
  required InventoryItem item,
  required InventoryItemEatRequest request,
}) {
  if (request.inventoryAmount < 1) {
    return item;
  }

  final unit = item.amountUnit;
  if (unit == null) {
    if (item.quantity == request.inventoryAmount &&
        item.initialQuantity == request.inventoryAmount) {
      return item;
    }
    return item.copyWith(
      quantity: request.inventoryAmount,
      initialQuantity: request.inventoryAmount,
    );
  }
  if (item.usesAmountProgress &&
      item.currentAmount == request.inventoryAmount) {
    return item;
  }

  final amountScale = safeInventoryManualAddAmountScale(
    unit: unit,
    scale: item.amountScale,
  );
  final amountText = formatInventoryAmountValue(
    amount: request.inventoryAmount,
    unit: unit,
    scale: amountScale,
  );
  return item.withResolvedAmount(
    weight: '$amountText ${unit.code}',
    parsedAmount: InventoryAmountParseResult(
      amount: request.inventoryAmount,
      unit: unit,
      scale: amountScale,
    ),
    quantity: item.quantity < 1 ? 1 : item.quantity,
  );
}

/// Resolves default unit for the manual-add consumed amount prompt.
InventoryAmountUnit defaultInventoryManualAddEatAmountUnit(
  InventoryItem item,
) {
  if (item.amountUnit case final InventoryAmountUnit unit) {
    return unit;
  }

  final combinedHint = <String>[
    item.servingSize ?? '',
    item.servingQuantityUnit ?? '',
  ].join(' ').toLowerCase();
  if (combinedHint.contains('ml') ||
      RegExp(r'(^|\s)l\b').hasMatch(combinedHint)) {
    return InventoryAmountUnit.milliliter;
  }
  if (combinedHint.contains('stk') ||
      combinedHint.contains('stück') ||
      combinedHint.contains('pc')) {
    return InventoryAmountUnit.piece;
  }
  return InventoryAmountUnit.gram;
}

/// Resolves initial amount for the immediate-eat sheet.
int? resolveInventoryManualAddInitialEatAmount({
  required InventoryItem item,
  required String? rawWeight,
}) {
  final amountUnit = item.amountUnit;
  if (amountUnit == null) {
    return null;
  }
  final parsed = _inventoryManualAddAmountParser.tryParse(
    rawWeight: rawWeight,
    quantity: 1,
    fallbackUnit: amountUnit,
  );
  if (parsed == null || parsed.unit != amountUnit || parsed.amount < 1) {
    return null;
  }
  return parsed.amount;
}

/// Safe amount scale for a unit.
int safeInventoryManualAddAmountScale({
  required InventoryAmountUnit unit,
  required int scale,
}) {
  if (scale > 0) {
    return scale;
  }
  return unit == InventoryAmountUnit.piece ? inventoryPieceAmountScale : 1;
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
