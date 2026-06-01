import 'package:flutter/material.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_saved_selection.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_action_grid/product_search_hub_action_grid.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_pinned_tabs/product_search_hub_pinned_tabs.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_search_launcher/product_search_hub_search_launcher.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_selection_overlay/'
    'product_search_hub_selection_overlay.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_tab_view/product_search_hub_tab_view.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_tabs/product_search_hub_tabs.dart';

const _productSearchHubSelectionOverlayClearance = 92.0;

/// Layout shell for product search hub.
@Dependencies([manualProductRecentItemsService])
class ProductSearchHubScaffold extends StatelessWidget {
  /// Creates product search hub scaffold.
  const ProductSearchHubScaffold({
    required this.title,
    required this.savedSelections,
    required this.isMutatingSelection,
    required this.showDiarySourceActions,
    required this.selectedProductKeys,
    required this.onSearchTap,
    required this.onVoiceSearchTap,
    required this.onBarcodePressed,
    required this.onAiPressed,
    required this.onCreateOwnPressed,
    required this.onRecentlySelectedProductPressed,
    required this.onCountPressed,
    required this.onSubmitPressed,
    super.key,
  });

  /// App bar title.
  final String title;

  /// Saved selections.
  final List<ProductSearchHubSavedSelection> savedSelections;

  /// Whether selection is currently mutating.
  final bool isMutatingSelection;

  /// Whether diary source actions are visible.
  final bool showDiarySourceActions;

  /// Source keys already selected.
  final Set<String> selectedProductKeys;

  /// Search launcher callback.
  final VoidCallback onSearchTap;

  /// Search launcher voice callback.
  final VoidCallback onVoiceSearchTap;

  /// Barcode callback.
  final VoidCallback onBarcodePressed;

  /// AI callback.
  final VoidCallback onAiPressed;

  /// Create own product callback.
  final VoidCallback onCreateOwnPressed;

  /// Recent product callback.
  final ValueChanged<InventoryItem> onRecentlySelectedProductPressed;

  /// Opens selected-product sheet.
  final VoidCallback onCountPressed;

  /// Closes completed hub.
  final VoidCallback onSubmitPressed;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: ProductSearchHubTabs.tabCount,
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          child: Stack(
            children: [
              _ProductSearchHubNestedContent(
                bottomClearance: savedSelections.isEmpty
                    ? AppSpacing.xl
                    : _productSearchHubSelectionOverlayClearance,
                showDiarySourceActions: showDiarySourceActions,
                selectedProductKeys: selectedProductKeys,
                onSearchTap: onSearchTap,
                onVoiceSearchTap: onVoiceSearchTap,
                onBarcodePressed: onBarcodePressed,
                onAiPressed: onAiPressed,
                onCreateOwnPressed: onCreateOwnPressed,
                onRecentlySelectedProductPressed:
                    onRecentlySelectedProductPressed,
              ),
              if (savedSelections.isNotEmpty)
                _ProductSearchHubOverlay(
                  productCount: savedSelections.length,
                  isMutatingSelection: isMutatingSelection,
                  onCountPressed: onCountPressed,
                  onSubmitPressed: onSubmitPressed,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

@Dependencies([manualProductRecentItemsService])
class _ProductSearchHubNestedContent extends StatelessWidget {
  const _ProductSearchHubNestedContent({
    required this.bottomClearance,
    required this.showDiarySourceActions,
    required this.selectedProductKeys,
    required this.onSearchTap,
    required this.onVoiceSearchTap,
    required this.onBarcodePressed,
    required this.onAiPressed,
    required this.onCreateOwnPressed,
    required this.onRecentlySelectedProductPressed,
  });

  final double bottomClearance;
  final bool showDiarySourceActions;
  final Set<String> selectedProductKeys;
  final VoidCallback onSearchTap;
  final VoidCallback onVoiceSearchTap;
  final VoidCallback onBarcodePressed;
  final VoidCallback onAiPressed;
  final VoidCallback onCreateOwnPressed;
  final ValueChanged<InventoryItem> onRecentlySelectedProductPressed;

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: ProductSearchHubActionGrid(
                showDiarySourceActions: showDiarySourceActions,
                onBarcodePressed: onBarcodePressed,
                onAiPressed: onAiPressed,
                onCreateOwnPressed: onCreateOwnPressed,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            sliver: SliverToBoxAdapter(
              child: ProductSearchHubSearchLauncher(
                onTap: onSearchTap,
                onVoiceSearchTap: onVoiceSearchTap,
              ),
            ),
          ),
          const ProductSearchHubPinnedTabs(),
        ];
      },
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          bottomClearance,
        ),
        child: ProductSearchHubTabView(
          selectedProductKeys: selectedProductKeys,
          onRecentlySelectedProductPressed: onRecentlySelectedProductPressed,
        ),
      ),
    );
  }
}

class _ProductSearchHubOverlay extends StatelessWidget {
  const _ProductSearchHubOverlay({
    required this.productCount,
    required this.isMutatingSelection,
    required this.onCountPressed,
    required this.onSubmitPressed,
  });

  final int productCount;
  final bool isMutatingSelection;
  final VoidCallback onCountPressed;
  final VoidCallback onSubmitPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppSpacing.xl,
      right: AppSpacing.xl,
      bottom: AppSpacing.xl,
      child: ProductSearchHubSelectionOverlay(
        productCount: productCount,
        isSaving: isMutatingSelection,
        onCountPressed: onCountPressed,
        onSubmitPressed: onSubmitPressed,
      ),
    );
  }
}
