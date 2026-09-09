import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';

/// Card showing expenditure changes and goal anticipation insights.
class TdeeInsightsCard extends StatelessWidget {
  /// Creates the insights card.
  const TdeeInsightsCard({
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
              'Insights & Veränderungen',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildDeltaRow(
              label: '3 Tage',
              delta: summary.threeDayDeltaKcal,
              theme: theme,
              colorScheme: colorScheme,
            ),
            const Divider(height: AppSpacing.lg),
            _buildDeltaRow(
              label: '7 Tage',
              delta: summary.sevenDayDeltaKcal,
              theme: theme,
              colorScheme: colorScheme,
            ),
            const Divider(height: AppSpacing.lg),
            _buildDeltaRow(
              label: '14 Tage',
              delta: summary.fourteenDayDeltaKcal,
              theme: theme,
              colorScheme: colorScheme,
            ),
            if (anticipation != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _buildAnticipationSection(theme, colorScheme),
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
  }) {
    final hasData = delta != null;
    final isPositive = (delta ?? 0) >= 0;
    final sign = isPositive ? '+' : '';
    final valStr = hasData ? '$sign${delta.toStringAsFixed(1)} kcal' : '–';
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

  Widget _buildAnticipationSection(ThemeData theme, ColorScheme colorScheme) {
    final proj = anticipation!;
    final targetStr = '${proj.targetWeightKg.toStringAsFixed(1)} kg';

    Widget content;
    if (proj.isAchieved) {
      content = Text(
        '🎉 Zielgewicht von $targetStr bereits erreicht!',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (proj.isMovingAway) {
      content = Text(
        '⚠️ Aktueller Trend weicht vom Ziel ($targetStr) ab.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.error,
        ),
      );
    } else {
      final date = proj.projectedDate!;
      final dateStr = '${date.day}.${date.month}.${date.year}';
      final days = proj.daysRemaining ?? 0;
      final speedStr = proj.trendSpeedKgPerWeek.abs().toStringAsFixed(2);

      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 18, color: colorScheme.tertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Ziel $targetStr: voraussichtlich $dateStr',
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
            'In ca. $days Tagen bei aktuellem Trend ($speedStr kg/Woche)',
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
                  'Prognose im Graph anzeigen',
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
