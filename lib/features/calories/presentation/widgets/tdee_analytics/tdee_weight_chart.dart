import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/calories/presentation/widgets/tdee_analytics/tdee_weight_chart_builder.dart';

/// Interactive chart displaying scale weights, trendline,
/// and goal anticipation.
class TdeeWeightChart extends StatelessWidget {
  /// Creates the weight analytics chart.
  const TdeeWeightChart({
    required this.points,
    this.goalCycles = const <TdeeAnalyticsGoalCycle>[],
    this.anticipation,
    this.showAnticipation = true,
    this.extendToProjectedGoal = true,
    super.key,
  });

  /// Historical daily points.
  final List<TdeeAnalyticsPoint> points;

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
    final validWeights = points.where((p) => p.scaleWeightKg != null).toList();
    if (validWeights.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final projection =
        (extendToProjectedGoal &&
            showAnticipation &&
            anticipation != null &&
            !anticipation!.isMovingAway &&
            !anticipation!.isAchieved)
        ? anticipation
        : null;

    final (minY, maxY) = TdeeWeightChartBuilder.calculateYBounds(
      validWeights,
      projection,
    );
    final firstDay = points.first.day;
    // A seven-day selection always fills a complete seven-day X-axis, even
    // when only some of those days contain a weight measurement.
    var maxX = math.max(6, points.length - 1).toDouble();
    for (final projectedPoint
        in projection?.projectionPoints ?? const <TdeeProjectionPoint>[]) {
      maxX = math.max(
        maxX,
        projectedPoint.day.difference(firstDay).inDays.toDouble(),
      );
    }
    if (extendToProjectedGoal) {
      for (final cycle in goalCycles) {
        final markerDate =
            cycle.endDate ?? cycle.reachedDate ?? cycle.estimatedEndDate;
        if (markerDate != null) {
          maxX = math.max(
            maxX,
            markerDate.difference(firstDay).inDays.toDouble(),
          );
        }
      }
    }

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
                'Gewicht & Ziel-Antizipation',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
                  locale: Localizations.localeOf(context).toLanguageTag(),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: TdeeWeightChartBuilder.buildTouchData(
                  colorScheme,
                  theme,
                ),
                extraLinesData: TdeeWeightChartBuilder.buildExtraLines(
                  projection,
                  goalCycles,
                  firstDay,
                  colorScheme,
                ),
                lineBarsData: [
                  TdeeWeightChartBuilder.buildHistoricalWeightBar(
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
}
