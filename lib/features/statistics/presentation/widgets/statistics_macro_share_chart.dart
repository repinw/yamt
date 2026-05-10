import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/statistics/domain/calorie_metrics.dart';

/// Defines statistics macro share chart.
class StatisticsMacroShareChart extends StatelessWidget {
  /// The statistics macro share chart.
  const StatisticsMacroShareChart({
    required this.items,
    required this.labelBuilder,
    required this.valueLabelBuilder,
    super.key,
  });

  /// The items.
  final List<StatisticsMacroShare> items;

  /// The label builder.
  final String Function(StatisticsMacroShare item) labelBuilder;

  /// The value label builder.
  final String Function(StatisticsMacroShare item) valueLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = <Color>[colors.tertiary, colors.primary, colors.error];
    final visibleItems = items.asMap().entries.where(
      (entry) => entry.value.share > 0,
    );
    final hasMacroData = visibleItems.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: SizedBox(
            height: 16,
            child: Row(
              children: [
                if (!hasMacroData)
                  Expanded(
                    child: ColoredBox(
                      key: const ValueKey('statistics-macro-share-empty-bar'),
                      color: colors.surfaceContainerHighest,
                    ),
                  ),
                for (final entry in visibleItems)
                  Expanded(
                    flex: _segmentFlex(entry.value.share),
                    child: ColoredBox(
                      key: ValueKey(
                        'statistics-macro-share-segment-${entry.key}',
                      ),
                      color: palette[entry.key % palette.length],
                    ),
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
