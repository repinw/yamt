import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';

/// Loading placeholder for compact metric cards.
class MetricCardSkeleton extends StatelessWidget {
  /// Creates a metric skeleton.
  const MetricCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MetricCardFrame(
      clip: false,
      withShadow: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MetricSkeletonBlock(
            width: 86,
            height: 14,
            color: colors.surfaceContainerHighest,
          ),
          const SizedBox(height: AppSpacing.sm),
          MetricSkeletonBlock(
            width: 92,
            height: 24,
            color: colors.surfaceContainerHighest,
          ),
          const SizedBox(height: AppSpacing.md),
          MetricSkeletonBlock(
            height: 32,
            color: colors.surfaceContainerHighest,
          ),
          const SizedBox(height: AppSpacing.md),
          MetricSkeletonBlock(
            width: 74,
            height: 12,
            color: colors.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }
}
