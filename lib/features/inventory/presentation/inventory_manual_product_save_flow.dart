import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_manual_add_product_factory.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_dialogs.dart';
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
  const new _({
    required this.status,
    this.item,
    this.calorieEntryId,
    this.addMoreRequested = false,
  });

  /// Saved outcome.
  factory saved(
    InventoryItem item, {
    String? calorieEntryId,
    bool addMoreRequested = false,
  }) {
    return InventoryManualProductSaveOutcome._(
      status: InventoryManualProductSaveStatus.saved,
      item: item,
      calorieEntryId: calorieEntryId,
      addMoreRequested: addMoreRequested,
    );
  }

  /// Canceled outcome.
  const new canceled()
    : this._(status: InventoryManualProductSaveStatus.canceled);

  /// Failed outcome.
  const new failed() : this._(status: InventoryManualProductSaveStatus.failed);

  /// Outcome status.
  final InventoryManualProductSaveStatus status;

  /// Saved inventory item.
  final InventoryItem? item;

  /// Calorie entry id created by an immediate diary eat flow.
  final String? calorieEntryId;

  /// Whether user asked to add another food after this save.
  final bool addMoreRequested;
}

/// Saves edited manual product result using inventory persistence rules.
///
/// [adjustItem] changes the built item before its only write, for example to
/// size it to the eaten amount.
Future<InventoryManualProductSaveOutcome> saveManualProductResultToInventory({
  required BuildContext context,
  required ProviderContainer container,
  required AppLocalizations l10n,
  required InventoryReceiptManualProductResult result,
  InventoryItem Function(InventoryItem item)? adjustItem,
}) async {
  try {
    return await _saveManualProductResultToInventory(
      context: context,
      container: container,
      l10n: l10n,
      result: result,
      adjustItem: adjustItem,
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

Future<InventoryManualProductSaveOutcome> _saveManualProductResultToInventory({
  required BuildContext context,
  required ProviderContainer container,
  required AppLocalizations l10n,
  required InventoryReceiptManualProductResult result,
  required InventoryItem Function(InventoryItem item)? adjustItem,
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
  final inventorySubscription = container.listen(
    inventoryItemsControllerProvider,
    (_, _) {},
    fireImmediately: true,
  );
  try {
    await _waitForInitializedInventory(container);
    if (!context.mounted) {
      return const InventoryManualProductSaveOutcome.canceled();
    }
    final inventoryItemsController = container.read(
      inventoryItemsControllerProvider.notifier,
    );
    return await _saveManualProductWithReadyInventory(
      container: container,
      l10n: l10n,
      result: result,
      promptResult: promptResult,
      now: now,
      inventoryItemsController: inventoryItemsController,
      adjustItem: adjustItem,
    );
  } finally {
    inventorySubscription.close();
  }
}

Future<void> _waitForInitializedInventory(ProviderContainer container) async {
  final current = container.read(inventoryItemsControllerProvider);
  if (current is! AsyncLoading) {
    return;
  }
  final completer = Completer<void>();
  final sub = container.listen<AsyncValue<List<InventoryItem>>>(
    inventoryItemsControllerProvider,
    (_, next) {
      if (next is! AsyncLoading && !completer.isCompleted) {
        completer.complete();
      }
    },
  );
  try {
    await completer.future;
  } finally {
    sub.close();
  }
}

Future<InventoryManualProductSaveOutcome> _saveManualProductWithReadyInventory({
  required ProviderContainer container,
  required AppLocalizations l10n,
  required InventoryReceiptManualProductResult result,
  required _ManualBarcodePromptResult promptResult,
  required DateTime now,
  required InventoryItemsController inventoryItemsController,
  required InventoryItem Function(InventoryItem item)? adjustItem,
}) async {
  final globalProduct = buildInventoryManualAddGlobalFoodItem(
    item: promptResult.item,
    barcode: promptResult.barcode,
    now: now,
    selectedProduct: result.selectedProduct,
    selectedGlobalFoodItemId: result.selectedGlobalFoodItemId,
    packageWeight: result.globalPackageWeight,
    manualGlobalFoodItemId: _inventoryManualProductSaveGlobalFoodItemId.v4(),
  );
  final builtItem = buildInventoryManualAddSavedItem(
    id: _inventoryManualProductSaveItemId.v4(),
    globalProduct: globalProduct,
    now: now,
    storeName: l10n.inventoryManualAddStoreName,
    inventoryWeight: resolveInventoryManualAddInventoryWeight(
      promptResult.item.weight,
    ),
  );
  final savedItem = adjustItem?.call(builtItem) ?? builtItem;
  final inventorySaved = await inventoryItemsController.addItem(savedItem);
  if (!inventorySaved) {
    return const InventoryManualProductSaveOutcome.failed();
  }
  unawaited(
    _persistGlobalProduct(
      container: container,
      globalProduct: globalProduct,
      requiresGlobalPersistence: result.requiresGlobalPersistence,
      barcode: promptResult.barcode,
      selectedAt: now,
    ),
  );
  return InventoryManualProductSaveOutcome.saved(savedItem);
}

/// Writes the shared catalog product and its barcode selection.
///
/// It runs in the background because both are catalog extras: the user's
/// inventory item and diary entry do not wait for the server.
Future<void> _persistGlobalProduct({
  required ProviderContainer container,
  required GlobalFoodItem globalProduct,
  required bool requiresGlobalPersistence,
  required String? barcode,
  required DateTime selectedAt,
}) async {
  try {
    if (requiresGlobalPersistence) {
      final saved = await container
          .read(globalFoodItemRepositoryProvider)
          .appendAll([globalProduct]);
      if (!saved) {
        log(
          'Failed to save global product ${globalProduct.id}.',
          name: _inventoryManualProductSaveLogName,
        );
        return;
      }
    }
    if (barcode != null) {
      await container
          .read(globalBarcodeCandidateRepositoryProvider)
          .recordSelection(
            barcode: barcode,
            globalFoodItem: globalProduct,
            selectedAt: selectedAt,
          );
    }
  } on Object catch (error, stackTrace) {
    log(
      'Failed to persist global product ${globalProduct.id}.',
      name: _inventoryManualProductSaveLogName,
      error: error,
      stackTrace: stackTrace,
    );
  }
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
  const new({required this.item, required this.barcode});

  final InventoryItem item;
  final String? barcode;
}
