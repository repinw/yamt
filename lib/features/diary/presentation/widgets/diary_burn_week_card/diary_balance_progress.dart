import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

const Duration _progressAnimationDuration = Duration(milliseconds: 1000);
const Curve _progressAnimationCurve = Curves.easeOut;

/// Burn Week pacing progress bar.
class DiaryBalanceProgressBar extends StatelessWidget {
  /// Creates a diary balance progress bar.
  const DiaryBalanceProgressBar({
    required this.actualConsumedKcal,
    required this.targetKcal,
    required this.weeklyGoalKcal,
    required this.totalDays,
    this.compact = false,
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

  /// Whether to render the slim diary summary version.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final accents = MetricAccentColors.of(context);
    final activity = accents.activityFor(colors.brightness);
    final l10n = AppLocalizations.of(context)!;
    final targetLabel = l10n.diaryBalanceTargetMarkerLabel;
    final trackColor = AppEditorialSurfaces.appBackground(colors);
    final compactTrackColor = AppEditorialSurfaces.compactProgressTrack(
      colors,
    );
    final dividerColor = isDark
        ? colors.surface.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.9);

    if (compact) {
      return SizedBox(
        height: 6,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width =
                constraints.hasBoundedWidth && constraints.maxWidth.isFinite
                ? math.max<double>(0, constraints.maxWidth)
                : diaryBalanceProgressFallbackWidth;
            final actualConsumedRatio = _ratioForKcal(
              actualConsumedKcal,
              weeklyGoalKcal,
            );
            final targetRatio = _ratioForKcal(targetKcal, weeklyGoalKcal);
            final targetMarkerLeft =
                (width * targetRatio - diaryBalanceTargetMarkerWidth / 2).clamp(
                  0.0,
                  math.max<double>(
                    0,
                    width - diaryBalanceTargetMarkerWidth,
                  ),
                );

            return ClipRRect(
              key: DiaryBalanceCardKeys.progressTrack,
              borderRadius: BorderRadius.circular(999),
              child: SizedBox.expand(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(color: compactTrackColor),
                    ),
                    TweenAnimationBuilder<double>(
                      duration: _progressAnimationDuration,
                      curve: _progressAnimationCurve,
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

    return SizedBox(
      height: diaryBalanceProgressAreaHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width =
              constraints.hasBoundedWidth && constraints.maxWidth.isFinite
              ? math.max<double>(0, constraints.maxWidth)
              : diaryBalanceProgressFallbackWidth;
          final targetRatio = _ratioForKcal(targetKcal, weeklyGoalKcal);
          final actualConsumedRatio = _ratioForKcal(
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
                          TweenAnimationBuilder<double>(
                            duration: _progressAnimationDuration,
                            curve: _progressAnimationCurve,
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
                TweenAnimationBuilder<double>(
                  duration: _progressAnimationDuration,
                  curve: _progressAnimationCurve,
                  tween: Tween<double>(begin: 0, end: targetRatio),
                  builder: (context, value, child) {
                    final targetCenter = width * value;
                    final animatedLabelLeft = (targetCenter - labelWidth / 2)
                        .clamp(
                          0.0,
                          math.max<double>(0, width - labelWidth),
                        );

                    return Positioned(
                      left: animatedLabelLeft,
                      top: 0,
                      width: labelWidth,
                      child: child!,
                    );
                  },
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppEditorialSurfaces.liftedCard(colors),
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
                TweenAnimationBuilder<double>(
                  duration: _progressAnimationDuration,
                  curve: _progressAnimationCurve,
                  tween: Tween<double>(begin: 0, end: targetRatio),
                  builder: (context, value, child) {
                    final targetCenter = width * value;
                    final animatedMarkerLeft =
                        (targetCenter - diaryBalanceTargetMarkerWidth / 2)
                            .clamp(
                              0.0,
                              math.max<double>(
                                0,
                                width - diaryBalanceTargetMarkerWidth,
                              ),
                            );

                    return Positioned(
                      left: animatedMarkerLeft,
                      top: progressTop - diaryBalanceTargetMarkerOverflowTop,
                      child: child!,
                    );
                  },
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
