import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_manual_add_product_factory.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_dialogs.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _inventoryManualProductSaveItemId = Uuid();
const _inventoryManualProductSaveGlobalFoodItemId = Uuid();
const _inventoryManualProductSaveLogName = 'InventoryManualProductSaveFlow';

/// Manual product inventory save status.
enum InventoryManualProductSaveStatus {
  /// Product was saved.
  saved,

  /// User canceled a required save step.
  canceled,

  /// Save failed.
  failed,
}

/// Manual product inventory save outcome.
class InventoryManualProductSaveOutcome {
  const InventoryManualProductSaveOutcome._({
    required this.status,
    this.item,
  });

  /// Saved outcome.
  factory InventoryManualProductSaveOutcome.saved(InventoryItem item) {
    return InventoryManualProductSaveOutcome._(
      status: InventoryManualProductSaveStatus.saved,
      item: item,
    );
  }

  /// Canceled outcome.
  const InventoryManualProductSaveOutcome.canceled()
    : this._(status: InventoryManualProductSaveStatus.canceled);

  /// Failed outcome.
  const InventoryManualProductSaveOutcome.failed()
    : this._(status: InventoryManualProductSaveStatus.failed);

  /// Outcome status.
  final InventoryManualProductSaveStatus status;

  /// Saved inventory item.
  final InventoryItem? item;
}

/// Saves edited manual product result using inventory persistence rules.
@Dependencies([
  InventoryItemsController,
])
Future<InventoryManualProductSaveOutcome> saveManualProductResultToInventory({
  required BuildContext context,
  required ProviderContainer container,
  required AppLocalizations l10n,
  required InventoryReceiptManualProductResult result,
}) async {
  try {
    return await _saveManualProductResultToInventory(
      context: context,
      container: container,
      l10n: l10n,
      result: result,
    );
  } on Object catch (error, stackTrace) {
    log(
      'Failed to save manual product result.',
      name: _inventoryManualProductSaveLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return const InventoryManualProductSaveOutcome.failed();
  }
}

@Dependencies([
  InventoryItemsController,
])
Future<InventoryManualProductSaveOutcome> _saveManualProductResultToInventory({
  required BuildContext context,
  required ProviderContainer container,
  required AppLocalizations l10n,
  required InventoryReceiptManualProductResult result,
}) async {
  final promptResult = result.skipMissingBarcodePrompt
      ? _ManualBarcodePromptResult(
          item: result.item,
          barcode: result.item.normalizedBarcode,
        )
      : await _resolveMissingBarcode(context, result.item);
  if (!context.mounted || promptResult == null) {
    return const InventoryManualProductSaveOutcome.canceled();
  }

  final now = DateTime.now();
  final inventoryItemsController = container.read(
    inventoryItemsControllerProvider.notifier,
  );
  final globalProduct = buildInventoryManualAddGlobalFoodItem(
    item: promptResult.item,
    barcode: promptResult.barcode,
    now: now,
    selectedProduct: result.selectedProduct,
    selectedGlobalFoodItemId: result.selectedGlobalFoodItemId,
    packageWeight: result.globalPackageWeight,
    manualGlobalFoodItemId: _inventoryManualProductSaveGlobalFoodItemId.v4(),
  );
  final globalSaved =
      !result.requiresGlobalPersistence ||
      await container.read(globalFoodItemRepositoryProvider).appendAll([
        globalProduct,
      ]);
  final savedItem = buildInventoryManualAddSavedItem(
    id: _inventoryManualProductSaveItemId.v4(),
    globalProduct: globalProduct,
    globalSaved: globalSaved,
    now: now,
    storeName: l10n.inventoryManualAddStoreName,
    inventoryWeight: resolveInventoryManualAddInventoryWeight(
      promptResult.item.weight,
    ),
  );
  final inventorySaved = await inventoryItemsController.addItem(savedItem);
  if (!inventorySaved) {
    return const InventoryManualProductSaveOutcome.failed();
  }
  if (globalSaved && promptResult.barcode != null) {
    await container
        .read(globalBarcodeCandidateRepositoryProvider)
        .recordSelection(
          barcode: promptResult.barcode!,
          globalFoodItem: globalProduct,
          selectedAt: now,
        );
  }
  return InventoryManualProductSaveOutcome.saved(savedItem);
}

Future<_ManualBarcodePromptResult?> _resolveMissingBarcode(
  BuildContext context,
  InventoryItem item,
) async {
  final currentBarcode = item.normalizedBarcode;
  if (currentBarcode != null) {
    return _ManualBarcodePromptResult(item: item, barcode: currentBarcode);
  }

  final enteredBarcode = await showInventoryManualAddMissingBarcodeDialog(
    context: context,
  );
  if (!context.mounted || enteredBarcode == null) {
    return null;
  }
  if (enteredBarcode.isEmpty) {
    return _ManualBarcodePromptResult(item: item, barcode: null);
  }

  final updatedItem = item.copyWith(barcode: enteredBarcode);
  return _ManualBarcodePromptResult(
    item: updatedItem,
    barcode: updatedItem.normalizedBarcode,
  );
}

class _ManualBarcodePromptResult {
  const _ManualBarcodePromptResult({
    required this.item,
    required this.barcode,
  });

  final InventoryItem item;
  final String? barcode;
}
