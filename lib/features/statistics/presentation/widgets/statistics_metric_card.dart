import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_surface_card.dart';

/// KPI card used throughout the statistics overview.
class StatisticsMetricCard extends StatelessWidget {
  /// The statistics metric card.
  const StatisticsMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    super.key,
    this.valueColor,
  });

  /// The title.
  final String title;

  /// The value.
  final String value;

  /// The subtitle.
  final String subtitle;

  /// The value color.
  final Color? valueColor;

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
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: valueColor ?? colors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
