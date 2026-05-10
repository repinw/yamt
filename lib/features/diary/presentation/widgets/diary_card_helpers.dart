import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Shared rounded detail card shell for diary secondary cards.
class DiaryDetailCardShell extends StatelessWidget {
  /// Creates a detail card shell.
  const DiaryDetailCardShell({required this.child, super.key});

  /// The card content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: isDark ? 0.28 : 0.1),
            blurRadius: isDark ? 30 : 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: child,
      ),
    );
  }
}

/// Shared rounded frame for compact diary metric cards.
class DiaryMetricCardFrame extends StatelessWidget {
  /// Creates a metric card frame.
  const DiaryMetricCardFrame({
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
    final isDark = colors.brightness == Brightness.dark;
    final radius = BorderRadius.circular(24);
    final content = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: radius,
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.55),
        ),
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: isDark ? 0.26 : 0.1),
                  blurRadius: isDark ? 25 : 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: clip ? ClipRRect(borderRadius: radius, child: content) : content,
    );
  }
}

/// Shared skeleton block for diary loading placeholders.
class DiarySkeletonBlock extends StatelessWidget {
  /// Creates a skeleton block.
  const DiarySkeletonBlock({
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

/// Compact retry content for diary cards.
class DiaryErrorRetryContent extends StatelessWidget {
  /// Creates retry content.
  const DiaryErrorRetryContent({
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
