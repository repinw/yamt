import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_surface_card.dart';

/// Defines statistics chart card.
class StatisticsChartCard extends StatelessWidget {
  /// The statistics chart card.
  const StatisticsChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
    this.legend,
  });

  /// The title.
  final String title;

  /// The subtitle.
  final String subtitle;

  /// The child.
  final Widget child;

  /// The legend.
  final String? legend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return StatisticsSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          if (legend != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const SizedBox(width: 16, height: 2),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  legend!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

/// Defines statistics chart empty state.
class StatisticsChartEmptyState extends StatelessWidget {
  /// The statistics chart empty state.
  const StatisticsChartEmptyState({required this.message, super.key});

  /// The message.
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 160,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
      ),
    );
  }
}
