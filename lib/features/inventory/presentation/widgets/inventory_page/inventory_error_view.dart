import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_home_shell_top_chrome.dart';

/// Error view for inventory page.
class InventoryErrorView extends StatelessWidget {
  /// Creates an inventory error view.
  const new({
    required this.onRetry,
    required this.message,
    required this.retryLabel,
    required this.includeHomeShellChrome,
    required this.topChromeActions,
    super.key,
  });

  /// Action when retry is pressed.
  final Future<void> Function() onRetry;

  /// Error message.
  final String message;

  /// Retry button label.
  final String retryLabel;

  /// Whether to render the home shell chrome.
  final bool includeHomeShellChrome;

  /// Actions rendered in the home shell chrome.
  final List<Widget> topChromeActions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cardRadius = BorderRadius.circular(AppRadius.xl);

    return CustomScrollView(
      slivers: [
        if (includeHomeShellChrome)
          InventoryHomeShellTopChrome(actions: topChromeActions),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: AppInsets.pageLarge,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: cardRadius,
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Padding(
                  padding: AppInsets.card,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wifi_tethering_error_rounded,
                        color: colors.error,
                        size: AppSizes.welcomeIcon * 0.45,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(message, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: Text(retryLabel),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
