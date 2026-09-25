import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart'
    as inventory_models;
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_barcode_direct_result.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_editor_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_recent_item_key.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _resultFlowLogName = 'ProductSearchHubResultFlow';

/// Completes a product-search hub result selected by the user.
typedef ProductSearchHubResultCompleter = Future<void> Function({
  required String sourceKey,
  required inventory_models.InventoryReceiptManualProductResult result,
});

/// Reports whether a source key is already blocked by current hub state.
typedef ProductSearchHubSourceBlocker = bool Function(String sourceKey);

/// Opens the right follow-up flow for a selected OFF product.
Future<void> editAndSaveProductSearchHubProduct({
  required BuildContext context,
  required ProductSearchHubRouteArgs args,
  required OffProductSearchResult product,
  required ProductSearchHubSourceBlocker isSourceBlocked,
  required ProductSearchHubResultCompleter completeResult,
}) async {
  final sourceKey = product.code;
  if (isSourceBlocked(sourceKey)) {
    return;
  }

  final directResult = _directDiaryProductResult(
    context: context,
    args: args,
    product: product,
  );
  if (directResult != null) {
    await completeResult(sourceKey: sourceKey, result: directResult);
    return;
  }

  await _editAndSaveDraft(
    context: context,
    args: args,
    sourceKey: sourceKey,
    isSourceBlocked: isSourceBlocked,
    completeResult: completeResult,
    openEditor: (draftItem) => openProductSearchHubSelectedProductEditor(
      context: context,
      draftItem: draftItem,
      product: product,
      args: args,
    ),
  );
}

/// Opens the right follow-up flow for a recently selected inventory item.
Future<void> editAndSaveProductSearchHubRecentItem({
  required BuildContext context,
  required ProductSearchHubRouteArgs args,
  required InventoryItem item,
  required ProductSearchHubSourceBlocker isSourceBlocked,
  required ProductSearchHubResultCompleter completeResult,
}) async {
  final sourceKey = productSearchHubRecentItemSelectionKey(item);
  if (isSourceBlocked(sourceKey)) {
    log(
      'Ignoring recent item ${item.id}: $sourceKey is already selected or '
      'a save is running.',
      name: _resultFlowLogName,
    );
    return;
  }

  final directResult = _directDiaryRecentItemResult(args: args, item: item);
  if (directResult != null) {
    await completeResult(sourceKey: sourceKey, result: directResult);
    return;
  }

  await _editAndSaveDraft(
    context: context,
    args: args,
    sourceKey: sourceKey,
    isSourceBlocked: isSourceBlocked,
    completeResult: completeResult,
    openEditor: (draftItem) => openProductSearchHubRecentItemEditor(
      context: context,
      draftItem: draftItem,
      recentItem: item,
      args: args,
    ),
  );
}

Future<void> _editAndSaveDraft({
  required BuildContext context,
  required ProductSearchHubRouteArgs args,
  required String sourceKey,
  required ProductSearchHubSourceBlocker isSourceBlocked,
  required ProductSearchHubResultCompleter completeResult,
  required Future<inventory_models.InventoryReceiptManualProductResult?>
  Function(InventoryItem draftItem)
  openEditor,
}) async {
  if (isSourceBlocked(sourceKey)) {
    return;
  }

  final l10n = AppLocalizations.of(context)!;
  final draftItem = buildProductSearchHubDraftItem(
    l10n: l10n,
    sourceItem: args.item,
  );
  final result = await openEditor(draftItem);
  if (!context.mounted || result == null) {
    return;
  }
  await completeResult(sourceKey: sourceKey, result: result);
}

inventory_models.InventoryReceiptManualProductResult?
_directDiaryProductResult({
  required BuildContext context,
  required ProductSearchHubRouteArgs args,
  required OffProductSearchResult product,
}) {
  if (args.mode != ProductSearchHubMode.diary) {
    return null;
  }
  final l10n = AppLocalizations.of(context)!;
  return productSearchHubDirectDiaryProductResult(
    container: ProviderScope.containerOf(context, listen: false),
    draftItem: buildProductSearchHubDraftItem(
      l10n: l10n,
      sourceItem: args.item,
    ),
    args: args,
    product: product,
  );
}

inventory_models.InventoryReceiptManualProductResult?
_directDiaryRecentItemResult({
  required ProductSearchHubRouteArgs args,
  required InventoryItem item,
}) {
  if (args.mode != ProductSearchHubMode.diary) {
    return null;
  }
  // A recent item is an old stock entry that is usually eaten up. Eating it
  // again starts from one full package.
  return productSearchHubDirectDiaryInventoryItemResult(
    args: args,
    item: item.withDerivedAmount(quantity: 1, fallbackUnit: item.amountUnit),
    selectedGlobalFoodItemId: manualProductRecentItemGlobalFoodItemId(item),
    globalPackageWeight: item.weight,
  );
}
