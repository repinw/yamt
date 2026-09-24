import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_color_roles.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_balance_formatters.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_goal_progress_track.dart';

/// Daily kcal progress bar.
class DiaryDailyGoalProgressBar extends StatelessWidget {
  /// Creates a daily goal progress bar.
  const new({
    required this.eatenKcal,
    required this.targetKcal,
    required this.numberFormat,
    required this.unit,
    this.compact = false,
    super.key,
  });

  /// Kcal eaten for the selected day.
  final double eatenKcal;

  /// Target kcal for the selected day.
  final double targetKcal;

  /// Locale-aware number formatter.
  final NumberFormat numberFormat;

  /// Localized kcal unit.
  final String unit;

  /// Whether to render only the bar, without axis labels.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accents = MetricAccentColors.of(context);
    final target = math.max<double>(0, targetKcal);
    final eatenRatio = target <= 0 ? 0.0 : (eatenKcal / target).clamp(0.0, 1.0);
    final targetLabel = formatDiaryKcal(numberFormat, target, unit);
    final trackColor = colors.progressTrack;
    final primary = accents.today;
    final barHeight = compact ? 10.0 : 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
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
        ],
        DiaryDailyGoalProgressTrack(
          height: barHeight,
          trackColor: trackColor,
          eatenColor: primary,
          eatenRatio: eatenRatio,
        ),
      ],
    );
  }
}
