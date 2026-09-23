import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/calories/presentation/widgets/tdee_analytics/tdee_weight_chart_builder.dart';
import 'package:yamt/features/calories/presentation/widgets/tdee_analytics/tdee_weight_chart_tooltip.dart';
import 'package:yamt/features/calories/presentation/widgets/tdee_analytics/tdee_weight_stats_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Interactive chart with the smoothed trend weight as a line, the measured
/// scale weights as faint dots, and the goal projection.
class TdeeWeightChart extends StatelessWidget {
  /// Creates the weight analytics chart.
  const new({
    required this.points,
    this.summary,
    this.goalCycles = const <TdeeAnalyticsGoalCycle>[],
    this.anticipation,
    this.showAnticipation = true,
    this.extendToProjectedGoal = true,
    super.key,
  });

  /// Historical daily points.
  final List<TdeeAnalyticsPoint> points;

  /// Summary with the trend weight numbers shown above the chart.
  final TdeeAnalyticsSummary? summary;

  /// Goal cycles whose completion dates should be marked.
  final List<TdeeAnalyticsGoalCycle> goalCycles;

  /// Optional anticipation projection data.
  final TdeeAnticipationProjection? anticipation;

  /// Whether anticipation projection should be drawn.
  final bool showAnticipation;

  /// Whether the chart may extend beyond its data window to the projected goal.
  final bool extendToProjectedGoal;

  @override
  Widget build(BuildContext context) {
    final hasWeight = points.any(
      (p) => p.scaleWeightKg != null || p.trendWeightKg != null,
    );
    if (!hasWeight) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final projection =
        (extendToProjectedGoal &&
            showAnticipation &&
            anticipation != null &&
            !anticipation!.isMovingAway &&
            !anticipation!.isAchieved)
        ? anticipation
        : null;

    final (minY, maxY) = TdeeWeightChartBuilder.calculateYBounds(
      points,
      projection,
    );
    final firstDay = points.first.day;
    final maxX = _resolveMaxX(firstDay, projection);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            children: [
              Icon(
                Icons.monitor_weight_outlined,
                size: 18,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.tdeeWeightChartTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (summary case final summary?)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              0,
            ),
            child: TdeeWeightStatsRow(summary: summary),
          ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 180,
          child: Padding(
            padding: const EdgeInsets.only(
              right: AppSpacing.md,
              left: AppSpacing.sm,
            ),
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                minX: 0,
                maxX: math.max(1, maxX),
                clipData: const FlClipData.all(),
                gridData: TdeeWeightChartBuilder.buildGridData(colorScheme),
                titlesData: TdeeWeightChartBuilder.buildTitlesData(
                  colorScheme,
                  theme,
                  firstDay: firstDay,
                  maxX: maxX,
                  locale: locale,
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: TdeeWeightChartTooltip.build(
                  colorScheme,
                  theme,
                  firstDay: firstDay,
                  locale: locale,
                  l10n: l10n,
                ),
                extraLinesData: TdeeWeightChartBuilder.buildExtraLines(
                  projection,
                  goalCycles,
                  firstDay,
                  colorScheme,
                  l10n,
                  NumberFormat('0.0', locale),
                ),
                // Order must match TdeeWeightChartBuilder.trendBarIndex and
                // scaleBarIndex.
                lineBarsData: [
                  TdeeWeightChartBuilder.buildTrendWeightBar(
                    points,
                    colorScheme,
                  ),
                  TdeeWeightChartBuilder.buildScaleWeightDots(
                    points,
                    colorScheme,
                  ),
                  if (projection != null)
                    TdeeWeightChartBuilder.buildProjectionBar(
                      points,
                      projection,
                      firstDay,
                      colorScheme,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _resolveMaxX(
    DateTime firstDay,
    TdeeAnticipationProjection? projection,
  ) {
    // A seven-day selection always fills a complete seven-day X-axis, even
    // when only some of those days contain a weight measurement.
    var maxX = math.max(6, points.length - 1).toDouble();
    for (final projectedPoint
        in projection?.projectionPoints ?? const <TdeeProjectionPoint>[]) {
      maxX = math.max(
        maxX,
        TdeeWeightChartBuilder.dayIndex(firstDay, projectedPoint.day),
      );
    }
    if (extendToProjectedGoal) {
      for (final cycle in goalCycles) {
        final markerDate = TdeeWeightChartBuilder.goalMarkerDate(cycle);
        if (markerDate != null) {
          maxX = math.max(
            maxX,
            TdeeWeightChartBuilder.dayIndex(firstDay, markerDate),
          );
        }
      }
    }
    return maxX;
  }
}
