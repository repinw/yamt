import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';

/// Skeleton loader for diary nutrition bars matching the 4-column layout.
class DiaryNutritionBarsSkeleton extends StatelessWidget {
  /// Creates the nutrition bars skeleton.
  const DiaryNutritionBarsSkeleton({
    required this.showTitle,
    super.key,
  });

  /// Whether to show the top title skeleton block.
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          MetricSkeletonBlock(
            width: 138,
            height: 18,
            color: colors.surfaceContainerHighest,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        for (var index = 0; index < 3; index += 1) ...[
          if (index > 0) const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                MetricSkeletonBlock(
                  width: 42,
                  height: 18,
                  color: colors.surfaceContainerHighest,
                ),
                const SizedBox(width: 6),
                MetricSkeletonBlock(
                  width: 44,
                  height: 14,
                  color: colors.surfaceContainerHighest,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Row(
                    children: List.generate(
                      4,
                      (i) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i < 3 ? 3.0 : 0.0),
                          child: MetricSkeletonBlock(
                            height: 6,
                            color: colors.surfaceContainerHighest,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                MetricSkeletonBlock(
                  width: 68,
                  height: 12,
                  color: colors.surfaceContainerHighest,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
