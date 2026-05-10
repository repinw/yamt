import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Centered loading indicator for full-page async states.
class AppLoadingView extends StatelessWidget {
  /// Creates app loading view.
  const AppLoadingView({super.key});

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

/// Centered error card with retry action for full-page async states.
class AppErrorRetryView extends StatelessWidget {
  /// Creates app error retry view.
  const AppErrorRetryView({
    required this.onRetry,
    required this.message,
    required this.retryLabel,
    this.retryButtonKey,
    this.icon = Icons.error_outline,
    super.key,
  });

  /// Called when retry action is pressed.
  final VoidCallback onRetry;

  /// Localized error message.
  final String message;

  /// Localized retry button label.
  final String retryLabel;

  /// Optional key for feature-level tests.
  final Key? retryButtonKey;

  /// Error icon shown above the message.
  final IconData icon;

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
                  icon,
                  color: colors.error,
                  size: AppSizes.welcomeIcon * 0.45,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  key: retryButtonKey,
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
