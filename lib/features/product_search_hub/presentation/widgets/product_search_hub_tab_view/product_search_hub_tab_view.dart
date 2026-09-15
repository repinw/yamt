import 'package:flutter/material.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/data/'
    'composite_product_search_adapter.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_recently_selected_tab/'
    'product_search_hub_recently_selected_tab.dart';

/// Product search hub tab contents.
@Dependencies([productSearchGateway])
class ProductSearchHubTabView extends StatelessWidget {
  /// Creates product search hub tab contents.
  const ProductSearchHubTabView({
    required this.selectedProductKeys,
    required this.onRecentlySelectedProductPressed,
    this.onRecentlySelectedProductCopied,
    super.key,
  });

  /// Selected product keys.
  final Set<String> selectedProductKeys;

  /// Called when a recent product is selected.
  final ValueChanged<InventoryItem> onRecentlySelectedProductPressed;

  /// Called when a recent product is copied.
  final ValueChanged<InventoryItem>? onRecentlySelectedProductCopied;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        ProductSearchHubRecentlySelectedTab(
          selectedProductKeys: selectedProductKeys,
          onProductPressed: onRecentlySelectedProductPressed,
          onProductCopied: onRecentlySelectedProductCopied,
        ),
      ],
    );
  }
}
