import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:yamt/core/widgets/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_editor_page/'
    'manual_product_search_editor_barcode_coordinator.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_editor_page/'
    'manual_product_search_editor_navigation.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_types.dart';

/// Launches the barcode scanner flow and dispatches candidate actions.
Future<void> launchEditorBarcodeScanner({
  required BuildContext context,
  required InventoryManualAddQuickEatConfig quickEatConfig,
  required InventoryReceiptManualProductConfig config,
  required InventoryReceiptManualProductController controller,
  required TextVoiceSearchController voiceSearchController,
  required bool showEatImmediatelyOption,
  required bool autofocusSearch,
  required void Function(
    InventoryReceiptManualProductAction action,
    VoidCallback apply,
  )
  onApplyAction,
  required void Function(String message) onShowSnackBar,
  required Future<void> Function(InventoryReceiptManualProductResult)? onSaved,
  required void Function(InventoryReceiptManualProductResult) onClosePage,
}) {
  return openEditorBarcodeScanner(
    context: context,
    quickEatConfig: quickEatConfig,
    config: config,
    controller: controller,
    showEatImmediatelyOption: showEatImmediatelyOption,
    autofocusSearch: autofocusSearch,
    onStopVoiceSearch: voiceSearchController.stopVoiceSearchIfNeeded,
    onDirectComplete: onClosePage,
    onApplyScannedProduct: (product, action) => onApplyAction(
      action,
      () => controller.applyScannedProduct(product),
    ),
    onApplyScannedInventoryItem: (item, action) => onApplyAction(
      action,
      () => controller.applyRecentItem(item),
    ),
    onApplyScannedBarcodeOnly: controller.applyScannedBarcodeOnly,
    onShowSnackBar: onShowSnackBar,
    onSaved: onSaved,
    onClosePage: onClosePage,
  );
}

/// Dispatches selected search result actions with voice-search cleanup.
Future<void> launchEditorSearchResultAction({
  required BuildContext context,
  required InventoryManualAddQuickEatConfig quickEatConfig,
  required OffProductSearchResult product,
  required InventoryReceiptManualProductAction action,
  required InventoryReceiptManualProductConfig config,
  required InventoryReceiptManualProductController controller,
  required TextVoiceSearchController voiceSearchController,
  required bool autofocusSearch,
  required bool showEatImmediatelyOption,
  required Future<void> Function(InventoryReceiptManualProductResult)? onSaved,
  required void Function(InventoryReceiptManualProductResult) onClosePage,
  required void Function(
    InventoryReceiptManualProductAction action,
    VoidCallback apply,
  )
  onApplyAction,
}) {
  return handleEditorSearchResultAction(
    context: context,
    quickEatConfig: quickEatConfig,
    product: product,
    action: action,
    config: config,
    controller: controller,
    autofocusSearch: autofocusSearch,
    showEatImmediatelyOption: showEatImmediatelyOption,
    onStopVoiceSearch: voiceSearchController.stopVoiceSearchIfNeeded,
    onSaved: onSaved,
    onClosePage: onClosePage,
    onApplyAction: (chosen) => onApplyAction(chosen, () {}),
  );
}

/// Launches the AI search sub-page after stopping active voice search.
Future<void> launchEditorAiSearchPage({
  required BuildContext context,
  required InventoryManualAddQuickEatConfig quickEatConfig,
  required InventoryReceiptManualProductConfig config,
  required TextVoiceSearchController voiceSearchController,
  required String searchQuery,
  required bool showEatImmediatelyOption,
  required InventoryReceiptManualProductAction selectedAction,
  required bool closeCurrentEditorOnSave,
  required Future<void> Function(InventoryReceiptManualProductResult)? onSaved,
  required void Function(InventoryReceiptManualProductResult) onClosePage,
}) async {
  await voiceSearchController.stopVoiceSearchIfNeeded();
  if (!context.mounted) {
    return;
  }
  await openManualProductAiSearchPage(
    context: context,
    quickEatConfig: quickEatConfig,
    config: config,
    searchQuery: searchQuery,
    showEatImmediatelyOption: showEatImmediatelyOption,
    selectedAction: selectedAction,
    closeCurrentEditorOnSave: closeCurrentEditorOnSave,
    onSaved: onSaved,
    onClosePage: onClosePage,
  );
}

/// Stops voice search and triggers starting a manual product draft.
Future<void> startManualProductDraftWithVoiceCleanup({
  required TextVoiceSearchController voiceSearchController,
  required InventoryReceiptManualProductController controller,
}) async {
  await voiceSearchController.stopVoiceSearchIfNeeded();
  controller.startManualProductDraft();
}

/// Shows a standard snackbar on the nearest ScaffoldMessenger.
void showEditorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Cancels voice search and pops the editor page with an optional result.
void closeEditorPage<T extends Object?>({
  required BuildContext context,
  required TextVoiceSearchController voiceSearchController,
  T? result,
}) {
  unawaited(voiceSearchController.cancelVoiceSearch());
  popManualProductSearchPage(context, result);
}

/// Schedules initial info message display on next frame if present.
void scheduleEditorInitialInfoMessage({
  required String? message,
  required bool Function() isMounted,
  required void Function(String message) onShowSnackBar,
}) {
  if (message == null) {
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (isMounted()) {
      onShowSnackBar(message);
    }
  });
}

/// Schedules applying the initial recent item on next frame if present.
void scheduleEditorInitialRecentItem({
  required InventoryItem? recentItem,
  required bool Function() isMounted,
  required void Function(InventoryItem item) onApplyRecentItem,
}) {
  if (recentItem == null) {
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (isMounted()) {
      onApplyRecentItem(recentItem);
    }
  });
}
