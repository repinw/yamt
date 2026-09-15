import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_product_search_hub_completion_handler.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_product_search_hub_completion_handler.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_completion_handler.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_completion_result.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_saved_selection.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';

part 'product_search_hub_completion_providers.g.dart';

/// Default no-op completion handler for selection mode.
class SelectionProductSearchHubCompletionHandler
    implements ProductSearchHubCompletionHandler {
  /// Creates a selection completion handler.
  const SelectionProductSearchHubCompletionHandler();

  @override
  Future<ProductSearchHubCompletionResult> completeResult({
    required BuildContext context,
    required ProductSearchHubRouteArgs args,
    required String sourceKey,
    required InventoryReceiptManualProductResult result,
    bool continueDiaryBatch = false,
  }) async {
    return const ProductSearchHubCompletionResult.none();
  }

  @override
  Future<bool> removeSavedSelection(
    ProductSearchHubSavedSelection selection,
  ) async {
    return true;
  }
}

/// Provides the completion handler for the given [mode].
@Riverpod(
  dependencies: [
    InventoryItemsController,
    inventoryBackedCalorieEntrySaveFlow,
  ],
)
ProductSearchHubCompletionHandler productSearchHubCompletionHandler(
  Ref ref,
  ProductSearchHubMode mode,
) {
  return switch (mode) {
    ProductSearchHubMode.inventory =>
      InventoryProductSearchHubCompletionHandler(container: ref.container),
    ProductSearchHubMode.diary => DiaryProductSearchHubCompletionHandler(
      container: ref.container,
    ),
    ProductSearchHubMode.selection =>
      const SelectionProductSearchHubCompletionHandler(),
  };
}
