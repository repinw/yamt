import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_recently_selected_tab/'
    'product_search_hub_recently_selected_tab.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_search_actions/product_search_hub_search_actions.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_search_bar/product_search_hub_search_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _productSearchHubSearchActionsAppearDuration = Duration(milliseconds: 90);

/// Animated action section displayed when no search query is active.
class ProductSearchHubSearchActionSection extends StatelessWidget {
  /// Creates the search action section.
  const new({
    required this.isVisible,
    required this.onBarcodePressed,
    required this.onAiPressed,
    required this.onCreateOwnPressed,
    super.key,
  });

  /// Whether the actions section is visible.
  final bool isVisible;

  /// Barcode action callback.
  final VoidCallback onBarcodePressed;

  /// AI search action callback.
  final VoidCallback onAiPressed;

  /// Create custom product callback.
  final VoidCallback onCreateOwnPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _productSearchHubSearchActionsAppearDuration,
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          alignment: AlignmentDirectional.topStart,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: isVisible
          ? Column(
              key: const Key('product_search_hub_search_actions_section'),
              children: [
                const SizedBox(height: AppSpacing.md),
                ProductSearchHubSearchActions(
                  onBarcodePressed: onBarcodePressed,
                  onAiPressed: onAiPressed,
                  onCreateOwnPressed: onCreateOwnPressed,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

/// Hero placeholder for the search bar when transitioning.
class ProductSearchHubSearchHeroField extends StatelessWidget {
  /// Creates the search hero field.
  const new({required this.isVisible, super.key});

  /// Whether the hero field is visible.
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: IgnorePointer(
        child: Opacity(
          opacity: isVisible ? 1 : 0,
          child: const ProductSearchHubSearchBar(
            isSearching: false,
            readOnly: true,
            fieldKey: Key('product_search_hub_search_hero_field'),
          ),
        ),
      ),
    );
  }
}

/// Blank tap catcher for dismissals.
class ProductSearchHubSearchBlank extends StatelessWidget {
  /// Creates the blank tap detector.
  const new({required this.onTap, super.key});

  /// Tap callback.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const SizedBox.expand(),
    );
  }
}

/// Recently selected products shown while the search query is empty.
class ProductSearchHubSearchRecentSection extends StatelessWidget {
  /// Creates the recent products section.
  const new({
    required this.onProductPressed,
    required this.onProductCopied,
    super.key,
  });

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
            selectedProductKeys: const <String>{},
            onProductPressed: onProductPressed,
            onProductCopied: onProductCopied,
          ),
        ),
      ],
    );
  }
}
