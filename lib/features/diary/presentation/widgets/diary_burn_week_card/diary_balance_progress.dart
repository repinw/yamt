import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Burn Week pacing progress bar.
class DiaryBalanceProgressBar extends StatelessWidget {
  /// Creates a diary balance progress bar.
  const DiaryBalanceProgressBar({
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
    final l10n = AppLocalizations.of(context)!;
    final targetLabel = l10n.diaryBalanceTargetMarkerLabel;
    final trackColor = isDark
        ? colors.surfaceContainerHighest.withValues(alpha: 0.45)
        : const Color(0xFFE8EDF2);
    final dividerColor = isDark
        ? colors.surface.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.9);

    return SizedBox(
      height: diaryBalanceProgressAreaHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width =
              constraints.hasBoundedWidth && constraints.maxWidth.isFinite
              ? math.max<double>(0, constraints.maxWidth)
              : diaryBalanceProgressFallbackWidth;
          final targetRatio = _ratioForKcal(targetKcal, weeklyGoalKcal);
          final actualConsumedRatio = _ratioForKcal(
            actualConsumedKcal,
            weeklyGoalKcal,
          );
          final fillWidth = width * actualConsumedRatio;
          final targetCenter = width * targetRatio;
          const progressTop =
              (diaryBalanceProgressAreaHeight - diaryBalanceProgressHeight) / 2;
          final labelWidth = math.min<double>(
            diaryBalanceTargetLabelWidth,
            math.max<double>(0, width),
          );
          final labelLeft = (targetCenter - labelWidth / 2).clamp(
            0.0,
            math.max<double>(0, width - labelWidth),
          );
          final markerLeft = (targetCenter - diaryBalanceTargetMarkerWidth / 2)
              .clamp(
                0.0,
                math.max<double>(
                  0,
                  width - diaryBalanceTargetMarkerWidth,
                ),
              );

          return SizedBox(
            width: width,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: progressTop,
                  child: ClipRRect(
                    key: DiaryBalanceCardKeys.progressTrack,
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: diaryBalanceProgressHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ColoredBox(color: trackColor),
                          ),
                          Positioned(
                            left: 0,
                            top: 0,
                            width: fillWidth,
                            bottom: 0,
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
                              left: (width * day / totalDays) - 1,
                              top: 0,
                              width: 2,
                              bottom: 0,
                              child: ColoredBox(color: dividerColor),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: labelLeft,
                  top: 0,
                  width: labelWidth,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(
                            alpha: isDark ? 0.4 : 0.58,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow.withValues(
                              alpha: isDark ? 0.22 : 0.08,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 3,
                        ),
                        child: Text(
                          targetLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                                height: 1,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: markerLeft,
                  top: progressTop - diaryBalanceTargetMarkerOverflowTop,
                  child: Container(
                    key: DiaryBalanceCardKeys.targetMarker,
                    width: diaryBalanceTargetMarkerWidth,
                    height:
                        diaryBalanceProgressHeight +
                        diaryBalanceTargetMarkerOverflowTop +
                        8,
                    decoration: BoxDecoration(
                      color: colors.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

double _ratioForKcal(double value, double maxKcal) {
  if (maxKcal <= 0) {
    return 0;
  }
  return (value / maxKcal).clamp(0.0, 1.0);
}
