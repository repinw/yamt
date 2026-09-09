import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/calories/presentation/widgets/tdee_analytics/tdee_weight_chart_builder.dart';

/// Interactive chart displaying scale weights, trendline,
/// and goal anticipation.
class TdeeWeightChart extends StatelessWidget {
  /// Creates the weight analytics chart.
  const TdeeWeightChart({
    required this.points,
    this.anticipation,
    this.showAnticipation = true,
    super.key,
  });

  /// Historical daily points.
  final List<TdeeAnalyticsPoint> points;

  /// Optional anticipation projection data.
  final TdeeAnticipationProjection? anticipation;

  /// Whether anticipation projection should be drawn.
  final bool showAnticipation;

  @override
  Widget build(BuildContext context) {
    final validWeights = points.where((p) => p.scaleWeightKg != null).toList();
    if (validWeights.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final projection = (showAnticipation &&
            anticipation != null &&
            !anticipation!.isMovingAway &&
            !anticipation!.isAchieved)
        ? anticipation
        : null;

    final (minY, maxY) = TdeeWeightChartBuilder.calculateYBounds(
      validWeights,
      projection,
    );
    final totalXCount = points.length +
        (projection != null ? projection.projectionPoints.length : 0);

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
                maxX: math.max(1, (totalXCount - 1).toDouble()),
                gridData: TdeeWeightChartBuilder.buildGridData(colorScheme),
                titlesData: TdeeWeightChartBuilder.buildTitlesData(
                  colorScheme,
                  theme,
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: TdeeWeightChartBuilder.buildTouchData(
                  colorScheme,
                  theme,
                ),
                extraLinesData: TdeeWeightChartBuilder.buildExtraLines(
                  projection,
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
