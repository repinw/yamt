import 'package:flutter/material.dart';
import 'package:yamt/core/widgets/app_state_views.dart';

/// Defines shopping list loading view.
class ShoppingListLoadingView extends StatelessWidget {
  /// The shopping list loading view.
  const ShoppingListLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLoadingView();
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
    return AppErrorRetryView(
      onRetry: onRetry,
      message: message,
      retryLabel: retryLabel,
    );
  }
}
