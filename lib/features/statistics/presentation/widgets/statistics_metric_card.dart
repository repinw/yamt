import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_surface_card.dart';

/// Tappable KPI card used throughout the statistics overview.
class StatisticsMetricCard extends StatelessWidget {
  const StatisticsMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    this.onTap,
    this.valueColor,
    this.trailing,
  });

  final String title;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.md),
          trailing!,
        ] else if (onTap != null) ...[
          const SizedBox(width: AppSpacing.md),
          Icon(Icons.arrow_forward_rounded, color: colors.onSurfaceVariant),
        ],
      ],
    );

    if (onTap == null) {
      return StatisticsSurfaceCard(child: content);
    }

    return StatisticsSurfaceCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: onTap,
          child: Padding(padding: AppInsets.card, child: content),
        ),
      ),
    );
  }
}
