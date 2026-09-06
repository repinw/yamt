import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Skeleton shown while meal cards are loading.
class DiaryMealCardsSkeleton extends StatelessWidget {
  /// Creates the meal card loading skeleton.
  const DiaryMealCardsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var index = 0; index < 4; index += 1)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
      ],
    );
  }
}
