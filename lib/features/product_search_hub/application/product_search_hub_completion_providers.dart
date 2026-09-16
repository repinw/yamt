import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_completion_handler.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_completion_result.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_saved_selection.dart';

part 'product_search_hub_completion_providers.g.dart';

/// Default no-op completion handler for selection mode.
class SelectionProductSearchHubCompletionHandler
    implements ProductSearchHubCompletionHandler {
  /// Creates a selection completion handler.
  const SelectionProductSearchHubCompletionHandler();

  @override
  Future<ProductSearchHubCompletionResult> completeResult({
    required BuildContext context,
    required String sourceKey,
    required InventoryReceiptManualProductResult result,
    MealType? preselectedMealType,
    DateTime? preselectedLoggedAt,
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

/// Resolves a mode-specific completion handler at the application boundary.
typedef ProductSearchHubCompletionHandlerFactory =
    ProductSearchHubCompletionHandler Function(ProductSearchHubMode mode);

/// Provides the default no-op handler factory for standalone hub usage.
@Riverpod(keepAlive: true)
ProductSearchHubCompletionHandlerFactory
productSearchHubCompletionHandlerFactory(Ref ref) {
  return (_) => const SelectionProductSearchHubCompletionHandler();
}

/// Provides the completion handler for the given [mode].
@riverpod
ProductSearchHubCompletionHandler productSearchHubCompletionHandler(
  Ref ref,
  ProductSearchHubMode mode,
) {
  return ref.watch(productSearchHubCompletionHandlerFactoryProvider)(mode);
}
