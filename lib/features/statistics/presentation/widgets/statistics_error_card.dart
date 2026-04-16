import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_surface_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines statistics error card.
class StatisticsErrorCard extends StatelessWidget {
  /// The statistics error card.
  const StatisticsErrorCard({required this.onRetry, super.key});

  /// The on retry.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StatisticsSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statisticsLoadFailed,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.tonal(
            onPressed: onRetry,
            child: Text(l10n.inventoryRetryAction),
          ),
        ],
      ),
    );
  }
}
