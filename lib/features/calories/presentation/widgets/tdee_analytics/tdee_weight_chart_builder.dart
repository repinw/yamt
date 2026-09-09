import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';

/// Helper class for configuring weight chart data and styles.
class TdeeWeightChartBuilder {
  const TdeeWeightChartBuilder._();

  /// Calculates Y-axis minimum and maximum bounds.
  static (double, double) calculateYBounds(
    List<TdeeAnalyticsPoint> valid,
    TdeeAnticipationProjection? proj,
  ) {
    var minVal = double.infinity;
    var maxVal = double.negativeInfinity;

    for (final p in valid) {
      final w = p.scaleWeightKg!;
      if (w < minVal) minVal = w;
      if (w > maxVal) maxVal = w;
    }

    if (proj != null) {
      if (proj.targetWeightKg < minVal) minVal = proj.targetWeightKg;
      if (proj.targetWeightKg > maxVal) maxVal = proj.targetWeightKg;
    }

    final roundedMin = (minVal - 1.0).floorToDouble();
    final roundedMax = (maxVal + 1.0).ceilToDouble();
    return (roundedMin, math.max(roundedMin + 2, roundedMax));
  }

  /// Builds the historical scale weight line.
  static LineChartBarData buildHistoricalWeightBar(
    List<TdeeAnalyticsPoint> points,
    ColorScheme colorScheme,
  ) {
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final weight = points[i].scaleWeightKg;
      if (weight != null) {
        spots.add(FlSpot(i.toDouble(), weight));
      }
    }
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.15,
      color: colorScheme.secondary,
      barWidth: 2.5,
      dotData: FlDotData(
        show: spots.length <= 14,
        getDotPainter: (spot, xPercentage, bar, index) => FlDotCirclePainter(
          radius: 3,
          color: colorScheme.secondary,
          strokeWidth: 1,
          strokeColor: colorScheme.surface,
        ),
      ),
    );
  }

  /// Builds the dashed projection anticipation line.
  static LineChartBarData buildProjectionBar(
    List<TdeeAnalyticsPoint> points,
    TdeeAnticipationProjection proj,
    ColorScheme colorScheme,
  ) {
    final spots = <FlSpot>[];
    final startIndex = points.length - 1;
    final lastWeight = points.last.scaleWeightKg ?? proj.currentWeightKg;
    spots.add(FlSpot(startIndex.toDouble(), lastWeight));

    for (var i = 0; i < proj.projectionPoints.length; i++) {
      final p = proj.projectionPoints[i];
      spots.add(FlSpot((startIndex + i + 1).toDouble(), p.weightKg));
    }

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.1,
      color: colorScheme.tertiary,
      dashArray: const [5, 5],
      dotData: const FlDotData(show: false),
    );
  }

  /// Builds horizontal target weight guide line.
  static ExtraLinesData buildExtraLines(
    TdeeAnticipationProjection? proj,
    ColorScheme colorScheme,
  ) {
    if (proj == null) return const ExtraLinesData();
    return ExtraLinesData(
      horizontalLines: [
        HorizontalLine(
          y: proj.targetWeightKg,
          color: colorScheme.tertiary.withValues(alpha: 0.6),
          strokeWidth: 1,
          dashArray: const [6, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 50, bottom: 2),
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.tertiary,
              fontWeight: FontWeight.bold,
            ),
            labelResolver: (line) => 'Ziel ${line.y.toStringAsFixed(1)} kg',
          ),
        ),
      ],
    );
  }

  /// Builds grid style.
  static FlGridData buildGridData(ColorScheme colorScheme) {
    return FlGridData(
      drawVerticalLine: false,
      horizontalInterval: 1,
      getDrawingHorizontalLine: (value) => FlLine(
        color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        strokeWidth: 1,
        dashArray: const [4, 4],
      ),
    );
  }

  /// Builds axis labels.
  static FlTitlesData buildTitlesData(
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return FlTitlesData(
      leftTitles: const AxisTitles(),
      topTitles: const AxisTitles(),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 46,
          interval: 2,
          getTitlesWidget: (val, meta) => Text(
            '${val.toStringAsFixed(0)} kg',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ),
      ),
      bottomTitles: const AxisTitles(),
    );
  }

  /// Builds touch tooltips.
  static LineTouchData buildTouchData(
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
          final val = spot.y.toStringAsFixed(1);
          return LineTooltipItem(
            '$val kg',
            theme.textTheme.labelMedium!.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList(),
      ),
    );
  }
}
