import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_balance_formatters.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';

/// Daily kcal progress bar with an activity extension segment.
class DiaryDailyGoalProgressBar extends StatelessWidget {
  /// Creates a daily goal progress bar.
  const DiaryDailyGoalProgressBar({
    required this.eatenKcal,
    required this.targetKcal,
    required this.activitySegmentKcal,
    required this.numberFormat,
    required this.unit,
    super.key,
  });

  /// Kcal eaten for the selected day.
  final double eatenKcal;

  /// Target kcal including activity not already counted in the base goal.
  final double targetKcal;

  /// Positive activity kcal displayed at the end of the bar.
  final double activitySegmentKcal;

  /// Locale-aware number formatter.
  final NumberFormat numberFormat;

  /// Localized kcal unit.
  final String unit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final accents = MetricAccentColors.of(context);
    final target = math.max<double>(0, targetKcal);
    final activitySegment = math.min<double>(
      math.max<double>(0, activitySegmentKcal),
      target,
    );
    final eatenRatio = target <= 0 ? 0.0 : (eatenKcal / target).clamp(0.0, 1.0);
    final activitySegmentRatio = target <= 0
        ? 0.0
        : (activitySegment / target).clamp(0.0, 1.0);
    final targetLabel = formatDiaryKcal(numberFormat, target, unit);
    final activitySegmentLabel = formatDiarySignedKcal(
      activitySegment,
      numberFormat,
      unit,
    );
    final trackColor = isDark
        ? colors.surfaceContainerHighest.withValues(alpha: 0.52)
        : const Color(0xFFE8EDF2);
    final activityColor = accents.activityFor(colors.brightness);
    final activityTextColor = accents.activityTextFor(colors.brightness);
    final primary = accents.today;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '0',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const Spacer(),
            if (activitySegment > 0) ...[
              _ActivitySegmentPill(
                label: activitySegmentLabel,
                color: activityColor,
                textColor: activityTextColor,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              targetLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final eatenWidth = width * eatenRatio;
            final activityWidth = width * activitySegmentRatio;
            return ClipRRect(
              key: DiaryBalanceCardKeys.dailyProgressTrack,
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 12,
                child: Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: trackColor)),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: eatenWidth,
                      child: DecoratedBox(
                        key: DiaryBalanceCardKeys.dailyProgressEatenFill,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    if (activityWidth > 0) ...[
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: activityWidth,
                        child: ColoredBox(
                          key: DiaryBalanceCardKeys.dailyProgressActivityFill,
                          color: activityColor,
                        ),
                      ),
                      Positioned(
                        right: activityWidth,
                        top: 0,
                        bottom: 0,
                        width: 1,
                        child: ColoredBox(
                          color: colors.surfaceContainerLowest.withValues(
                            alpha: 0.92,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ActivitySegmentPill extends StatelessWidget {
  const _ActivitySegmentPill({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: isDark ? 0.18 : 0.12),
          colors.surfaceContainerLowest,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_run_rounded, size: 11, color: textColor),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
