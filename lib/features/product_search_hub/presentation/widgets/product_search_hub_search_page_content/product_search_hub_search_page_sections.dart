import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_recently_selected_tab/'
    'product_search_hub_recently_selected_tab.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_search_actions/product_search_hub_search_actions.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Barcode, AI, and own product actions above the search content.
class ProductSearchHubSearchActionSection extends StatelessWidget {
  /// Creates the search action section.
  const new({
    required this.onBarcodePressed,
    required this.onAiPressed,
    required this.onCreateOwnPressed,
    super.key,
  });

  /// Barcode action callback.
  final VoidCallback onBarcodePressed;

  /// AI search action callback.
  final VoidCallback onAiPressed;

  /// Create custom product callback.
  final VoidCallback onCreateOwnPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('product_search_hub_search_actions_section'),
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xl),
      child: ProductSearchHubSearchActions(
        onBarcodePressed: onBarcodePressed,
        onAiPressed: onAiPressed,
        onCreateOwnPressed: onCreateOwnPressed,
      ),
    );
  }
}

/// Recently selected products shown while the search query is empty.
class ProductSearchHubSearchRecentSection extends StatelessWidget {
  /// Creates the recent products section.
  const new({
    required this.selectedProductKeys,
    required this.onProductPressed,
    required this.onProductCopied,
    super.key,
  });

  /// Source keys of the products selected so far.
  final Set<String> selectedProductKeys;

  /// Called when a recent product is selected.
  final ValueChanged<InventoryItem> onProductPressed;

  /// Called when a recent product is copied as template.
  final ValueChanged<InventoryItem> onProductCopied;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            l10n.productSearchHubRecentlySelectedTab,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Expanded(
          child: ProductSearchHubRecentlySelectedTab(
            selectedProductKeys: selectedProductKeys,
            onProductPressed: onProductPressed,
            onProductCopied: onProductCopied,
          ),
        ),
      ],
    );
  }
}
