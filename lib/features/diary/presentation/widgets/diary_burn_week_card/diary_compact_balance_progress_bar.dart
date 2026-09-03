import 'package:flutter/material.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_progress_helpers.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_segmented_progress_bar.dart';

/// Compact 7-segment Burn Week progress bar matching macro bars.
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
    final isDark = colors.brightness == Brightness.dark;
    final accents = MetricAccentColors.of(context);
    final activity = accents.activityFor(colors.brightness);
    final trackColor = AppEditorialSurfaces.compactProgressTrack(colors);

    final progressRatio = diaryBalanceProgressRatioForKcal(
      actualConsumedKcal,
      weeklyGoalKcal,
    );
    final segmentCount = totalDays > 0 ? totalDays : 7;

    return SizedBox(
      key: DiaryBalanceCardKeys.progressTrack,
      height: 6,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = diaryBalanceProgressWidth(constraints);

          return SizedBox(
            width: width,
            child: TweenAnimationBuilder<double>(
              duration: diaryBalanceProgressAnimationDuration,
              curve: diaryBalanceProgressAnimationCurve,
              tween: Tween<double>(begin: 0, end: progressRatio),
              builder: (context, animatedProgress, _) {
                return DiarySegmentedProgressBar(
                  progress: animatedProgress,
                  color: activity,
                  trackColor: trackColor,
                  isDark: isDark,
                  segmentCount: segmentCount,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
