import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/utils/currency_format.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/statistics/domain/spending_metrics.dart';
import 'package:yamt/features/statistics/domain/statistics_models.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_chart_card.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_error_card.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_metric_card.dart';
import 'package:yamt/features/statistics/presentation/widgets/'
    'statistics_vertical_bar_chart.dart';
import 'package:yamt/l10n/app_localizations.dart';

class StatisticsSpendingView extends StatelessWidget {
  const StatisticsSpendingView({
    super.key,
    required this.timeframe,
    required this.inventoryAsync,
    required this.onRetry,
  });

  final StatisticsTimeframe timeframe;
  final AsyncValue<List<InventoryItem>> inventoryAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();

    if (inventoryAsync.isLoading) {
      return const LinearProgressIndicator();
    }
    if (inventoryAsync.hasError) {
      return StatisticsErrorCard(onRetry: onRetry);
    }

    final inventoryItems = inventoryAsync.asData?.value;
    if (inventoryItems == null) {
      return StatisticsErrorCard(onRetry: onRetry);
    }

    final snapshot = _buildSnapshot(inventoryItems);
    final currency = buildCurrencyFormat(
      locale: locale,
      currencyCode: snapshot.currencyCode,
    );
    final topStore = snapshot.topStores.isEmpty
        ? null
        : snapshot.topStores.first;
    final topItem = snapshot.expensiveEntries.isEmpty
        ? null
        : snapshot.expensiveEntries.first;
    final topTrend = snapshot.priceTrends.isEmpty
        ? null
        : snapshot.priceTrends.first;
    final spendValues = snapshot.dailySpendValues;
    final chartDays = spendValues.length <= 7
        ? spendValues
        : spendValues.sublist(spendValues.length - 7);
    final spendChartData = chartDays
        .map((day) {
          return StatisticsBarChartDatum(
            label: DateFormat.Md(locale).format(day.date),
            value: day.value,
            valueLabel: currency.format(day.value),
          );
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatisticsChartCard(
          title: l10n.statisticsSpendingChartTitle,
          subtitle: l10n.statisticsSpendingChartSubtitle,
          child: spendChartData.isEmpty
              ? StatisticsChartEmptyState(
                  message: l10n.statisticsSpendingChartEmpty,
                )
              : StatisticsVerticalBarChart(data: spendChartData),
        ),
        const SizedBox(height: AppSpacing.lg),
        StatisticsMetricCard(
          title: l10n.statisticsSpendingTotalTitle,
          value: currency.format(snapshot.totalValue),
          subtitle: l10n.statisticsSpendingTotalSubtitle,
        ),
        const SizedBox(height: AppSpacing.lg),
        StatisticsMetricCard(
          title: l10n.statisticsSpendingTrendTitle,
          value: topTrend == null
              ? l10n.statisticsMetricNoTrend
              : _formatSignedPercent(topTrend.changeRatio),
          subtitle: topTrend == null
              ? l10n.statisticsSpendingTrendEmpty
              : '${topTrend.title} · ${currency.format(topTrend.latestPrice)}',
        ),
        const SizedBox(height: AppSpacing.lg),
        StatisticsMetricCard(
          title: l10n.statisticsSpendingStoresTitle,
          value: topStore == null
              ? l10n.statisticsMetricNoData
              : currency.format(topStore.value),
          subtitle: topStore == null
              ? l10n.statisticsTopStoresEmpty
              : '${topStore.storeName} · ${topStore.itemCount}',
        ),
        const SizedBox(height: AppSpacing.lg),
        StatisticsMetricCard(
          title: l10n.statisticsSpendingItemsTitle,
          value: topItem == null
              ? l10n.statisticsMetricNoData
              : currency.format(topItem.value),
          subtitle: topItem == null
              ? l10n.statisticsExpensiveItemsEmpty
              : topItem.title,
        ),
      ],
    );
  }

  StatisticsSpendingSnapshot _buildSnapshot(List<InventoryItem> items) {
    final startDate = _resolveHouseholdStartDate(items);
    return buildStatisticsSpendingSnapshot(
      items: items,
      startDate: startDate,
      endDate: DateUtils.dateOnly(DateTime.now()),
    );
  }

  DateTime _resolveHouseholdStartDate(List<InventoryItem> items) {
    final spendingDates = items
        .where((item) => !item.isReviewOnly)
        .map((item) => item.receiptDate ?? item.entryDate);
    if (spendingDates.isEmpty) {
      return _calendarStartDateForTimeframe(
        timeframe: timeframe,
        today: DateUtils.dateOnly(DateTime.now()),
      );
    }
    return resolveVisibleSpendingStartDate(
      spendingDates: spendingDates,
      maxVisibleDays: timeframe.dayCount,
      fallbackDate: DateTime.now(),
    );
  }

  DateTime _calendarStartDateForTimeframe({
    required StatisticsTimeframe timeframe,
    required DateTime today,
  }) {
    if (timeframe == StatisticsTimeframe.total) {
      return today.subtract(const Duration(days: 6));
    }

    final days = timeframe.dayCount ?? 7;
    return today.subtract(Duration(days: days - 1));
  }

  String _formatSignedPercent(double ratio) {
    final percent = (ratio * 100).round();
    if (percent > 0) {
      return '+$percent %';
    }
    return '$percent %';
  }
}
