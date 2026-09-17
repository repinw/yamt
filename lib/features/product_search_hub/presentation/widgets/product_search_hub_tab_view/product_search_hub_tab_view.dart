import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_recently_selected_tab/'
    'product_search_hub_recently_selected_tab.dart';

/// Product search hub tab contents.
class ProductSearchHubTabView extends StatelessWidget {
  /// Creates product search hub tab contents.
  const new({
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
