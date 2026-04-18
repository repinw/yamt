import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

/// Defines nutrition metric.
class NutritionMetric {
  /// The nutrition metric.
  const NutritionMetric({required this.label, required this.value});

  /// The label.
  final String label;

  /// The value.
  final String value;
}

/// Shared nutrition metrics strip.
class NutritionMetricsStrip extends StatelessWidget {
  /// The nutrition metrics strip.
  const NutritionMetricsStrip({
    required this.metrics,
    super.key,
    this.colorScheme,
    this.height = 72,
    this.radius = 24,
    this.dividerHeight = 28,
  });

  /// The metrics to display.
  final List<NutritionMetric> metrics;

  /// Optional color scheme override.
  final ColorScheme? colorScheme;

  /// The strip height.
  final double height;

  /// The strip border radius.
  final double radius;

  /// The divider height.
  final double dividerHeight;

  @override
  Widget build(BuildContext context) {
    final resolvedColorScheme = colorScheme ?? Theme.of(context).colorScheme;
    final stripColor = Color.alphaBlend(
      resolvedColorScheme.primary.withValues(alpha: 0.04),
      resolvedColorScheme.surfaceContainerLowest,
    );

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: stripColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: AppInventoryEditorialSurfaces.ghostBorder(
              resolvedColorScheme,
            ),
          ),
        ),
        child: Row(
          children: [
            for (var index = 0; index < metrics.length; index += 1) ...[
              Expanded(
                child: _NutritionMetricCell(
                  metric: metrics[index],
                  colorScheme: resolvedColorScheme,
                ),
              ),
              if (index < metrics.length - 1)
                SizedBox(
                  height: dividerHeight,
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppInventoryEditorialSurfaces.ghostBorder(
                      resolvedColorScheme,
                    ).withValues(alpha: 0.9),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NutritionMetricCell extends StatelessWidget {
  const _NutritionMetricCell({
    required this.metric,
    required this.colorScheme,
  });

  final NutritionMetric metric;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            metric.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats nutrition values without unnecessary trailing decimals.
extension NutritionMetricValueFormatting on double {
  /// Returns a compact nutrition string.
  String toNutritionMetricValue() {
    final hasFraction = this % 1 != 0;
    return hasFraction ? toStringAsFixed(1) : toStringAsFixed(0);
  }
}
