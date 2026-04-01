import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_error_card.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_metric_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

class StatisticsWasteView extends StatelessWidget {
  const StatisticsWasteView({
    super.key,
    required this.inventoryAsync,
    required this.mealsAsync,
    required this.onRetry,
  });

  final AsyncValue<List<InventoryItem>> inventoryAsync;
  final AsyncValue<List<PreparedMeal>> mealsAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (inventoryAsync.isLoading || mealsAsync.isLoading) {
      return const LinearProgressIndicator();
    }
    if (inventoryAsync.hasError || mealsAsync.hasError) {
      return StatisticsErrorCard(onRetry: onRetry);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatisticsMetricCard(
          title: l10n.statisticsWasteOverviewTitle,
          value: l10n.statisticsWasteTrackingMissingValue,
          subtitle: l10n.statisticsWasteTrackingMissingMessage,
        ),
        const SizedBox(height: AppSpacing.lg),
        StatisticsMetricCard(
          title: l10n.statisticsWasteRatioTitle,
          value: l10n.statisticsWasteTrackingMissingValue,
          subtitle: l10n.statisticsWasteMoneyLossMissing,
        ),
        const SizedBox(height: AppSpacing.lg),
        StatisticsMetricCard(
          title: l10n.statisticsWasteReasonsTitle,
          value: l10n.statisticsMetricNoData,
          subtitle: l10n.statisticsWasteReasonsMissing,
        ),
        const SizedBox(height: AppSpacing.lg),
        StatisticsMetricCard(
          title: l10n.statisticsWasteItemsTitle,
          value: l10n.statisticsMetricNoData,
          subtitle: l10n.statisticsWasteItemsMissing,
        ),
      ],
    );
  }
}
