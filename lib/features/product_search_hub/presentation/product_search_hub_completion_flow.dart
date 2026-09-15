import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/data/'
    'product_search_hub_completion_providers.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_completion_handler.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_completion_result.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_saved_selection.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/l10n/app_localizations.dart';

export 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_completion_result.dart';

@Dependencies([productSearchHubCompletionHandler])
/// Completes a product search hub editor result for the active route mode.
Future<ProductSearchHubCompletionResult> completeProductSearchHubResult({
  required BuildContext context,
  required ProductSearchHubRouteArgs args,
  required String sourceKey,
  required InventoryReceiptManualProductResult result,
  ProductSearchHubCompletionHandler? handler,
  ProviderContainer? container,
  AppLocalizations? l10n,
  bool continueDiaryBatch = false,
}) {
  final ProductSearchHubCompletionHandler resolvedHandler;
  if (handler != null) {
    resolvedHandler = handler;
  } else if (container != null) {
    resolvedHandler = container.read(
      productSearchHubCompletionHandlerProvider(args.mode),
    );
  } else {
    resolvedHandler = ProviderScope.containerOf(context, listen: false).read(
      productSearchHubCompletionHandlerProvider(args.mode),
    );
  }
  return resolvedHandler.completeResult(
    context: context,
    args: args,
    sourceKey: sourceKey,
    result: result,
    continueDiaryBatch: continueDiaryBatch,
  );
}

@Dependencies([productSearchHubCompletionHandler])
/// Removes a saved hub selection from caller persistence.
Future<bool> removeProductSearchHubSelection({
  required ProductSearchHubSavedSelection selection,
  ProductSearchHubCompletionHandler? handler,
  ProviderContainer? container,
  ProductSearchHubMode? mode,
}) {
  final effectiveMode =
      mode ??
      (selection.calorieEntryId != null
          ? ProductSearchHubMode.diary
          : ProductSearchHubMode.inventory);
  final resolvedHandler =
      handler ??
      container?.read(productSearchHubCompletionHandlerProvider(effectiveMode));
  if (resolvedHandler == null) {
    throw ArgumentError(
      'Either handler or container must be provided to remove selection.',
    );
  }
  return resolvedHandler.removeSavedSelection(selection);
}
