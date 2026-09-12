import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
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
    DateTime firstDay,
    ColorScheme colorScheme,
  ) {
    final spots = <FlSpot>[];
    final lastWeightPoint = points.lastWhere(
      (point) => point.scaleWeightKg != null,
      orElse: () => points.last,
    );
    final startIndex = lastWeightPoint.day.difference(firstDay).inDays;
    final lastWeight = lastWeightPoint.scaleWeightKg ?? proj.currentWeightKg;
    spots.add(FlSpot(startIndex.toDouble(), lastWeight));

    for (final p in proj.projectionPoints) {
      final x = p.day.difference(firstDay).inDays.toDouble();
      if (x > startIndex) {
        spots.add(FlSpot(x, p.weightKg));
      }
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
    List<TdeeAnalyticsGoalCycle> cycles,
    DateTime firstDay,
    ColorScheme colorScheme,
  ) {
    return ExtraLinesData(
      horizontalLines: proj == null
          ? const []
          : [
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
                  labelResolver: (line) =>
                      'Ziel ${line.y.toStringAsFixed(1)} kg',
                ),
              ),
            ],
      verticalLines: [
        for (final cycle in cycles)
          if (cycle.endDate ?? cycle.reachedDate ?? cycle.estimatedEndDate
              case final markerDate?)
            VerticalLine(
              x: markerDate.difference(firstDay).inDays.toDouble(),
              color: cycle.endDate != null || cycle.reachedDate != null
                  ? colorScheme.primary
                  : colorScheme.tertiary,
              strokeWidth: 1.5,
              dashArray: cycle.endDate == null && cycle.reachedDate == null
                  ? const [5, 4]
                  : null,
              label: VerticalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: TextStyle(
                  fontSize: 9,
                  color: cycle.endDate != null || cycle.reachedDate != null
                      ? colorScheme.primary
                      : colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                ),
                labelResolver: (_) => cycle.endDate != null
                    ? 'Ende'
                    : cycle.reachedDate != null
                    ? 'Erreicht'
                    : 'Schätzung',
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
    ThemeData theme, {
    required DateTime firstDay,
    required double maxX,
    required String locale,
  }) {
    final dateFormat = DateFormat.Md(locale);
    final bottomInterval = math.max(1, (maxX / 6).ceil()).toDouble();
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
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: bottomInterval,
          getTitlesWidget: (value, meta) {
            final dayOffset = value.round();
            if ((value - dayOffset).abs() > 0.01 ||
                dayOffset < 0 ||
                dayOffset > maxX.round()) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                dateFormat.format(
                  firstDay.add(Duration(days: dayOffset)),
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                  fontSize: 10,
                ),
              ),
            );
          },
        ),
      ),
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
