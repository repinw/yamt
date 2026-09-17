import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_daily_balance_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_metric_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Top row showing left and eaten balance metrics.
class DiaryDailyBalanceMetricsRow extends StatelessWidget {
  /// Creates the daily balance metrics row.
  const new({required this.data, required this.showDetails, super.key});

  /// Render-ready card data.
  final DiaryDailyBalanceData data;

  /// Whether the eaten metric is shown next to what is left. Future days
  /// always show both planning values.
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final accents = MetricAccentColors.of(context);
    final primary = accents.today;

    final leftAccent = data.isOverTarget ? colors.error : primary;
    final resolvedLeftLabel = data.isFutureDay
        ? l10n.diaryBalanceBaseLabel
        : data.isOverTarget
        ? l10n.diaryBalanceOverGoalLabel
        : l10n.diaryBalanceLeftTodayLabel;
    final resolvedLeftValue = data.isFutureDay
        ? data.baseNumber
        : data.leftValue;
    final resolvedLeftUnit = data.isFutureDay
        ? data.caloriesUnit
        : data.leftUnit;
    final resolvedLeftLabelColor = (data.isFutureDay || data.isPauseDay)
        ? colors.onSurfaceVariant
        : leftAccent;
    final resolvedLeftValueColor = data.isFutureDay
        ? colors.onSurface
        : (data.isPauseDay ? colors.onSurfaceVariant : leftAccent);
    final resolvedLeftUnitColor = (data.isFutureDay || data.isPauseDay)
        ? colors.onSurfaceVariant
        : leftAccent.withValues(alpha: 0.78);

    final resolvedRightLabel = data.isFutureDay
        ? l10n.diaryBalancePlannedWithCarryoverLabel
        : l10n.diaryBalanceEatenLabel;
    final resolvedRightValue = data.isFutureDay
        ? data.plannedWithCarryoverNumber
        : data.eatenValue;
    final resolvedRightUnit = data.isFutureDay
        ? data.caloriesUnit
        : data.targetAddition;
    final resolvedRightUnitFontSize = data.isFutureDay ? 13.0 : 17.0;
    final resolvedRightSubtitle = data.isFutureDay ? null : data.eatenSubtitle;
    final resolvedRightLabelColor = data.isFutureDay
        ? primary
        : colors.onSurfaceVariant;
    final resolvedRightValueColor = data.isFutureDay
        ? primary
        : colors.onSurface;
    final resolvedRightUnitColor = data.isFutureDay
        ? primary.withValues(alpha: 0.78)
        : colors.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DiaryBalanceMetricTile.daily(
            label: resolvedLeftLabel,
            value: resolvedLeftValue,
            unit: resolvedLeftUnit,
            labelColor: resolvedLeftLabelColor,
            valueColor: resolvedLeftValueColor,
            unitColor: resolvedLeftUnitColor,
            alignment: CrossAxisAlignment.start,
            icon: data.isFutureDay ? null : Icons.circle,
          ),
        ),
        if (showDetails || data.isFutureDay) ...[
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: DiaryBalanceMetricTile.daily(
              label: resolvedRightLabel,
              value: resolvedRightValue,
              unit: resolvedRightUnit,
              unitFontSize: resolvedRightUnitFontSize,
              subtitle: resolvedRightSubtitle,
              labelColor: resolvedRightLabelColor,
              valueColor: resolvedRightValueColor,
              unitColor: resolvedRightUnitColor,
              alignment: CrossAxisAlignment.end,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ],
    );
  }
}
