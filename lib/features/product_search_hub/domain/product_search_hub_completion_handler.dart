import 'package:flutter/widgets.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_completion_result.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_saved_selection.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';

/// Contract for completing and persisting product search hub selections.
abstract interface class ProductSearchHubCompletionHandler {
  /// Handles completion and persistence of an edited product result.
  Future<ProductSearchHubCompletionResult> completeResult({
    required BuildContext context,
    required ProductSearchHubRouteArgs args,
    required String sourceKey,
    required InventoryReceiptManualProductResult result,
    bool continueDiaryBatch = false,
  });

  /// Removes a saved selection from caller persistence.
  Future<bool> removeSavedSelection(ProductSearchHubSavedSelection selection);
}
