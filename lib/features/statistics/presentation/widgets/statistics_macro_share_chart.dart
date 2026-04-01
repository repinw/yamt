import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/statistics/domain/statistics_metrics.dart';

class StatisticsMacroShareChart extends StatelessWidget {
  const StatisticsMacroShareChart({
    super.key,
    required this.items,
    required this.labelBuilder,
    required this.valueLabelBuilder,
  });

  final List<StatisticsMacroShare> items;
  final String Function(StatisticsMacroShare item) labelBuilder;
  final String Function(StatisticsMacroShare item) valueLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = <Color>[
      colors.tertiary,
      AppInventoryEditorial.primary,
      AppInventoryEditorial.warning,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: SizedBox(
            height: 16,
            child: Row(
              children: [
                for (var index = 0; index < items.length; index += 1)
                  Expanded(
                    flex: _segmentFlex(items[index].share),
                    child: ColoredBox(color: palette[index % palette.length]),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var index = 0; index < items.length; index += 1)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette[index % palette.length],
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const SizedBox(width: 12, height: 12),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    labelBuilder(items[index]),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(valueLabelBuilder(items[index])),
              ],
            ),
          ),
      ],
    );
  }

  int _segmentFlex(double share) {
    final flex = (share * 100).round();
    return flex < 1 ? 1 : flex;
  }
}
