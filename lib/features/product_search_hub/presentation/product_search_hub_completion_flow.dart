import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/application/'
    'product_search_hub_completion_providers.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_completion_handler.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_completion_result.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_saved_selection.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Completes a product search hub editor result for the active route mode,
/// or for [mode] in its place. A food that goes elsewhere through [mode],
/// such as a diary food put into the Vorrat, ends like one eaten food: it
/// closes the hub with a message and does not join the hub's selection.
Future<ProductSearchHubCompletionResult> completeProductSearchHubResult({
  required BuildContext context,
  required ProductSearchHubRouteArgs args,
  required String sourceKey,
  required InventoryReceiptManualProductResult result,
  ProductSearchHubMode? mode,
  ProductSearchHubCompletionHandler? handler,
  ProviderContainer? container,
  AppLocalizations? l10n,
  bool continueDiaryBatch = false,
}) async {
  final effectiveMode = mode ?? args.mode;
  final ProductSearchHubCompletionHandler resolvedHandler;
  if (handler != null) {
    resolvedHandler = handler;
  } else if (container != null) {
    resolvedHandler = container.read(
      productSearchHubCompletionHandlerProvider(effectiveMode),
    );
  } else {
    resolvedHandler = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(productSearchHubCompletionHandlerProvider(effectiveMode));
  }
  final completion = await resolvedHandler.completeResult(
    context: context,
    sourceKey: sourceKey,
    result: result,
    preselectedMealType: args.preselectedMealType,
    preselectedLoggedAt: args.preselectedLoggedAt,
    continueDiaryBatch: continueDiaryBatch,
  );
  if (effectiveMode == args.mode ||
      completion.selection == null ||
      !context.mounted) {
    return completion;
  }
  ScaffoldMessenger.of(context).showAppSnackBar(
    (l10n ?? AppLocalizations.of(context)!).productSearchHubStoredInVorrat(
      result.item.name,
    ),
  );
  return const ProductSearchHubCompletionResult.closeHub();
}

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
