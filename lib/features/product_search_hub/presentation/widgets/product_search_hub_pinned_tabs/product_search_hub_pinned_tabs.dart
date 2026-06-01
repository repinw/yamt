import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_scroll_hint_handle/'
    'product_search_hub_scroll_hint_handle.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_tabs/product_search_hub_tabs.dart';

const _productSearchHubPinnedTabsExtent = 72.0;

/// Pinned tab header with a centered scroll affordance above the tabs.
class ProductSearchHubPinnedTabs extends StatelessWidget {
  /// Creates a pinned product search hub tab header.
  const ProductSearchHubPinnedTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _ProductSearchHubPinnedTabsDelegate(
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}

class _ProductSearchHubPinnedTabsDelegate
    extends SliverPersistentHeaderDelegate {
  const _ProductSearchHubPinnedTabsDelegate({
    required this.backgroundColor,
  });

  final Color backgroundColor;

  @override
  double get minExtent => _productSearchHubPinnedTabsExtent;

  @override
  double get maxExtent => _productSearchHubPinnedTabsExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: backgroundColor,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xs,
          AppSpacing.xl,
          0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ProductSearchHubScrollHintHandle(),
            SizedBox(height: AppSpacing.xs),
            ProductSearchHubTabs(),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_ProductSearchHubPinnedTabsDelegate oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor;
  }
}
