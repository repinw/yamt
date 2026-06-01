import 'package:flutter/material.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_recently_selected_tab/'
    'product_search_hub_recently_selected_tab.dart';

/// Product search hub tab contents.
@Dependencies([manualProductRecentItemsService])
class ProductSearchHubTabView extends StatelessWidget {
  /// Creates product search hub tab contents.
  const ProductSearchHubTabView({
    required this.selectedProductKeys,
    required this.onRecentlySelectedProductPressed,
    super.key,
  });

  /// Selected product keys.
  final Set<String> selectedProductKeys;

  /// Called when a recent product is selected.
  final ValueChanged<InventoryItem> onRecentlySelectedProductPressed;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        ProductSearchHubRecentlySelectedTab(
          selectedProductKeys: selectedProductKeys,
          onProductPressed: onRecentlySelectedProductPressed,
        ),
      ],
    );
  }
}
