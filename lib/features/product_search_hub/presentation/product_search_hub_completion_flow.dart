import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_eat_completion_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_save_flow.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_manual_product_save_outcome.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_completion_result.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _completionLogName = 'ProductSearchHubCompletionFlow';

/// Completes a product search hub editor result for the active route mode,
/// or for [mode] in its place: the Vorrat saves the food, the diary eats or
/// plans it, and the pickers save nothing. A food that goes elsewhere
/// through [mode] ends like one eaten food and closes the hub. A diary food
/// put into the Vorrat says so in a message; the diary shows its own for a
/// Vorrat food eaten instead.
Future<ProductSearchHubCompletionResult> completeProductSearchHubResult({
  required BuildContext context,
  required ProductSearchHubRouteArgs args,
  required String sourceKey,
  required InventoryReceiptManualProductResult result,
  ProductSearchHubMode? mode,
  ProviderContainer? container,
  AppLocalizations? l10n,
}) async {
  final effectiveMode = mode ?? args.mode;
  final providers =
      container ?? ProviderScope.containerOf(context, listen: false);
  final strings = l10n ?? AppLocalizations.of(context)!;
  final completion = await switch (effectiveMode) {
    ProductSearchHubMode.inventory => _storeInVorrat(
      context: context,
      container: providers,
      l10n: strings,
      sourceKey: sourceKey,
      result: result,
    ),
    ProductSearchHubMode.diary => _eatInDiary(
      context: context,
      container: providers,
      l10n: strings,
      args: args,
      sourceKey: sourceKey,
      result: result,
    ),
    ProductSearchHubMode.selection || ProductSearchHubMode.mealFood =>
      Future.value(const ProductSearchHubCompletionResult.none()),
  };
  if (effectiveMode == args.mode || !completion.saved || !context.mounted) {
    return completion;
  }
  if (effectiveMode == ProductSearchHubMode.inventory) {
    ScaffoldMessenger.of(
      context,
    ).showAppSnackBar(strings.productSearchHubStoredInVorrat(result.item.name));
  }
  return const ProductSearchHubCompletionResult.closeHub();
}

/// Saves [result] to the Vorrat with the package count picked on the Vorrat
/// page.
Future<ProductSearchHubCompletionResult> _storeInVorrat({
  required BuildContext context,
  required ProviderContainer container,
  required AppLocalizations l10n,
  required String sourceKey,
  required InventoryReceiptManualProductResult result,
}) async {
  final outcome = await saveManualProductResultToInventory(
    context: context,
    container: container,
    l10n: l10n,
    result: result,
    // The saved item is built again from the catalog product, so it keeps
    // the package count picked on the Vorrat page, one bar segment each.
    adjustItem: (item) => item
        .withDerivedAmount(
          quantity: result.item.quantity,
          fallbackUnit: item.amountUnit,
        )
        .copyWith(initialQuantity: result.item.quantity),
  );
  if (!context.mounted) {
    return const ProductSearchHubCompletionResult.none();
  }
  if (outcome.status != InventoryManualProductSaveStatus.saved ||
      outcome.item == null) {
    log(
      'Product search hub result $sourceKey ended with '
      '${outcome.status.name}.',
      name: _completionLogName,
    );
    if (outcome.status == InventoryManualProductSaveStatus.failed) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        l10n.inventoryManualAddSaveFailed,
        tone: AppSnackBarTone.error,
      );
    }
    if (outcome.status == InventoryManualProductSaveStatus.canceled) {
      return const ProductSearchHubCompletionResult.canceled();
    }
    return const ProductSearchHubCompletionResult.none();
  }
  // One food per add (#532): the hub closes back to the Vorrat. Several
  // foods at once come from the receipt scan.
  return const ProductSearchHubCompletionResult.closeHub(saved: true);
}

/// Eats [result] on the route's day and meal, or plans it on a later day.
Future<ProductSearchHubCompletionResult> _eatInDiary({
  required BuildContext context,
  required ProviderContainer container,
  required AppLocalizations l10n,
  required ProductSearchHubRouteArgs args,
  required String sourceKey,
  required InventoryReceiptManualProductResult result,
}) async {
  final outcome = await saveManualProductResultForEatFlow(
    context: context,
    container: container,
    l10n: l10n,
    result: result,
    preselectedMealType: args.preselectedMealType,
    preselectedLoggedAt: args.preselectedLoggedAt,
  );
  if (!context.mounted) {
    return const ProductSearchHubCompletionResult.none();
  }
  if (outcome.status == InventoryManualProductSaveStatus.planned) {
    final plan = outcome.plan!;
    ScaffoldMessenger.of(context).showAppSnackBar(
      l10n.diaryPlanSaved,
      onUndo: () =>
          InventoryItemEatFlow.undoPlan(container: container, plan: plan),
    );
    return const ProductSearchHubCompletionResult.closeHub();
  }
  if (outcome.status != InventoryManualProductSaveStatus.saved ||
      outcome.item == null) {
    log(
      'Product search hub result $sourceKey ended with '
      '${outcome.status.name}.',
      name: _completionLogName,
    );
    if (outcome.status == InventoryManualProductSaveStatus.failed) {
      ScaffoldMessenger.of(context)
          .showAppSnackBar(switch (outcome.planFailure) {
            null => l10n.inventoryManualAddSaveFailed,
            final failure => InventoryItemEatFlow.failureMessage(l10n, failure),
          }, tone: AppSnackBarTone.error);
    }
    if (outcome.status == InventoryManualProductSaveStatus.canceled) {
      return const ProductSearchHubCompletionResult.canceled();
    }
    return const ProductSearchHubCompletionResult.none();
  }
  return const ProductSearchHubCompletionResult.closeHub(saved: true);
}
