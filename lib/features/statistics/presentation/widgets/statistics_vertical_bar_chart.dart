import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

/// Defines statistics bar chart datum.
class StatisticsBarChartDatum {
  /// The statistics bar chart datum.
  const StatisticsBarChartDatum({
    required this.label,
    required this.value,
    this.goalValue,
    this.valueLabel,
  });

  /// The label.
  final String label;

  /// The value.
  final double value;

  /// The goal value.
  final double? goalValue;

  /// The value label.
  final String? valueLabel;
}

/// Lightweight bar chart for the statistics MVP.
class StatisticsVerticalBarChart extends StatelessWidget {
  /// The statistics vertical bar chart.
  const StatisticsVerticalBarChart({
    required this.data, super.key,
    this.height = 180,
  });

  /// The data.
  final List<StatisticsBarChartDatum> data;

  /// The height.
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxValue = _resolveMaxValue();

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final item in data)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Column(
                  children: [
                    Text(
                      item.valueLabel ?? item.value.round().toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final chartHeight = constraints.maxHeight;
                          final barHeight = maxValue <= 0
                              ? 0.0
                              : (item.value / maxValue) * chartHeight;
                          final goalLineBottom = _goalLineBottom(
                            item: item,
                            maxValue: maxValue,
                            chartHeight: chartHeight,
                          );

                          return Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
                                ),
                              ),
                              if (goalLineBottom != null)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: goalLineBottom,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: colors.onSurfaceVariant,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: const SizedBox(height: 2),
                                  ),
                                ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  width: double.infinity,
                                  height: barHeight.clamp(0.0, chartHeight),
                                  decoration: BoxDecoration(
                                    gradient:
                                        AppInventoryEditorialSurfaces.soulGradient(
                                          colors,
                                        ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.lg,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      item.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _resolveMaxValue() {
    var maxValue = 0.0;
    for (final item in data) {
      if (item.value > maxValue) {
        maxValue = item.value;
      }
      final goalValue = item.goalValue;
      if (goalValue != null && goalValue > maxValue) {
        maxValue = goalValue;
      }
    }
    return maxValue;
  }

  double? _goalLineBottom({
    required StatisticsBarChartDatum item,
    required double maxValue,
    required double chartHeight,
  }) {
    final goalValue = item.goalValue;
    if (goalValue == null || goalValue <= 0 || maxValue <= 0) {
      return null;
    }
    return (goalValue / maxValue) * chartHeight;
  }
}
