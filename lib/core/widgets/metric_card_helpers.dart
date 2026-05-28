import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';

/// Shared rounded detail card shell for secondary metric cards.
class MetricDetailCardShell extends StatelessWidget {
  /// Creates a detail card shell.
  const MetricDetailCardShell({required this.child, super.key});

  /// The card content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppQuietSurfaces.cardDecoration(colors),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: child,
      ),
    );
  }
}

/// Shared rounded frame for compact metric cards.
class MetricCardFrame extends StatelessWidget {
  /// Creates a metric card frame.
  const MetricCardFrame({
    required this.child,
    this.padding,
    this.clip = true,
    this.withShadow = true,
    super.key,
  });

  /// Card content.
  final Widget child;

  /// Optional inner padding.
  final EdgeInsetsGeometry? padding;

  /// Whether to clip overflowing children to the rounded shape.
  final bool clip;

  /// Whether to draw the metric card shadow.
  final bool withShadow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = AppQuietSurfaces.cardBorderRadius();
    final content = padding == null
        ? child
        : Padding(padding: padding!, child: child);
    final decoration = AppQuietSurfaces.cardDecoration(
      colors,
      withShadow: withShadow,
    );

    return DecoratedBox(
      decoration: decoration,
      child: clip ? ClipRRect(borderRadius: radius, child: content) : content,
    );
  }
}

/// Shared skeleton block for metric loading placeholders.
class MetricSkeletonBlock extends StatelessWidget {
  /// Creates a skeleton block.
  const MetricSkeletonBlock({
    required this.height,
    required this.color,
    this.width,
    super.key,
  });

  /// Optional width.
  final double? width;

  /// Height.
  final double height;

  /// Fill color.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

/// Compact retry content for metric cards.
class MetricErrorRetryContent extends StatelessWidget {
  /// Creates retry content.
  const MetricErrorRetryContent({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.retryButtonKey,
    super.key,
  });

  /// Localized error message.
  final String message;

  /// Localized retry action label.
  final String retryLabel;

  /// Called when retry is tapped.
  final VoidCallback onRetry;

  /// Optional retry button key for tests.
  final Key? retryButtonKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline_rounded, color: colors.error),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.tonalIcon(
          key: retryButtonKey,
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(retryLabel),
        ),
      ],
    );
  }
}
