import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_card_helpers.dart';

/// Loading placeholder for compact diary metric cards.
class DiaryMetricCardSkeleton extends StatelessWidget {
  /// Creates a metric skeleton.
  const DiaryMetricCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DiaryMetricCardFrame(
      clip: false,
      withShadow: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DiarySkeletonBlock(
            width: 86,
            height: 14,
            color: colors.surfaceContainerHighest,
          ),
          const SizedBox(height: AppSpacing.sm),
          DiarySkeletonBlock(
            width: 92,
            height: 24,
            color: colors.surfaceContainerHighest,
          ),
          const SizedBox(height: AppSpacing.md),
          DiarySkeletonBlock(
            height: 32,
            color: colors.surfaceContainerHighest,
          ),
          const SizedBox(height: AppSpacing.md),
          DiarySkeletonBlock(
            width: 74,
            height: 12,
            color: colors.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }
}
