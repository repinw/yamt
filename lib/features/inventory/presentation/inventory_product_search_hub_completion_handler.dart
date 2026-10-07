import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_save_flow.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_manual_product_save_outcome.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_completion_handler.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_completion_result.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Inventory completion handler for product search hub.
class InventoryProductSearchHubCompletionHandler
    implements ProductSearchHubCompletionHandler {
  /// Creates an inventory completion handler.
  const new();

  @override
  Future<ProductSearchHubCompletionResult> completeResult({
    required BuildContext context,
    required String sourceKey,
    required InventoryReceiptManualProductResult result,
    MealType? preselectedMealType,
    DateTime? preselectedLoggedAt,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await saveManualProductResultToInventory(
      context: context,
      container: ProviderScope.containerOf(context, listen: false),
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
        name: 'InventoryProductSearchHubCompletionHandler',
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
}
