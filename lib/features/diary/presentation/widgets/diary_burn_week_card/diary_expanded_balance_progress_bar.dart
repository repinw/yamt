import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_progress_helpers.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_expanded_balance_progress_marker.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_expanded_balance_progress_target_label.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_expanded_balance_progress_track.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Expanded Burn Week progress bar for full balance cards.
class DiaryExpandedBalanceProgressBar extends StatelessWidget {
  /// Creates an expanded diary balance progress bar.
  const DiaryExpandedBalanceProgressBar({
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
    final targetLabel = AppLocalizations.of(
      context,
    )!.diaryBalanceTargetMarkerLabel;
    final trackColor = AppEditorialSurfaces.appBackground(colors);
    final dividerColor = diaryBalanceProgressDividerColor(colors);

    return SizedBox(
      height: diaryBalanceProgressAreaHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = diaryBalanceProgressWidth(constraints);
          final targetRatio = diaryBalanceProgressRatioForKcal(
            targetKcal,
            weeklyGoalKcal,
          );
          final actualConsumedRatio = diaryBalanceProgressRatioForKcal(
            actualConsumedKcal,
            weeklyGoalKcal,
          );
          const progressTop =
              (diaryBalanceProgressAreaHeight - diaryBalanceProgressHeight) / 2;
          final labelWidth = math.min<double>(
            diaryBalanceTargetLabelWidth,
            math.max<double>(0, width),
          );

          return SizedBox(
            width: width,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                DiaryExpandedBalanceProgressTrack(
                  width: width,
                  actualConsumedRatio: actualConsumedRatio,
                  activityColor: activity,
                  fatColor: accents.fat,
                  trackColor: trackColor,
                  dividerColor: dividerColor,
                  totalDays: totalDays,
                  progressTop: progressTop,
                ),
                DiaryExpandedBalanceProgressTargetLabel(
                  width: width,
                  labelWidth: labelWidth,
                  targetRatio: targetRatio,
                  targetLabel: targetLabel,
                  colors: colors,
                  isDark: isDark,
                ),
                DiaryExpandedBalanceProgressMarker(
                  width: width,
                  targetRatio: targetRatio,
                  colors: colors,
                  progressTop: progressTop,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
