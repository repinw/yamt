import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_home_shell_top_chrome.dart';

/// Loading view for inventory page.
class InventoryLoadingView extends StatelessWidget {
  /// Creates an inventory loading view.
  const InventoryLoadingView({
    required this.includeHomeShellChrome,
    required this.topChromeActions,
    super.key,
  });

  /// Whether to render the home shell chrome.
  final bool includeHomeShellChrome;

  /// Actions rendered in the home shell chrome.
  final List<Widget> topChromeActions;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (includeHomeShellChrome)
          InventoryHomeShellTopChrome(actions: topChromeActions),
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: SizedBox.square(
              dimension: AppSizes.inlineProgressIndicator,
              child: CircularProgressIndicator(
                strokeWidth: AppSizes.progressStrokeWidth,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
