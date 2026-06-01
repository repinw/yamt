import 'package:flutter/material.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_search_bar/product_search_hub_search_bar.dart';

/// Read-only search field that opens the focused search route.
class ProductSearchHubSearchLauncher extends StatelessWidget {
  /// Creates a product search launcher field.
  const ProductSearchHubSearchLauncher({
    required this.onTap,
    required this.onVoiceSearchTap,
    super.key,
  });

  /// Called when the launcher is tapped.
  final VoidCallback onTap;

  /// Called when the voice button is tapped.
  final VoidCallback onVoiceSearchTap;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: productSearchHubSearchBarHeroTag,
      child: Material(
        type: MaterialType.transparency,
        child: ProductSearchHubSearchBar(
          isSearching: false,
          readOnly: true,
          onTap: onTap,
          onVoiceSearchPressed: onVoiceSearchTap,
        ),
      ),
    );
  }
}
