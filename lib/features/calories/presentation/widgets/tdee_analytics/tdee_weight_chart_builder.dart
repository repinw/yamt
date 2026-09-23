import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Helper class for configuring weight chart data and styles.
class TdeeWeightChartBuilder {
  const new _();

  /// Position of the trend line in `lineBarsData`.
  static const int trendBarIndex = 0;

  /// Position of the scale weight dots in `lineBarsData`.
  static const int scaleBarIndex = 1;

  /// Calculates Y-axis minimum and maximum bounds.
  static (double, double) calculateYBounds(
    List<TdeeAnalyticsPoint> points,
    TdeeAnticipationProjection? proj,
  ) {
    final values = <double>[
      for (final p in points) ...[?p.scaleWeightKg, ?p.trendWeightKg],
      ?proj?.targetWeightKg,
    ];
    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final roundedMin = (minVal - 1.0).floorToDouble();
    final roundedMax = (maxVal + 1.0).ceilToDouble();
    return (roundedMin, math.max(roundedMin + 2, roundedMax));
  }

  /// Builds the smooth trend weight line.
  static LineChartBarData buildTrendWeightBar(
    List<TdeeAnalyticsPoint> points,
    ColorScheme colorScheme,
  ) {
    return LineChartBarData(
      spots: [
        for (final (index, point) in points.indexed)
          if (point.trendWeightKg case final weight?)
            FlSpot(index.toDouble(), weight),
      ],
      isCurved: true,
      curveSmoothness: 0.2,
      preventCurveOverShooting: true,
      color: colorScheme.secondary,
      barWidth: AppSizes.weightChartTrendLineWidth,
      dotData: const FlDotData(show: false),
    );
  }

  /// Builds faint dots for the measured scale weights, without a line.
  static LineChartBarData buildScaleWeightDots(
    List<TdeeAnalyticsPoint> points,
    ColorScheme colorScheme,
  ) {
    final dotColor = colorScheme.secondary.withValues(
      alpha: AppOpacities.weightChartScaleDot,
    );
    return LineChartBarData(
      spots: [
        for (final (index, point) in points.indexed)
          if (point.scaleWeightKg case final weight?)
            FlSpot(index.toDouble(), weight),
      ],
      color: Colors.transparent,
      barWidth: 0,
      dotData: FlDotData(
        getDotPainter: (spot, xPercentage, bar, index) => FlDotCirclePainter(
          radius: AppSizes.weightChartScaleDotRadius,
          color: dotColor,
        ),
      ),
    );
  }

  /// Builds the dashed projection line, starting at the last trend weight.
  static LineChartBarData buildProjectionBar(
    List<TdeeAnalyticsPoint> points,
    TdeeAnticipationProjection proj,
    DateTime firstDay,
    ColorScheme colorScheme,
  ) {
    final startIndex = points.lastIndexWhere((p) => p.trendWeightKg != null);
    final start = startIndex < 0
        ? FlSpot(
            dayIndex(
              firstDay,
              proj.projectionPoints.firstOrNull?.day ?? firstDay,
            ),
            proj.currentWeightKg,
          )
        : FlSpot(startIndex.toDouble(), points[startIndex].trendWeightKg!);
    return LineChartBarData(
      spots: [
        start,
        for (final p in proj.projectionPoints)
          if (dayIndex(firstDay, p.day) > start.x)
            FlSpot(dayIndex(firstDay, p.day), p.weightKg),
      ],
      isCurved: true,
      curveSmoothness: 0.1,
      color: colorScheme.tertiary,
      dashArray: const [5, 5],
      dotData: const FlDotData(show: false),
    );
  }

  /// Builds the target weight guide line and the goal end markers.
  static ExtraLinesData buildExtraLines(
    TdeeAnticipationProjection? proj,
    List<TdeeAnalyticsGoalCycle> cycles,
    DateTime firstDay,
    ColorScheme colorScheme,
    AppLocalizations l10n,
    NumberFormat weightFormat,
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
                      l10n.tdeeWeightTargetLine(weightFormat.format(line.y)),
                ),
              ),
            ],
      verticalLines: [
        for (final cycle in cycles)
          if (goalMarkerDate(cycle) case final markerDate?)
            _buildGoalMarker(cycle, markerDate, firstDay, colorScheme, l10n),
      ],
    );
  }

  /// Date at which [cycle] ended, was reached, or is estimated to end.
  static DateTime? goalMarkerDate(TdeeAnalyticsGoalCycle cycle) {
    return cycle.endDate ?? cycle.reachedDate ?? cycle.estimatedEndDate;
  }

  static VerticalLine _buildGoalMarker(
    TdeeAnalyticsGoalCycle cycle,
    DateTime markerDate,
    DateTime firstDay,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final isConfirmed = cycle.endDate != null || cycle.reachedDate != null;
    final color = isConfirmed ? colorScheme.primary : colorScheme.tertiary;
    return VerticalLine(
      x: dayIndex(firstDay, markerDate),
      color: color,
      strokeWidth: 1.5,
      dashArray: isConfirmed ? null : const [5, 4],
      label: VerticalLineLabel(
        show: true,
        alignment: Alignment.topRight,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.bold,
        ),
        labelResolver: (_) => cycle.endDate != null
            ? l10n.goalArchiveEndLabel
            : cycle.reachedDate != null
            ? l10n.goalArchiveReachedLabel
            : l10n.tdeeChartEstimateMarker,
      ),
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
                dateFormat.format(addDiaryDays(firstDay, dayOffset)),
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

  /// Whole days from [firstDay] to [day], safe across daylight saving changes.
  static double dayIndex(DateTime firstDay, DateTime day) {
    return (day.difference(firstDay).inHours / Duration.hoursPerDay)
        .roundToDouble();
  }
}
