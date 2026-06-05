import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_progress_helpers.dart';

/// Compact Burn Week progress bar for diary summary surfaces.
class DiaryCompactBalanceProgressBar extends StatelessWidget {
  /// Creates a compact diary balance progress bar.
  const DiaryCompactBalanceProgressBar({
    required this.actualConsumedKcal,
    required this.targetKcal,
    required this.weeklyGoalKcal,
    required this.totalDays,
    super.key,
  });

  /// Real consumed calories in the displayed Burn Week.
  final double actualConsumedKcal;

  /// Pacing target in calories for the displayed day.
  final double targetKcal;

  /// Stable weekly goal used as the bar maximum.
  final double weeklyGoalKcal;

  /// Total days represented by the bar.
  final int totalDays;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accents = MetricAccentColors.of(context);
    final activity = accents.activityFor(colors.brightness);
    final dividerColor = diaryBalanceProgressDividerColor(colors);

    return SizedBox(
      height: 6,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = diaryBalanceProgressWidth(constraints);
          final actualConsumedRatio = diaryBalanceProgressRatioForKcal(
            actualConsumedKcal,
            weeklyGoalKcal,
          );
          final targetRatio = diaryBalanceProgressRatioForKcal(
            targetKcal,
            weeklyGoalKcal,
          );
          final targetMarkerLeft =
              (width * targetRatio - diaryBalanceTargetMarkerWidth / 2).clamp(
                0.0,
                math.max<double>(0, width - diaryBalanceTargetMarkerWidth),
              );

          return ClipRRect(
            key: DiaryBalanceCardKeys.progressTrack,
            borderRadius: BorderRadius.circular(999),
            child: SizedBox.expand(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: AppEditorialSurfaces.compactProgressTrack(colors),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    duration: diaryBalanceProgressAnimationDuration,
                    curve: diaryBalanceProgressAnimationCurve,
                    tween: Tween<double>(
                      begin: 0,
                      end: actualConsumedRatio,
                    ),
                    builder: (context, value, child) {
                      return Positioned(
                        left: 0,
                        top: 0,
                        width: width * value,
                        bottom: 0,
                        child: child!,
                      );
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            activity,
                            accents.fat,
                          ],
                        ),
                      ),
                    ),
                  ),
                  for (var day = 1; day < totalDays; day += 1)
                    Positioned(
                      left: (width * day / totalDays) - 0.5,
                      top: 0,
                      width: 1,
                      bottom: 0,
                      child: ColoredBox(color: dividerColor),
                    ),
                  Positioned(
                    key: DiaryBalanceCardKeys.targetMarker,
                    left: targetMarkerLeft,
                    top: 0,
                    width: diaryBalanceTargetMarkerWidth,
                    bottom: 0,
                    child: ColoredBox(
                      color: colors.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
