import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/utils/currency_format.dart';
import 'package:yamt/features/statistics/domain/statistics_models.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_error_card.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_metric_card.dart';
import 'package:yamt/features/statistics/provider/'
    'statistics_waste_data_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines statistics waste view.
class StatisticsWasteView extends ConsumerWidget {
  /// The statistics waste view.
  const StatisticsWasteView({
    required this.timeframe,
    required this.onRetry,
    super.key,
  });

  /// The timeframe.
  final StatisticsTimeframe timeframe;

  /// The on retry.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final wasteAsync = ref.watch(statisticsWasteDataProvider(timeframe));

    return wasteAsync.when(
      data: (snapshot) {
        if (!snapshot.hasData) {
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

        final currency = buildCurrencyFormat(
          locale: locale,
          currencyCode: snapshot.currencyCode,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatisticsMetricCard(
              title: l10n.statisticsWasteOverviewTitle,
              value: snapshot.totalEvents.toString(),
              subtitle: l10n.statisticsWasteOverviewSummary(
                snapshot.totalEvents,
                currency.format(snapshot.totalDiscardedValue),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            StatisticsMetricCard(
              title: l10n.statisticsWasteRatioTitle,
              value: currency.format(snapshot.totalDiscardedValue),
              subtitle: l10n.statisticsWasteMoneyLossTracked,
            ),
            const SizedBox(height: AppSpacing.lg),
            StatisticsMetricCard(
              title: l10n.statisticsWasteReasonsTitle,
              value: snapshot.topReason == null
                  ? l10n.statisticsMetricNoData
                  : snapshot.topReason!.localizedLabel(l10n),
              subtitle: snapshot.topReason == null
                  ? l10n.statisticsWasteReasonsMissing
                  : l10n.statisticsWasteReasonsTopSummary(
                      snapshot.topReasonCount,
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            StatisticsMetricCard(
              title: l10n.statisticsWasteItemsTitle,
              value: snapshot.topItemName == null
                  ? l10n.statisticsMetricNoData
                  : snapshot.topItemName!,
              subtitle: snapshot.topItemName == null
                  ? l10n.statisticsWasteItemsMissing
                  : l10n.statisticsWasteItemsTopSummary(
                      snapshot.topItemCount,
                    ),
            ),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => StatisticsErrorCard(onRetry: onRetry),
    );
  }
}
