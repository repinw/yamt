import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';

/// Interactive line chart displaying learned TDEE with a shaded flux range.
class TdeeFluxChart extends StatelessWidget {
  /// Creates the TDEE flux chart.
  const TdeeFluxChart({
    required this.points,
    super.key,
  });

  /// Chronological daily points.
  final List<TdeeAnalyticsPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return _buildEmptyState(context);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final validPoints =
        points.where((p) => p.learnedBaseTdeeKcal != null).toList();

    if (validPoints.length < 2) {
      return _buildEmptyState(context);
    }

    final (minY, maxY) = _calculateYBounds(validPoints);

    return SizedBox(
      height: 240,
      child: Padding(
        padding: const EdgeInsets.only(
          right: AppSpacing.md,
          left: AppSpacing.sm,
          top: AppSpacing.md,
          bottom: AppSpacing.sm,
        ),
        child: LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            minX: 0,
            maxX: (points.length - 1).toDouble(),
            gridData: _buildGridData(colorScheme),
            titlesData: _buildTitlesData(colorScheme, theme),
            borderData: FlBorderData(show: false),
            lineTouchData: _buildTouchData(colorScheme, theme),
            betweenBarsData: [
              BetweenBarsData(
                fromIndex: 0,
                toIndex: 1,
                color: colorScheme.primary.withValues(alpha: 0.15),
              ),
            ],
            lineBarsData: [
              _buildBaseTdeeBar(colorScheme),
              _buildTotalTdeeBar(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  LineChartBarData _buildBaseTdeeBar(ColorScheme colorScheme) {
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final val = points[i].learnedBaseTdeeKcal;
      if (val != null) {
        spots.add(FlSpot(i.toDouble(), val));
      }
    }
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.25,
      color: colorScheme.primary,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
    );
  }

  LineChartBarData _buildTotalTdeeBar(ColorScheme colorScheme) {
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final base = points[i].learnedBaseTdeeKcal;
      final total = points[i].totalTdeeKcal ?? base;
      if (total != null) {
        spots.add(FlSpot(i.toDouble(), total));
      }
    }
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.25,
      color: colorScheme.primary.withValues(alpha: 0.3),
      barWidth: 1,
      dotData: const FlDotData(show: false),
    );
  }

  FlGridData _buildGridData(ColorScheme colorScheme) {
    return FlGridData(
      drawVerticalLine: false,
      horizontalInterval: 200,
      getDrawingHorizontalLine: (value) => FlLine(
        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        strokeWidth: 1,
        dashArray: const [4, 4],
      ),
    );
  }

  FlTitlesData _buildTitlesData(ColorScheme colorScheme, ThemeData theme) {
    final interval = math.max(1, (points.length / 5).floor());
    return FlTitlesData(
      leftTitles: const AxisTitles(),
      topTitles: const AxisTitles(),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 46,
          interval: 200,
          getTitlesWidget: (val, meta) => Text(
            val.toInt().toString(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 26,
          interval: interval.toDouble(),
          getTitlesWidget: (val, meta) {
            final index = val.toInt();
            if (index < 0 || index >= points.length) {
              return const SizedBox.shrink();
            }
            final day = points[index].day;
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${day.day}.${day.month}.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  LineTouchData _buildTouchData(ColorScheme colorScheme, ThemeData theme) {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            final index = spot.x.toInt();
            if (index < 0 || index >= points.length) {
              return null;
            }
            final p = points[index];
            final dayStr = '${p.day.day}.${p.day.month}.${p.day.year}';
            final val = spot.y.round();
            return LineTooltipItem(
              '$dayStr\n$val kcal',
              theme.textTheme.labelMedium!.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList();
        },
      ),
    );
  }

  (double, double) _calculateYBounds(List<TdeeAnalyticsPoint> valid) {
    var minVal = double.infinity;
    var maxVal = double.negativeInfinity;

    for (final p in valid) {
      final base = p.learnedBaseTdeeKcal!;
      final total = p.totalTdeeKcal ?? base;
      if (base < minVal) minVal = base;
      if (total > maxVal) maxVal = total;
    }

    final roundedMin = ((minVal - 80) / 100).floor() * 100.0;
    final roundedMax = ((maxVal + 80) / 100).ceil() * 100.0;
    return (roundedMin, math.max(roundedMin + 200, roundedMax));
  }

  Widget _buildEmptyState(BuildContext context) {
    return const SizedBox(
      height: 200,
      child: Center(
        child: Text('Nicht genügend Daten für diesen Zeitraum vorhanden.'),
      ),
    );
  }
}
