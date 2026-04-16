import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_health_trend_snapshot.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines calorie health trend chart.
class CalorieHealthTrendChart extends StatelessWidget {
  /// The calorie health trend chart.
  const CalorieHealthTrendChart({required this.snapshot, super.key});

  /// The snapshot.
  final CalorieHealthTrendSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final intakeValues = snapshot.points
        .where((point) => point.intakeKcal > 0)
        .map((point) => point.intakeKcal)
        .toList(growable: false);
    final burnedValues = snapshot.points
        .map((point) => point.burnedKcal?.toDouble())
        .whereType<double>()
        .toList(growable: false);
    final weightValues = snapshot.points
        .map((point) => point.weightKg)
        .whereType<double>()
        .toList(growable: false);
    final layout = _TrendChartLayout.build(
      calorieValues: <double>[...intakeValues, ...burnedValues],
      weightValues: weightValues,
    );
    if (!layout.hasAnyData || snapshot.points.isEmpty) {
      return SizedBox(
        height: 260,
        child: Center(
          child: Text(
            l10n.caloriesHealthTrendsEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      );
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    final calorieFormat = NumberFormat.compact(locale: locale);
    final dayFormat = DateFormat.E(locale);
    final weightFormat = NumberFormat('0.#', locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            _LegendChip(
              color: colors.tertiary,
              label: l10n.caloriesHealthTrendsLegendWeight,
            ),
            _LegendChip(
              color: colors.secondary,
              label: l10n.caloriesHealthTrendsLegendBurned,
            ),
            _LegendChip(
              color: colors.primary,
              label: l10n.caloriesHealthTrendsLegendIntake,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (snapshot.points.length - 1).toDouble(),
              minY: layout.minY,
              maxY: layout.maxY,
              clipData: const FlClipData.all(),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(color: colors.outlineVariant),
                  bottom: BorderSide(color: colors.outlineVariant),
                ),
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: layout.interval,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: colors.outlineVariant.withValues(alpha: 0.4),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: layout.showCalorieAxis,
                    reservedSize: 42,
                    interval: layout.interval,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        calorieFormat.format(value),
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: layout.showWeightAxis,
                    reservedSize: 44,
                    interval: layout.interval,
                    getTitlesWidget: (value, meta) {
                      final weightValue = layout.weightFromChartValue(value);
                      if (weightValue == null) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        weightFormat.format(weightValue),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 || index >= snapshot.points.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          dayFormat.format(snapshot.points[index].day),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (spots) {
                    return spots
                        .map((spot) {
                          final point = snapshot.points[spot.x.toInt()];
                          final valueLabel = switch (spot.barIndex) {
                            0 =>
                              '${point.intakeKcal.toStringAsFixed(0)} '
                                  '${l10n.caloriesUnitKcal}',
                            1 when point.burnedKcal != null =>
                              '${point.burnedKcal} ${l10n.caloriesUnitKcal}',
                            2 when point.weightKg != null =>
                              '${weightFormat.format(point.weightKg)} '
                                  '${l10n.caloriesUnitKg}',
                            _ => spot.y.toStringAsFixed(1),
                          };
                          return LineTooltipItem(
                            '${dayFormat.format(point.day)}\n$valueLabel',
                            TextStyle(
                              color: spot.bar.color ?? colors.onInverseSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        })
                        .toList(growable: false);
                  },
                ),
              ),
              lineBarsData: [
                _buildLine(
                  points: snapshot.points,
                  color: colors.primary,
                  selector: (point) => point.intakeKcal,
                  transformY: (value) => value,
                ),
                _buildLine(
                  points: snapshot.points,
                  color: colors.secondary,
                  selector: (point) => point.burnedKcal?.toDouble(),
                  transformY: (value) => value,
                ),
                _buildLine(
                  points: snapshot.points,
                  color: colors.tertiary,
                  selector: (point) => point.weightKg,
                  transformY: layout.mapWeight,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _buildLine({
    required List<CalorieHealthTrendPoint> points,
    required Color color,
    required double? Function(CalorieHealthTrendPoint point) selector,
    required double Function(double value) transformY,
  }) {
    return LineChartBarData(
      spots: [
        for (var index = 0; index < points.length; index += 1)
          if (selector(points[index]) case final value?)
            FlSpot(index.toDouble(), transformY(value)),
      ],
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      belowBarData: BarAreaData(),
    );
  }
}

class _TrendChartLayout {
  const _TrendChartLayout({
    required this.hasAnyData,
    required this.minY,
    required this.maxY,
    required this.interval,
    required this.showCalorieAxis,
    required this.showWeightAxis,
    required this.weightMin,
    required this.weightMax,
    required this.weightUsesIdentity,
  });

  factory _TrendChartLayout.build({
    required List<double> calorieValues,
    required List<double> weightValues,
  }) {
    if (calorieValues.isEmpty && weightValues.isEmpty) {
      return const _TrendChartLayout(
        hasAnyData: false,
        minY: 0,
        maxY: 1,
        interval: 1,
        showCalorieAxis: false,
        showWeightAxis: false,
        weightMin: null,
        weightMax: null,
        weightUsesIdentity: false,
      );
    }

    if (calorieValues.isNotEmpty) {
      final calorieRange = _paddedRange(
        calorieValues,
        minimumPadding: 1,
        relativePadding: 0.12,
      );
      double? weightMin;
      double? weightMax;
      if (weightValues.isNotEmpty) {
        final weightRange = _paddedRange(
          weightValues,
          minimumPadding: 0.2,
          relativePadding: 0.08,
        );
        weightMin = weightRange.$1;
        weightMax = weightRange.$2;
      }
      final minY = calorieRange.$1;
      final maxY = calorieRange.$2;
      return _TrendChartLayout(
        hasAnyData: true,
        minY: minY,
        maxY: maxY,
        interval: ((maxY - minY) / 4).clamp(1.0, double.infinity),
        showCalorieAxis: true,
        showWeightAxis: weightMin != null && weightMax != null,
        weightMin: weightMin,
        weightMax: weightMax,
        weightUsesIdentity: false,
      );
    }

    final weightRange = _paddedRange(
      weightValues,
      minimumPadding: 0.2,
      relativePadding: 0.08,
    );
    final minY = weightRange.$1;
    final maxY = weightRange.$2;
    return _TrendChartLayout(
      hasAnyData: true,
      minY: minY,
      maxY: maxY,
      interval: ((maxY - minY) / 4).clamp(0.1, double.infinity),
      showCalorieAxis: false,
      showWeightAxis: true,
      weightMin: minY,
      weightMax: maxY,
      weightUsesIdentity: true,
    );
  }

  final bool hasAnyData;
  final double minY;
  final double maxY;
  final double interval;
  final bool showCalorieAxis;
  final bool showWeightAxis;
  final double? weightMin;
  final double? weightMax;
  final bool weightUsesIdentity;

  double mapWeight(double value) {
    final weightMin = this.weightMin;
    final weightMax = this.weightMax;
    if (weightMin == null || weightMax == null) {
      return value;
    }
    if (weightUsesIdentity || weightMax == weightMin) {
      return value;
    }
    final ratio = (value - weightMin) / (weightMax - weightMin);
    return minY + ratio * (maxY - minY);
  }

  double? weightFromChartValue(double chartValue) {
    final weightMin = this.weightMin;
    final weightMax = this.weightMax;
    if (weightMin == null || weightMax == null) {
      return null;
    }
    if (weightUsesIdentity || maxY == minY) {
      return chartValue;
    }
    final ratio = (chartValue - minY) / (maxY - minY);
    return weightMin + ratio * (weightMax - weightMin);
  }
}

(double, double) _paddedRange(
  List<double> values, {
  required double minimumPadding,
  required double relativePadding,
}) {
  final minValue = values.reduce((left, right) => left < right ? left : right);
  final maxValue = values.reduce((left, right) => left > right ? left : right);
  final span = (maxValue - minValue).abs();
  final padding = span == 0
      ? (maxValue.abs() * relativePadding).clamp(
          minimumPadding,
          double.infinity,
        )
      : span * relativePadding;
  return ((minValue - padding).clamp(0.0, double.infinity), maxValue + padding);
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
