import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_saved_selection.dart';

/// Local selection list state for the product search hub page.
class ProductSearchHubSelectionState {
  /// Creates selection state.
  const ProductSearchHubSelectionState(this.selections);

  /// Empty selection state.
  const ProductSearchHubSelectionState.empty()
    : selections = const <ProductSearchHubSavedSelection>[];

  /// Saved selections shown in the hub overlay.
  final List<ProductSearchHubSavedSelection> selections;

  /// Selected product source keys.
  Set<String> get sourceKeys {
    return {
      for (final selection in selections) selection.sourceKey,
    };
  }

  /// Whether a source key is already selected.
  bool containsSourceKey(String sourceKey) {
    return selections.any((selection) => selection.sourceKey == sourceKey);
  }

  /// Adds a saved selection.
  ProductSearchHubSelectionState add(
    ProductSearchHubSavedSelection selection,
  ) {
    return ProductSearchHubSelectionState([...selections, selection]);
  }

  /// Removes a saved selection by inventory item id.
  ProductSearchHubSelectionState removeItemId(String itemId) {
    return ProductSearchHubSelectionState([
      for (final selection in selections)
        if (selection.item.id != itemId) selection,
    ]);
  }
}
