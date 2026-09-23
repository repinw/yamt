import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Card showing expenditure changes and goal anticipation insights.
class TdeeInsightsCard extends StatelessWidget {
  /// Creates the insights card.
  const new({
    required this.summary,
    this.anticipation,
    this.showAnticipation = true,
    this.onToggleAnticipation,
    super.key,
  });

  /// Analytics summary metrics.
  final TdeeAnalyticsSummary summary;

  /// Optional anticipation projection.
  final TdeeAnticipationProjection? anticipation;

  /// Whether anticipation is visible in chart.
  final bool showAnticipation;

  /// Toggle callback.
  final VoidCallback? onToggleAnticipation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tdeeInsightsTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildDeltaRow(
              label: l10n.tdeeInsightsDays(3),
              delta: summary.threeDayDeltaKcal,
              theme: theme,
              colorScheme: colorScheme,
              valueFormat: NumberFormat('+0.0;-0.0', locale),
              unit: l10n.caloriesUnitKcal,
            ),
            const Divider(height: AppSpacing.lg),
            _buildDeltaRow(
              label: l10n.tdeeInsightsDays(7),
              delta: summary.sevenDayDeltaKcal,
              theme: theme,
              colorScheme: colorScheme,
              valueFormat: NumberFormat('+0.0;-0.0', locale),
              unit: l10n.caloriesUnitKcal,
            ),
            const Divider(height: AppSpacing.lg),
            _buildDeltaRow(
              label: l10n.tdeeInsightsDays(14),
              delta: summary.fourteenDayDeltaKcal,
              theme: theme,
              colorScheme: colorScheme,
              valueFormat: NumberFormat('+0.0;-0.0', locale),
              unit: l10n.caloriesUnitKcal,
            ),
            if (anticipation != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _buildAnticipationSection(theme, colorScheme, l10n, locale),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeltaRow({
    required String label,
    required double? delta,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required NumberFormat valueFormat,
    required String unit,
  }) {
    final hasData = delta != null;
    final isPositive = (delta ?? 0) >= 0;
    final valStr = hasData ? '${valueFormat.format(delta)} $unit' : '–';
    final color = !hasData
        ? colorScheme.outline
        : (isPositive ? colorScheme.primary : colorScheme.error);
    final icon = !hasData
        ? Icons.remove_rounded
        : (isPositive
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              valStr,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnticipationSection(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
    String locale,
  ) {
    final proj = anticipation!;
    final targetStr =
        '${NumberFormat('0.0', locale).format(proj.targetWeightKg)} '
        '${l10n.caloriesUnitKg}';

    Widget content;
    if (proj.isAchieved) {
      content = Text(
        l10n.tdeeGoalAchieved(targetStr),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (proj.isMovingAway) {
      content = Text(
        l10n.tdeeGoalMovingAway(targetStr),
        style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
      );
    } else {
      final dateStr = DateFormat.yMd(locale).format(proj.projectedDate!);
      final days = proj.daysRemaining ?? 0;
      final speedStr = NumberFormat(
        '0.00',
        locale,
      ).format(proj.trendSpeedKgPerWeek.abs());

      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 18, color: colorScheme.tertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.tdeeGoalProjection(targetStr, dateStr),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.tdeeGoalRemaining(days, speedStr),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          content,
          if (onToggleAnticipation != null && !proj.isAchieved) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.tdeeShowProjection,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Switch.adaptive(
                  value: showAnticipation,
                  onChanged: (_) => onToggleAnticipation!(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
