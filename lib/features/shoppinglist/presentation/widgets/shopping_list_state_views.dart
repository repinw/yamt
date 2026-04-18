import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

/// Defines shopping list loading view.
class ShoppingListLoadingView extends StatelessWidget {
  /// The shopping list loading view.
  const ShoppingListLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: AppSizes.inlineProgressIndicator,
        child: CircularProgressIndicator(
          strokeWidth: AppSizes.progressStrokeWidth,
        ),
      ),
    );
  }
}

/// Defines shopping list error view.
class ShoppingListErrorView extends StatelessWidget {
  /// The shopping list error view.
  const ShoppingListErrorView({
    required this.onRetry,
    required this.message,
    required this.retryLabel,
    super.key,
  });

  /// The on retry.
  final VoidCallback onRetry;

  /// The message.
  final String message;

  /// The retry label.
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: AppInsets.pageLarge,
        child: Card(
          margin: EdgeInsets.zero,
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
    );
  }
}
