import 'package:flutter/material.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_editor_page/'
    'manual_product_search_editor_support.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_types.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'product_ai_search_page/product_ai_search_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the nested product editor for [product].
Future<void> openSelectedProductEditor({
  required BuildContext context,
  required InventoryManualAddQuickEatConfig quickEatConfig,
  required InventoryReceiptManualProductConfig parentConfig,
  required OffProductSearchResult product,
  required InventoryReceiptManualProductAction action,
  required bool showEatImmediatelyOption,
  required bool showActionSelector,
  required Future<void> Function(InventoryReceiptManualProductResult)? onSaved,
  required void Function(InventoryReceiptManualProductResult) onClosePage,
  String? initialInfoMessage,
}) async {
  final config = InventoryReceiptManualProductConfig(
    item: parentConfig.item,
    selectedProduct: product,
    includeStoreInSearch: parentConfig.includeStoreInSearch,
    includeWeightInSearch: parentConfig.includeWeightInSearch,
  );
  final result =
      await pushManualProductSearchPage<InventoryReceiptManualProductResult>(
        context: context,
        args: ManualProductSearchRouteArgs.editor(
          config: config,
          showEatImmediatelyOption: showEatImmediatelyOption,
          initialAction: action,
          closeCurrentEditorOnSave: true,
          showActionSelector: showActionSelector,
          initialInfoMessage: initialInfoMessage,
          quickEatConfig: quickEatConfig,
        ),
      );
  if (!context.mounted || result == null) {
    return;
  }

  if (onSaved != null) {
    await onSaved(result);
    return;
  }
  onClosePage(result);
}

/// Opens the AI product search child route.
Future<void> openManualProductAiSearchPage({
  required BuildContext context,
  required InventoryManualAddQuickEatConfig quickEatConfig,
  required InventoryReceiptManualProductConfig config,
  required String searchQuery,
  required bool showEatImmediatelyOption,
  required InventoryReceiptManualProductAction selectedAction,
  required bool closeCurrentEditorOnSave,
  required Future<void> Function(InventoryReceiptManualProductResult)? onSaved,
  required void Function(InventoryReceiptManualProductResult) onClosePage,
}) async {
  final result =
      await pushManualProductSearchPage<ManualProductAiSearchResult>(
        context: context,
        args: ManualProductSearchRouteArgs.aiSearch(
          item: config.item,
          initialPrompt: searchQuery,
          showEatImmediatelyOption: showEatImmediatelyOption,
          initialAction: selectedAction,
          quickEatConfig: quickEatConfig,
        ),
      );
  if (!context.mounted || result == null) {
    return;
  }

  final wrappedResult = InventoryReceiptManualProductResult(
    item: result.item,
    action: result.action,
    globalPackageWeight: result.globalPackageWeight,
    skipMissingBarcodePrompt: true,
    eatSelection: result.eatSelection,
  );
  if (closeCurrentEditorOnSave) {
    onClosePage(wrappedResult);
    return;
  }
  if (onSaved != null) {
    await onSaved(wrappedResult);
    return;
  }
  onClosePage(wrappedResult);
}

/// Handles search result selection and directs to eat-now, editor, or form.
Future<void> handleEditorSearchResultAction({
  required BuildContext context,
  required InventoryManualAddQuickEatConfig quickEatConfig,
  required OffProductSearchResult product,
  required InventoryReceiptManualProductAction action,
  required InventoryReceiptManualProductConfig config,
  required InventoryReceiptManualProductController controller,
  required bool autofocusSearch,
  required bool showEatImmediatelyOption,
  required Future<void> Function() onStopVoiceSearch,
  required Future<void> Function(InventoryReceiptManualProductResult)? onSaved,
  required void Function(InventoryReceiptManualProductResult) onClosePage,
  required void Function(InventoryReceiptManualProductAction action)
  onApplyAction,
}) async {
  final eatNowRequiresNutritionMessage = AppLocalizations.of(
    context,
  )!.inventoryManualAddEatNowRequiresNutrition;
  await onStopVoiceSearch();
  if (!context.mounted) {
    return;
  }
  if (action == InventoryReceiptManualProductAction.eatNow) {
    final directEat = tryBuildDirectEatResultFromSearchResult(
      product: product,
      controller: controller,
    );
    if (directEat != null) {
      onClosePage(directEat);
      return;
    }
  }

  if (autofocusSearch || quickEatConfig.quickEatOnly) {
    await openSelectedProductEditor(
      context: context,
      quickEatConfig: quickEatConfig,
      parentConfig: config,
      product: product,
      action: action,
      showEatImmediatelyOption: showEatImmediatelyOption,
      showActionSelector: false,
      initialInfoMessage: action == InventoryReceiptManualProductAction.eatNow
          ? eatNowRequiresNutritionMessage
          : null,
      onSaved: onSaved,
      onClosePage: onClosePage,
    );
    return;
  }
  if (!context.mounted) {
    return;
  }
  onApplyAction(action);
  controller.applySearchResult(product);
}
