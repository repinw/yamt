import 'package:flutter/material.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Product search hub tab selector.
class ProductSearchHubTabs extends StatelessWidget {
  /// Creates product search hub tabs.
  const ProductSearchHubTabs({super.key});

  /// Number of hub tabs.
  static const tabCount = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      tabs: [
        Tab(text: l10n.productSearchHubRecentlySelectedTab),
      ],
    );
  }
}
