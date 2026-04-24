import 'package:flutter/material.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';

/// Loading view shown while calorie entries are being loaded.
class CaloriesLoadingView extends StatelessWidget {
  /// The calories loading view.
  const CaloriesLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLoadingView();
  }
}

/// Error view shown when calorie entries could not be loaded.
class CaloriesErrorView extends StatelessWidget {
  /// The calories error view.
  const CaloriesErrorView({
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
      retryButtonKey: CaloriesPageKeys.retryButton,
    );
  }
}
